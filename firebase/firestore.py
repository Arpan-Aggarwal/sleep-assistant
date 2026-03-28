# firebase/firestore.py
# Handles all Firestore database operations
# Every Firebase call runs on a separate thread
# so the UI never freezes

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import threading
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, firestore
from firebase_config import FIREBASE_CONFIG

# ─── Initialize Firebase Admin once ──────────────────────────
# Check if already initialized to avoid duplicate app error
if not firebase_admin._apps:
    cred = credentials.Certificate('serviceAccountKey.json')
    firebase_admin.initialize_app(cred)

db = firestore.client()


class FirestoreManager:

    def __init__(self, user_id: str, queue_manager):
        self.user_id     = user_id
        self.queue       = queue_manager

    # ─── USER PROFILE ────────────────────────────────────────

    def save_profile(self, profile_data: dict, on_done=None):
        """
        Save user profile to Firestore.
        Also saves locally in case of offline use.

        profile_data example:
        {
            'sleepGoalTime': '11:00 PM',
            'wakeTime': '6:30 AM',
            'mode': 'silent'
        }
        """
        def _save():
            try:
                db.collection('users') \
                  .document(self.user_id) \
                  .collection('profile') \
                  .document('data') \
                  .set(profile_data)

                # Save locally too for offline access
                self.queue.save_prefs(profile_data)
                print("[Firestore] Profile saved successfully")

                if on_done:
                    on_done(True)

            except Exception as e:
                print(f"[Firestore] Profile save failed: {e}")
                # Still save locally even if Firebase fails
                self.queue.save_prefs(profile_data)
                if on_done:
                    on_done(False)

        thread = threading.Thread(target=_save)
        thread.daemon = True
        thread.start()

    # ─── NIGHT EVENTS ────────────────────────────────────────

    def push_night_event(self, event: dict, on_done=None):
        """
        Push a single tracking event to Firestore.
        If Firebase unavailable, saves to local queue.

        event example:
        {
            'total_screen_time': 47,
            'unlock_count': 13,
            'longest_session': 22,
            'hour_of_first_use': 23,
            'app_category': 2,
            'risk_local': 'High',
            'timestamp': '2024-01-15T23:30:00'
        }
        """
        def _push():
            try:
                today = datetime.now().strftime('%Y-%m-%d')
                db.collection('users') \
                  .document(self.user_id) \
                  .collection('nightSessions') \
                  .document(today) \
                  .collection('events') \
                  .add(event)

                print("[Firestore] Night event pushed successfully")
                if on_done:
                    on_done(True)

            except Exception as e:
                print(f"[Firestore] Push failed — saving to queue: {e}")
                self.queue.add_event(event)
                if on_done:
                    on_done(False)

        thread = threading.Thread(target=_push)
        thread.daemon = True
        thread.start()

    # ─── FLUSH OFFLINE QUEUE ─────────────────────────────────

    def flush_queue(self, on_done=None):
        """
        Send all locally queued events to Firestore.
        Call this when internet becomes available.
        """
        def _flush():
            events = self.queue.get_all_events()

            if not events:
                print("[Firestore] Queue is empty — nothing to flush")
                if on_done:
                    on_done(True)
                return

            try:
                today = datetime.now().strftime('%Y-%m-%d')
                batch = db.batch()

                collection_ref = db.collection('users') \
                                   .document(self.user_id) \
                                   .collection('nightSessions') \
                                   .document(today) \
                                   .collection('events')

                for event in events:
                    new_doc = collection_ref.document()
                    batch.set(new_doc, event)

                batch.commit()
                self.queue.clear_queue()
                print(f"[Firestore] Flushed {len(events)} queued events")

                if on_done:
                    on_done(True)

            except Exception as e:
                print(f"[Firestore] Flush failed: {e}")
                if on_done:
                    on_done(False)

        thread = threading.Thread(target=_flush)
        thread.daemon = True
        thread.start()

    # ─── GET LAST SESSION ────────────────────────────────────

    def get_last_session(self, callback):
        """
        Fetch last night's session summary from Firestore.
        Falls back to local cache if Firebase unavailable.

        callback(data) is called when data is ready.
        This is async — data arrives via callback not return value.

        Usage:
            def on_data(data):
                print(data)
            firestore_manager.get_last_session(on_data)
        """
        def _fetch():
            try:
                today = datetime.now().strftime('%Y-%m-%d')
                doc = db.collection('users') \
                        .document(self.user_id) \
                        .collection('nightSessions') \
                        .document(today) \
                        .get()

                if doc.exists:
                    data = doc.to_dict()
                    # Update local cache with fresh data
                    self.queue.save_cache(data)
                    print("[Firestore] Session data fetched successfully")
                    callback(data)
                else:
                    print("[Firestore] No session found — using cache")
                    callback(self.queue.get_cache())

            except Exception as e:
                print(f"[Firestore] Fetch failed — using cache: {e}")
                callback(self.queue.get_cache())

        thread = threading.Thread(target=_fetch)
        thread.daemon = True
        thread.start()

    # ─── SAVE RISK SCORE ─────────────────────────────────────

    def save_risk_score(self, risk_score: str,
                        session_summary: dict,
                        on_done=None):
        """
        Save tonight's calculated risk score to Firestore.
        Called after ML classification.
        """
        def _save():
            try:
                today = datetime.now().strftime('%Y-%m-%d')
                data  = {
                    'riskScore':       risk_score,
                    'totalScreenTime': session_summary.get(
                                         'total_screen_time', 0),
                    'unlockCount':     session_summary.get(
                                         'unlock_count', 0),
                    'longestSession':  session_summary.get(
                                         'longest_session', 0),
                    'nudgeSent':       False,
                    'updatedAt':       firestore.SERVER_TIMESTAMP
                }

                db.collection('users') \
                  .document(self.user_id) \
                  .collection('nightSessions') \
                  .document(today) \
                  .set(data, merge=True)

                print(f"[Firestore] Risk score saved: {risk_score}")
                if on_done:
                    on_done(True)

            except Exception as e:
                print(f"[Firestore] Risk save failed: {e}")
                if on_done:
                    on_done(False)

        thread = threading.Thread(target=_save)
        thread.daemon = True
        thread.start()

    # ─── MARK NUDGE SENT ─────────────────────────────────────

    def mark_nudge_sent(self, on_done=None):
        """
        Mark that nudge was sent tonight.
        Prevents sending more than one nudge per night.
        """
        def _mark():
            try:
                today = datetime.now().strftime('%Y-%m-%d')
                db.collection('users') \
                  .document(self.user_id) \
                  .collection('nightSessions') \
                  .document(today) \
                  .set({'nudgeSent': True}, merge=True)

                print("[Firestore] Nudge marked as sent")
                if on_done:
                    on_done(True)

            except Exception as e:
                print(f"[Firestore] Mark nudge failed: {e}")
                if on_done:
                    on_done(False)

        thread = threading.Thread(target=_mark)
        thread.daemon = True
        thread.start()

    # ─── SAVE FEEDBACK ───────────────────────────────────────

    def save_feedback(self, helped: bool,
                      risk_score: str,
                      on_done=None):
        """
        Save user's morning feedback.
        Used to improve nudge sensitivity over time.
        """
        def _save():
            try:
                today = datetime.now().strftime('%Y-%m-%d')
                db.collection('users') \
                  .document(self.user_id) \
                  .collection('feedback') \
                  .document(today) \
                  .set({
                      'helped':          helped,
                      'linkedRiskScore': risk_score,
                      'timestamp':       firestore.SERVER_TIMESTAMP
                  })

                print(f"[Firestore] Feedback saved: helped={helped}")
                if on_done:
                    on_done(True)

            except Exception as e:
                print(f"[Firestore] Feedback save failed: {e}")
                if on_done:
                    on_done(False)

        thread = threading.Thread(target=_save)
        thread.daemon = True
        thread.start()

    # ─── GET WEEKLY SUMMARY ──────────────────────────────────

    def get_weekly_summary(self, callback):
        """
        Fetch last 7 days of session data for insights screen.
        callback(list_of_sessions) called when ready.
        """
        def _fetch():
            try:
                sessions_ref = db.collection('users') \
                                 .document(self.user_id) \
                                 .collection('nightSessions') \
                                 .order_by('updatedAt',
                                           direction=firestore.Query.DESCENDING) \
                                 .limit(7)

                docs     = sessions_ref.stream()
                sessions = [doc.to_dict() for doc in docs]

                print(f"[Firestore] Got {len(sessions)} sessions")
                callback(sessions)

            except Exception as e:
                print(f"[Firestore] Weekly fetch failed: {e}")
                callback([])

        thread = threading.Thread(target=_fetch)
        thread.daemon = True
        thread.start()