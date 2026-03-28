# core/nudge_engine.py
# Decides if and when to send the silent nudge notification
# This is the most important logic file in the entire app

from datetime import datetime


class NudgeEngine:

    # ─── MAIN DECISION ───────────────────────────────────────

    def should_send_nudge(self,
                          risk_score: str,
                          nudge_already_sent: bool,
                          current_hour: int) -> bool:
        """
        Returns True only if ALL conditions are met.
        If even one condition fails, no nudge is sent.

        Conditions:
          1. Risk must be Medium or High
          2. No nudge sent yet tonight
          3. Time must be between 11 PM and 2 AM
        """

        # Condition 1 — Risk level check
        if risk_score not in ['Medium', 'High']:
            print(f"[NudgeEngine] No nudge — risk is {risk_score}")
            return False

        # Condition 2 — Only one nudge per night
        if nudge_already_sent:
            print("[NudgeEngine] No nudge — already sent tonight")
            return False

        # Condition 3 — Only during these hours
        # 23 = 11 PM, 0 = midnight, 1 = 1 AM, 2 = 2 AM
        valid_hours = [23, 0, 1, 2]
        if current_hour not in valid_hours:
            print(f"[NudgeEngine] No nudge — hour {current_hour} is outside window")
            return False

        print(f"[NudgeEngine] Nudge approved — risk={risk_score}, hour={current_hour}")
        return True

    # ─── NUDGE MESSAGE ───────────────────────────────────────

    def get_nudge_message(self, risk_score: str) -> str:
        """
        Returns the notification message text.

        Rules we follow:
          - No question marks (creates pressure)
          - No urgency words
          - No commands
          - Feels like a gentle presence, not an alert
        """
        messages = {
            'High':   "If your mind is racing, I'm here.",
            'Medium': "Whenever you're ready, I'm here.",
        }
        return messages.get(risk_score, "I'm here if you need me.")

    # ─── TIME HELPERS ────────────────────────────────────────

    def is_night_time(self) -> bool:
        """
        Returns True if current time is in tracking window.
        Tracking window: 10 PM (22) to 4 AM (4)
        """
        hour = datetime.now().hour
        return hour >= 22 or hour < 4

    def get_current_hour(self) -> int:
        """Returns current hour as integer (0-23)"""
        return datetime.now().hour