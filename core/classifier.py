# core/classifier.py
# Classifies sleep disruption risk from night session data
# Uses ML model if available, falls back to rules if not

import pickle
import os


class SleepClassifier:

    def __init__(self):
        self.model = None
        self._load_model()

    # ─── MODEL LOADING ───────────────────────────────────────

    def _load_model(self):
        """
        Load trained scikit-learn model from disk.
        If model file doesn't exist yet, that's fine —
        rule-based fallback will be used instead.
        """
        model_path = 'models/sleep_model.pkl'

        if os.path.exists(model_path):
            try:
                with open(model_path, 'rb') as f:
                    self.model = pickle.load(f)
                print("[Classifier] ML model loaded successfully")
            except Exception as e:
                print(f"[Classifier] Failed to load model: {e}")
                self.model = None
        else:
            print("[Classifier] No model file found — using rules")

    # ─── MAIN CLASSIFICATION ─────────────────────────────────

    def classify(self, session_data: dict) -> str:
        """
        Main entry point. Call this with night session data.

        Example input:
        {
            'total_screen_time': 47,   # minutes
            'unlock_count': 13,
            'longest_session': 22,     # minutes
            'hour_of_first_use': 23,   # 23 = 11 PM
            'app_category': 2          # 2 = Social Media
        }

        Returns: 'Low', 'Medium', or 'High'
        """
        if self.model is not None:
            return self._ml_classify(session_data)
        return self._rule_classify(session_data)

    # ─── ML CLASSIFICATION ───────────────────────────────────

    def _ml_classify(self, data: dict) -> str:
        """
        Use trained Logistic Regression model.
        Called only when model file exists.
        """
        try:
            features = [[
                data.get('total_screen_time', 0),
                data.get('unlock_count', 0),
                data.get('longest_session', 0),
                data.get('hour_of_first_use', 0),
                data.get('app_category', 0)
            ]]
            result = self.model.predict(features)[0]
            print(f"[Classifier] ML result: {result}")
            return result

        except Exception as e:
            print(f"[Classifier] ML failed: {e} — falling back to rules")
            return self._rule_classify(data)

    # ─── RULE BASED FALLBACK ─────────────────────────────────

    def _rule_classify(self, data: dict) -> str:
        """
        Simple rule-based classification.
        Used when ML model is not available.
        Also used as safety fallback if ML crashes.

        Rules:
          High   → screen time > 40 mins
                   OR (unlocks > 10 AND after 11 PM)
                   OR longest session > 25 mins after midnight

          Medium → screen time > 20 mins
                   OR unlocks > 5
                   OR longest session > 15 mins

          Low    → everything else
        """
        screen_time = data.get('total_screen_time', 0)
        unlocks     = data.get('unlock_count', 0)
        longest     = data.get('longest_session', 0)
        hour        = data.get('hour_of_first_use', 0)

        # High risk conditions
        after_11pm = hour >= 23 or hour < 4

        if screen_time > 40:
            print("[Classifier] Rule result: High (screen time)")
            return 'High'

        if unlocks > 10 and after_11pm:
            print("[Classifier] Rule result: High (unlocks + late hour)")
            return 'High'

        if longest > 25 and (hour == 0 or hour == 1 or hour == 2):
            print("[Classifier] Rule result: High (long session at midnight)")
            return 'High'

        # Medium risk conditions
        if screen_time > 20 or unlocks > 5 or longest > 15:
            print("[Classifier] Rule result: Medium")
            return 'Medium'

        # Low risk
        print("[Classifier] Rule result: Low")
        return 'Low'

    # ─── HELPER ──────────────────────────────────────────────

    def is_model_loaded(self) -> bool:
        """Returns True if ML model is available."""
        return self.model is not None