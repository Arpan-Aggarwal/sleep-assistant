# main.py
# Entry point of Sleep Assistant
# This is the file that launches the entire app

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from kivy.app import App
from kivy.uix.screenmanager import ScreenManager, FadeTransition
from kivy.clock import Clock
from datetime import datetime


class SleepAssistantApp(App):

    def build(self):
        """
        Called once when app starts.
        Sets up screen manager and adds all screens.
        """
        # App window title (desktop only)
        self.title = 'Sleep Assistant'

        # Screen manager with smooth fade transition
        self.sm = ScreenManager(
            transition=FadeTransition(duration=0.4)
        )

        # Import and add all screens
        from screens.onboarding import OnboardingScreen
        from screens.home_night  import HomeNightScreen
        from screens.home_day    import HomeDayScreen
        from screens.support     import SupportScreen

        self.sm.add_widget(OnboardingScreen(name='onboarding'))
        self.sm.add_widget(HomeNightScreen(name='home_night'))
        self.sm.add_widget(HomeDayScreen(name='home_day'))
        self.sm.add_widget(SupportScreen(name='support'))

        # Decide starting screen
        self.sm.current = self._get_start_screen()

        return self.sm

    # ─── START SCREEN LOGIC ──────────────────────────────────

    def _get_start_screen(self) -> str:
        """
        Decides which screen to show on launch.

        Logic:
          1. Has user completed setup? → No  → onboarding
          2. Is it night time?         → Yes → home_night
          3. Default                         → home_day
        """
        from core.queue_manager import QueueManager
        prefs = QueueManager().get_prefs()

        # First time user — show onboarding
        if not prefs.get('setup_complete'):
            print("[App] First launch — showing onboarding")
            return 'onboarding'

        # Night time — show night screen
        hour = datetime.now().hour
        if hour >= 22 or hour < 4:
            print("[App] Night time — showing night screen")
            return 'home_night'

        # Daytime — show morning dashboard
        print("[App] Day time — showing dashboard")
        return 'home_day'

    # ─── APP LIFECYCLE ───────────────────────────────────────

    def on_start(self):
        """
        Called after build() completes.
        Good place to start background tasks.
        """
        print("[App] App started")
        self._try_sync_queue()
        self._start_background_service()

    def on_pause(self):
        """
        Called when app goes to background on Android.
        Must return True to allow pausing.
        """
        print("[App] App paused")
        return True

    def on_resume(self):
        """
        Called when app comes back from background.
        Refresh current screen data.
        """
        print("[App] App resumed")
        self._refresh_current_screen()

    def on_stop(self):
        """Called when app is fully closed."""
        print("[App] App stopped")

    # ─── SYNC QUEUE ──────────────────────────────────────────

    def _try_sync_queue(self):
        """
        Try to flush any offline queued events
        to Firebase when app opens.
        """
        import threading
        from core.queue_manager import QueueManager

        def _sync():
            queue   = QueueManager()
            prefs   = queue.get_prefs()
            user_id = prefs.get('user_id')

            if not user_id:
                return

            events = queue.get_all_events()
            if not events:
                print("[App] Queue empty — nothing to sync")
                return

            try:
                from firebase.firestore import FirestoreManager
                fs = FirestoreManager(user_id, queue)
                fs.flush_queue()
                print(f"[App] Flushed {len(events)} queued events")
            except Exception as e:
                print(f"[App] Sync failed: {e}")

        threading.Thread(target=_sync, daemon=True).start()

    # ─── BACKGROUND SERVICE ──────────────────────────────────

    def _start_background_service(self):
        """
        Start Android background service.
        Only runs on Android — skipped on desktop.
        """
        try:
            from android import AndroidService
            service = AndroidService(
                'Sleep Assistant',
                'Watching over your night'
            )
            service.start('service_started')
            print("[App] Background service started")
        except ImportError:
            # Running on desktop — simulate service
            print("[App] Desktop mode — background service skipped")
            self._start_desktop_simulation()

    def _start_desktop_simulation(self):
        """
        On desktop, simulate what background service does.
        Runs a check every 30 seconds for testing.
        """
        Clock.schedule_interval(
            self._desktop_check, 30
        )

    def _desktop_check(self, dt):
        """
        Desktop simulation of background service check.
        On Android this runs in background.py instead.
        """
        from core.nudge_engine  import NudgeEngine
        from core.classifier    import SleepClassifier
        from core.queue_manager import QueueManager

        engine = NudgeEngine()

        if not engine.is_night_time():
            return

        # Simulate screen usage data
        import random
        session = {
            'total_screen_time': random.randint(5, 60),
            'unlock_count':      random.randint(1, 15),
            'longest_session':   random.randint(2, 30),
            'hour_of_first_use': datetime.now().hour,
            'app_category':      random.randint(0, 4)
        }

        clf   = SleepClassifier()
        risk  = clf.classify(session)
        queue = QueueManager()

        session['risk_local'] = risk
        queue.add_event(session)

        print(f"[Desktop Sim] Risk: {risk} | "
              f"Screen time: {session['total_screen_time']} mins")

        # Try to push to Firebase
        prefs   = queue.get_prefs()
        user_id = prefs.get('user_id')

        if user_id:
            from firebase.firestore import FirestoreManager
            fs = FirestoreManager(user_id, queue)
            fs.push_night_event(session)
            fs.save_risk_score(risk, session)

    # ─── REFRESH SCREEN ──────────────────────────────────────

    def _refresh_current_screen(self):
        """
        Refresh data on current screen when app resumes.
        Calls on_enter() to reload fresh data.
        """
        current = self.sm.current_screen
        if hasattr(current, 'on_enter'):
            current.on_enter()


# ─── LAUNCH ──────────────────────────────────────────────────

if __name__ == '__main__':
    SleepAssistantApp().run()