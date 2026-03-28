# firebase/auth.py
# Handles all user authentication with Firebase
# Uses pyrebase for auth operations

import pyrebase
from firebase_config import FIREBASE_CONFIG

# Initialize pyrebase once at module level
firebase = pyrebase.initialize_app(FIREBASE_CONFIG)
auth     = firebase.auth()


class FirebaseAuth:

    def __init__(self):
        self.current_user = None

    # ─── SIGN UP ─────────────────────────────────────────────

    def sign_up(self, email: str, password: str) -> dict:
        """
        Create a new user account.

        Returns:
          { 'success': True,  'user_id': '...' }
          { 'success': False, 'error': 'message' }
        """
        try:
            user = auth.create_user_with_email_and_password(
                email, password
            )
            self.current_user = user
            print(f"[Auth] Sign up successful: {email}")
            return {
                'success': True,
                'user_id': user['localId']
            }

        except Exception as e:
            error = self._parse_error(str(e))
            print(f"[Auth] Sign up failed: {error}")
            return {
                'success': False,
                'error': error
            }

    # ─── SIGN IN ─────────────────────────────────────────────

    def sign_in(self, email: str, password: str) -> dict:
        """
        Sign in existing user.

        Returns:
          { 'success': True,  'user_id': '...' }
          { 'success': False, 'error': 'message' }
        """
        try:
            user = auth.sign_in_with_email_and_password(
                email, password
            )
            self.current_user = user
            print(f"[Auth] Sign in successful: {email}")
            return {
                'success': True,
                'user_id': user['localId']
            }

        except Exception as e:
            error = self._parse_error(str(e))
            print(f"[Auth] Sign in failed: {error}")
            return {
                'success': False,
                'error': error
            }

    # ─── SIGN OUT ────────────────────────────────────────────

    def sign_out(self):
        """Clear current user session."""
        self.current_user = None
        print("[Auth] User signed out")

    # ─── GETTERS ─────────────────────────────────────────────

    def get_user_id(self) -> str:
        """
        Returns current user's unique ID.
        This ID is used everywhere in Firestore.
        Returns None if not logged in.
        """
        if self.current_user:
            return self.current_user['localId']
        return None

    def get_user_email(self) -> str:
        """Returns current user's email."""
        if self.current_user:
            return self.current_user['email']
        return None

    def is_logged_in(self) -> bool:
        """Returns True if a user is currently signed in."""
        return self.current_user is not None

    # ─── TOKEN REFRESH ───────────────────────────────────────

    def refresh_token(self) -> bool:
        """
        Refresh auth token if it expired.
        Firebase tokens expire every hour.
        Call this if you get permission errors.

        Returns True if refresh worked, False if failed.
        """
        if not self.current_user:
            return False
        try:
            self.current_user = auth.refresh(
                self.current_user['refreshToken']
            )
            print("[Auth] Token refreshed successfully")
            return True
        except Exception as e:
            print(f"[Auth] Token refresh failed: {e}")
            return False

    # ─── ERROR PARSER ────────────────────────────────────────

    def _parse_error(self, error_str: str) -> str:
        """
        Convert Firebase error codes into readable messages.
        Firebase returns ugly JSON error strings —
        this converts them to simple human readable text.
        """
        if 'EMAIL_EXISTS' in error_str:
            return 'This email is already registered'
        elif 'INVALID_EMAIL' in error_str:
            return 'Please enter a valid email address'
        elif 'WEAK_PASSWORD' in error_str:
            return 'Password must be at least 6 characters'
        elif 'EMAIL_NOT_FOUND' in error_str:
            return 'No account found with this email'
        elif 'INVALID_PASSWORD' in error_str:
            return 'Incorrect password'
        elif 'TOO_MANY_ATTEMPTS' in error_str:
            return 'Too many attempts. Try again later'
        elif 'NETWORK_REQUEST_FAILED' in error_str:
            return 'No internet connection'
        else:
            return 'Something went wrong. Try again'