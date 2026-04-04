# test_server.py
import urllib.request
import json

# Your live Render URL
SERVER_URL = "https://sleep-assistant.onrender.com"

# ─── Test 1: Health Check ─────────────────────────────────────
print("=== Test 1: Health Check ===")
try:
    req    = urllib.request.urlopen(SERVER_URL, timeout=30)
    result = json.loads(req.read())
    print(result)
    print("PASSED")
except Exception as e:
    print(f"FAILED: {e}")
print()

# ─── Test 2: Classify Endpoint ───────────────────────────────
print("=== Test 2: Classify ===")
try:
    data = json.dumps({
        "user_id": "test_user_123",
        "session": {
            "total_screen_time": 47,
            "unlock_count":      13,
            "longest_session":   22,
            "hour_of_first_use": 23,
            "app_category":      2
        },
        "nudge_sent_tonight": False,
        "current_hour":       23
    }).encode('utf-8')

    req = urllib.request.Request(
        f"{SERVER_URL}/classify",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    result = json.loads(
        urllib.request.urlopen(req, timeout=30).read()
    )
    print(result)
    print("PASSED")
except Exception as e:
    print(f"FAILED: {e}")
print()

# ─── Test 3: Feedback Endpoint ───────────────────────────────
print("=== Test 3: Feedback ===")
try:
    data = json.dumps({
        "user_id":    "test_user_123",
        "helped":     True,
        "risk_score": "High"
    }).encode('utf-8')

    req = urllib.request.Request(
        f"{SERVER_URL}/feedback",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    result = json.loads(
        urllib.request.urlopen(req, timeout=30).read()
    )
    print(result)
    print("PASSED")
except Exception as e:
    print(f"FAILED: {e}")
print()

# ─── Test 4: Low Risk Session ────────────────────────────────
print("=== Test 4: Low Risk Session ===")
try:
    data = json.dumps({
        "user_id": "test_user_123",
        "session": {
            "total_screen_time": 8,
            "unlock_count":      2,
            "longest_session":   5,
            "hour_of_first_use": 22,
            "app_category":      0
        },
        "nudge_sent_tonight": False,
        "current_hour":       22
    }).encode('utf-8')

    req = urllib.request.Request(
        f"{SERVER_URL}/classify",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    result = json.loads(
        urllib.request.urlopen(req, timeout=30).read()
    )
    print(result)
    print("PASSED")
except Exception as e:
    print(f"FAILED: {e}")
print()

print("=" * 40)
print("All tests complete.")
print(f"Server: {SERVER_URL}")