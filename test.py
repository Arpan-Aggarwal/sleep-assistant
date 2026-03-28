# test_firestore.py
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import time
from firebase.auth import FirebaseAuth
from firebase.firestore import FirestoreManager
from core.queue_manager import QueueManager

# First sign in
auth = FirebaseAuth()
result = auth.sign_in(
    email="testuser@sleepapp.com",
    password="test123456"
)

if not result['success']:
    print("Sign in failed — cannot test Firestore")
    exit()

user_id = result['user_id']
queue   = QueueManager()
fs      = FirestoreManager(user_id, queue)
print(f"Signed in as: {user_id}\n")

# ─── Test 1: Save Profile ─────────────────────────────────
print("=== Test 1: Save Profile ===")
fs.save_profile({
    'sleepGoalTime': '11:00 PM',
    'wakeTime':      '6:30 AM',
    'mode':          'silent'
})
time.sleep(2)  # Wait for async thread
print()

# ─── Test 2: Push Night Event ────────────────────────────
print("=== Test 2: Push Night Event ===")
fs.push_night_event({
    'total_screen_time': 47,
    'unlock_count':      13,
    'longest_session':   22,
    'hour_of_first_use': 23,
    'app_category':      2,
    'risk_local':        'High'
})
time.sleep(2)
print()

# ─── Test 3: Save Risk Score ─────────────────────────────
print("=== Test 3: Save Risk Score ===")
fs.save_risk_score('High', {
    'total_screen_time': 47,
    'unlock_count':      13,
    'longest_session':   22
})
time.sleep(2)
print()

# ─── Test 4: Get Last Session ────────────────────────────
print("=== Test 4: Get Last Session ===")
def on_session(data):
    print(f"Session data received: {data}")

fs.get_last_session(on_session)
time.sleep(2)
print()

# ─── Test 5: Mark Nudge Sent ─────────────────────────────
print("=== Test 5: Mark Nudge Sent ===")
fs.mark_nudge_sent()
time.sleep(2)
print()

# ─── Test 6: Save Feedback ───────────────────────────────
print("=== Test 6: Save Feedback ===")
fs.save_feedback(helped=True, risk_score='High')
time.sleep(2)
print()

# ─── Test 7: Offline Queue Flush ─────────────────────────
print("=== Test 7: Offline Queue Flush ===")
queue.add_event({'test': 'queued_event', 'unlock_count': 5})
queue.add_event({'test': 'queued_event_2', 'unlock_count': 8})
print(f"Queue size before flush: {len(queue.get_all_events())}")
fs.flush_queue()
time.sleep(2)
print(f"Queue size after flush: {len(queue.get_all_events())}")
print()

print("All Firestore tests done.")
print("Check your Firebase Console to verify data appeared.")
