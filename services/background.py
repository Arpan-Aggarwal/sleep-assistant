# services/background.py
# Background tracking service
# On Android: runs as foreground service via Python-for-Android
# On Desktop: runs as simulation thread for testing

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import time
import threading
from datetime import datetime


# ─── SERVICE ENTRY POINT ─────────────────────────────────────

def start_service():
    """
    Entry point called by Android or desktop simulation.
    Starts the monitoring loop in a background thread.
    """
    print("[Service] Background service starting...")
    thread = threading.Thread(target=_monitoring_loop, daemon=True)
    thread.start()
    return thread


# ─── MAIN MONITORING LOOP ────────────────────────────────────

def _monitoring_loop():
    """
    Runs forever.
    Checks every 30 minutes during night hours.
    Does nothing during daytime.
    """
    from core.nudge_engine  import NudgeEngine
    from core.classifier    import SleepClassifier
    from core.queue_manager import QueueManager

    engine     = NudgeEngine()
    classifier = SleepClassifier()
    queue      = QueueManager()

    # Track nudge state per night
    nudge_sent_tonight = False
    last_date          = datetime.now().date()

    print("[Service] Monitoring loop started")

    while True:
        try:
            current_date = datetime.now().date()
            current_hour = datetime.now().hour

            # Reset nudge flag at start of new day
            if current_date != last_date:
                nudge_sent_tonight = False
                last_date          = current_date
                print("[Service] New day — nudge flag reset")

            # Only run during night hours
            if engine.is_night_time():
                print(f"[Service] Night check at {datetime.now().strftime('%H:%M')}")

                # Step 1 — Get usage data
                session_data = _get_usage_data()

                # Step 2 — Classify risk
                risk = classifier.classify(session_data)
                session_data['risk_local']  = risk
                session_data['timestamp']   = datetime.now().isoformat()

                print(f"[Service] Risk: {risk} | "
                      f"Screen: {session_data.get('total_screen_time')}m | "
                      f"Unlocks: {session_data.get('unlock_count')}")

                # Step 3 — Save to local queue
                queue.add_event(session_data)

                # Step 4 — Try Firebase sync
                _try_firebase_sync(session_data, risk, queue)

                # Step 5 — Decide nudge
                should_nudge = engine.should_send_nudge(
                    risk, nudge_sent_tonight, current_hour
                )

                # Step 6 — Send nudge if needed
                if should_nudge:
                    message = engine.get_nudge_message(risk)
                    _send_notification(message)
                    nudge_sent_tonight = True
                    _mark_nudge_in_firebase(queue)
                    print(f"[Service] Nudge sent: {message}")

            else:
                print(f"[Service] Daytime ({current_hour}:00) — sleeping")

        except Exception as e:
            print(f"[Service] Error in loop: {e}")

        # Wait 30 minutes before next check
        # On desktop reduced to 60 seconds for testing
        wait_time = 60 if _is_desktop() else 1800
        print(f"[Service] Next check in {wait_time} seconds")
        time.sleep(wait_time)


# ─── GET USAGE DATA ──────────────────────────────────────────

def _get_usage_data() -> dict:
    """
    Get screen usage data.
    Uses Pyjnius on Android.
    Uses simulation on desktop.
    """
    if _is_desktop():
        return _simulate_usage()
    else:
        return _get_android_usage()


def _get_android_usage() -> dict:
    """
    Real Android screen usage via Pyjnius.
    Calls Android's UsageStatsManager Java class.
    """
    try:
        from jnius import autoclass

        # Android Java classes
        UsageStatsManager = autoclass(
            'android.app.usage.UsageStatsManager'
        )
        Context = autoclass(
            'android.content.Context'
        )
        PythonActivity = autoclass(
            'org.kivy.android.PythonActivity'
        )

        context       = PythonActivity.mActivity
        usage_manager = context.getSystemService(
            Context.USAGE_STATS_SERVICE
        )

        # Get stats for last 6 hours
        end_time   = int(datetime.now().timestamp() * 1000)
        start_time = end_time - (6 * 60 * 60 * 1000)

        stats = usage_manager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            start_time,
            end_time
        )

        total_time   = 0
        dominant_app = 'unknown'
        max_time     = 0
        unlock_count = _get_unlock_count()

        if stats:
            for stat in stats:
                app_time = stat.getTotalTimeInForeground()
                total_time += app_time
                if app_time > max_time:
                    max_time     = app_time
                    dominant_app = stat.getPackageName()

        return {
            'total_screen_time': total_time // 60000,
            'unlock_count':      unlock_count,
            'longest_session':   max_time // 60000,
            'hour_of_first_use': datetime.now().hour,
            'app_category':      _categorize_app(dominant_app),
            'dominant_app':      dominant_app
        }

    except Exception as e:
        print(f"[Service] Android usage fetch failed: {e}")
        return _simulate_usage()


def _get_unlock_count() -> int:
    """Get phone unlock count via Android PowerManager"""
    try:
        from jnius import autoclass
        PowerManager  = autoclass('android.os.PowerManager')
        PythonActivity = autoclass(
            'org.kivy.android.PythonActivity'
        )
        context = PythonActivity.mActivity
        pm      = context.getSystemService('power')
        return 1 if pm.isInteractive() else 0
    except Exception:
        return 0


