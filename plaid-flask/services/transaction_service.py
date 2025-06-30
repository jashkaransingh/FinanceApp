from datetime import date, timedelta
from firebase_admin import firestore
import traceback

from plaid_client import fetch_all_transactions

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