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
import datetime

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
    start_date = (datetime.datetime.now() - datetime.timedelta(days=30)).date()#start date is 30 days ago
    end_date = datetime.datetime.now().date()#end date as today
    request_data = TransactionsGetRequest(#request to send to Plaid's /transactions/get endpoint
        access_token=access_token,
        start_date=start_date,
        end_date=end_date,
        options=TransactionsGetRequestOptions(count=10, offset=0)
    )
    response = plaid_client.transactions_get(request_data)#sends the request to plaid
    return jsonify(response.to_dict())#convert the response to a dictionary and send it back to the ios app

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5050, debug=True)
