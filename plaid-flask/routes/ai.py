# routes/ai.py

import os
import json
from flask import Blueprint, request, jsonify, current_app
from utils.gemini_client import call_gemini
from utils.cache_manager  import get_cached_summary, set_cached_summary

ai_bp = Blueprint("ai", __name__)

@ai_bp.route("/ai/weekly_summary", methods=["POST"])
def weekly_summary():
    # 1. Parse the incoming JSON from the app
    data = request.get_json(force=True)
    print("▶️ [weekly_summary] raw request JSON:", data) 

    # 2. Check if this is a reallocation request or an initial request
    if "locked_category" in data:
        # --- THIS IS THE NEW, SMARTER REALLOCATION FLOW ---
        
        # Pull out all the data sent from the app
        current_plan = data["current_plan"]
        locked_category = data["locked_category"]
        new_value = data["new_value"]
        total_budget = data["total_budget"]
        transactions = data.get("transactions", []) # Pass transactions for context

        # Build a transaction history string for the AI
        history = "\n".join(f"- {tx['name']}: ${tx['amount']:.2f}" for tx in transactions)

        # Engineer the new, more powerful prompt for reallocation
        prompt = f"""
        You are a helpful budgeting assistant.
        A user has an existing weekly budget plan that totals ${total_budget}. Here is their current plan:
        {json.dumps(current_plan, indent=2)}

        The user now wants to make a specific change. They have decided to **lock the "{locked_category}" category to exactly ${new_value}**.

        Based on their transaction history provided below, your task is to intelligently reallocate the remaining budget across all OTHER categories.
        ---
        Transaction History:
        {history}
        ---
        RULES:
        1. The "{locked_category}" category MUST be ${new_value} in your response.
        2. Intelligently adjust the other categories. Be realistic: essential categories like "Debt Payments" and "Transportation" are less flexible and should be reduced less than discretionary categories like "Shopping" or "Entertainment".
        3. The sum of all "amount" values in your final JSON must exactly equal the total budget of ${total_budget}.
        4. Return ONLY the raw JSON object for the complete new plan. The format must be identical to the input plan. Do not add any explanatory text or markdown.
        """.strip()

        # Create a unique cache key for this specific reallocation request
        cache_key = f"reallocate:{json.dumps(current_plan, sort_keys=True)}:lock:{locked_category}:{new_value}"

    else:
        # --- THIS IS THE ORIGINAL FLOW FOR INITIAL BUDGET GENERATION ---
        # (This logic remains the same as before)
        
        transactions = data.get("transactions", [])
        if not transactions:
            sample_path = os.path.join(current_app.root_path, "data", "sample_transactions.json")
            with open(sample_path, "r") as f:
                transactions = json.load(f)

        budget  = data.get("weekly_budget", 100)
        user_id = data.get("user_id", "anonymous")
        history = "\n".join(f"- {tx['name']}: ${tx['amount']:.2f}" for tx in transactions)

        # Your original, detailed prompt for initial generation
        prompt = f"""
        Given the following transaction history:
        ---
        {history}
        ---
        And a total weekly budget of ${budget}, create a suggested spending plan.
        Your response must be ONLY a raw JSON object. The JSON object should have top-level keys representing spending categories (e.g., "Food", "Transportation"). The value for each key must be another JSON object with three specific fields: "amount", "percent", and "subtitle".
        - "amount": An integer representing the suggested budget for that category.
        - "percent": An integer representing what percentage of the total weekly budget this amount is. You must calculate this.
        - "subtitle": A short, helpful string (max 5 words) listing 1-3 example merchants from the transaction history that fit this category.
        The sum of all "amount" values must equal the total weekly budget of ${budget}.
        Example of the required output format:
        {{
          "Food": {{ "amount": 75, "percent": 38, "subtitle": "McDonald's, KFC" }}
        }}
        Do not include markdown fences (```json) or any other text outside of the main JSON object.
        """.strip()
        cache_key = f"{user_id}:{budget}"

    # --- THE REST OF THE FUNCTION (CACHE, GEMINI CALL, RETURN) REMAINS IDENTICAL ---
    
    # 3) Return from cache if available
    cached = get_cached_summary(cache_key)
    if cached:
        return jsonify(suggestion=cached)

    # 4) Call Gemini and process output
    try:
        gemini_response = call_gemini(prompt).strip()
        # ... (rest of the Gemini processing logic is the same)
        lines = gemini_response.splitlines()
        json_lines = [l for l in lines if not l.strip().startswith("```") and l.strip().lower() != "json"]
        cleaned = "\n".join(json_lines).strip()
        suggestion = json.loads(cleaned)

    except Exception as err:
        print("[weekly_summary] parse error:", err)
        print("Raw Gemini output:", gemini_response)
        suggestion = {}

    # 5) Cache & return
    set_cached_summary(cache_key, suggestion)
    return jsonify(suggestion=suggestion)
