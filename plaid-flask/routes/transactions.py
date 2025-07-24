from flask import Blueprint, jsonify, request
from datetime import date, timedelta
import traceback
from firebase_admin import auth, firestore
from plaid_client import fetch_all_transactions
from services.transaction_service import sync_transactions_for_item

tx_bp = Blueprint("transactions", __name__)

def parse_date_range(start_str: str, end_str: str, period: str):
    """
    (This function remains unchanged, it's already perfect)
    """
    today = date.today()
    if period:
        if period == "today": return today, today
        if period == "week": return today - timedelta(days=7), today
        if period == "month": return today - timedelta(days=30), today
        raise ValueError(f"Invalid period specified: {period}")
    if start_str and end_str:
        try:
            return date.fromisoformat(start_str), date.fromisoformat(end_str)
        except ValueError:
            raise ValueError("Invalid date format; expected YYYY-MM-DD")
    return today - timedelta(days=30), today


# --- MODIFIED: This endpoint is now secure and saves data ---
@tx_bp.route("/transactions", methods=["GET"])
def get_transactions():
    """
    A thin API wrapper that calls the transaction sync service.
    """
    try:
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        
        start_str = request.args.get("start_date")
        end_str   = request.args.get("end_date")
        period    = request.args.get("period")
        start_date, end_date = parse_date_range(start_str, end_str, period)

        # Simply call your service function and return its result
        client_transactions = sync_transactions_for_item(uid, start_date, end_date)
        
        return jsonify(transactions=client_transactions)

    except Exception as e:
        traceback.print_exc()
        return jsonify(error=str(e)), 500



# --- This endpoint is no longer needed with the new architecture ---
# The client should not be triggering a refresh manually with a token.
# This logic will be replaced by webhooks in a later step.
# You can safely remove or comment out this endpoint.
# @tx_bp.route("/refresh", methods=["POST"])
# def refresh_transactions():
#     ...
