# core/queue_manager.py
# This file manages all local data storage on the device
# Think of it as the app's local memory

import json
import os
from datetime import datetime

# File paths for local storage
QUEUE_FILE  = 'data/queue.json'   # events waiting to sync to Firebase
CACHE_FILE  = 'data/cache.json'   # last known data from Firebase
PREFS_FILE  = 'data/user_prefs.json'  # user settings


class QueueManager:

    # ─── QUEUE (offline event storage) ───────────────────────

    def add_event(self, event: dict):
        """
        Save a tracking event locally.
        Called by background service every 30 mins.
        """
        queue = self._read_file(QUEUE_FILE, default=[])
        event['queued_at'] = datetime.now().isoformat()
        queue.append(event)
        self._write_file(QUEUE_FILE, queue)

    def get_all_events(self) -> list:
        """Return all events waiting to be synced."""
        return self._read_file(QUEUE_FILE, default=[])

    def clear_queue(self):
        """
        Empty the queue after successful Firebase sync.
        """
        self._write_file(QUEUE_FILE, [])

    # ─── CACHE (last known Firebase data) ────────────────────

    def save_cache(self, data: dict):
        """
        Save a copy of Firebase data locally.
        Used when Firebase is unreachable.
        """
        self._write_file(CACHE_FILE, data)

    def get_cache(self) -> dict:
        """Return last saved Firebase data."""
        return self._read_file(CACHE_FILE, default={})

    # ─── USER PREFERENCES ────────────────────────────────────

    def save_prefs(self, prefs: dict):
        """
        Save user settings locally.
        Example: sleep time, wake time, user_id
        """
        self._write_file(PREFS_FILE, prefs)

    def get_prefs(self) -> dict:
        """Return saved user preferences."""
        return self._read_file(PREFS_FILE, default={})

    def update_pref(self, key: str, value):
        """Update a single preference without overwriting others."""
        prefs = self.get_prefs()
        prefs[key] = value
        self.save_prefs(prefs)

    # ─── HELPERS ─────────────────────────────────────────────

    def _read_file(self, path: str, default):
        """
        Safely read a JSON file.
        Returns default value if file doesn't exist.
        """
        if not os.path.exists(path):
            return default
        try:
            with open(path, 'r') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return default

    def _write_file(self, path: str, data):
        """
        Safely write data to a JSON file.
        Creates the data/ folder if it doesn't exist.
        """
        os.makedirs('data', exist_ok=True)
        try:
            with open(path, 'w') as f:
                json.dump(data, f, indent=2)
        except IOError as e:
            print(f"[QueueManager] Failed to write {path}: {e}")