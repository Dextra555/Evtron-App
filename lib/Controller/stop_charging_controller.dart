import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/stop_charging_model.dart';
import '../Service/charging_session_service.dart';
import '../Service/stop_charging_service.dart';

class StopChargingController extends ChangeNotifier {
  final StopChargingService _stopChargingService = StopChargingService();

  bool _isLoading = false;
  String? _errorMessage;
  StopChargingResponse? _stopResponse;
  bool _isStopping = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StopChargingResponse? get stopResponse => _stopResponse;
  bool get isStopping => _isStopping;

  Future<bool> stopChargingSession({required int sessionId}) async {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║              STOP CHARGING CONTROLLER - STOP SESSION           ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('\n📝 Input Parameters:');
    print('   • Session ID: $sessionId');

    // Prevent multiple stop requests
    if (_isStopping) {
      print('⚠️ Stop request already in progress');
      return false;
    }

    _isLoading = true;
    _isStopping = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _stopChargingService.stopCharging(
        sessionId: sessionId,
      );

      print('\n📥 Response received in Controller:');
      print('   • Success: ${response.success}');
      print('   • Message: ${response.message}');
      print('   • Has Data: ${response.data != null}');

      // ✅ FIX: Check only success flag, not data presence
      if (response.success) {
        _stopResponse = response;

        // 🔴 CRITICAL: Clear the active charging session from SharedPreferences
        print('\n🔍 Clearing active charging session...');

        // Clear all session-related data
        await ChargingSessionService.clearActiveSession();

        // Also clear any other charging status data
        await _clearChargingStatusData();

        print('✅ Active charging session cleared successfully');

        print('\n✅ CHARGING SESSION STOPPED SUCCESSFULLY!');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📊 Session Summary:');
        print('   • Session ID: $sessionId');
        print('   • Status: ${response.message}');
        if (response.data != null) {
          print('   • Transaction ID: ${response.data!.transactionId}');
          print('   • Duration: ${response.data!.formattedDuration}');
          print('   • Energy Consumed: ${response.data!.formattedEnergy}');
          print('   • Total Cost: ${response.data!.formattedCost}');
          print('   • Wallet Balance: ₹${response.data!.walletBalanceAfter}');
        } else {
          print('   • Note: Full session data will be available in invoice');
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

        _isLoading = false;
        _isStopping = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        print('\n❌ ERROR: ${response.message}');

        // Even if the API returns an error, we might still want to clear the session
        final errorMsg = response.message?.toLowerCase() ?? '';

        if (errorMsg.contains('already') == true ||
            errorMsg.contains('not found') == true ||
            errorMsg.contains('inactive') == true ||
            errorMsg.contains('completed') == true) {
          print('⚠️ Session appears to be already stopped or invalid. Clearing active session...');
          await ChargingSessionService.clearActiveSession();
          await _clearChargingStatusData();

          // ✅ Return true so invoice shows for already stopped session
          _isLoading = false;
          _isStopping = false;
          notifyListeners();
          return true;
        }

        _isLoading = false;
        _isStopping = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('\n❌ EXCEPTION in Controller:');
      print('   • Error: $e');

      // Check for specific network errors
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        _errorMessage = 'Network error. Please check your internet connection and try again.';
        print('⚠️ Network error occurred - keeping session active for retry');
      } else if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        _errorMessage = 'Session expired. Please login again.';
        await ChargingSessionService.clearActiveSession();
        print('⚠️ Unauthorized error - cleared active session');
      } else {
        _errorMessage = 'Failed to stop charging: ${e.toString()}';
      }

      _isLoading = false;
      _isStopping = false;
      notifyListeners();
      return false;
    }
  }

  // Helper method to clear all charging status data
  Future<void> _clearChargingStatusData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Comprehensive list of all charging-related keys
      const chargingKeys = [
        'charging_status',
        'charging_session_id',
        'charging_started_at',
        'active_session_id',
        'session_status',
        'session_started_at',
        'current_session_id',
        'last_charging_status',
        // Add any other keys that might store session data
      ];

      for (var key in chargingKeys) {
        await prefs.remove(key);
      }

      // Also clear using the service
      await ChargingSessionService.clearActiveSession();

      print('✅ Cleared all charging status data from SharedPreferences');

      // Verify clearing
      final remainingKeys = prefs.getKeys();
      print('📋 Remaining keys: $remainingKeys');
    } catch (e) {
      print('⚠️ Error clearing charging status data: $e');
    }
  }

  // Method to retry stopping charging session
  Future<bool> retryStopCharging({required int sessionId}) async {
    print('🔄 Retrying stop charging for session: $sessionId');

    // Wait a moment before retrying
    await Future.delayed(const Duration(seconds: 2));

    return await stopChargingSession(sessionId: sessionId);
  }

  // Method to check if a session can be stopped
  Future<bool> canStopSession(int sessionId) async {
    try {
      final hasActive = await ChargingSessionService.hasActiveSession();
      final activeSessionId = await ChargingSessionService.getActiveSessionId();

      return hasActive && activeSessionId == sessionId;
    } catch (e) {
      print('❌ Error checking if session can be stopped: $e');
      return false;
    }
  }

  // Method to get stop summary text
  String getStopSummary() {
    if (_stopResponse?.data == null) {
      return 'Stop request sent successfully!\n\nSession will stop shortly.';
    }

    final data = _stopResponse!.data!;
    return '''
    Session Complete!
    
    ⏱️ Duration: ${data.formattedDuration}
    ⚡ Energy: ${data.formattedEnergy}
    💰 Total Cost: ${data.formattedCost}
    💳 Wallet Balance: ₹${data.walletBalanceAfter}
    Status: ${data.status.toUpperCase()}
    ''';
  }

  // Method to format stop response for display
  Map<String, String> getFormattedStopDetails() {
    if (_stopResponse?.data == null) {
      return {
        'status': 'STOP REQUESTED',
        'message': _stopResponse?.message ?? 'Stop request sent successfully',
      };
    }

    final data = _stopResponse!.data!;
    return {
      'sessionId': data.sessionId.toString(),
      'transactionId': data.transactionId,
      'status': data.status.toUpperCase(),
      'duration': data.formattedDuration,
      'energy': data.formattedEnergy,
      'cost': data.formattedCost,
      'walletBalance': '₹${data.walletBalanceAfter}',
    };
  }

  // Clear response data
  void clearResponse() {
    _stopResponse = null;
    _errorMessage = null;
    _isStopping = false;
    notifyListeners();
  }

  // Reset controller state
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _stopResponse = null;
    _isStopping = false;
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}