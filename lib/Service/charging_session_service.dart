import 'package:shared_preferences/shared_preferences.dart';

class ChargingSessionService {
  static const String _activeSessionIdKey = 'active_session_id';
  static const String _sessionIdKey = 'session_id';
  static const String _sessionStatusKey = 'session_status';
  static const String _sessionStartedAtKey = 'session_started_at';
  static const String _sessionTransactionIdKey = 'session_transaction_id';
  static const String _sessionPhaseKey = 'session_phase';

  // ✅ Vehicle data keys
  static const String _vehicleNameKey = 'vehicle_name';
  static const String _vehicleManufacturerKey = 'vehicle_manufacturer';
  static const String _vehicleModelKey = 'vehicle_model';
  static const String _vehicleRegistrationKey = 'vehicle_registration';
  static const String _vehicleIdKey = 'vehicle_id';

  // ==================== SAVE SESSION ====================

  /// ✅ Save session with vehicle details
  static Future<void> saveActiveSession({
    required int sessionId,
    required DateTime startedAt,
    required String status,
    String? transactionId,
    String? phase,
    Map<String, dynamic>? vehicleData, // ✅ Add vehicle data
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save session data
      await prefs.setInt(_activeSessionIdKey, sessionId);
      await prefs.setInt(_sessionIdKey, sessionId);
      await prefs.setString(_sessionStatusKey, status);
      await prefs.setString(_sessionStartedAtKey, startedAt.toIso8601String());

      if (transactionId != null) {
        await prefs.setString(_sessionTransactionIdKey, transactionId);
      }
      if (phase != null) {
        await prefs.setString(_sessionPhaseKey, phase);
      }

      // ✅ Save vehicle data with session (same as session ID)
      if (vehicleData != null) {
        final vehicleName = vehicleData['vehicleName'] ?? '';
        final manufacturer = vehicleData['manufacturer'] ?? '';
        final model = vehicleData['model'] ?? '';
        final registration = vehicleData['registrationNumber'] ?? '';
        final vehicleId = vehicleData['vehicleId'];

        // Save generic vehicle data (fallback)
        if (vehicleName.isNotEmpty) {
          await prefs.setString(_vehicleNameKey, vehicleName);
        }
        if (manufacturer.isNotEmpty) {
          await prefs.setString(_vehicleManufacturerKey, manufacturer);
        }
        if (model.isNotEmpty) {
          await prefs.setString(_vehicleModelKey, model);
        }
        if (registration.isNotEmpty) {
          await prefs.setString(_vehicleRegistrationKey, registration);
        }
        if (vehicleId != null) {
          await prefs.setInt(_vehicleIdKey, vehicleId);
        }

        // ✅ Save session-specific vehicle data (keyed by session ID) - MOST RELIABLE
        await prefs.setString('session_${sessionId}_vehicle_name', vehicleName);
        await prefs.setString('session_${sessionId}_vehicle_manufacturer', manufacturer);
        await prefs.setString('session_${sessionId}_vehicle_model', model);
        await prefs.setString('session_${sessionId}_vehicle_registration', registration);
        if (vehicleId != null) {
          await prefs.setInt('session_${sessionId}_vehicle_id', vehicleId);
        }

        print('✅ Vehicle data saved with session: $vehicleName');
        print('   Session-specific keys: session_${sessionId}_vehicle_name');
      }

      print('✅ Active session saved: $sessionId ($status)');
    } catch (e) {
      print('❌ Error saving active session: $e');
    }
  }

