# server/app.py
import os
import sys
import json
import pickle
import threading
from datetime import datetime
from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, firestore, messaging

app = Flask(__name__)

model      = None
model_path = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    'model.pkl'
)

if os.path.exists(model_path):
    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    print("[Server] ML model loaded")
else:
    print("[Server] No model found — training fresh model...")
    try:
        import numpy as np
        from sklearn.linear_model import LogisticRegression

        # Same synthetic data as our training notebook
        np.random.seed(42)
        n = 200

        # Generate High risk samples
        high_data = np.column_stack([
            np.random.randint(40, 80, n//3),   # screen time
            np.random.randint(10, 20, n//3),   # unlocks
            np.random.randint(20, 45, n//3),   # longest session
            np.random.randint(22, 24, n//3),   # hour
            np.random.randint(2, 4,  n//3)     # category
        ])
        high_labels = ['High'] * (n//3)

        # Generate Medium risk samples
        med_data = np.column_stack([
            np.random.randint(20, 40, n//3),
            np.random.randint(5, 10,  n//3),
            np.random.randint(10, 20, n//3),
            np.random.randint(21, 23, n//3),
            np.random.randint(0, 3,   n//3)
        ])
        med_labels = ['Medium'] * (n//3)

        # Generate Low risk samples
        low_data = np.column_stack([
            np.random.randint(0, 20,  n//3),
            np.random.randint(0, 5,   n//3),
            np.random.randint(0, 10,  n//3),
            np.random.randint(20, 22, n//3),
            np.random.randint(0, 2,   n//3)
        ])
        low_labels = ['Low'] * (n//3)

        # Combine
        X = np.vstack([high_data, med_data, low_data])
        y = high_labels + med_labels + low_labels

        # Train
        model = LogisticRegression(max_iter=1000)
        model.fit(X, y)

        # Save
        with open(model_path, 'wb') as f:
            pickle.dump(model, f)

        print("[Server] Fresh model trained and saved")

    except Exception as e:
        print(f"[Server] Model training failed: {e}")
        print("[Server] Will use rule-based classification")
# ─── Initialize Firebase ─────────────────────────────────────

cred_json = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS_JSON')

if cred_json:
    cred_dict = json.loads(cred_json)
    cred      = credentials.Certificate(cred_dict)
else:
    cred_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        'serviceAccountKey.json'
    )
    cred = credentials.Certificate(cred_path)

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

# ─── Load ML Model ───────────────────────────────────────────

model      = None
model_path = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    'model.pkl'
)

if os.path.exists(model_path):
    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    print("[Server] ML model loaded")
else:
    print("[Server] No model — using rules")


# ─── ROUTES ──────────────────────────────────────────────────

@app.route('/')
def home():
    return jsonify({
        'status': 'Sleep Assistant Server is running',
        'time':   datetime.now().isoformat()
    })


@app.route('/classify', methods=['POST'])
def classify():
    try:
        data         = request.get_json()
        user_id      = data.get('user_id')
        session      = data.get('session', {})
        nudge_sent   = data.get('nudge_sent_tonight', False)
        current_hour = data.get('current_hour', 0)

        if not user_id or not session:
            return jsonify({
                'error': 'Missing user_id or session'
            }), 400

        # Classify risk
        risk = _classify_risk(session)

        # Save to Firestore in background
        threading.Thread(
            target=_save_risk_to_firestore,
            args=(user_id, risk, session),
            daemon=True
        ).start()

        # Send nudge if needed
        nudge_sent_now = False
        valid_hours    = [23, 0, 1, 2]

        if (risk in ['High', 'Medium']
                and not nudge_sent
                and current_hour in valid_hours):

            sent = _send_nudge(user_id, risk)
            if sent:
                nudge_sent_now = True
                threading.Thread(
                    target=_mark_nudge_sent,
                    args=(user_id,),
                    daemon=True
                ).start()

        return jsonify({
            'risk':       risk,
            'nudge_sent': nudge_sent_now,
            'timestamp':  datetime.now().isoformat()
        })

    except Exception as e:
        print(f"[Server] Classify error: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/feedback', methods=['POST'])
def save_feedback():
    try:
        data    = request.get_json()
        user_id = data.get('user_id')
        helped  = data.get('helped')
        risk    = data.get('risk_score', '--')

        if not user_id:
            return jsonify({'error': 'Missing user_id'}), 400

        today = datetime.now().strftime('%Y-%m-%d')
        db.collection('users') \
          .document(user_id) \
          .collection('feedback') \
          .document(today) \
          .set({
              'helped':          helped,
              'linkedRiskScore': risk,
              'timestamp':       firestore.SERVER_TIMESTAMP
          })

        return jsonify({'status': 'feedback saved'})

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ─── ML CLASSIFICATION ───────────────────────────────────────

def _classify_risk(session: dict) -> str:
    if model:
        try:
            features = [[
                session.get('total_screen_time', 0),
                session.get('unlock_count', 0),
                session.get('longest_session', 0),
                session.get('hour_of_first_use', 0),
                session.get('app_category', 0)
            ]]
            result = model.predict(features)[0]
            print(f"[Server] ML result: {result}")
            return result
        except Exception as e:
            print(f"[Server] ML failed: {e}")

    return _rule_classify(session)


def _rule_classify(session: dict) -> str:
    screen  = session.get('total_screen_time', 0)
    unlocks = session.get('unlock_count', 0)
    longest = session.get('longest_session', 0)
    hour    = session.get('hour_of_first_use', 0)

    after_midnight = hour >= 23 or hour < 4

    if screen > 40:
        return 'High'
    if unlocks > 10 and after_midnight:
        return 'High'
    if longest > 25 and after_midnight:
        return 'High'
    if screen > 20 or unlocks > 5 or longest > 15:
        return 'Medium'
    return 'Low'


# ─── FIRESTORE HELPERS ───────────────────────────────────────

def _save_risk_to_firestore(user_id: str,
                             risk: str,
                             session: dict):
    try:
        today = datetime.now().strftime('%Y-%m-%d')
        db.collection('users') \
          .document(user_id) \
          .collection('nightSessions') \
          .document(today) \
          .set({
              'riskScore':       risk,
              'totalScreenTime': session.get(
                                   'total_screen_time', 0),
              'unlockCount':     session.get(
                                   'unlock_count', 0),
              'longestSession':  session.get(
                                   'longest_session', 0),
              'nudgeSent':       False,
              'updatedAt':       firestore.SERVER_TIMESTAMP
          }, merge=True)
        print(f"[Server] Risk saved: {risk}")
    except Exception as e:
        print(f"[Server] Firestore save failed: {e}")


def _mark_nudge_sent(user_id: str):
    try:
        today = datetime.now().strftime('%Y-%m-%d')
        db.collection('users') \
          .document(user_id) \
          .collection('nightSessions') \
          .document(today) \
          .set({'nudgeSent': True}, merge=True)
        print("[Server] Nudge marked sent")
    except Exception as e:
        print(f"[Server] Mark nudge failed: {e}")


# ─── FCM NOTIFICATION ────────────────────────────────────────

def _send_nudge(user_id: str, risk: str) -> bool:
    messages = {
        'High':   "If your mind is racing, I'm here.",
        'Medium': "Whenever you're ready, I'm here."
    }
    text = messages.get(risk, "I'm here.")

    try:
        profile = db.collection('users') \
                    .document(user_id) \
                    .collection('profile') \
                    .document('data') \
                    .get().to_dict() or {}

        fcm_token = profile.get('fcmToken')
        if not fcm_token:
            print("[Server] No FCM token")
            return False

        message = messaging.Message(
            notification=messaging.Notification(
                title='Sleep Assistant',
                body=text
            ),
            android=messaging.AndroidConfig(
                priority='normal',
                notification=messaging.AndroidNotification(
                    sound=None,
                    default_vibrate_timings=False
                )
            ),
            token=fcm_token
        )

        messaging.send(message)
        print(f"[Server] Nudge sent: {text}")
        return True

    except Exception as e:
        print(f"[Server] Nudge failed: {e}")
        return False


# ─── START ───────────────────────────────────────────────────

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"[Server] Starting on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)