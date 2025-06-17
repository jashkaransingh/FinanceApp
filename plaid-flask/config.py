import os
from dotenv import load_dotenv
from plaid import Environment

load_dotenv()

PLAID_CLIENT_ID = os.getenv("PLAID_CLIENT_ID")
PLAID_SECRET    = os.getenv("PLAID_SECRET")
PLAID_ENV       = os.getenv("PLAID_ENV", "sandbox").lower()

if PLAID_ENV == "sandbox":
    PLAID_HOST = Environment.Sandbox
elif PLAID_ENV == "development":
    PLAID_HOST = Environment.Development
elif PLAID_ENV == "production":
    PLAID_HOST = Environment.Production
else:
    raise ValueError(f"Unsupported PLAID_ENV: {PLAID_ENV}")
