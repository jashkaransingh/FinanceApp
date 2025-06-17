from flask import Blueprint, jsonify
from plaid_client import plaid_client
from plaid.model.sandbox_public_token_create_request import SandboxPublicTokenCreateRequest
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
from plaid.model.transactions_refresh_request import TransactionsRefreshRequest

sb_bp = Blueprint("sandbox", __name__)

@sb_bp.route("/sandbox_refresh", methods=["POST"])
def sandbox_refresh():
    create_req = SandboxPublicTokenCreateRequest(
        institution_id="ins_109508",  # First Platypus Balance Bank
        initial_products=["transactions"]
    )
    create_resp = plaid_client.sandbox_public_token_create(create_req)

    exchange_req = ItemPublicTokenExchangeRequest(public_token=create_resp.public_token)
    exchange_resp = plaid_client.item_public_token_exchange(exchange_req)
    access_token = exchange_resp.access_token

    refresh_req = TransactionsRefreshRequest(access_token=access_token)
    plaid_client.transactions_refresh(refresh_req)

    return jsonify(access_token=access_token)
