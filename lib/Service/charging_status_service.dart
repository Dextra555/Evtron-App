// lib/Service/charging_status_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class ChargingStatusService {
  static const String _keyChargingStatus = 'charging_status';
  static const String _keySessionId = 'current_session_id';
  static const String _keyStartedAt = 'charging_started_at';

  // Save charging status
  static Future<void> saveChargingStatus(String status, {int? sessionId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyChargingStatus, status);

    if (sessionId != null) {
      await prefs.setInt(_keySessionId, sessionId);
    }

    print('📝 Charging status saved: $status');
  }

  // Get charging status
  static Future<String> getChargingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyChargingStatus) ?? 'completed'; // Default to completed
  }

  // Save session ID
  static Future<void> saveSessionId(int sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySessionId, sessionId);
  }

  // Get session ID
  static Future<int?> getSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySessionId);
  }

  // Save started at (accepts either String or DateTime)
  static Future<void> saveStartedAt(dynamic startedAt) async {
    final prefs = await SharedPreferences.getInstance();
    String startedAtString;

    if (startedAt is DateTime) {
      startedAtString = startedAt.toIso8601String();
    } else if (startedAt is String) {
      startedAtString = startedAt;
    } else {
      startedAtString = startedAt.toString();
    }

    await prefs.setString(_keyStartedAt, startedAtString);
  }

  // Get started at (returns DateTime)
  static Future<DateTime?> getStartedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final startedAtString = prefs.getString(_keyStartedAt);

    if (startedAtString != null) {
      try {
        return DateTime.parse(startedAtString);
      } catch (e) {
        print('Error parsing startedAt: $e');
        return null;
      }
    }
    return null;
  }

  // Clear all charging data
  static Future<void> clearChargingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyChargingStatus);
    await prefs.remove(_keySessionId);
    await prefs.remove(_keyStartedAt);
    print('🗑️ Charging data cleared');
  }

  // Check if there's an active charging session
  static Future<bool> hasActiveChargingSession() async {
    final status = await getChargingStatus();
    return status == 'charging';
  }
}