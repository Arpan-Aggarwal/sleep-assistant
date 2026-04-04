// lib/services/storage_service.dart
// Local storage using SharedPreferences

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {

  // ── User preferences ─────────────────────────────────────
  static Future<void> savePrefs(Map<String, dynamic> prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('user_prefs', jsonEncode(prefs));
  }

  static Future<Map<String, dynamic>> getPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final data = sp.getString('user_prefs');
    if (data == null) return {};
    return jsonDecode(data);
  }

  static Future<void> updatePref(String key, dynamic value) async {
    final prefs = await getPrefs();
    prefs[key] = value;
    await savePrefs(prefs);
  }

  // ── Cache ────────────────────────────────────────────────
  static Future<void> saveCache(Map<String, dynamic> data) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('cache', jsonEncode(data));
  }

  static Future<Map<String, dynamic>> getCache() async {
    final sp = await SharedPreferences.getInstance();
    final data = sp.getString('cache');
    if (data == null) return {};
    return jsonDecode(data);
  }

  // ── Queue ────────────────────────────────────────────────
  static Future<void> addToQueue(Map<String, dynamic> event) async {
    final sp    = await SharedPreferences.getInstance();
    final data  = sp.getString('queue');
    final queue = data != null
        ? List<Map<String, dynamic>>.from(jsonDecode(data))
        : <Map<String, dynamic>>[];
    queue.add(event);
    await sp.setString('queue', jsonEncode(queue));
  }

  static Future<List<Map<String, dynamic>>> getQueue() async {
    final sp   = await SharedPreferences.getInstance();
    final data = sp.getString('queue');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  static Future<void> clearQueue() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('queue');
  }

  // ── Helpers ──────────────────────────────────────────────
  static Future<bool> isSetupComplete() async {
    final prefs = await getPrefs();
    return prefs['setup_complete'] == true;
  }

  static Future<String?> getUserId() async {
    final prefs = await getPrefs();
    return prefs['user_id'];
  }
}