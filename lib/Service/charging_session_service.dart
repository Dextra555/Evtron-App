
import 'package:shared_preferences/shared_preferences.dart';

class ChargingSessionService {
  static const String _activeSessionIdKey = 'active_session_id';
  static const String _sessionStartedAtKey = 'session_started_at';
  static const String _sessionStatusKey = 'session_status';

  // Save active session
  static Future<void> saveActiveSession({
    required int sessionId,
    required DateTime startedAt,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeSessionIdKey, sessionId);
    await prefs.setString(_sessionStartedAtKey, startedAt.toIso8601String());
    await prefs.setString(_sessionStatusKey, status);
    print('✅ Active session saved: $sessionId');
  }

  // Get active session ID
  static Future<int?> getActiveSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeSessionIdKey);
  }

  // Check if there's an active session
  static Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getInt(_activeSessionIdKey);
    final status = prefs.getString(_sessionStatusKey);

    return sessionId != null && status == 'charging';
  }

  // Clear active session (when charging stops)
  static Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSessionIdKey);
    await prefs.remove(_sessionStartedAtKey);
    await prefs.remove(_sessionStatusKey);
    print('✅ Active session cleared');
  }

  // Update session status
  static Future<void> updateSessionStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionStatusKey, status);
    print('✅ Session status updated to: $status');
  }
}
