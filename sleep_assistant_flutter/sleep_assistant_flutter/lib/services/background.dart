// lib/services/background.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'storage_service.dart';
import 'api_service.dart';
import 'screen_tracker_service.dart';
@pragma('vm:entry-point')
class BackgroundServiceManager {

  static const String _channelId  = 'sleep_assistant_channel';
  static const int    _notifId    = 888;

  // ── Initialize ───────────────────────────────────────────

  static Future<void> initialize() async {
    await _setupNotificationChannel();

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart:                         onStart,
        autoStart:                       true,
        isForegroundMode:                true,
        notificationChannelId:           _channelId,
        initialNotificationTitle:        'Sleep Assistant',
        initialNotificationContent:      'Watching over your night',
        foregroundServiceNotificationId: _notifId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart:    true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }

    print('[BG] Initialized');
  }

  // ── Notification Channel ─────────────────────────────────

  static Future<void> _setupNotificationChannel() async {
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await plugin.initialize(initSettings);

    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      'sleep_assistant_channel',
      'Sleep Assistant',
      description:     'Sleep tracking notifications',
      importance:      Importance.low,
      playSound:       false,
      enableVibration: false,
    );

    final androidPlugin = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }

    print('[BG] Notification channel created');
  }

  // ── iOS Background ───────────────────────────────────────

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(
    ServiceInstance service,
  ) async {
    return true;
  }

  // ── Service Entry Point ──────────────────────────────────

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    print('[BG] Service started');

    await _runNightCheck();

    Timer.periodic(
      const Duration(minutes: 30),
      (_) async => await _runNightCheck(),
    );
  }

  // ── Night Check ──────────────────────────────────────────

  static Future<void> _runNightCheck() async {
    final hour    = DateTime.now().hour;
    final isNight = hour >= 22 || hour < 4;

    if (!isNight) {
      print('[BG] Daytime — skipping');
      return;
    }

    print('[BG] Night check at $hour:00');

    try {
      final stats = await ScreenTrackerService.getTonightStats();

      final userId = await StorageService.getUserId();
      if (userId == null) return;

      final cache = await StorageService.getCache();
      cache['totalScreenTime'] = stats['total_screen_time'];
      cache['unlockCount']     = stats['unlock_count'];
      cache['longestSession']  = stats['longest_session'];
      await StorageService.saveCache(cache);

      final result = await ApiService.classifySession(
        userId:           userId,
        session:          stats,
        nudgeSentTonight: cache['nudgeSent'] == true,
        currentHour:      hour,
      );

      cache['riskScore'] = result['risk'];
      if (result['nudge_sent'] == true) {
        cache['nudgeSent'] = true;
      }
      await StorageService.saveCache(cache);

      print('[BG] Done. Risk: ${result['risk']}');

    } catch (e) {
      print('[BG] Error: $e');
    }
  }
}