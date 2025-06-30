# routes/ai.py

import os
import json
import traceback
from flask import Blueprint, request, jsonify, current_app
from firebase_admin import auth, firestore
from utils.gemini_client import call_gemini
from utils.cache_manager  import get_cached_summary, set_cached_summary

ai_bp = Blueprint("ai", __name__)

# --- NEW: Endpoint to get a user's saved budget plan ---
@ai_bp.route("/budget", methods=["GET"])
def get_budget():
    """
    Retrieves the saved budget plan for the authenticated user from Firestore.
    """
    try:
        # 1. Verify user's identity
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        
        # 2. Access Firestore and get the user's document
        db = firestore.client()
        user_ref = db.collection('users').document(uid)
        user_doc = user_ref.get()
        
        if user_doc.exists:
            user_data = user_doc.to_dict()
            # 3. Check if a budget plan exists and return it
            if 'budgetPlan' in user_data:
                return jsonify(
                    budgetPlan=user_data['budgetPlan'],
                    totalBudget=user_data.get('totalBudget', 0)
                ), 200
        
        # 4. If no plan exists, return a clear response
        return jsonify(message="No budget plan found for user."), 404

    except Exception as e:
        traceback.print_exc()
        return jsonify(error=str(e)), 500


# --- NEW: Endpoint to save a user's budget plan ---
@ai_bp.route("/budget", methods=["POST"])
def save_budget():
    """
    Saves a budget plan for the authenticated user to Firestore.
    """
    try:
        # 1. Verify user's identity
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        
        # 2. Get the plan from the request body
        data = request.get_json(force=True)
        budget_plan = data.get("budgetPlan")
        total_budget = data.get("totalBudget")

        if not budget_plan or total_budget is None:
            return jsonify(error="Missing 'budgetPlan' or 'totalBudget' in request body."), 400
            
        # 3. Access Firestore and update the user's document
        db = firestore.client()
        user_ref = db.collection('users').document(uid)
        user_ref.update({
            'budgetPlan': budget_plan,
            'totalBudget': total_budget
        })
        
        print(f"✅ Budget plan saved for user {uid}")
        return jsonify(success=True), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify(error=str(e)), 500

@ai_bp.route("/ai/weekly_summary", methods=["POST"])
def weekly_summary():
    """
    Generates or reallocates a budget plan using the AI.
    This endpoint is now secured with Firebase Auth.
    """
    try:
        # 1. Verify user's identity (This was missing before)
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        print(f"✅ Verified user for AI summary: {uid}")

    except Exception as e:
        return jsonify(error="Invalid or missing Authorization token.", details=str(e)), 401
    
    # 1. Parse the incoming JSON from the app
    data = request.get_json(force=True)
    print("▶️ [weekly_summary] raw request JSON:", data) 

    transactions = data.get("transactions", [])
    history = "\n".join(f"- {tx['name']}: ${tx['amount']:.2f}" for tx in transactions)
    total_budget = data.get("total_budget") or data.get("weekly_budget", 100)
    
    base_prompt = f"""
    You are a helpful budgeting assistant. Given the following transaction history and a total weekly budget of ${total_budget}, create a suggested spending plan.
    ---
    Transaction History:
    {history}
    ---
    """
    
    # The cache key needs to uniquely identify the request.
    # We start with the user's secure ID and their total budget.
    cache_key_parts = [uid, str(total_budget)]

    if "locked_category" in data:
        # Reallocation Flow
        current_plan = data["current_plan"]
        locked_category = data["locked_category"]
        new_value = data["new_value"]
        
        reallocation_rules = f"""
        The user has an existing plan and wants to make a specific change.
        Their current plan is: {json.dumps(current_plan, indent=2)}
        They have decided to **lock the "{locked_category}" category to exactly ${new_value}**.
        Your task is to intelligently reallocate the remaining budget across all OTHER categories.
        - The "{locked_category}" category MUST have an "amount" of ${new_value}.
        - Be realistic: essential categories like "Debt Payments" are less flexible than discretionary categories like "Shopping".
        """
        prompt = base_prompt + reallocation_rules
        # Add reallocation details to the cache key for uniqueness
        cache_key_parts.extend(["reallocate", locked_category, str(new_value)])

    else:
        # Initial Generation Flow
        prompt = base_prompt
        # Add generation details to the cache key
        cache_key_parts.append("initial")

    formatting_rules = f"""
    RULES FOR RESPONSE FORMAT:
    1. Your response MUST be ONLY a raw JSON object.
    2. The JSON object must have top-level keys representing spending categories (e.g., "Food", "Transportation").
    3. The value for EACH key must be another JSON object with three specific fields: "amount", "percent", and "subtitle".
       - "amount": An integer for the suggested budget.
       - "percent": An integer representing the percentage of the total budget. You MUST calculate this for every category.
       - "subtitle": A short, helpful string (max 5 words) listing 1-3 example merchants. If no relevant merchants exist, create a sensible default (e.g., "General savings").
    4. The sum of all "amount" values in your final JSON must exactly equal the total budget of ${total_budget}.
    
    Example of the required output format:
    {{
      "Food": {{ "amount": 75, "percent": 38, "subtitle": "McDonald's, KFC" }}
    }}
    Do not include markdown fences (```json) or any other text outside of the main JSON object.
    """
    prompt += formatting_rules

    # Join the parts to create the final, unique cache key
    cache_key = ":".join(cache_key_parts)
    print(f"Generated Cache Key: {cache_key}")
    
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