def _categorize_app(package_name: str) -> int:
    """
    Map Android package name to category number.
    0 = Productivity
    1 = Wellness/Meditation
    2 = Social Media
    3 = Entertainment
    4 = Communication
    """
    pkg = package_name.lower()

    social      = ['instagram', 'facebook', 'twitter',
                   'tiktok', 'snapchat', 'reddit']
    wellness    = ['calm', 'headspace', 'insight', 'sleep']
    entertainment = ['youtube', 'netflix', 'spotify',
                     'prime', 'hotstar']
    communication = ['whatsapp', 'telegram', 'messenger',
                     'gmail', 'outlook']

    if any(s in pkg for s in social):
        return 2
    elif any(w in pkg for w in wellness):
        return 1
    elif any(e in pkg for e in entertainment):
        return 3
    elif any(c in pkg for c in communication):
        return 4
    return 0


def _simulate_usage() -> dict:
    """
    Desktop simulation of screen usage.
    Generates realistic random data for testing.
    """
    import random
    hour = datetime.now().hour

    # More realistic data based on time of night
    if hour >= 23 or hour == 0:
        # Peak bad usage time
        screen_time = random.randint(20, 65)
        unlocks     = random.randint(5, 18)
    elif hour == 1 or hour == 2:
        # Late night — could go either way
        screen_time = random.randint(5, 40)
        unlocks     = random.randint(2, 12)
    else:
        # Earlier evening — usually lighter
        screen_time = random.randint(5, 30)
        unlocks     = random.randint(1, 8)

    longest = min(screen_time, random.randint(5, 30))

    return {
        'total_screen_time': screen_time,
        'unlock_count':      unlocks,
        'longest_session':   longest,
        'hour_of_first_use': hour,
        'app_category':      random.randint(0, 4),
        'dominant_app':      'simulated'
    }


# ─── FIREBASE SYNC ───────────────────────────────────────────

def _try_firebase_sync(session_data: dict,
                        risk: str,
                        queue):
    """
    Try to push event and risk score to Firebase.
    If it fails data stays in local queue.
    Runs on separate thread so it doesn't block loop.
    """
    def _sync():
        try:
            prefs   = queue.get_prefs()
            user_id = prefs.get('user_id')

            if not user_id:
                print("[Service] No user_id — skipping Firebase sync")
                return

            # Check internet first
            if not _has_internet():
                print("[Service] No internet — event stays in queue")
                return

            from firebase.firestore import FirestoreManager
            fs = FirestoreManager(user_id, queue)

            # Push event
            fs.push_night_event(session_data)

            # Save risk score
            fs.save_risk_score(risk, session_data)

            # Flush any previously queued events
            fs.flush_queue()

            print("[Service] Firebase sync complete")

        except Exception as e:
            print(f"[Service] Firebase sync failed: {e}")

    threading.Thread(target=_sync, daemon=True).start()


def _mark_nudge_in_firebase(queue):
    """Mark nudge as sent in Firestore"""
    def _mark():
        try:
            prefs   = queue.get_prefs()
            user_id = prefs.get('user_id')

            if not user_id or not _has_internet():
                return

            from firebase.firestore import FirestoreManager
            fs = FirestoreManager(user_id, queue)
            fs.mark_nudge_sent()

        except Exception as e:
            print(f"[Service] Mark nudge failed: {e}")

    threading.Thread(target=_mark, daemon=True).start()


# ─── NOTIFICATION ────────────────────────────────────────────

def _send_notification(message: str):
    """
    Send silent notification.
    Uses Android notification system on device.
    Prints to console on desktop.
    """
    if _is_desktop():
        print(f"[Service] NUDGE (desktop): {message}")
        return

    try:
        from jnius import autoclass

        PythonActivity      = autoclass(
            'org.kivy.android.PythonActivity'
        )
        NotificationBuilder = autoclass(
            'android.app.Notification$Builder'
        )
        NotificationManager = autoclass(
            'android.app.NotificationManager'
        )
        NotificationChannel = autoclass(
            'android.app.NotificationChannel'
        )

        context    = PythonActivity.mActivity
        channel_id = 'sleep_assistant_channel'

        # Create notification channel (required Android 8+)
        channel = NotificationChannel(
            channel_id,
            'Sleep Assistant',
            NotificationManager.IMPORTANCE_LOW  # silent
        )
        channel.setSound(None, None)
        channel.enableVibration(False)

        nm = context.getSystemService('notification')
        nm.createNotificationChannel(channel)

        # Build notification
        builder = NotificationBuilder(context, channel_id)
        builder.setContentTitle('Sleep Assistant')
        builder.setContentText(message)
        builder.setSmallIcon(
            context.getApplicationInfo().icon
        )
        builder.setSilent(True)
        builder.setPriority(
            NotificationBuilder.PRIORITY_LOW
        )

        nm.notify(1, builder.build())
        print(f"[Service] Notification sent: {message}")

    except Exception as e:
        print(f"[Service] Notification failed: {e}")


# ─── HELPERS ─────────────────────────────────────────────────

def _is_desktop() -> bool:
    """Returns True if running on PC not Android"""
    try:
        import android
        return False
    except ImportError:
        return True


def _has_internet() -> bool:
    """Quick internet connectivity check"""
    try:
        import urllib.request
        urllib.request.urlopen(
            'https://www.google.com', timeout=3
        )
        return True
    except Exception:
        return False


# ─── DIRECT RUN (Android service entry point) ────────────────

if __name__ == '__main__':
    """
    Python-for-Android calls this file directly
    as a service. This keeps it running.
    """
    print("[Service] Started as Android service")
    start_service()

    # Keep main thread alive on Android
    while True:
        time.sleep(60)