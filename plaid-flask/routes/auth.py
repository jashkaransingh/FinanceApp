from flask import Blueprint, jsonify, request
from plaid_client import plaid_client
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
# --- New Imports ---
from firebase_admin import auth, firestore
import traceback
from plaid.model.item_remove_request import ItemRemoveRequest
import config # Import your config file

auth_bp = Blueprint("auth", __name__)


# --- MODIFIED: This endpoint is now secure ---
@auth_bp.route("/create_link_token", methods=["POST"])
def create_link_token():
    """
    Creates a Plaid Link token, now associated with a verified Firebase user.
    The iOS app must send the user's Firebase ID Token in the Authorization header.
    """
    try:
        # 1. Verify the user's Firebase ID token from the request header.
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        print(f"✅ Verified user with UID: {uid}")

        # 2. Create the Link Token request for Plaid.
        #    We now use the real user's UID for client_user_id.
        plaid_request = LinkTokenCreateRequest(
            user=LinkTokenCreateRequestUser(client_user_id=uid),
            client_name="Finance App", # You can customize this
            products=[Products("transactions")],
            country_codes=[CountryCode("US")],
            language="en",
            redirect_uri=config.PLAID_REDIRECT_URI # <-- ADD THIS LINE
        )
        
        # 3. Make the request to Plaid and return the link_token to the client.
        response = plaid_client.link_token_create(plaid_request)
        return jsonify(link_token=response['link_token'])
        
    except Exception as e:
        traceback.print_exc()
        return jsonify(error=str(e)), 500


# --- MODIFIED: This endpoint is now secure and handles everything ---
@auth_bp.route("/exchange_public_token", methods=["POST"])
def exchange_public_token():
    """
    Exchanges a public_token for an access_token and saves it directly to Firestore.
    Does NOT return the access_token to the client.
    Requires the user's Firebase ID Token for verification.
    """
    try:
        # 1. Verify the user's Firebase ID token.
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        print(f"✅ Verified user for token exchange with UID: {uid}")

        # 2. Get the public_token from the request body.
        public_token = request.json.get("public_token")
        if not public_token:
            return jsonify(error="Missing public_token in request body."), 400

        # 3. Exchange the public_token for an access_token with Plaid.
        exchange_request = ItemPublicTokenExchangeRequest(public_token=public_token)
        exchange_response = plaid_client.item_public_token_exchange(exchange_request)
        access_token = exchange_response['access_token']
        item_id = exchange_response['item_id'] # Plaid's ID for this linked item

        # 4. Save the new, secure token directly to the user's Firestore document.
        db = firestore.client()
        user_ref = db.collection('users').document(uid)
        user_ref.update({
            'plaidAccessToken': access_token,
            'plaidItemId': item_id,
            'isBankConnected': True
        })
        
        print(f"✅ Successfully saved access token for user {uid}")
        return jsonify(success=True)
    except Exception as e:
        traceback.print_exc()
        return jsonify(error=str(e)), 500

@auth_bp.route("/remove_item", methods=["POST"])
def remove_item():
    """
    Securely removes a Plaid item.
    The client no longer needs to know the access_token.
    """
    try:
        # 1. Verify the user is legitimate via their Firebase ID token
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        print(f"✅ Verified user for item removal with UID: {uid}")
        
        # 2. Get the user's access token from Firestore
        db = firestore.client()
        user_ref = db.collection('users').document(uid)
        user_doc = user_ref.get()

        if not user_doc.exists or 'plaidAccessToken' not in user_doc.to_dict():
            return jsonify(error="No Plaid access token found for this user to remove."), 404
        access_token = user_doc.to_dict()['plaidAccessToken']

        # 3. Call Plaid's /item/remove endpoint
        remove_request = ItemRemoveRequest(access_token=access_token)
        response = plaid_client.item_remove(remove_request)
        
        # 4. Clean up the user's document in Firestore
        user_ref.update({
            'plaidAccessToken': firestore.DELETE_FIELD,
            'plaidItemId': firestore.DELETE_FIELD,
            'isBankConnected': firestore.DELETE_FIELD
        })
        
        print(f"✅ Successfully removed Plaid item and cleaned up Firestore for user {uid}")
        # The response object doesn't have a 'removed' key.
        # A simple success JSON is all that's needed. The 200 OK status is what the client checks.
        return jsonify(success=True)

    except Exception as e:
        traceback.print_exc()
        return jsonify(error=str(e)), 500
