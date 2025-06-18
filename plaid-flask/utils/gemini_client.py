import requests
import os

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")  # Add this to your .env

def call_gemini(prompt):
    endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    headers = {
        "Content-Type": "application/json"
    }
    payload = {
        "contents": [
            {"parts": [{"text": prompt}]}
        ]
    }
    params = {
        "key": GEMINI_API_KEY
    }
    response = requests.post(endpoint, headers=headers, json=payload, params=params)
    data = response.json()
    return data["candidates"][0]["content"]["parts"][0]["text"]
