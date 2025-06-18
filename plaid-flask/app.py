from flask import Flask, jsonify, send_file
from flask_cors import CORS

import config
from routes.auth         import auth_bp
from routes.transactions import tx_bp
from routes.sandbox      import sb_bp
import routes.ai as ai_module

# MARK: – Application Setup

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes


# MARK: – Blueprint Registration

# Auth endpoints:       /auth/create_link_token, /auth/exchange_public_token
app.register_blueprint(auth_bp, url_prefix="/auth")

# Transaction endpoints:  /transactions, /refresh, /summaries
# (root‐level, no prefix)
app.register_blueprint(tx_bp)

# Sandbox‐only endpoints: /sandbox/sandbox_refresh
app.register_blueprint(sb_bp, url_prefix="/sandbox")

app.register_blueprint(ai_module.ai_bp)


# MARK: – Health Check & Miscellaneous Routes

@app.route("/", methods=["GET"])
def home():
    """
    Basic health-check endpoint.
    """
    return jsonify(message="Hello, Flask is up and running!")


@app.route(
    "/apple-app-site-association",
    methods=["GET"]
)
def apple_app_site_association():
    """
    Serves the Apple App Site Association file for Universal Links.
    """
    return send_file(
        "apple-app-site-association.json",
        mimetype="application/json"
    )


# MARK: – Entry Point

if __name__ == "__main__":
    # Use debug=True only in development
    app.run(host="0.0.0.0", port=5050, debug=True)