  /// Save session ID only
  static Future<void> saveSessionIdOnly(int sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_activeSessionIdKey, sessionId);
      await prefs.setInt(_sessionIdKey, sessionId);
      print('✅ Session ID saved: $sessionId');
    } catch (e) {
      print('❌ Error saving session ID: $e');
    }
  }

  // ==================== GET SESSION ====================

  static Future<int?> getActiveSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_activeSessionIdKey);
    } catch (e) {
      print('❌ Error getting active session ID: $e');
      return null;
    }
  }

  static Future<String?> getActiveSessionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_sessionStatusKey);
    } catch (e) {
      print('❌ Error getting active session status: $e');
      return null;
    }
  }

  static Future<String?> getActiveSessionPhase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_sessionPhaseKey);
    } catch (e) {
      print('❌ Error getting active session phase: $e');
      return null;
    }
  }

  static Future<bool> hasActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getInt(_activeSessionIdKey);
      final status = prefs.getString(_sessionStatusKey);

      print('🔍 Checking active session:');
      print('   Session ID: $sessionId');
      print('   Status: $status');

      if (sessionId == null) {
        print('   Result: No session ID found');
        return false;
      }

      // Check if status is in active states
      final activeStatuses = [
        'active',
        'charging',
        'preparing',
        'starting',
        'pending',
        'initializing',
        'requesting',
        'suspended',
        'finishing'
      ];
      final isActive = sessionId != null &&
          status != null &&
          activeStatuses.contains(status.toLowerCase());

      print('   Result: $isActive');
      return isActive;
    } catch (e) {
      print('❌ Error checking active session: $e');
      return false;
    }
  }

  /// ✅ Get active session with vehicle details
  static Future<Map<String, dynamic>?> getActiveSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final sessionId = prefs.getInt(_activeSessionIdKey);
      if (sessionId == null) {
        print('📭 No active session found');
        return null;
      }

      final status = prefs.getString(_sessionStatusKey) ?? 'unknown';
      final phase = prefs.getString(_sessionPhaseKey) ?? 'unknown';
      final startedAtStr = prefs.getString(_sessionStartedAtKey);
      final transactionId = prefs.getString(_sessionTransactionIdKey);

      // ✅ Get vehicle data - prioritize session-specific keys
      String vehicleName = prefs.getString('session_${sessionId}_vehicle_name') ??
          prefs.getString(_vehicleNameKey) ??
          'Unknown Vehicle';

      String manufacturer = prefs.getString('session_${sessionId}_vehicle_manufacturer') ??
          prefs.getString(_vehicleManufacturerKey) ??
          '';

      String model = prefs.getString('session_${sessionId}_vehicle_model') ??
          prefs.getString(_vehicleModelKey) ??
          '';

      String registration = prefs.getString('session_${sessionId}_vehicle_registration') ??
          prefs.getString(_vehicleRegistrationKey) ??
          'N/A';

      int? vehicleId = prefs.getInt('session_${sessionId}_vehicle_id') ??
          prefs.getInt(_vehicleIdKey);

      print('📊 Retrieved session data:');
      print('   Session ID: $sessionId');
      print('   Status: $status');
      print('   Phase: $phase');
      print('   Vehicle: $vehicleName');
      print('   Registration: $registration');

      return {
        'sessionId': sessionId,
        'status': status,
        'phase': phase,
        'startedAt': startedAtStr,
        'transactionId': transactionId,
        'vehicleData': {
          'vehicleName': vehicleName,
          'manufacturer': manufacturer,
          'model': model,
          'registrationNumber': registration,
          'vehicleId': vehicleId,
        },
      };
    } catch (e) {
      print('❌ Error getting active session data: $e');
      return null;
    }
  }

  /// ✅ Get vehicle data for a specific session
  static Future<Map<String, String>> getVehicleDataForSession(int sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'vehicleName': prefs.getString('session_${sessionId}_vehicle_name') ??
            prefs.getString(_vehicleNameKey) ??
            'Unknown Vehicle',
        'manufacturer': prefs.getString('session_${sessionId}_vehicle_manufacturer') ??
            prefs.getString(_vehicleManufacturerKey) ??
            '',
        'model': prefs.getString('session_${sessionId}_vehicle_model') ??
            prefs.getString(_vehicleModelKey) ??
            '',
        'registrationNumber': prefs.getString('session_${sessionId}_vehicle_registration') ??
            prefs.getString(_vehicleRegistrationKey) ??
            'N/A',
      };
    } catch (e) {
      print('❌ Error getting vehicle data for session: $e');
      return {
        'vehicleName': 'Unknown Vehicle',
        'manufacturer': '',
        'model': '',
        'registrationNumber': 'N/A',
      };
    }
  }

  /// ✅ Save vehicle data for a specific session
  static Future<void> saveVehicleDataForSession({
    required int sessionId,
    required String vehicleName,
    required String manufacturer,
    required String model,
    required String registrationNumber,
    int? vehicleId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save generic keys (fallback)
      await prefs.setString(_vehicleNameKey, vehicleName);
      await prefs.setString(_vehicleManufacturerKey, manufacturer);
      await prefs.setString(_vehicleModelKey, model);
      await prefs.setString(_vehicleRegistrationKey, registrationNumber);
      if (vehicleId != null) {
        await prefs.setInt(_vehicleIdKey, vehicleId);
      }

      // ✅ Save session-specific keys (most reliable)
      await prefs.setString('session_${sessionId}_vehicle_name', vehicleName);
      await prefs.setString('session_${sessionId}_vehicle_manufacturer', manufacturer);
      await prefs.setString('session_${sessionId}_vehicle_model', model);
      await prefs.setString('session_${sessionId}_vehicle_registration', registrationNumber);
      if (vehicleId != null) {
        await prefs.setInt('session_${sessionId}_vehicle_id', vehicleId);
      }

      print('✅ Vehicle data saved for session $sessionId: $vehicleName');
    } catch (e) {
      print('❌ Error saving vehicle data for session: $e');
    }
  }

  // ==================== CLEAR SESSION ====================

  static Future<void> clearActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get session ID before clearing
      final sessionId = prefs.getInt(_activeSessionIdKey);

      // Clear session keys
      await prefs.remove(_activeSessionIdKey);
      await prefs.remove(_sessionIdKey);
      await prefs.remove(_sessionStatusKey);
      await prefs.remove(_sessionStartedAtKey);
      await prefs.remove(_sessionTransactionIdKey);
      await prefs.remove(_sessionPhaseKey);

      // ✅ Clear session-specific vehicle keys
      if (sessionId != null) {
        await prefs.remove('session_${sessionId}_vehicle_name');
        await prefs.remove('session_${sessionId}_vehicle_manufacturer');
        await prefs.remove('session_${sessionId}_vehicle_model');
        await prefs.remove('session_${sessionId}_vehicle_registration');
        await prefs.remove('session_${sessionId}_vehicle_id');
      }

      // ✅ Optionally clear generic vehicle data (comment out if you want to keep for other sessions)
      // await prefs.remove(_vehicleNameKey);
      // await prefs.remove(_vehicleManufacturerKey);
      // await prefs.remove(_vehicleModelKey);
      // await prefs.remove(_vehicleRegistrationKey);
      // await prefs.remove(_vehicleIdKey);

      print('🗑️ Active session cleared');
    } catch (e) {
      print('❌ Error clearing active session: $e');
    }
  }

  /// ✅ Clear all session data including generic vehicle data
  static Future<void> clearAllSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all session keys
      await prefs.remove(_activeSessionIdKey);
      await prefs.remove(_sessionIdKey);
      await prefs.remove(_sessionStatusKey);
      await prefs.remove(_sessionStartedAtKey);
      await prefs.remove(_sessionTransactionIdKey);
      await prefs.remove(_sessionPhaseKey);

      // Clear all session-specific vehicle keys
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('session_') && key.contains('_vehicle_')) {
          await prefs.remove(key);
        }
      }

      // Clear generic vehicle data
      await prefs.remove(_vehicleNameKey);
      await prefs.remove(_vehicleManufacturerKey);
      await prefs.remove(_vehicleModelKey);
      await prefs.remove(_vehicleRegistrationKey);
      await prefs.remove(_vehicleIdKey);

      print('🗑️ All session and vehicle data cleared');
    } catch (e) {
      print('❌ Error clearing all session data: $e');
    }
  }
}

