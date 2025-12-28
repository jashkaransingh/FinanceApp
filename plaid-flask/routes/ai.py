# routes/ai.py
import os
import json
import traceback
import hashlib
import re  # for regex
import math # for rounding
from flask import Blueprint, request, jsonify
from firebase_admin import auth, firestore
from utils.claude_client import call_claude
from utils.cache_manager import get_cached_summary, set_cached_summary

ai_bp = Blueprint("ai", __name__)


def _parse_subtitle_string(subtitle: str) -> dict[str, int]:
    """
    Parses an AI-generated subtitle string into a dictionary of merchants and visit counts.
    e.g., "Starbucks (2 visits), Chipotle (1 visit)"
    OR "Starbucks (2 visits, $12), Chipotle (1 visit, $14)"
    Returns: {"Starbucks": 2, "Chipotle": 1}
    """
    
    # It finds the merchant name, then '(', then the number,
    # and IGNORES everything else after the number.
    pattern = re.compile(r"([\w\s'-]+?)\s*\((\d+)\s")

    matches = pattern.findall(subtitle)
    
    # Return a dictionary comprehension, e.g., {"Starbucks": 2, "Chipotle": 1}
    # We strip whitespace from the name just in case
    return {name.strip(): int(visits) for name, visits in matches}

#
# --- THIS IS THE CORRECT, UPGRADED HEALER FUNCTION ---
#
def _recalculate_budget_plan(
    ai_suggestion: dict,
    patterns: dict,
    total_budget: int
) -> dict:
    """
    "Heals" the AI suggestion.
    
    NEW in v4: This now returns a "flat" dictionary where EACH MERCHANT
    is a top-level key. This is for the new "aesthetic as fuck" UI.
    """
    final_plan = {}
    total_allocated = 0 # This will be a sum of integers

    # 1. Loop through all CATEGORIES from the AI (e.g., "Food & Dining")
    #    We do this *only* to get the category name for coloring.
    for category_name, details in ai_suggestion.items():
        subtitle = details.get("subtitle", "")
        
        # Skip the "Everything Else" category for now
        if category_name.lower() == "everything else":
            continue

        # 2. Parse the AI's subtitle string, e.g., "Starbucks (2 visits)"
        merchants_in_subtitle = _parse_subtitle_string(subtitle)
        
        # 3. Look up EACH MERCHANT and add it to the final_plan
        for merchant_name, visit_count in merchants_in_subtitle.items():
            if visit_count > 0 and merchant_name in patterns:
                
                # 4. Get the *accurate* median cost from our analyzer
                cost_per_visit = patterns[merchant_name]["median_cost_per_visit"]
                merchant_total_amount = cost_per_visit * visit_count
                
                # --- THIS IS THE BUG FIX ---
                # We ceil the final merchant amount to get an integer
                final_merchant_amount_int = math.ceil(merchant_total_amount)
                
                # We add *that integer* to the total_allocated
                total_allocated += final_merchant_amount_int
                # ---------------------------

                # 5. Create a new, simpler subtitle
                plural_word = "visits"   # default
                singular_word = "visit"  # default

                # Find the visit word from the AI's *first* example
                match = re.search(r"\(\d+\s+(\w+)", subtitle)
                if match:
                    plural_word = match.group(1) # e.g., "visits", "rides", "month"

                    if plural_word == "rides":
                        singular_word = "ride"
                    elif plural_word.endswith("s"):
                        singular_word = plural_word[:-1] # "visits" -> "visit"
                    else:
                        singular_word = plural_word      # "month" -> "month"

                # Now, build the "f-ing proper" subtitle
                current_visit_word = plural_word if visit_count != 1 else singular_word

                new_subtitle = f"{visit_count} {current_visit_word} at ${cost_per_visit:.2f}/{singular_word}"

                # 6. Add the MERCHANT to the final plan
                final_plan[merchant_name] = {
                    "amount": final_merchant_amount_int,
                    "percent": 0,
                    "subtitle": new_subtitle,
                    "category": category_name, # <-- NEW: For app coloring
                    "cost_per_visit": cost_per_visit, # <-- NEW: For stepper logic
                    "visits": visit_count # <-- NEW: For stepper logic
                }

    # 7. Calculate the "Everything Else" amount
    everything_else_amount = total_budget - total_allocated

    # 8. Add the "Everything Else" category
    final_plan["Buffer"] = {
    "amount": max(0, everything_else_amount),
    "percent": 0,
    "subtitle": "Anything extra you wanna spend",
    "category": "Buffer",
    "cost_per_visit": 0,
    "visits": 0
}

    # 9. Final pass to calculate all percentages
    if total_budget > 0:
        final_total = sum(details["amount"] for details in final_plan.values())
        if final_total > 0:
            for key in final_plan:
                amount = final_plan[key]["amount"]
                percent = (amount / final_total) * 100
                final_plan[key]["percent"] = round(percent)
        else:
             for key in final_plan:
                final_plan[key]["percent"] = 0
    else:
        for key in final_plan:
            final_plan[key]["percent"] = 0
            
    return final_plan


