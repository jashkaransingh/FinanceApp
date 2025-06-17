import certifi
from datetime import date
from typing import List

from plaid.configuration import Configuration
from plaid.api_client import ApiClient
from plaid.api import plaid_api
from plaid.model.transactions_get_request import TransactionsGetRequest
from plaid.model.transactions_get_request_options import TransactionsGetRequestOptions

import config  # your config.py with PLAID_HOST, PLAID_CLIENT_ID, PLAID_SECRET


# MARK: – Plaid Client Initialization

# Configure the Plaid API client once at import time.
configuration = Configuration(
    host=config.PLAID_HOST,
    api_key={
        "clientId": config.PLAID_CLIENT_ID,
        "secret":   config.PLAID_SECRET
    },
    ssl_ca_cert=certifi.where()
)
api_client   = ApiClient(configuration)
plaid_client = plaid_api.PlaidApi(api_client)


# MARK: – Helpers

def fetch_all_transactions(
    access_token: str,
    start_date: date,
    end_date: date
) -> List:
    """
    Retrieve *all* transactions between `start_date` and `end_date`
    by paging through Plaid’s /transactions/get endpoint in 500-item chunks.

    Parameters:
      - access_token: The Plaid access token for the user’s bank item.
      - start_date:    Earliest date to include (inclusive).
      - end_date:      Latest date to include (inclusive).

    Returns:
      A list of Plaid Transaction models.
    """
    all_txns: List = []
    page_size = 500
    offset    = 0

    while True:
        # Build the request with paging options
        req = TransactionsGetRequest(
            access_token=access_token,
            start_date=start_date,
            end_date=end_date,
            options=TransactionsGetRequestOptions(
                count=page_size,
                offset=offset
            )
        )

        # Execute the request
        resp = plaid_client.transactions_get(req)
        batch = resp.transactions
        all_txns.extend(batch)

        # Stop when the returned batch is smaller than the page size
        if len(batch) < page_size:
            break

        offset += page_size

    return all_txns