from flask import Blueprint, jsonify, request
from datetime import date, timedelta
import traceback

# --- New Imports ---
from firebase_admin import auth, firestore

# --- We still use this helper from your plaid_client.py ---
from plaid_client import fetch_all_transactions

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
    Fetches transactions from Plaid and saves them to Firestore.
    The client must provide a Firebase ID Token for authentication.
    """
    try:
        # 1. Verify user and get their Plaid access token from Firestore.
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        
        db = firestore.client()
        user_doc = db.collection('users').document(uid).get()
        if not user_doc.exists or 'plaidAccessToken' not in user_doc.to_dict():
            return jsonify(error="Plaid access token not found for this user."), 404
        access_token = user_doc.to_dict()['plaidAccessToken']

        # 2. Parse date range from request.
        start_str = request.args.get("start_date", "")
        end_str   = request.args.get("end_date", "")
        period    = request.args.get("period", "")
        start_date, end_date = parse_date_range(start_str, end_str, period)

        # 3. Fetch all transactions from Plaid using your helper.
        plaid_transactions = fetch_all_transactions(access_token, start_date, end_date)

        # 4. Save the fetched transactions to a subcollection in Firestore.
        #    We use a batch write for efficiency.
        batch = db.batch()
        transactions_ref = db.collection('users').document(uid).collection('transactions')
        
        client_transactions = []
        for t in plaid_transactions:
            # The Plaid transaction_id is the perfect unique key for our document ID.
            # This prevents us from ever creating duplicate transaction entries.
            doc_ref = transactions_ref.document(t.transaction_id)
            
            # Format the data for both Firestore and the client response.
            tx_data = {
                "name": t.name,
                "amount": t.amount,
                "date": t.date.isoformat(),
                "category": t.personal_finance_category.primary if t.personal_finance_category else "Other",
                "plaid_id": t.transaction_id
            }
            batch.set(doc_ref, tx_data)
            client_transactions.append(tx_data)
        
        batch.commit() # Commit all writes to the database at once.
        print(f"✅ Saved {len(plaid_transactions)} transactions to Firestore for user {uid}")

        # 5. Return the transactions to the client.
        return jsonify(transactions=client_transactions)

    except Exception as e:
        traceback.print_exc()
        return jsonify(error=str(e)), 500


# --- MODIFIED: This endpoint is now secure and HIGHLY optimized ---
@tx_bp.route("/summaries", methods=["GET"])
def get_summaries():
    """
    Calculates spending summaries efficiently. Makes only ONE call to Plaid.
    Requires Firebase ID Token for authentication.
    """
    try:
        # 1. Verify user and get their Plaid access token from Firestore.
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        
        db = firestore.client()
        user_doc = db.collection('users').document(uid).get()
        if not user_doc.exists or 'plaidAccessToken' not in user_doc.to_dict():
            return jsonify(summaries=[]) # Return empty if no token
        access_token = user_doc.to_dict()['plaidAccessToken']

        # 2. Fetch data for the entire required period (last 60 days) in ONE call.
        today = date.today()
        sixty_days_ago = today - timedelta(days=60)
        all_txns = fetch_all_transactions(access_token, sixty_days_ago, today)

        # 3. Process the transactions in memory (much faster and cheaper).
        today_total = 0
        yesterday_total = 0
        this_week_total = 0
        last_week_total = 0
        this_month_total = 0
        last_month_total = 0

        yesterday = today - timedelta(days=1)
        week_ago = today - timedelta(days=7)
        two_weeks_ago = today - timedelta(days=14)
        month_ago = today - timedelta(days=30)

        for t in all_txns:
            if t.amount < 0: continue # Optional: ignore income for summaries
            
            if t.date == today:
                today_total += t.amount
            if t.date == yesterday:
                yesterday_total += t.amount
            if week_ago <= t.date <= today:
                this_week_total += t.amount
            if two_weeks_ago <= t.date < week_ago:
                last_week_total += t.amount
            if month_ago <= t.date <= today:
                this_month_total += t.amount
            if sixty_days_ago <= t.date < month_ago:
                last_month_total += t.amount

        # 4. Calculate percentages.
        pct_today = ((today_total - yesterday_total) / yesterday_total * 100) if yesterday_total > 0 else 0
        pct_week = ((this_week_total - last_week_total) / last_week_total * 100) if last_week_total > 0 else 0
        pct_month = ((this_month_total - last_month_total) / last_month_total * 100) if last_month_total > 0 else 0

        # 5. Build the response payload.
        payload = [
            {"periodTitle": "Spent Today", "amount": round(today_total, 2), "percentage": round(pct_today, 1), "subtitle": f"Yesterday ${yesterday_total:.2f}", "usesPieIcon": False},
            {"periodTitle": "Spent This Week", "amount": round(this_week_total, 2), "percentage": round(pct_week, 1), "subtitle": f"Last Week ${last_week_total:.2f}", "usesPieIcon": False},
            {"periodTitle": "Spent This Month", "amount": round(this_month_total, 2), "percentage": round(pct_month, 1), "subtitle": f"Last Month ${last_month_total:.2f}", "usesPieIcon": True}
        ]
        return jsonify(summaries=payload)

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
