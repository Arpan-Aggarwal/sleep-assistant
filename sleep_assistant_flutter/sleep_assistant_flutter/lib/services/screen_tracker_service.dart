// lib/services/screen_tracker_service.dart
import 'dart:math';
import 'package:app_usage/app_usage.dart';

class ScreenTrackerService {

  // ── Permission ───────────────────────────────────────────

  static Future<bool> hasPermission() async {
    try {
      final now   = DateTime.now();
      final start = now.subtract(const Duration(hours: 1));
      await AppUsage().getAppUsage(start, now);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      final now   = DateTime.now();
      final start = now.subtract(const Duration(hours: 1));
      await AppUsage().getAppUsage(start, now);
    } catch (e) {
      print('[Tracker] Permission needed — opening settings');
    }
  }

  // ── Get Tonight Stats ────────────────────────────────────

  static Future<Map<String, dynamic>> getTonightStats() async {
    try {
      final now        = DateTime.now();
      final nightStart = DateTime(
        now.hour < 10 ? now.year      : now.year,
        now.hour < 10 ? now.month     : now.month,
        now.hour < 10 ? now.day - 1   : now.day,
        22, 0, 0,
      );

      final List<AppUsageInfo> usageList =
          await AppUsage().getAppUsage(nightStart, now);

      if (usageList.isEmpty) {
        print('[Tracker] No data — simulation');
        return _simulateStats();
      }

      int    totalScreenTime = 0;
      int    longestSession  = 0;
      String dominantApp     = 'unknown';
      int    maxTime         = 0;

      for (final info in usageList) {
        final minutes = info.usage.inMinutes;
        if (minutes <= 0) continue;

        totalScreenTime += minutes;

        if (minutes > maxTime) {
          maxTime     = minutes;
          dominantApp = info.packageName;
        }

        if (minutes > longestSession) {
          longestSession = minutes;
        }
      }

      // Estimate unlocks from number of apps used
      final unlockCount = (usageList.length * 1.5).toInt();

      final result = {
        'total_screen_time': totalScreenTime,
        'unlock_count':      unlockCount,
        'longest_session':   longestSession,
        'hour_of_first_use': nightStart.hour,
        'app_category':      _categorizeApp(dominantApp),
        'dominant_app':      dominantApp,
      };

      print('[Tracker] Real stats: $result');
      return result;

    } catch (e) {
      print('[Tracker] Error: $e — simulation');
      return _simulateStats();
    }
  }

  // ── App Category ─────────────────────────────────────────

  static int _categorizeApp(String packageName) {
    final pkg = packageName.toLowerCase();

    const social        = ['instagram', 'facebook', 'twitter',
                           'tiktok', 'snapchat', 'reddit'];
    const wellness      = ['calm', 'headspace', 'insight'];
    const entertainment = ['youtube', 'netflix', 'spotify',
                           'prime', 'hotstar'];
    const communication = ['whatsapp', 'telegram', 'messenger',
                           'gmail', 'outlook'];

    if (social.any((s)        => pkg.contains(s))) return 2;
    if (wellness.any((w)      => pkg.contains(w))) return 1;
    if (entertainment.any((e) => pkg.contains(e))) return 3;
    if (communication.any((c) => pkg.contains(c))) return 4;
    return 0;
  }

  // ── Simulation Fallback ──────────────────────────────────

  static Map<String, dynamic> _simulateStats() {
    final random = Random();
    final hour   = DateTime.now().hour;

    int screenTime;
    int unlocks;

    if (hour >= 23 || hour == 0) {
      screenTime = random.nextInt(45) + 20;
      unlocks    = random.nextInt(13) + 5;
    } else if (hour == 1 || hour == 2) {
      screenTime = random.nextInt(35) + 10;
      unlocks    = random.nextInt(10) + 3;
    } else {
      screenTime = random.nextInt(25) + 5;
      unlocks    = random.nextInt(7)  + 1;
    }

    return {
      'total_screen_time': screenTime,
      'unlock_count':      unlocks,
      'longest_session':   min(screenTime, random.nextInt(25) + 5),
      'hour_of_first_use': hour,
      'app_category':      random.nextInt(5),
      'dominant_app':      'simulated',
    };
  }
}