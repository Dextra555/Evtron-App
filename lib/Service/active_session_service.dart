// lib/Service/active_session_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

class ActiveSessionService {
  static const String _activeSessionIdKey = 'active_session_id';
  static const String _sessionIdKey = 'session_id';
  static const String _sessionStatusKey = 'session_status';
  static const String _sessionStartedAtKey = 'session_started_at';
  static const String _sessionTransactionIdKey = 'session_transaction_id';
  static const String _sessionDataKey = 'session_data';

  /// Fetch the current active session from the live charging API with timeout
  static Future<Map<String, dynamic>?> getActiveSessionFromServer({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        print('❌ No auth token found');
        return null;
      }

      final url = Uri.parse(ApiEndpoints.liveCharging);

      print('🌐 Fetching active session from: ${url.toString()}');

      // Use timeout for the request
      final response = await http
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(
        timeout,
        onTimeout: () {
          print('⏰ Timeout fetching active session after ${timeout.inSeconds}s');
          throw TimeoutException('Request timeout');
        },
      );

      print('📥 Active Session Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final sessionData = data['data'];

          // Extract session info
          final sessionId = sessionData['session_id'] ?? sessionData['id'];
          final status = sessionData['status'] ?? 'charging';
          final phase = sessionData['phase'] ?? 'unknown';
          final transactionId = sessionData['transaction_id'] ?? sessionData['transactionId'] ?? '';
          final startedAt = sessionData['started_at'] ?? sessionData['startedAt'];

          print('✅ Active session found on server:');
          print('   Session ID: $sessionId');
          print('   Status: $status');
          print('   Phase: $phase');
          print('   Transaction: $transactionId');
          print('   Charger: ${sessionData['charger']?['name'] ?? 'N/A'}');

          // Save to SharedPreferences for future use
          await _saveSessionToStorage(
            sessionId: sessionId,
            status: status,
            phase: phase,
            transactionId: transactionId,
            startedAt: startedAt,
            fullData: sessionData,
          );

          return {
            'sessionId': sessionId,
            'status': status,
            'phase': phase,
            'transactionId': transactionId,
            'startedAt': startedAt,
            'data': sessionData,
          };
        } else if (data['data'] == null &&
            (data['message']?.toLowerCase().contains('no active session') == true ||
                data['message']?.toLowerCase().contains('not found') == true)) {
          print('⚠️ No active session on server');
          await clearSessionFromStorage();
          return null;
        } else {
          print('⚠️ Unexpected response format: ${response.body}');
          return null;
        }
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        // Handle specific error cases
        try {
          final errorData = jsonDecode(response.body);
          final message = errorData['message']?.toLowerCase() ?? '';

          if (message.contains('already have an active charging session') ||
              message.contains('active session exists')) {
            print('⚠️ Server says we have an active session but live API returned error');
            // Try to get session from SharedPreferences
            return await _getActiveSessionFromStorage();
          } else if (message.contains('no active session') ||
              message.contains('not found')) {
            print('⚠️ No active session on server');
            await clearSessionFromStorage();
            return null;
          }
        } catch (e) {
          print('❌ Error parsing error response: $e');
        }
        return null;
      } else {
        print('❌ Failed to fetch active session: ${response.statusCode}');
        print('   Response: ${response.body}');
        return null;
      }
    } on TimeoutException {
      print('⏰ Timeout - Could not fetch active session');
      // Try to get from storage as fallback
      return await _getActiveSessionFromStorage();
    } catch (e) {
      print('❌ Error fetching active session: $e');
      // Try to get from storage as fallback
      return await _getActiveSessionFromStorage();
    }
  }

  /// Get active session from SharedPreferences
  static Future<Map<String, dynamic>?> _getActiveSessionFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check for active session first
      int? sessionId = prefs.getInt(_activeSessionIdKey);

      // If not found, try fallback keys
      if (sessionId == null) {
        sessionId = prefs.getInt(_sessionIdKey);
      }

      if (sessionId != null) {
        final status = prefs.getString(_sessionStatusKey) ?? 'charging';
        final phase = prefs.getString('${_sessionStatusKey}_phase') ?? 'unknown';
        final transactionId = prefs.getString(_sessionTransactionIdKey) ?? '';
        final startedAtStr = prefs.getString(_sessionStartedAtKey);
        final fullDataStr = prefs.getString(_sessionDataKey);

        Map<String, dynamic>? fullData;
        if (fullDataStr != null) {
          try {
            fullData = jsonDecode(fullDataStr) as Map<String, dynamic>;
          } catch (e) {
            // Ignore parsing errors
          }
        }

        print('📦 Found session in SharedPreferences: $sessionId');

        // Validate if the session is still active based on time
        // If started more than 24 hours ago, consider it stale
        if (startedAtStr != null) {
          try {
            final startedAt = DateTime.parse(startedAtStr);
            final now = DateTime.now();
            if (now.difference(startedAt).inHours > 24) {
              print('⚠️ Session is older than 24 hours, may be stale');
              // Don't delete it, but mark as potentially stale
            }
          } catch (e) {
            // Ignore date parsing errors
          }
        }

        return {
          'sessionId': sessionId,
          'status': status,
          'phase': phase,
          'transactionId': transactionId,
          'startedAt': startedAtStr,
          'data': fullData,
          '_fromStorage': true,
        };
      }

      print('⚠️ No session data found in SharedPreferences');
      return null;
    } catch (e) {
      print('❌ Error reading from storage: $e');
      return null;
    }
  }

  /// Save session to SharedPreferences
  static Future<void> _saveSessionToStorage({
    required int sessionId,
    required String status,
    String phase = 'unknown',
    String transactionId = '',
    dynamic startedAt,
    Map<String, dynamic>? fullData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save active session
      await prefs.setInt(_activeSessionIdKey, sessionId);
      await prefs.setInt(_sessionIdKey, sessionId);
      await prefs.setString(_sessionStatusKey, status);
      await prefs.setString('${_sessionStatusKey}_phase', phase);

      if (transactionId.isNotEmpty) {
        await prefs.setString(_sessionTransactionIdKey, transactionId);
      }

      if (startedAt != null) {
        final startedAtStr = startedAt is DateTime
            ? startedAt.toIso8601String()
            : startedAt.toString();
        await prefs.setString(_sessionStartedAtKey, startedAtStr);
      }

      if (fullData != null) {
        await prefs.setString(_sessionDataKey, jsonEncode(fullData));
      }

      // ✅ Session saved (silent log - reduce spam)
    } catch (e) {
      print('❌ Error saving session: $e');
    }
  }

  static Future<void> clearSessionFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeSessionIdKey);
      await prefs.remove(_sessionIdKey);
      await prefs.remove(_sessionStatusKey);
      await prefs.remove('${_sessionStatusKey}_phase');
      await prefs.remove(_sessionTransactionIdKey);
      await prefs.remove(_sessionStartedAtKey);
      await prefs.remove(_sessionDataKey);
      print('🗑️ Session cleared from storage');
    } catch (e) {
      print('❌ Error clearing session: $e');
    }
  }

  static Future<bool> hasActiveSessionInStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getInt(_activeSessionIdKey);
      return sessionId != null;
    } catch (e) {
      print('❌ Error checking active session: $e');
      return false;
    }
  }

  /// Get the active session ID from storage
  static Future<int?> getActiveSessionIdFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_activeSessionIdKey);
    } catch (e) {
      print('❌ Error getting session ID: $e');
      return null;
    }
  }

  /// Get the active session status from storage
  static Future<String?> getActiveSessionStatusFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_sessionStatusKey);
    } catch (e) {
      print('❌ Error getting session status: $e');
      return null;
    }
  }

  /// Update the session status in storage
  static Future<void> updateSessionStatus(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionStatusKey, status);
      print('💾 Session status updated to: $status');
    } catch (e) {
      print('❌ Error updating session status: $e');
    }
  }

  /// Check if the session is still valid (not completed or stopped)
  static bool isSessionActive(String status) {
    final activeStatuses = ['charging', 'preparing', 'starting', 'pending', 'initializing', 'requesting'];
    return activeStatuses.contains(status.toLowerCase());
  }

  /// Get full session data from storage
  static Future<Map<String, dynamic>?> getFullSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_sessionDataKey);

      if (dataStr != null) {
        try {
          return jsonDecode(dataStr) as Map<String, dynamic>;
        } catch (e) {
          print('❌ Error parsing session data: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting session data: $e');
      return null;
    }
  }

  /// Get session data with validation
  static Future<Map<String, dynamic>?> getValidatedSessionData() async {
    try {
      final sessionData = await getActiveSessionFromServer(timeout: const Duration(seconds: 3));

      if (sessionData != null) {
        final status = sessionData['status']?.toLowerCase() ?? '';
        if (isSessionActive(status)) {
          return sessionData;
        }
      }

      // Try storage as fallback
      final storageData = await _getActiveSessionFromStorage();
      if (storageData != null) {
        final status = storageData['status']?.toLowerCase() ?? '';
        if (isSessionActive(status)) {
          return storageData;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting validated session: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> forceRefreshSession() async {
    print('🔄 Forcing session refresh...');
    // Clear storage first to force fresh fetch
    await clearSessionFromStorage();
    return await getActiveSessionFromServer();
  }
}