@ai_bp.route("/budget", methods=["GET"])
def get_budget():
    """Retrieves the saved budget plan for the authenticated user."""
    try:
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        
        db = firestore.client()
        user_ref = db.collection('users').document(uid)
        user_doc = user_ref.get()
        
        if user_doc.exists:
            user_data = user_doc.to_dict()
            if 'budgetPlan' in user_data:
                return jsonify(
                    budgetPlan=user_data['budgetPlan'],
                    totalBudget=user_data.get('totalBudget', 0)
                ), 200
        
        return jsonify(message="No budget plan found for user."), 404
        
    except Exception as e:
        traceback.print_exc()
        return jsonify(error=str(e)), 500


@ai_bp.route("/budget", methods=["POST"])
def save_budget():
    """Saves a budget plan for the authenticated user."""
    try:
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        
        data = request.get_json(force=True)
        budget_plan = data.get("budgetPlan")
        total_budget = data.get("totalBudget")
        
        if not budget_plan or total_budget is None:
            return jsonify(error="Missing 'budgetPlan' or 'totalBudget'."), 400
            
        db = firestore.client()
        user_ref = db.collection('users').document(uid)
        user_ref.update({
            'budgetPlan': budget_plan,
            'totalBudget': total_budget
        })
        
        print(f"Budget plan saved for user {uid}")
        return jsonify(success=True), 200
        
    except Exception as e:
        traceback.print_exc()
        return jsonify(error=str(e)), 500

@ai_bp.route("/ai/frequent_merchants", methods=["POST"])
def get_frequent_merchants():
    """
    Analyzes a user's transactions and returns a sorted list of
    their most frequent merchants (habits).
    """
    try:
        # 1. Verify user
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        print(f"Verified user for frequent merchants: {uid}")
    except Exception as e:
        return jsonify(error="Invalid token.", details=str(e)), 401

    try:
        # 2. Parse request
        data = request.get_json(force=True)
        transactions = data.get("transactions", [])
        
        # 3. Analyze spending patterns (using our existing analyzer)
        from services.budget_analyzer import analyze_spending_patterns
        patterns = analyze_spending_patterns(transactions)
        
        if not patterns:
            return jsonify(merchants=[])

        # 4. Format the patterns into a clean list for the iOS app
        merchants_list = []
        for name, info in patterns.items():
            merchants_list.append({
                "name": name,
                "total_visits": info["total_visits"],
                "median_cost": info["median_cost_per_visit"],
                "category": info["category"] # Pass this to the app for UI icons
            })

        # 5. Sort the list by most visits first
        sorted_list = sorted(merchants_list, key=lambda x: x["total_visits"], reverse=True)
        
        # 6. Return the top 10 habits
        return jsonify(merchants=sorted_list[:10])

    except Exception as e:
        traceback.print_exc()
        return jsonify(error=f"Failed to analyze merchants: {str(e)}"), 500

