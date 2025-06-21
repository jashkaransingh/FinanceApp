# routes/ai.py

import os
import json
from flask import Blueprint, request, jsonify, current_app
from utils.gemini_client import call_gemini
from utils.cache_manager  import get_cached_summary, set_cached_summary

ai_bp = Blueprint("ai", __name__)

@ai_bp.route("/ai/weekly_summary", methods=["POST"])
def weekly_summary():
    # 1) Parse JSON
    data = request.get_json(force=True)
    print("▶️ [weekly_summary] raw request JSON:", data) 

    # 2 Pull out whichever payload you got
    if "merchant_budgets" in data:
        # — Flow A: Merchant-specific budget split —
        merchant_budgets = data["merchant_budgets"]

        # Build prompt for Gemini to normalize merchants and allocate budget
        prompt = """
        You’re given a JSON object of raw merchant descriptions → average weekly spend, for example:
        { 
        "Uber 063015 SF**POOL**": 2,
        "Starbucks": 1,
        "SparkFun": 30,
        "Touchstone Climbing": 26
        }

        And a slider parameter `"weekly_budget"` indicating the total dollars available.

        1. Normalize each description into a clean merchant name by:
        • Stripping dates, codes, special characters, and location tags  
        • Grouping obvious variants under one name (e.g. both "Uber 063015 SF**POOL**"  
            and "Uber 072515 SF**POOL**" → "Uber")  

        2. **Using exactly those normalized merchant names** (no new keys, no dropped keys),  
        produce a JSON object mapping each merchant → recommended weekly budget.  
        Make sure the sum of all values equals the passed `"weekly_budget"`.  

        Return **only** the final JSON object—no extra text, no markdown fences.

        """.strip()

        budget = data["weekly_budget"]

        # now include budget
        cache_key = f"merchant:{json.dumps(merchant_budgets, sort_keys=True)}:budget:{budget}"

    # — weekly_budget + transactions flow —
    else:
        # — Flow B: Raw transactions + budget → generic breakdown —
        transactions = data.get("transactions", [])
        # If transactions are missing, load a fallback sample
        if not transactions:
            sample_path = os.path.join(
                current_app.root_path, "data", "sample_transactions.json"
            )
            with open(sample_path, "r") as f:
                transactions = json.load(f)

        budget  = data.get("weekly_budget", 100)
        user_id = data.get("user_id", "anonymous")

        # Build transaction history lines
        history = "\n".join(f"{tx['name']} - ${tx['amount']}"
                             for tx in transactions)

        prompt = (
            f"Based on the following past transactions:\n\n{history}\n\n"
            f"And a weekly budget of ${budget}, generate a breakdown "
            "of how I could spend this week. I want only a JSON "
            "object mapping categories to amounts (e.g. "
            "{ 'subway': 2, 'groceries': 30, 'bars': 20 }). "
            "Do not include any additional fields like notes."
        )
        # Build cache key so each budget + txn set is distinct
        cache_key = f"{user_id}:{budget}"

    # 3) Return from cache if available
    cached = get_cached_summary(cache_key)
    if cached:
        return jsonify(suggestion=cached)

    # 4) Call Gemini and process output
    try:
        gemini_response = call_gemini(prompt).strip()

        # strip any ``` fences or lone “json” lines
        lines = gemini_response.splitlines()
        json_lines = [
            l for l in lines
            if not l.strip().startswith("```") and l.strip().lower() != "json"
        ]
        cleaned = "\n".join(json_lines).strip()
        # parse the cleaned JSON output
        suggestion = json.loads(cleaned)

    except Exception as err:
        # on parse error, log & return empty
        print("[weekly_summary] parse error:", err)
        print("Raw Gemini output:", gemini_response)
        suggestion = {}

    # 5) Cache & return
    set_cached_summary(cache_key, suggestion)
    return jsonify(suggestion=suggestion)
