import os
from dotenv import load_dotenv
from plaid import Environment

load_dotenv()

PLAID_CLIENT_ID = os.getenv("PLAID_CLIENT_ID")
PLAID_SECRET    = os.getenv("PLAID_SECRET")
PLAID_ENV       = os.getenv("PLAID_ENV", "sandbox").lower()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
PLAID_REDIRECT_URI = 'https://financeapp-9wxw.onrender.com/plaid-redirect'

if PLAID_ENV == "sandbox":
    PLAID_HOST = Environment.Sandbox
elif PLAID_ENV == "development":
    PLAID_HOST = Environment.Development
elif PLAID_ENV == "production":
    PLAID_HOST = Environment.Production
else:
    raise ValueError(f"Unsupported PLAID_ENV: {PLAID_ENV}")

# AI Configuration
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY")

REQUIRE_EMAIL_VERIFIED = False  # IMPORTANT: set True before production