from flask import Blueprint, jsonify, request
from datetime import date, timedelta

from plaid_client import fetch_all_transactions, plaid_client
from plaid.model.transactions_refresh_request import TransactionsRefreshRequest

tx_bp = Blueprint("transactions", __name__)


def parse_date_range(start_str: str, end_str: str, period: str):
    """
    Determine start_date and end_date based on either:
      • a shorthand `period` ("today", "week", "month"), or
      • explicit ISO-8601 `start_str`/`end_str`.
    Defaults to the last 30 days if neither is provided.
    Raises ValueError on invalid period or date format.
    """
    today = date.today()

    if period:
        if period == "today":
            return today, today
        if period == "week":
            return today - timedelta(days=7), today
        if period == "month":
            return today - timedelta(days=30), today
        raise ValueError(f"Invalid period specified: {period}")

    if start_str and end_str:
        try:
            return date.fromisoformat(start_str), date.fromisoformat(end_str)
        except ValueError:
            raise ValueError("Invalid date format; expected YYYY-MM-DD")

    # Default fallback: last 30 days
    return today - timedelta(days=30), today


@tx_bp.route("/transactions", methods=["GET"])
def get_transactions():
    """
    GET /transactions?access_token=…[&period=today|week|month]
      OR &start_date=YYYY-MM-DD&end_date=YYYY-MM-DD

    Returns a JSON array of transactions, each:
      { name, amount, date, category }
    """
    token     = request.args.get("access_token", "")
    if not token:
        return jsonify(error="Missing access_token"), 400

    start_str = request.args.get("start_date", "")
    end_str   = request.args.get("end_date", "")
    period    = request.args.get("period", "")

    try:
        start_date, end_date = parse_date_range(start_str, end_str, period)
    except ValueError as e:
        return jsonify(error=str(e)), 400

    # Fetch all txns in the date range
    txns = fetch_all_transactions(token, start_date, end_date)

    # Convert to simple dicts for the client
    out = [
        {
            "name":     t.name,
            "amount":   t.amount,
            "date":     t.date.isoformat(),
            "category": t.category or ""
        }
        for t in txns
    ]
    return jsonify(transactions=out)


@tx_bp.route("/refresh", methods=["POST"])
def refresh_transactions():
    """
    POST /refresh
    {
      "access_token": "..."
    }

    Tells Plaid to refresh the given access token's transactions.
    """
    token = request.json.get("access_token", "")
    if not token:
        return jsonify(error="Missing access_token"), 400

    req = TransactionsRefreshRequest(access_token=token)
    plaid_client.transactions_refresh(req)
    return jsonify(message="Transactions refreshed successfully")


@tx_bp.route("/summaries", methods=["GET"])
def get_summaries():
    """
    GET /summaries?access_token=…

    Returns JSON of the form:
    {
      "summaries": [
        {
          "periodTitle": "Spent Today",
          "amount": 123.45,
          "percentage": -5.6,
          "subtitle": "Yesterday $130.00",
          "usesPieIcon": false
        },
        …
      ]
    }
    """
    token = request.args.get("access_token", "")
    if not token:
        return jsonify(error="Missing access_token"), 400

    today = date.today()

    # Helper to sum all txns between two dates
    def sum_between_days(start: date, end: date) -> float:
        return sum(t.amount for t in fetch_all_transactions(token, start, end))

    # 1) Today vs Yesterday
    t_total    = sum_between_days(today, today)
    y_total    = sum_between_days(today - timedelta(days=1), today - timedelta(days=1))
    pct_today  = ((t_total - y_total) / abs(y_total) * 100) if y_total else 0

    # 2) This Week vs Last Week
    w_start    = today - timedelta(days=7)
    this_week  = sum_between_days(w_start, today)
    last_week  = sum_between_days(w_start - timedelta(days=7), w_start)
    pct_week   = ((this_week - last_week) / abs(last_week) * 100) if last_week else 0

    # 3) This Month vs Last Month
    m_start    = today - timedelta(days=30)
    this_month = sum_between_days(m_start, today)
    last_month = sum_between_days(m_start - timedelta(days=30), m_start)
    pct_month  = ((this_month - last_month) / abs(last_month) * 100) if last_month else 0

    payload = [
        {
            "periodTitle": "Spent Today",
            "amount":      round(t_total, 2),
            "percentage":  round(pct_today, 1),
            "subtitle":    f"Yesterday ${y_total:.2f}",
            "usesPieIcon": False
        },
        {
            "periodTitle": "Spent This Week",
            "amount":      round(this_week, 2),
            "percentage":  round(pct_week, 1),
            "subtitle":    f"Last Week ${last_week:.2f}",
            "usesPieIcon": False
        },
        {
            "periodTitle": "Spent This Month",
            "amount":      round(this_month, 2),
            "percentage":  round(pct_month, 1),
            "subtitle":    f"Last Month ${last_month:.2f}",
            "usesPieIcon": True
        }
    ]

    return jsonify(summaries=payload)