@ai_bp.route("/ai/weekly_summary", methods=["POST"])
def weekly_summary():
    """
    Generates a frequency-based budget plan based on a user's
    pre-selected merchants.
    """
    try:
        # 1. Verify user
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        print(f" Verified user for AI summary: {uid}")
    except Exception as e:
        return jsonify(error="Invalid token.", details=str(e)), 401
    
    # 2. Parse request
    data = request.get_json(force=True)
    print("▶ [weekly_summary] raw request JSON:", data)
    
    transactions = data.get("transactions", [])
    total_budget = data.get("total_budget") or data.get("weekly_budget", 100)
    
    # --- THIS IS THE NEW LOGIC (Task 2a) ---
    # Get the list of merchants the user pre-selected.
    # It might be empty or None if they skipped the selection step.
    selected_merchants = data.get("selected_merchants")
    # ----------------------------------------

    # 3. Analyze spending patterns
    from services.budget_analyzer import analyze_spending_patterns
    patterns = analyze_spending_patterns(transactions)
    
    print(f"📊 Analyzed {len(patterns)} merchants from {len(transactions)} transactions")
    
    # 4. Handle no patterns case
    if not patterns:
        return jsonify(suggestion={
            "Buffer": { # Changed to be consistent
                "amount": total_budget,
                "percent": 100,
                "subtitle": "No recurring expenses found"
            }
        })
    
    # 5. Build prompt
    merchant_examples = []
    
    # --- THIS IS THE NEW PROMPT LOGIC (Task 2a) ---
    if selected_merchants:
        # User selected specific merchants. Only use those.
        print(f" User selected {len(selected_merchants)} merchants.")
        for name in selected_merchants:
            if name in patterns:
                info = patterns[name]
                merchant_examples.append(
                    f"  - {name}: {info['total_visits']} visits in 6 weeks (${info['median_cost_per_visit']:.0f} per visit)"
                )
    else:
        # No selection. Fall back to the original behavior (top 5).
        print("No merchants selected. Building plan from top 5 habits.")
        # We limit to top 5 to keep the prompt clean
        for merchant, info in sorted(patterns.items(), key=lambda x: x[1]['total_spent'], reverse=True)[:5]:
            merchant_examples.append(
                f"  - {merchant}: {info['total_visits']} visits in 6 weeks (${info['median_cost_per_visit']:.0f} per visit)"
            )
    # -----------------------------------------------

    merchants_list = "\n".join(merchant_examples)
    print(f"📋 Sending to Gemini:\n{merchants_list}")
    
    # --- THIS IS THE NEW PROMPT STRING (Task 2a) ---
    prompt = f"""You are a friendly and practical budget assistant. Your job is to create a SIMPLE weekly spending plan for **discretionary** ("fun money") spending.

---
WEEKLY BUDGET: ${total_budget}
USER'S PRE-SELECTED HABITS:
{merchants_list}

Each line shows: Merchant, total visits in 6 weeks, and the user's *typical* cost per visit.
---

YOUR JOB:
Create a plan that **budgets *only* for the merchants listed under USER'S PRE-SELECTED HABITS.**
The user has pre-selected these as important.
Show the user HOW MANY TIMES they can visit these *specific* places this week and stay within their ${total_budget} budget.

RULES (FOLLOW THESE *EXACTLY*):

1.  **THINK IN VISITS, NOT DOLLARS.**
    * If they went 6 times in 6 weeks -> 1 visit per week.
    * If 12 times in 6 weeks -> 2 visits per week.
    * If 3 times in 6 weeks -> 0-1 visit per week.
    * Use WHOLE numbers: "1 visit", "2 visits", "3 rides" (NO decimals).

2.  **CALCULATE THE COST.**
    * Use the typical cost provided (e.g., "Starbucks: 2 visits" at $6/visit = $12).
    * Round all calculated amounts to the nearest whole dollar.

3.  **CREATE A "BUFFER" CATEGORY.**
    * First, budget for the selected merchants.
    * Then, add up their total: (e.g., $12 for Starbucks + $20 for Uber = $32).
    * Subtract this total from the main budget: (${total_budget} - $32 = ${total_budget - 32}).
    * Put ALL remaining money into a single category named **"Buffer"**.
    * This "Everything Else" category MUST make the grand total equal **${total_budget} EXACTLY**.

4.  **STICK TO THE LIST.**
    * You MUST create a plan for *every* merchant in the list.
    * It is OK to give "0 visits" to places if the budget is too tight.
    * Do NOT include any merchants that are *not* in the list.
    * Group merchants into logical categories: "Food & Dining", "Transportation", "Entertainment", "Shopping & Other", and "Everything Else".

OUTPUT FORMAT:
Return JSON ONLY. **No markdown, no ``` fences**, just the raw JSON object.
Use this exact shape. **DO NOT include "amount" or "percent" fields.**

{{
  "Food & Dining": {{
    "subtitle": "Starbucks (2 visits), Chipotle (1 visit)"
  }},
  "Transportation": {{
    "subtitle": "Uber (2 rides)"
  }},
  "Buffer": {{
    "subtitle": "Anything extra you wanna spend"
    }}
}}

Constraints:
- You MUST return a "Buffer" category.
- `subtitle` MUST mention visits/rides/nights like "X (N visits)".
"""
    # -------------------------------------------
    
    # 6. Check cache
    tx_string = json.dumps(transactions, sort_keys=True)
    tx_hash = hashlib.md5(tx_string.encode()).hexdigest()
    
    # --- NEW CACHE KEY (Task 2a) ---
    # Create a stable hash for the selected merchants list
    merchants_string = json.dumps(selected_merchants, sort_keys=True)
    merchants_hash = hashlib.md5(merchants_string.encode()).hexdigest()
    cache_key = f"{uid}:{total_budget}:{tx_hash}:{merchants_hash}:v3" # v3 for new logic
    # -------------------------------
    
    cached = get_cached_summary(cache_key)
    if cached:
        print("Cache hit")
        return jsonify(suggestion=cached)
    
    # 7. Call Claude
    claude_response = None

    try:
        print("Calling Claude...")
        claude_response = call_claude(prompt).strip()
        print("CLAUDE RAW RESPONSE:", claude_response)

        lines = claude_response.splitlines()
        json_lines = [l for l in lines if not l.strip().startswith("```") and l.strip().lower() != "json"]
        cleaned = "\n".join(json_lines).strip()
        
        # 1. Get the "raw" suggestion from the AI
        ai_suggestion = json.loads(cleaned)
        
        # 2. "Heal" the suggestion using our Python code and patterns data
        print(f"AI raw suggestion: {ai_suggestion}")
        suggestion = _recalculate_budget_plan(
            ai_suggestion=ai_suggestion,
            patterns=patterns,  # We already have this from the analyzer!
            total_budget=total_budget
        )
        print(f" Healed suggestion: {suggestion}")

    except Exception as err:
        print(f"Claude call/parse error: {err}")
        traceback.print_exc()
        if claude_response is not None:
            print("Raw response:", claude_response)
        else:
            print("No Claude response received.")
        return jsonify(error="AI summary failed", details=str(err)), 500
    
    # 8. Cache & return
    set_cached_summary(cache_key, suggestion)
    return jsonify(suggestion=suggestion)


