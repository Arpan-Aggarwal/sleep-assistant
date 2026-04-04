// lib/services/api_service.dart
// Calls your Render Flask server

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {

  // ── Classify sleep risk ──────────────────────────────────
  static Future<Map<String, dynamic>> classifySession({
    required String userId,
    required Map<String, dynamic> session,
    required bool nudgeSentTonight,
    required int currentHour,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.serverUrl}/classify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':            userId,
          'session':            session,
          'nudge_sent_tonight': nudgeSentTonight,
          'current_hour':       currentHour,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'risk': 'Medium', 'nudge_sent': false};

    } catch (e) {
      print('[API] Classify error: $e');
      return {'risk': 'Medium', 'nudge_sent': false};
    }
  }

  // ── Save feedback ────────────────────────────────────────
  static Future<bool> saveFeedback({
    required String userId,
    required bool helped,
    required String riskScore,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.serverUrl}/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id':    userId,
          'helped':     helped,
          'risk_score': riskScore,
        }),
      ).timeout(const Duration(seconds: 15));

      final result = jsonDecode(response.body);
      return result['status'] == 'feedback saved';

    } catch (e) {
      print('[API] Feedback error: $e');
      return false;
    }
  }

  // ── Save profile ─────────────────────────────────────────
  static Future<bool> saveProfile({
    required String userId,
    required Map<String, dynamic> profile,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.serverUrl}/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'profile': profile,
        }),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;

    } catch (e) {
      print('[API] Profile error: $e');
      return false;
    }
  }

  // ── Health check ─────────────────────────────────────────
  static Future<bool> isServerOnline() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.serverUrl),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}