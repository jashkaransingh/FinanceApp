from datetime import date, timedelta
from firebase_admin import firestore
import traceback

from plaid_client import fetch_all_transactions
from . import update_account_summaries


def get_transactions(uid: str, start_date: date, end_date: date) -> list:
    """
    (This function remains unchanged from before. It's used by your iOS app.)
    """
    print(f"🔄 Service: Getting transactions for user {uid} from {start_date} to {end_date}")
    db = firestore.client()
    transactions_ref = db.collection('users').document(uid).collection('transactions')

    # Query Firestore First
    query = transactions_ref.where('date', '>=', start_date.isoformat()).where('date', '<=', end_date.isoformat())
    docs = query.stream()
    firestore_transactions = [doc.to_dict() for doc in docs]

    if firestore_transactions:
        print(f"✅ Service: Found {len(firestore_transactions)} transactions in Firestore.")
        return firestore_transactions

    print(f"⚠️ Service: No transactions in Firestore for this range. Fetching from Plaid API.")
    # Fallback to Plaid API
    return sync_transactions_for_item(uid, start_date, end_date)


# --- NEW FUNCTION FOR WEBHOOKS ---
def sync_transactions_for_item(uid: str, start_date: date = None, end_date: date = None) -> list:
    """
    Fetches transactions for a user from Plaid and saves them to Firestore.
    If no date range is provided, it fetches the last 30 days by default.
    This function is now used by both the webhook and the fallback logic in get_transactions.
    """
    db = firestore.client()
    transactions_ref = db.collection('users').document(uid).collection('transactions')

    try:
        user_doc = db.collection('users').document(uid).get()
        if not user_doc.exists or 'plaidAccessToken' not in user_doc.to_dict():
            raise Exception("Plaid access token not found for this user.")
        access_token = user_doc.to_dict()['plaidAccessToken']

        # If no dates are provided (i.e., called from a webhook), fetch the last 30 days.
        if start_date is None or end_date is None:
            end_date = date.today()
            start_date = end_date - timedelta(days=30)
            print(f"Webhook sync: fetching last 30 days for user {uid}")

        plaid_transactions = fetch_all_transactions(access_token, start_date, end_date)

        if not plaid_transactions:
            print(f"No new transactions found for user {uid} in the date range.")
            return []

        batch = db.batch()
        for t in plaid_transactions:
            doc_ref = transactions_ref.document(t.transaction_id)
            tx_data = {
                "name": t.name, "amount": t.amount, "date": t.date.isoformat(),
                "category": t.personal_finance_category.primary if t.personal_finance_category else "Other",
                "plaid_id": t.transaction_id
            }
            batch.set(doc_ref, tx_data, merge=True) # Use merge=True to be safe
        
        batch.commit()
        print(f"✅ Service: Synced and saved {len(plaid_transactions)} transactions to Firestore for user {uid}")
        update_account_summaries(uid)

        # Re-format the data for the client if needed
        client_transactions = [
            {
                "name": t.name, "amount": t.amount, "date": t.date.isoformat(),
                "category": t.personal_finance_category.primary if t.personal_finance_category else "Other",
                "plaid_id": t.transaction_id
            } for t in plaid_transactions
        ]
        return client_transactions

    except Exception as e:
        traceback.print_exc()
        return []
    
def update_account_summaries(uid):
    """
    Calculates user's spending summaries from Firestore data and saves them
    back to the main user document. This should be called after any
    transaction sync.
    """
    print(f"🔥 Triggering summary update for user: {uid}")
    db = firestore.client()
    
    # 1. Define the date ranges needed for calculation.
    today = date.today()
    sixty_days_ago = today - timedelta(days=60)
    
    # 2. Fetch the last 60 days of transactions directly from Firestore.
    #    This is much faster and cheaper than calling the Plaid API again.
    transactions_ref = db.collection('users').document(uid).collection('transactions')
    query = transactions_ref.where('date', '>=', sixty_days_ago.isoformat())
    docs = query.stream()

    # 3. Process the transactions in memory (reusing your existing logic).
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

    for doc in docs:
        t = doc.to_dict()
        t_date = date.fromisoformat(t['date'])
        t_amount = t.get('amount', 0)

        if t_amount < 0: continue
        
        if t_date == today: today_total += t_amount
        if t_date == yesterday: yesterday_total += t_amount
        if week_ago <= t_date <= today: this_week_total += t_amount
        if two_weeks_ago <= t_date < week_ago: last_week_total += t_amount
        if month_ago <= t_date <= today: this_month_total += t_amount
        if sixty_days_ago <= t_date < month_ago: last_month_total += t_amount

    # 4. Calculate percentages (reusing your existing logic).
    pct_today = ((today_total - yesterday_total) / yesterday_total * 100) if yesterday_total > 0 else 0
    pct_week = ((this_week_total - last_week_total) / last_week_total * 100) if last_week_total > 0 else 0
    pct_month = ((this_month_total - last_month_total) / last_month_total * 100) if last_month_total > 0 else 0

    # 5. Build the payload.
    summary_payload = [
        {"periodTitle": "Spent Today", "amount": round(today_total, 2), "percentage": round(pct_today, 1), "subtitle": f"Yesterday ${yesterday_total:.2f}", "usesPieIcon": False},
        {"periodTitle": "Spent This Week", "amount": round(this_week_total, 2), "percentage": round(pct_week, 1), "subtitle": f"Last Week ${last_week_total:.2f}", "usesPieIcon": False},
        {"periodTitle": "Spent This Month", "amount": round(this_month_total, 2), "percentage": round(pct_month, 1), "subtitle": f"Last Month ${last_month_total:.2f}", "usesPieIcon": True}
    ]
    
    # 6. Save this payload to the main user document.
    user_ref = db.collection('users').document(uid)
    user_ref.update({"accountSummaries": summary_payload})
    
    print(f"✅ Successfully updated summaries for user: {uid}")