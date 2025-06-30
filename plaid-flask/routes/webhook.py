from flask import Blueprint, request, jsonify
from firebase_admin import firestore
import traceback

# We will import and use a new service function we are about to create.
from services.transaction_service import sync_transactions_for_item

webhook_bp = Blueprint("webhook", __name__)

def find_user_by_item_id(item_id):
    """
    Queries the 'users' collection to find which user a Plaid item_id belongs to.
    """
    db = firestore.client()
    users_ref = db.collection('users')
    query = users_ref.where('plaidItemId', '==', item_id).limit(1)
    docs = query.stream()
    
    for doc in docs:
        # Return the user's ID as soon as we find a match
        return doc.id
    
    # Return None if no user is found with that item_id
    return None

@webhook_bp.route("/plaid-webhook", methods=["POST"])
def plaid_webhook():
    """
    This is the main endpoint that Plaid will call to send updates.
    """
    data = request.get_json(force=True)
    print("🔔 Plaid Webhook Received:")
    print(data)

    webhook_type = data.get('webhook_type')
    webhook_code = data.get('webhook_code')
    item_id = data.get('item_id')

    # This is the most common webhook, sent when new transaction data is available.
    if webhook_code == 'SYNC_UPDATES_AVAILABLE':
        print(f"🔄 Sync updates available for item: {item_id}")
        
        # 1. Find which of our users this update belongs to.
        uid = find_user_by_item_id(item_id)
        
        if uid:
            # 2. If we found a user, trigger a transaction sync for them.
            print(f"Found user {uid} for item {item_id}. Triggering sync.")
            sync_transactions_for_item(uid)
        else:
            print(f"⚠️ Could not find user for item_id: {item_id}")

    # It's critical to always respond with a 200 OK to Plaid
    return jsonify(status='ok')