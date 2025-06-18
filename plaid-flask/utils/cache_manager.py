import json
import os
from datetime import datetime

CACHE_FILE = "ai_weekly_cache.json"  # This will be created in your Flask root dir

def get_current_week_key():
    today = datetime.today()
    return f"{today.year}-W{today.isocalendar()[1]}"

def load_cache():
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, "r") as f:
            return json.load(f)
    return {}

def save_cache(cache):
    with open(CACHE_FILE, "w") as f:
        json.dump(cache, f, indent=2)

def get_cached_summary(user_id):
    cache = load_cache()
    week_key = get_current_week_key()
    return cache.get(user_id, {}).get(week_key)

def set_cached_summary(user_id, suggestion):
    cache = load_cache()
    week_key = get_current_week_key()
    if user_id not in cache:
        cache[user_id] = {}
    cache[user_id][week_key] = suggestion
    save_cache(cache)
