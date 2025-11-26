# services/budget_analyzer.py
from datetime import datetime
from collections import defaultdict
import re
import statistics

def normalize_merchant_name(raw_name: str) -> str:
    """
    Normalizes merchant names by removing location codes, numbers, etc.

    Examples:
        "Uber 063015 SF**POOL**" → "Uber"
        "Starbucks #1234" → "Starbucks"
        "McDonald's" → "McDonald's"
    """
    # Remove everything after common patterns
    name = re.sub(r'\s+\d{5,}.*$', '', raw_name)   # Remove long numeric IDs
    name = re.sub(r'\s*\*+.*$', '', name)          # Remove asterisk suffixes
    name = re.sub(r'\s*#\d+.*$', '', name)         # Remove store numbers
    name = re.sub(r'\s+(SF|NYC|LA|CHI)\b.*$', '', name, flags=re.IGNORECASE)

    # Clean up whitespace
    name = name.strip()
    name = re.sub(r'\s+', ' ', name)

    return name


def should_exclude_transaction(transaction: dict) -> bool:
    """
    Returns True if this transaction should be excluded from budget analysis.

    Excludes:
    - Fixed monthly bills (rent, utilities, payroll)
    - Credit card/loan payments
    - Savings/investments
    - Income (negative amounts for deposits)
    - Large one-time travel expenses
    """
    name = (transaction.get("name") or "").upper()
    category = (transaction.get("category") or "").upper()
    amount = float(transaction.get("amount", 0))

    # ❌ 1. Exclude income (negative amounts)
    if amount < 0:
        return True

    # ❌ 2. Exclude fixed/monthly expenses by category
    excluded_categories = {
        "RENT_AND_UTILITIES",
        "TRANSFER_OUT",      # Credit card / transfer payments
        "LOAN_PAYMENTS",
        "INCOME",
    }
    if category in excluded_categories:
        return True

    # ❌ 3. Exclude by merchant name patterns
    # NOTE: all patterns are UPPERCASE because we uppercased "name"
    excluded_patterns = [
        "AUTOMATIC PAYMENT",
        "CREDIT CARD",
        "ACH ELECTRONIC",
        "GUSTO PAY",         # Payroll
        "CD DEPOSIT",        # Savings
        "INTRST PYMNT",      # Interest
        "PAYMENT *",         # Generic payments
    ]
    for pattern in excluded_patterns:
        if pattern in name:
            return True

    # ❌ 4. Exclude large travel expenses (flights over $300)
    if category == "TRAVEL" and amount > 300:
        return True

    return False


def analyze_spending_patterns(transactions: list[dict]) -> dict:
    """
    Analyzes transactions and returns merchant-level spending patterns.

    Returns:
    {
        "Subway": {
            "visits_per_week": 2.5,
            "avg_cost_per_visit": 6.50,
            "total_visits": 15,
            "total_spent": 97.50,
            "consistency": "regular",
            "category": "FOOD_AND_DRINK",
            "dates": ["2025-11-01", "2025-11-03", ...]
        },
        ...
    }
    """
    # ✅ 1. Filter out excluded transactions
    relevant_txs = [tx for tx in transactions if not should_exclude_transaction(tx)]

    if not relevant_txs:
        return {}

    # ✅ 2. Calculate date range for visits per week
    dates = [datetime.fromisoformat(tx["date"]) for tx in relevant_txs]
    start_date = min(dates)
    end_date = max(dates)
    total_weeks = max(1, (end_date - start_date).days / 7)

    # ✅ 3. Group by normalized merchant name
    merchant_data = defaultdict(lambda: {
        "visits": [],
        "amounts": [],
        "category": None,
    })

    for tx in relevant_txs:
        merchant = normalize_merchant_name(tx["name"])
        merchant_data[merchant]["visits"].append(tx["date"])
        merchant_data[merchant]["amounts"].append(float(tx["amount"]))
        if not merchant_data[merchant]["category"]:
            merchant_data[merchant]["category"] = tx.get("category", "OTHER")

    # ✅ 4. Calculate patterns for each merchant
    patterns: dict[str, dict] = {}

    for merchant, data in merchant_data.items():
        total_visits = len(data["visits"])
        total_spent = sum(data["amounts"])
        # Use median for a more accurate "typical" cost
        if total_visits > 0:
            median_cost = statistics.median(data["amounts"])
        else:
            median_cost = 0
        visits_per_week = total_visits / total_weeks if total_weeks else 0

        # Determine consistency
        visit_dates = sorted(datetime.fromisoformat(d) for d in data["visits"])
        if total_visits >= 4:
            gaps = [
                (visit_dates[i + 1] - visit_dates[i]).days
                for i in range(len(visit_dates) - 1)
            ]
            avg_gap = sum(gaps) / len(gaps) if gaps else 0

            if avg_gap <= 10:
                consistency = "regular"
            elif avg_gap <= 21:
                consistency = "occasional"
            else:
                consistency = "inconsistent"
        elif total_visits >= 2:
            consistency = "occasional"
        else:
            consistency = "one-time"

        # ✅ 5. Only include if they visit at least twice
        if total_visits >= 2:
            patterns[merchant] = {
                "visits_per_week": round(visits_per_week, 1),
                "median_cost_per_visit": round(median_cost, 2),
                "total_visits": total_visits,
                "total_spent": round(total_spent, 2),
                "consistency": consistency,
                "category": data["category"],
                "dates": data["visits"],
            }

    return patterns