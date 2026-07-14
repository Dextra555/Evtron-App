import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Auth keys
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userPhoneKey = 'user_phone';
  static const String _accessTokenKey = 'access_token';
  static const String _tokenTypeKey = 'token_type';
  static const String _fullTokenKey = 'full_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';

  // Session keys
  static const String _activeSessionIdKey = 'active_session_id';
  static const String _sessionStatusKey = 'session_status';
  static const String _sessionPhaseKey = 'session_phase';
  static const String _sessionStartedAtKey = 'session_started_at';
  static const String _sessionTransactionIdKey = 'session_transaction_id';
  static const String _sessionDataKey = 'session_data';
  static const String _sessionChargerIdKey = 'session_charger_id';
  static const String _sessionConnectorIdKey = 'session_connector_id';

  // ✅ Vehicle data keys (only declared once)
  static const String _vehicleManufacturerKey = 'vehicle_manufacturer';
  static const String _vehicleModelKey = 'vehicle_model';
  static const String _vehicleRegistrationKey = 'vehicle_registration';
  static const String _vehicleNameKey = 'vehicle_name';
  static const String _vehicleIdKey = 'vehicle_id';

  // ==================== VEHICLE DATA METHODS ====================


  static Future<void> saveVehicleData({
    required String manufacturer,
    required String model,
    String registrationNumber = '',
    int? vehicleId,
    int? sessionId, // ✅ Add sessionId parameter
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final vehicleName = '$manufacturer $model'.trim();

      // Save generic vehicle data
      await prefs.setString(_vehicleManufacturerKey, manufacturer);
      await prefs.setString(_vehicleModelKey, model);
      await prefs.setString(_vehicleRegistrationKey, registrationNumber);
      await prefs.setString(_vehicleNameKey, vehicleName.isEmpty ? 'Unknown Vehicle' : vehicleName);
      if (vehicleId != null) {
        await prefs.setInt(_vehicleIdKey, vehicleId);
      }

      // ✅ Save session-specific vehicle data
      if (sessionId != null && sessionId > 0) {
        await prefs.setString('session_${sessionId}_vehicle_name', vehicleName);
        await prefs.setString('session_${sessionId}_vehicle_manufacturer', manufacturer);
        await prefs.setString('session_${sessionId}_vehicle_model', model);
        await prefs.setString('session_${sessionId}_vehicle_registration', registrationNumber);
        if (vehicleId != null) {
          await prefs.setInt('session_${sessionId}_vehicle_id', vehicleId);
        }
      }

      print('💾 Vehicle data saved to SharedPreferences:');
      print('   Session ID: ${sessionId ?? 'N/A'}');
      print('   Manufacturer: $manufacturer');
      print('   Model: $model');
      print('   Registration: $registrationNumber');
      print('   Name: $vehicleName');
    } catch (e) {
      print('❌ Error saving vehicle data: $e');
    }
  }

  /// Get vehicle data from SharedPreferences
  static Future<Map<String, String>> getVehicleData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final manufacturer = prefs.getString(_vehicleManufacturerKey) ?? '';
      final model = prefs.getString(_vehicleModelKey) ?? '';
      final registrationNumber = prefs.getString(_vehicleRegistrationKey) ?? '';
      final vehicleName = prefs.getString(_vehicleNameKey) ?? '';

      return {
        'manufacturer': manufacturer,
        'model': model,
        'registrationNumber': registrationNumber,
        'vehicleName': vehicleName.isNotEmpty ? vehicleName : '$manufacturer $model'.trim(),
      };
    } catch (e) {
      print('❌ Error getting vehicle data: $e');
      return {
        'manufacturer': '',
        'model': '',
        'registrationNumber': '',
        'vehicleName': 'Unknown Vehicle',
      };
    }
  }

  /// Get vehicle name from SharedPreferences
  static Future<String> getVehicleName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_vehicleNameKey) ?? '';
      if (name.isNotEmpty) return name;

      final manufacturer = prefs.getString(_vehicleManufacturerKey) ?? '';
      final model = prefs.getString(_vehicleModelKey) ?? '';
      final fullName = '$manufacturer $model'.trim();
      return fullName.isNotEmpty ? fullName : 'Unknown Vehicle';
    } catch (e) {
      print('❌ Error getting vehicle name: $e');
      return 'Unknown Vehicle';
    }
  }

  /// Get vehicle manufacturer from SharedPreferences
  static Future<String> getVehicleManufacturer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_vehicleManufacturerKey) ?? '';
    } catch (e) {
      print('❌ Error getting vehicle manufacturer: $e');
      return '';
    }
  }

  /// Get vehicle model from SharedPreferences
  static Future<String> getVehicleModel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_vehicleModelKey) ?? '';
    } catch (e) {
      print('❌ Error getting vehicle model: $e');
      return '';
    }
  }

  /// Get vehicle registration from SharedPreferences
  static Future<String> getVehicleRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_vehicleRegistrationKey) ?? '';
    } catch (e) {
      print('❌ Error getting vehicle registration: $e');
      return '';
    }
  }

  /// Get vehicle ID from SharedPreferences
  static Future<int?> getVehicleId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_vehicleIdKey);
    } catch (e) {
      print('❌ Error getting vehicle ID: $e');
      return null;
    }
  }

  /// Check if vehicle data exists in SharedPreferences
  static Future<bool> hasVehicleData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final manufacturer = prefs.getString(_vehicleManufacturerKey) ?? '';
      final model = prefs.getString(_vehicleModelKey) ?? '';
      return manufacturer.isNotEmpty || model.isNotEmpty;
    } catch (e) {
      print('❌ Error checking vehicle data: $e');
      return false;
    }
  }

  /// Clear vehicle data from SharedPreferences
  static Future<void> clearVehicleData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_vehicleManufacturerKey);
      await prefs.remove(_vehicleModelKey);
      await prefs.remove(_vehicleRegistrationKey);
      await prefs.remove(_vehicleNameKey);
      await prefs.remove(_vehicleIdKey);
      print('🗑️ Vehicle data cleared from storage');
    } catch (e) {
      print('❌ Error clearing vehicle data: $e');
    }
  }

  // ==================== AUTH METHODS ====================

  static Future<void> setLoggedIn(bool isLoggedIn, {
    String? phone,
    String? token,
    String? tokenType,
    String? name,
    String? email,
    int? userId,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);

    if (phone != null) {
      await prefs.setString(_userPhoneKey, phone);
    }

    if (token != null && token.isNotEmpty) {
      await prefs.setString(_accessTokenKey, token);
      print('✅ Token saved in AuthService');
      print('   Key: $_accessTokenKey');
      print('   Token length: ${token.length}');
      print('   Token preview: ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
    }

    if (tokenType != null) {
      await prefs.setString(_tokenTypeKey, tokenType);
    }

    if (name != null) {
      await prefs.setString(_userNameKey, name);
    }

    if (email != null) {
      await prefs.setString(_userEmailKey, email);
    }

    if (userId != null) {
      await prefs.setInt(_userIdKey, userId);
    }

    if (role != null) {
      await prefs.setString(_userRoleKey, role);
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    print('🔍 AuthService.isLoggedIn() = $isLoggedIn');
    return isLoggedIn;
  }

  static Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString(_accessTokenKey);

    if (token != null && token.isNotEmpty) {
      print('🔍 AuthService.getUserToken() - Token found with key: $_accessTokenKey');
      print('   Token length: ${token.length}');
      return token;
    }

    token = prefs.getString(_fullTokenKey);
    if (token != null && token.isNotEmpty) {
      print('🔍 AuthService.getUserToken() - Token found with key: $_fullTokenKey');
      return token;
    }

    print('🔍 AuthService.getUserToken() - No token found');
    return null;
  }

  static Future<String?> getTokenType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenTypeKey) ?? 'Bearer';
  }

  static Future<String?> getFullToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await getUserToken();
    final tokenType = await getTokenType();

    if (token != null && tokenType != null) {
      return '$tokenType $token';
    }
    return null;
  }

  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // ==================== SESSION METHODS ====================

  static Future<void> saveSessionId(int sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_activeSessionIdKey, sessionId);
      print('💾 Session ID saved: $sessionId');
    } catch (e) {
      print('❌ Error saving session ID: $e');
    }
  }

  static Future<void> saveSessionData({
    required int sessionId,
    required String status,
    String phase = 'unknown',
    String? startedAt,
    String? transactionId,
    int? chargerId,
    int? connectorId,
    Map<String, dynamic>? fullData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(_activeSessionIdKey, sessionId);
      await prefs.setString(_sessionStatusKey, status);
      await prefs.setString(_sessionPhaseKey, phase);

      if (startedAt != null) {
        await prefs.setString(_sessionStartedAtKey, startedAt);
      }

      if (transactionId != null && transactionId.isNotEmpty) {
        await prefs.setString(_sessionTransactionIdKey, transactionId);
      }

      if (chargerId != null) {
        await prefs.setInt(_sessionChargerIdKey, chargerId);
      }

      if (connectorId != null) {
        await prefs.setInt(_sessionConnectorIdKey, connectorId);
      }

      if (fullData != null) {
        await prefs.setString(_sessionDataKey, fullData.toString());
      }

      print('💾 Session data saved:');
      print('   Session ID: $sessionId');
      print('   Status: $status');
      print('   Phase: $phase');
    } catch (e) {
      print('❌ Error saving session data: $e');
    }
  }

  static Future<int?> getActiveSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_activeSessionIdKey);
    } catch (e) {
      print('❌ Error getting session ID: $e');
      return null;
    }
  }

  static Future<String?> getSessionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_sessionStatusKey);
    } catch (e) {
      print('❌ Error getting session status: $e');
      return null;
    }
  }

  static Future<String?> getSessionPhase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_sessionPhaseKey);
    } catch (e) {
      print('❌ Error getting session phase: $e');
      return null;
    }
  }

  static Future<String?> getSessionStartedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_sessionStartedAtKey);
    } catch (e) {
      print('❌ Error getting session started at: $e');
      return null;
    }
  }

  static Future<String?> getSessionTransactionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_sessionTransactionIdKey);
    } catch (e) {
      print('❌ Error getting session transaction ID: $e');
      return null;
    }
  }

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
      final startedAt = prefs.getString(_sessionStartedAtKey);
      final transactionId = prefs.getString(_sessionTransactionIdKey);
      final chargerId = prefs.getInt(_sessionChargerIdKey);
      final connectorId = prefs.getInt(_sessionConnectorIdKey);
      final fullDataStr = prefs.getString(_sessionDataKey);

      // ✅ Also get vehicle data
      final vehicleData = await getVehicleData();

      Map<String, dynamic>? fullData;
      if (fullDataStr != null) {
        try {
          fullData = Map<String, dynamic>.from(jsonDecode(fullDataStr));
        } catch (e) {
          // Ignore parsing errors
        }
      }

      print('📋 Retrieved session data:');
      print('   Session ID: $sessionId');
      print('   Status: $status');
      print('   Phase: $phase');
      print('   Vehicle: ${vehicleData['vehicleName']}');

      return {
        'sessionId': sessionId,
        'status': status,
        'phase': phase,
        'startedAt': startedAt,
        'transactionId': transactionId,
        'chargerId': chargerId,
        'connectorId': connectorId,
        'fullData': fullData,
        'vehicleData': vehicleData, // ✅ Include vehicle data
        '_fromStorage': true,
      };
    } catch (e) {
      print('❌ Error getting session data: $e');
      return null;
    }
  }

  static Future<bool> hasActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getInt(_activeSessionIdKey);
      return sessionId != null && sessionId > 0;
    } catch (e) {
      print('❌ Error checking active session: $e');
      return false;
    }
  }

  static Future<void> updateSessionStatus(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionStatusKey, status);
      print('💾 Session status updated to: $status');
    } catch (e) {
      print('❌ Error updating session status: $e');
    }
  }

  static Future<void> updateSessionPhase(String phase) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionPhaseKey, phase);
      print('💾 Session phase updated to: $phase');
    } catch (e) {
      print('❌ Error updating session phase: $e');
    }
  }

  static Future<void> clearSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeSessionIdKey);
      await prefs.remove(_sessionStatusKey);
      await prefs.remove(_sessionPhaseKey);
      await prefs.remove(_sessionStartedAtKey);
      await prefs.remove(_sessionTransactionIdKey);
      await prefs.remove(_sessionChargerIdKey);
      await prefs.remove(_sessionConnectorIdKey);
      await prefs.remove(_sessionDataKey);
      // ✅ Also clear vehicle data
      await clearVehicleData();
      print('🗑️ Session data cleared from storage');
    } catch (e) {
      print('❌ Error clearing session data: $e');
    }
  }

  static bool isSessionActive(String status) {
    final activeStatuses = [
      'charging',
      'preparing',
      'starting',
      'pending',
      'initializing',
      'requesting',
      'finishing',
      'suspended',
    ];
    return activeStatuses.contains(status.toLowerCase());
  }

  static bool isSessionTerminal(String status) {
    final terminalStatuses = [
      'completed',
      'stopped',
      'finished',
      'done',
      'interrupted',
      'error',
      'failed',
    ];
    return terminalStatuses.contains(status.toLowerCase());
  }

  // ==================== LOGOUT ====================

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_tokenTypeKey);
    await prefs.remove(_fullTokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userRoleKey);

    // Clear all data
    await clearSessionData();
    await clearVehicleData();

    print('✅ User logged out, all preferences and session data cleared');
  }

  // ==================== DEBUG METHODS ====================

  static Future<void> debugPrintAllData() async {
    final prefs = await SharedPreferences.getInstance();
    print('=== AuthService Debug: All SharedPreferences Data ===');
    final keys = prefs.getKeys();
    for (String key in keys) {
      final value = prefs.get(key);
      if (key.contains('token') || key.contains('session') || key.contains('vehicle')) {
        final valueStr = value.toString();
        print('Key: $key -> Value: ${valueStr.substring(0, valueStr.length > 50 ? 50 : valueStr.length)}...');
      } else {
        print('Key: $key -> Value: $value');
      }
    }
    print('=====================================================');
  }

  static Future<void> debugPrintSessionData() async {
    print('=== AuthService Debug: Session Data ===');
    final sessionId = await getActiveSessionId();
    print('Session ID: $sessionId');
    if (sessionId != null) {
      final status = await getSessionStatus();
      final phase = await getSessionPhase();
      final startedAt = await getSessionStartedAt();
      final transactionId = await getSessionTransactionId();
      final vehicleData = await getVehicleData();
      print('Status: $status');
      print('Phase: $phase');
      print('Started At: $startedAt');
      print('Transaction ID: $transactionId');
      print('Vehicle: ${vehicleData['vehicleName']}');
      print('Manufacturer: ${vehicleData['manufacturer']}');
      print('Model: ${vehicleData['model']}');
      print('Registration: ${vehicleData['registrationNumber']}');
    }
    print('=======================================');
  }
}