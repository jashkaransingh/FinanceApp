import os
import certifi
from flask import Flask, jsonify, request
from flask_cors import CORS
from dotenv import load_dotenv
from plaid.api import plaid_api
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from plaid.model.item_public_token_exchange_request import ItemPublicTokenExchangeRequest
from plaid.model.transactions_get_request import TransactionsGetRequest
from plaid.model.transactions_get_request_options import TransactionsGetRequestOptions
from plaid.configuration import Configuration
from plaid.api_client import ApiClient
from plaid.model.sandbox_public_token_create_request import SandboxPublicTokenCreateRequest
from plaid.model.transactions_refresh_request import TransactionsRefreshRequest
from datetime import datetime, timedelta, date

# Load .env values
load_dotenv()

app = Flask(__name__) #setup Flask app
CORS(app) 

# Configure Plaid client
configuration = Configuration(
    host="https://sandbox.plaid.com",  
    api_key={
      "clientId": os.getenv("PLAID_CLIENT_ID"),
      "secret":   os.getenv("PLAID_SECRET"),
    },
    ssl_ca_cert=certifi.where()
)


api_client = ApiClient(configuration)
plaid_client = plaid_api.PlaidApi(api_client)

@app.route("/")
def home():
    return jsonify(message="Hello, Flask is up and running!")

#start of plaid routes - when the frontend click the plus button
@app.route("/create_link_token", methods=["POST"])
def create_link_token():
    try:
        request_data = LinkTokenCreateRequest( #request body to send to plaid
            user=LinkTokenCreateRequestUser(client_user_id="user-123"),# dummy for now
            client_name="My Finance App",
            products=[Products("transactions")],#telling plaid what products we want
            country_codes=[CountryCode("US")],
            language="en"
        )
        response = plaid_client.link_token_create(request_data)#http request to plaid
        return jsonify(link_token=response.link_token)#send back the link token to the frontend

    except Exception as e:#if something goes wrong exception will run
        # Print full traceback so we see exactly what failed
        import traceback
        traceback.print_exc()
        return jsonify(error=str(e)), 500



@app.route("/exchange_public_token", methods=["POST"])
def exchange_public_token():
    public_token = request.json.get("public_token")# get the public token from the ios app
    request_data = ItemPublicTokenExchangeRequest(public_token=public_token)#now request plaid to exchange the public token for an access token
    response = plaid_client.item_public_token_exchange(request_data)#response from plaid
    access_token = response.access_token#extract the access token from the response
    return jsonify(access_token=access_token)#send it back to the ios app(for now). later we will store it in the database

@app.route("/transactions", methods=["GET"])#ask the ios app for the access token. But in irl we will get it from the database
def get_transactions():#uses the access token to get transactions in last 30 days
    access_token = request.args.get("access_token")#gets the access token from the ios app
    start_str = request.args.get("start_date")#start date is 30 days ago
    end_str   = request.args.get("end_date")#end date as today
    if start_str and end_str:
        # expect YYYY-MM-DD
        start_date = date.fromisoformat(start_str)
        end_date   = date.fromisoformat(end_str)
    else:
        end_date   = date.today()
        start_date = end_date - timedelta(days=30)

    # page through everything between those two dates
    txns = fetch_all_transactions(access_token, start_date, end_date)

    # convert to simple dicts
    out = []
    for t in txns:
        out.append({
          "name":     t.name,
          "amount":   t.amount,
          "date":     t.date.isoformat(),
          "category": t.category or ""
        })

    return jsonify(transactions=out)

@app.route("/refresh", methods=["POST"])
def refresh_transactions():
    access_token = request.json.get("access_token")
    request_data = TransactionsRefreshRequest(access_token=access_token)
    response = plaid_client.transactions_refresh(request_data)
    return jsonify(message="Transactions refreshed successfully")

@app.route("/sandbox_refresh", methods=["POST"])
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

def fetch_all_transactions(access_token: str, start_date: date, end_date: date) -> list:
    """
    Return _all_ transactions between start_date and end_date by paging
    through the Plaid /transactions/get endpoint in 500-item chunks.
    """
    all_txns = []
    page_size = 500
    offset    = 0

    while True:
        req = TransactionsGetRequest(
            access_token=access_token,
            start_date=start_date,
            end_date=end_date,
            options=TransactionsGetRequestOptions(count=page_size, offset=offset)
        )
        resp  = plaid_client.transactions_get(req)
        batch = resp.transactions
        all_txns.extend(batch)

        # if we got back less than a full page, we’re done
        if len(batch) < page_size:
            break

        offset += page_size

    return all_txns

def sum_between(access_token: str, start_date: date, end_date: date) -> float:
    """
    Sum up the 'amount' field of every transaction in the given date range.
    """
    txns = fetch_all_transactions(access_token, start_date, end_date)
    return sum(tx.amount for tx in txns)

@app.route("/summaries", methods=["GET"])
def get_summaries():
    """
    Returns JSON of the form:

    {
      "summaries": [
        { "periodTitle": "...", "amount": 12.34, "percentage": -5.6, ... },
        …
      ]
    }
    """
    token = request.args.get("access_token", "")
    today = date.today()

    # 1) Today vs. Yesterday
    t_total = sum_between(token, today, today)
    y_day   = today - timedelta(days=1)
    y_total = sum_between(token, y_day, y_day)
    pct_today = ((t_total - y_total) / abs(y_total) * 100) if y_total else 0

    # 2) This Week vs. Last Week
    w_start    = today - timedelta(days=7)
    this_week  = sum_between(token, w_start, today)
    last_start = w_start - timedelta(days=7)
    last_week  = sum_between(token, last_start, w_start)
    pct_week = ((this_week - last_week) / abs(last_week) * 100) if last_week else 0

    # 3) This Month vs. Last Month
    m_start     = today - timedelta(days=30)
    this_month  = sum_between(token, m_start, today)
    prev_start  = m_start - timedelta(days=30)
    last_month  = sum_between(token, prev_start, m_start)
    pct_month = ((this_month - last_month) / abs(last_month) * 100) if last_month else 0

    payload = [
      {
        "periodTitle": "Spent Today",
        "amount":      round(t_total, 2),
        "percentage":  round(pct_today, 1),
        "subtitle":    f"Yesterday ${y_total:.2f}",
        "usesPieIcon": False
      },
      {
        "periodTitle": "Spent This Week",
        "amount":      round(this_week, 2),
        "percentage":  round(pct_week, 1),
        "subtitle":    f"Last Week ${last_week:.2f}",
        "usesPieIcon": False
      },
      {
        "periodTitle": "Spent This Month",
        "amount":      round(this_month, 2),
        "percentage":  round(pct_month, 1),
        "subtitle":    f"Last Month ${last_month:.2f}",
        "usesPieIcon": True
      }
    ]

    return jsonify(summaries=payload)




if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5050, debug=True)
