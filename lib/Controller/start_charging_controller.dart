// lib/Controller/start_charging_controller.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/start_charging_model.dart';
import '../Service/charging_session_service.dart';
import '../Service/start_charging_service.dart';

class ChargingController extends ChangeNotifier {
  final ChargingService _chargingService = ChargingService();

  bool _isLoading = false;
  String? _errorMessage;
  ChargingSessionResponse? _currentSession;
  ChargingSessionResponse? _lastErrorResponse;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ChargingSessionResponse? get currentSession => _currentSession;
  ChargingSessionResponse? get lastErrorResponse => _lastErrorResponse;

  Future<bool> startChargingSession({
    required int connectorId,
    required int vehicleId,
  }) async {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║           CHARGING CONTROLLER - START SESSION                ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('\n📝 Input Parameters:');
    print('   • Connector ID: $connectorId');
    print('   • Vehicle ID: $vehicleId');

    // Validate parameters
    if (connectorId <= 0) {
      _errorMessage = 'Invalid connector ID. Please scan a valid QR code.';
      print('\n❌ ERROR: ${_errorMessage}');
      _lastErrorResponse = ChargingSessionResponse(
        success: false,
        message: _errorMessage!,
        statusCode: 422,
        failedCheck: 'connector_invalid',
      );
      notifyListeners();
      return false;
    }

    if (vehicleId <= 0) {
      _errorMessage = 'Invalid vehicle ID. Please select a valid vehicle.';
      print('\n❌ ERROR: ${_errorMessage}');
      _lastErrorResponse = ChargingSessionResponse(
        success: false,
        message: _errorMessage!,
        statusCode: 422,
        failedCheck: 'vehicle_invalid',
      );
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _lastErrorResponse = null;
    notifyListeners();

    try {
      final response = await _chargingService.startCharging(
        connectorId: connectorId,
        vehicleId: vehicleId,
      );

      print('\n📥 Response received in Controller:');
      print('   • Success: ${response.success}');
      print('   • Message: ${response.message}');
      if (response.failedCheck != null) {
        print('   • Failed Check: ${response.failedCheck}');
      }

      if (response.success && response.data != null) {
        _currentSession = response;
        _lastErrorResponse = null;
        _errorMessage = null;

        // Save session data to SharedPreferences
        await _saveSessionData(response.data!);

        print('\n✅ SUCCESS: Charging session started successfully!');
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.getUserFriendlyMessage();
        _lastErrorResponse = response;

        print('\n❌ ERROR: ${_errorMessage}');

        // Check if there's an active session
        if (response.message?.toLowerCase().contains('active charging session') == true) {
          print('⚠️ Active session detected - attempting to recover...');
          await _recoverActiveSession();
        }

        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _lastErrorResponse = ChargingSessionResponse(
        success: false,
        message: _errorMessage!,
        statusCode: 500,
        failedCheck: 'unexpected_error',
      );
      print('\n❌ EXCEPTION in Controller: $e');
      print('Stack trace: $stackTrace');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSessionData(ChargingSessionData data) async {
    try {
      print('\n🔑 Saving session data to SharedPreferences...');

      final prefs = await SharedPreferences.getInstance();
      final sessionId = data.sessionId;

      if (sessionId > 0) {
        await ChargingSessionService.saveActiveSession(
          sessionId: sessionId,
          startedAt: DateTime.parse(data.startedAt),
          status: 'charging',
        );

        // Save additional data
        await prefs.setInt('active_session_id', sessionId);
        await prefs.setInt('current_session_id', sessionId);
        await prefs.setString('session_status', 'charging');
        await prefs.setString('charging_status', 'charging');
        await prefs.setString('session_started_at', data.startedAt);
        await prefs.setString('transaction_id', data.transactionId);
        await prefs.setInt('connector_id', data.connector.id);
        await prefs.setString('charger_id', data.charger.id);

        print('✅ Session data saved successfully:');
        print('   Session ID: $sessionId');
        print('   Started At: ${data.startedAt}');
        print('   Transaction ID: ${data.transactionId}');
        print('   Connector ID: ${data.connector.id}');
      } else {
        print('⚠️ Warning: Invalid session ID: $sessionId');
      }
    } catch (e) {
      print('⚠️ Error saving session to SharedPreferences: $e');
    }
  }

  Future<void> _recoverActiveSession() async {
    try {
      print('🔍 Attempting to recover active session data...');
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getInt('active_session_id') ??
          prefs.getInt('current_session_id');

      if (sessionId != null && sessionId > 0) {
        print('✅ Found existing session ID: $sessionId');
        await prefs.setString('session_status', 'charging');
        await prefs.setString('charging_status', 'charging');
        await prefs.setInt('active_session_id', sessionId);
        await prefs.setInt('current_session_id', sessionId);
        print('✅ Session status updated to "charging"');
        print('   Session ID: $sessionId');
      } else {
        print('⚠️ No existing session data found');
      }
    } catch (e) {
      print('⚠️ Error recovering active session: $e');
    }
  }

  Future<bool> hasActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getInt('active_session_id');
      final status = prefs.getString('session_status');
      return sessionId != null && status == 'charging' && sessionId > 0;
    } catch (e) {
      print('❌ Error checking active session: $e');
      return false;
    }
  }

  Future<int?> getActiveSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('active_session_id');
    } catch (e) {
      print('❌ Error getting active session ID: $e');
      return null;
    }
  }

  ChargingSessionResponse? getErrorResponse() {
    return _lastErrorResponse;
  }

  void clearSession() {
    _currentSession = null;
    _errorMessage = null;
    _lastErrorResponse = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clearSession();
    super.dispose();
  }
}