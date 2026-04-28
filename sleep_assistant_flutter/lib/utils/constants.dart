// lib/utils/constants.dart
// App-wide constants

class AppConstants {
  // Your Render server URL
  static const String serverUrl = 
      'https://sleep-assistant.onrender.com';

  // Colors
  static const int darkNavy      = 0xFF0A0E1A;
  static const int softNavy      = 0xFF1C2340;
  static const int lavendorText  = 0xFF7B8FBF;
  static const int lightText     = 0xFFD9DCEC;
  static const int accentBlue    = 0xFF3D5299;

  // Night hours
  static const int nightStart = 22;  // 10 PM
  static const int nightEnd   = 4;   // 4 AM
  // ── Wave controllers ─────────────────────────────────────
  

  // Nudge valid hours
  static const List<int> nudgeHours = [23, 0, 1, 2];
}