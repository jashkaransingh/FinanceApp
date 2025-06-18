from flask import Blueprint, request, jsonify
from utils.gemini_client import call_gemini
from utils.cache_manager import get_cached_summary, set_cached_summary
import json

ai_bp = Blueprint("ai", __name__)

@ai_bp.route("/ai/weekly_summary", methods=["POST"])
def weekly_summary():
    data = request.get_json()
    transactions = data.get("transactions", [])
    budget = data.get("weekly_budget", 100)
    user_id = data.get("user_id", "anonymous")  # You can send Firebase UID here

    # ⏪ Try to load from cache first
    cached = get_cached_summary(user_id)
    if cached:
        return jsonify(suggestion=cached)

    # 🧠 If not cached, build a prompt and call Gemini
    history = "\n".join(f"{tx['name']} - ${tx['amount']}" for tx in transactions)
    prompt = (
        f"Based on the following past transactions:\n\n{history}\n\n"
        f"And a weekly budget of ${budget}, generate a breakdown of how I could spend this week. "
        f"Include quantities, categories, and amounts. Format your response as a clean JSON like:\n\n"
        "{ 'subway': 2, 'mcdonalds': 3, 'bars': '$20', 'groceries': '$30' }\n"
    )

    try:
        raw = call_gemini(prompt)
        cleaned = raw.strip().removeprefix("```json").removesuffix("```").strip()
        parsed = json.loads(cleaned)
    except Exception:
        return jsonify(error="AI response was not valid JSON"), 500

    # ✅ Cache the result
    set_cached_summary(user_id, parsed)

    return jsonify(suggestion=parsed)

# structure - iOS App → /ai/weekly_summary → Flask → Gemini → Spending Breakdown → iOS