@ai_bp.route("/ai/clear_cache", methods=["POST"])
def clear_cache():
    """Clears the AI cache."""
    try:
        cache_file = "ai_weekly_cache.json"
        if os.path.exists(cache_file):
            os.remove(cache_file)
            return jsonify(success=True, message="Cache cleared")
        return jsonify(success=True, message="No cache to clear")
    except Exception as e:
        return jsonify(error=str(e)), 500

#
# --- THIS IS THE CORRECT RE-ALLOCATION ROUTE ---
#
@ai_bp.route("/ai/reallocate", methods=["POST"])
def reallocate_budget():
    """
    Re-allocates a budget when one category is locked by the user.
    """
    try:
        # 1. Verify user
        id_token = request.headers.get('Authorization').split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        print(f" Verified user for AI reallocation: {uid}")
    except Exception as e:
        return jsonify(error="Invalid token.", details=str(e)), 401

    # 2. Parse request
    try:
        data = request.get_json(force=True)
        print("▶️ [reallocate] raw request JSON:", data)
        
        transactions = data.get("transactions", [])
        current_plan = data.get("current_plan", {})
        locked_category = data.get("locked_category", "")
        new_value = data.get("new_value", 0)
        total_budget = data.get("total_budget", 0)
        
        if not locked_category or not total_budget:
            return jsonify(error="Missing required fields for reallocation."), 400
            
    except Exception as e:
        return jsonify(error="Invalid request body.", details=str(e)), 400

    # 3. Analyze spending patterns (so we have the median costs)
    from services.budget_analyzer import analyze_spending_patterns
    patterns = analyze_spending_patterns(transactions)
    
    # 4. Prepare data for the prompt
    
    # This is the "locked" part of the plan
    locked_item_str = f"- {locked_category}: ${new_value}"
    
    # This is the "unlocked" part of the plan
    unlocked_items = []
    unlocked_total = 0
    for category, details in current_plan.items():
        if category != locked_category:
            unlocked_items.append(f"- {category}: ${details.get('amount', 0)}")
            unlocked_total += details.get('amount', 0)
            
    unlocked_items_str = "\n".join(unlocked_items)
    
    # Calculate how much money is left to re-distribute
    remaining_budget = total_budget - new_value
    
    # 5. Build the prompt
    # (The prompt is unchanged, as the AI only needs to know the subtitles,
    #  not the new "merchants" array. This is good.)
    prompt = f"""You are a budget assistant. A user has locked one category and wants to re-allocate the *remaining* money among their other categories.

TOTAL BUDGET: ${total_budget}
LOCKED CATEGORY:
{locked_item_str}

This leaves ${remaining_budget} to be split among these categories:
{unlocked_items_str}

YOUR JOB:
Intelligently re-distribute the ${remaining_budget} across the *unlocked* categories. You MUST adjust their values. You cannot keep them the same.

RULES:
1.  The user's past spending habits (for context):
{json.dumps(patterns, indent=2)}
2.  The "Buffer" category should absorb most of the changes.
3.  The final plan (locked + unlocked) must sum to ${total_budget}.
4.  You MUST return a plan that includes the *visit counts* in the subtitle, just like you did before.

OUTPUT FORMAT:
Return JSON ONLY. **No markdown, no ``` fences**.
Use this exact shape. **DO NOT include "amount" or "percent" fields.**

{{
  "Food & Dining": {{
    "subtitle": "Starbucks (1 visit), Chipotle (1 visit)"
  }},
  "Transportation": {{
    "subtitle": "Uber (0 rides)"
  }},
  "Buffer": {{
    "subtitle": "Anything extra you wanna spend"
  }}
}}
"""

    # 6. Call AI (No cache for re-allocation)
    try:
        print("Calling Claude for re-allocation...")
        claude_response = call_claude(prompt).strip()
        print("CLAUDE RAW RESPONSE:", claude_response)

        lines = claude_response.splitlines()
        json_lines = [l for l in lines if not l.strip().startswith("```") and l.strip().lower() != "json"]
        cleaned = "\n".join(json_lines).strip()
        
        # 1. Get the "raw" suggestion from the AI
        ai_suggestion = json.loads(cleaned)
        
        # 2. "Heal" the suggestion using our Python code
        # IMPORTANT: We only heal the *unlocked* categories
        print(f"🧠 AI raw re-allocation: {ai_suggestion}")
        
        # --- THIS IS THE KEY ---
        # Our *new* _recalculate_budget_plan function is called here.
        # It will automatically add the "merchants" array to all
        # the *unlocked* categories (including "Everything Else").
        healed_plan = _recalculate_budget_plan(
            ai_suggestion=ai_suggestion,
            patterns=patterns,
            total_budget=remaining_budget # Heal based on the *remaining* budget
        )
        
        # 3. Add the locked category back in
        #    We must now *also* add the "merchants" array back in,
        #    which we get from the "current_plan" sent by the app.
        
        # --- THIS BLOCK IS THE ONLY CHANGE ---
        locked_category_details = current_plan.get(locked_category, {})
        locked_subtitle = locked_category_details.get("subtitle", "")
        locked_merchants = locked_category_details.get("merchants", []) # <-- NEW
        
        healed_plan[locked_category] = {
            "amount": new_value,
            "percent": 0, # Will fix in a moment
            "subtitle": locked_subtitle,
            "merchants": locked_merchants # <-- NEW
        }
        # -------------------------------------

        # 4. We must do a final pass to fix the "Everything Else" amount
        #    and all percentages, because our healer function was only
        #    aware of the *remaining* budget.
        
        final_total_without_else = 0
        for category, details in healed_plan.items():
            if category.lower() != "buffer":
                final_total_without_else += details["amount"]
        
        # Fix "Everything Else" amount
        final_else_amount = total_budget - final_total_without_else
        
        # Make sure "Everything Else" exists, even if AI didn't return it
        if "Buffer" not in healed_plan:
            healed_plan["Buffer"] = {
                "subtitle": "Anything extra you wanna spend",
                "merchants": []
            }

        healed_plan["Buffer"]["amount"] = max(0, final_else_amount)
        
        # Fix all percentages
        if total_budget > 0:
            final_total = sum(details["amount"] for details in healed_plan.values())
            if final_total > 0:
                for category, details in healed_plan.items():
                    amount = details["amount"]
                    details["percent"] = round((amount / final_total) * 100)
            else:
                for category, details in healed_plan.items():
                    details["percent"] = 0
        else:
            for category, details in healed_plan.items():
                details["percent"] = 0

        print(f" Healed re-allocation: {healed_plan}")
        
        return jsonify(suggestion=healed_plan)

    except Exception as err:
        print(f"Claude re-allocation call/parse error: {err}")
        traceback.print_exc()
        if claude_response is not None:
            print("Raw response:", claude_response)
        return jsonify(error="AI re-allocation failed", details=str(err)), 500