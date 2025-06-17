
from flask import Blueprint, jsonify, request
from plaid_client import plaid_client
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/create_link_token", methods=["POST"])
def create_link_token():
    try:
        request_data = LinkTokenCreateRequest( #request body to send to plaid
            user=LinkTokenCreateRequestUser(client_user_id="user-123"),# dummy for now
            client_name="My Finance App",
            products=[Products("transactions")],#telling plaid what products we want
            country_codes=[CountryCode("US")],
            language="en",
            # this must match your CFBundleURLSchemes entry above:
            redirect_uri="https://1699-8-34-174-169.ngrok-free.app/oauth-redirect",
            # hosted_link=LinkTokenCreateRequestHostedLink(
            # completion_redirect_uri="com.mycompany.myapp://oauth-redirect",
            # is_mobile_app=True
        )
        response = plaid_client.link_token_create(request_data)#http request to plaid
        return jsonify(link_token=response.link_token)#send back the link token to the frontend
    except Exception as e:#if something goes wrong exception will run
        # Print full traceback so we see exactly what failed
        import traceback
        traceback.print_exc()
        return jsonify(error=str(e)), 500

@auth_bp.route("/exchange_public_token", methods=["POST"])
def exchange_public_token():
    public_token = request.json.get("public_token")
    req = ItemPublicTokenExchangeRequest(public_token=public_token)
    resp = plaid_client.item_public_token_exchange(req)
    return jsonify(access_token=resp.access_token)
