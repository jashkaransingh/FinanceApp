import firebase_admin
from firebase_admin import credentials, firestore, auth

# Init once
if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

class Unauthorized(Exception):
    pass

class EmailNotVerified(Exception):
    pass

def verify_auth_header(auth_header, require_email_verified: bool = True):
    if not auth_header or not str(auth_header).startswith("Bearer "):
        raise Unauthorized("Missing/invalid Authorization header")

    id_token = auth_header.split("Bearer ", 1)[1].strip()
    if not id_token:
        raise Unauthorized("Missing token")

    try:
        decoded = auth.verify_id_token(id_token)
    except Exception:
        raise Unauthorized("Invalid/expired token")

    if require_email_verified and decoded.get("email_verified") is not True:
        raise EmailNotVerified("Email not verified")

    return decoded["uid"], decoded
