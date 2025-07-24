# utils/cache_manager.py
import json
import os
import time

CACHE_FILE = "ai_cache.json"
CACHE_TTL_SECONDS = 86400  # Cache entries expire after 24 hours

def load_cache():
    if not os.path.exists(CACHE_FILE):
        return {}
    with open(CACHE_FILE, "r") as f:
        try:
            return json.load(f)
        except json.JSONDecodeError:
            return {}

def save_cache(cache):
    with open(CACHE_FILE, "w") as f:
        json.dump(cache, f, indent=2)

def get_cached_summary(key):
    cache = load_cache()
    entry = cache.get(key)
    
    if not entry:
        return None # Not in cache
    
    # Check if the cache entry has expired
    if time.time() - entry.get("timestamp", 0) > CACHE_TTL_SECONDS:
        print(f"Cache expired for key: {key}")
        return None # Expired
        
    print(f"✅ Cache hit for key: {key}")
    return entry.get("data")

def set_cached_summary(key, suggestion):
    cache = load_cache()
    cache[key] = {
        "timestamp": time.time(),
        "data": suggestion
    }
    save_cache(cache)
