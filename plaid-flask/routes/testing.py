from flask import Blueprint, jsonify
from datetime import datetime, timedelta
import random

testing_bp = Blueprint("testing", __name__)

REALISTIC_SCENARIOS = {
    "college_student": [
        # Food - frequent, small amounts
        *[{"name": "Chipotle", "amount": random.uniform(10, 15), "category": "FOOD_AND_DRINK", 
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(8)],
        
        *[{"name": "Starbucks", "amount": random.uniform(4, 7), "category": "FOOD_AND_DRINK",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(12)],
        
        # Transportation
        *[{"name": "Uber", "amount": random.uniform(8, 15), "category": "TRANSPORTATION",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(6)],
        
        # Entertainment
        *[{"name": "AMC Theaters", "amount": 15.50, "category": "ENTERTAINMENT",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(3)],
        
        *[{"name": "Spotify", "amount": 10.99, "category": "ENTERTAINMENT",
           "date": (datetime.now() - timedelta(days=i*30)).strftime("%Y-%m-%d")} 
          for i in range(2)],
    ],
    
    "working_professional": [
        # Food - lunch spots
        *[{"name": "Sweetgreen", "amount": random.uniform(12, 18), "category": "FOOD_AND_DRINK",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(15)],
        
        *[{"name": "Starbucks", "amount": random.uniform(5, 8), "category": "FOOD_AND_DRINK",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(20)],
        
        # Transportation
        *[{"name": "Uber", "amount": random.uniform(12, 25), "category": "TRANSPORTATION",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(10)],
        
        # Fitness
        *[{"name": "Equinox", "amount": 200, "category": "PERSONAL_CARE",
           "date": (datetime.now() - timedelta(days=i*30)).strftime("%Y-%m-%d")} 
          for i in range(2)],
        
        # Shopping
        *[{"name": "Amazon", "amount": random.uniform(20, 80), "category": "GENERAL_MERCHANDISE",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(8)],
    ],
    
    "budget_conscious": [
        # Groceries (cheaper than eating out)
        *[{"name": "Trader Joe's", "amount": random.uniform(30, 60), "category": "FOOD_AND_DRINK",
           "date": (datetime.now() - timedelta(days=i*7)).strftime("%Y-%m-%d")} 
          for i in range(6)],
        
        # Rare eating out
        *[{"name": "McDonald's", "amount": random.uniform(6, 10), "category": "FOOD_AND_DRINK",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(4)],
        
        # Public transit
        *[{"name": "Subway MetroCard", "amount": 127, "category": "TRANSPORTATION",
           "date": (datetime.now() - timedelta(days=i*30)).strftime("%Y-%m-%d")} 
          for i in range(2)],
        
        # Occasional treats
        *[{"name": "Target", "amount": random.uniform(15, 40), "category": "GENERAL_MERCHANDISE",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(5)],
    ],
    
    "foodie": [
        # Lots of dining out
        *[{"name": "Chipotle", "amount": random.uniform(12, 18), "category": "FOOD_AND_DRINK",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(8)],
        
        *[{"name": "Whole Foods", "amount": random.uniform(40, 80), "category": "FOOD_AND_DRINK",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(6)],
        
        *[{"name": "Local Restaurant", "amount": random.uniform(40, 90), "category": "FOOD_AND_DRINK",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(10)],
        
        *[{"name": "DoorDash", "amount": random.uniform(25, 45), "category": "FOOD_AND_DRINK",
           "date": (datetime.now() - timedelta(days=random.randint(0, 42))).strftime("%Y-%m-%d")} 
          for _ in range(12)],
    ]
}

@testing_bp.route("/test/scenarios", methods=["GET"])
def get_scenarios():
    """Returns available test scenarios."""
    return jsonify(scenarios=list(REALISTIC_SCENARIOS.keys()))

@testing_bp.route("/test/scenario/<name>", methods=["GET"])
def get_scenario(name):
    """Returns transactions for a specific scenario."""
    if name not in REALISTIC_SCENARIOS:
        return jsonify(error="Scenario not found"), 404
    
    return jsonify(transactions=REALISTIC_SCENARIOS[name])