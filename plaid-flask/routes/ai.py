from flask import Blueprint, request, jsonify
from utils.gemini_client import call_gemini
from utils.cache_manager import get_cached_summary, set_cached_summary
import json

ai_bp = Blueprint("ai", __name__)

@ai_bp.route("/ai/weekly_summary", methods=["POST"])
def weekly_summary():
    # 1️⃣ Parse JSON body from request
    data = request.get_json(force=True)

    # 2️⃣ Extract fields
    transactions = data.get("transactions", [])
    budget       = data.get("weekly_budget", 100)
    user_id      = data.get("user_id", "anonymous")

    # 3️⃣ Construct cache key
    cache_key = f"{user_id}:{budget}"
    cached = get_cached_summary(cache_key)
    if cached:
        return jsonify(suggestion=cached)

    # 4️⃣ Build prompt for Gemini
    history = "\n".join(f"{tx['name']} - ${tx['amount']}" for tx in transactions)
    prompt = (
        f"Based on the following past transactions:\n{history}\n\n"
        f"And a weekly budget of ${budget}, generate a breakdown of how I could spend this week. "
        "I want **only** a JSON object mapping categories to amounts (e.g. "
        "{ 'subway': 2, 'groceries': 30, 'bars': 20 }). "
        "Do **not** include any additional fields like notes or summary."
    )

    # 5️⃣ Call Gemini and parse
    try:
        raw = call_gemini(prompt).strip()

        # Remove markdown formatting (```json / json / ```)
        lines = raw.splitlines()
        json_lines = [line for line in lines if not line.strip().startswith("```") and line.strip() != "json"]
        cleaned = "\n".join(json_lines).strip()

        parsed = json.loads(cleaned)
    except Exception as e:
        print("❌ [weekly_summary] error parsing AI response:", e)
        parsed = {}

    # 6️⃣ Cache and return result
    set_cached_summary(cache_key, parsed)
    return jsonify(suggestion=parsed)
