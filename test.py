# test_firebase.py
import firebase_admin
from firebase_admin import credentials, firestore
from firebase_config import FIREBASE_CONFIG
import pyrebase

# ─── Test 1: Admin SDK (for backend operations) ───────────

print("=== Test 1: Firebase Admin SDK ===")
try:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("Firebase Admin connected successfully")
except Exception as e:
    print(f"Admin SDK failed: {e}")

# ─── Test 2: Pyrebase (for authentication) ────────────────

print("\n=== Test 2: Pyrebase Auth ===")
try:
    firebase = pyrebase.initialize_app(FIREBASE_CONFIG)
    auth = firebase.auth()
    print("Pyrebase connected successfully")
except Exception as e:
    print(f"Pyrebase failed: {e}")

# ─── Test 3: Write to Firestore ───────────────────────────

print("\n=== Test 3: Write to Firestore ===")
try:
    db.collection('test').document('connection_test').set({
        'status': 'connected',
        'message': 'Sleep Assistant Firebase is working'
    })
    print("Write to Firestore successful")
except Exception as e:
    print(f"Firestore write failed: {e}")

# ─── Test 4: Read from Firestore ──────────────────────────

print("\n=== Test 4: Read from Firestore ===")
try:
    doc = db.collection('test').document('connection_test').get()
    if doc.exists:
        print("Read from Firestore successful")
        print("Data:", doc.to_dict())
    else:
        print("Document not found")
except Exception as e:
    print(f"Firestore read failed: {e}")

print("\nAll Firebase tests done.")