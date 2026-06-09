// lib/Controller/live_charging_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../Model/live_charging_model.dart';
import '../Service/charging_session_service.dart';
import '../Service/live_charging_service.dart';
import '../Service/charging_status_service.dart';

class LiveChargingController extends ChangeNotifier {
  final LiveChargingService _liveChargingService = LiveChargingService();

  LiveChargingData? _currentLiveData;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;
  int? _currentSessionId;
  int _pollingAttempts = 0;
  static const int maxPollingAttempts = 3;

  LiveChargingData? get currentLiveData => _currentLiveData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get currentSessionId => _currentSessionId;

  // Battery percentage
  double get batteryPercentage {
    if (_currentLiveData != null && _currentLiveData!.energy.consumedKwh > 0) {
      double batteryCapacity = 50.0;
      double percentage = (_currentLiveData!.energy.consumedKwh / batteryCapacity) * 100;
      return percentage.clamp(0, 100);
    }
    return 32.0;
  }

  String get chargingStatus {
    if (_currentLiveData == null) return "Charging";
    return _currentLiveData!.status == 'charging' ? "Charging" : "Stopped";
  }

  String get formattedElapsedTime {
    return _currentLiveData?.elapsedTime.formatted ?? "00:00:00";
  }

  String get energyConsumed {
    return "${_currentLiveData?.energy.consumedKwh.toStringAsFixed(2) ?? '0'} kWh";
  }

  String get currentPower {
    return "${_currentLiveData?.energy.powerKw.toStringAsFixed(1) ?? '0'} kW";
  }

  String get totalCost {
    final cost = _currentLiveData?.cost.total ?? 0;
    final currency = _currentLiveData?.cost.currency ?? '₹';
    return "$currency${cost.toStringAsFixed(2)}";
  }

  String get chargerName {
    return _currentLiveData?.charger.name ?? "Charging Unit";
  }

  String get chargerId {
    return _currentLiveData?.charger.id ?? "N/A";
  }

  String get chargerPowerCapacity {
    return "${_currentLiveData?.charger.powerCapacity.toStringAsFixed(1) ?? '0'} kW";
  }

  String get chargerStatus {
    return _currentLiveData?.charger.status ?? "unknown";
  }

  String get connectorType {
    return _currentLiveData?.connector.type ?? "Type 2";
  }

  String get connectorName {
    return _currentLiveData?.connector.name ?? "N/A";
  }

  String get connectorStatus {
    return _currentLiveData?.connector.status ?? "unknown";
  }

  String get stationName {
    return _currentLiveData?.station.name ?? "Charging Station";
  }

  int get stationId {
    return _currentLiveData?.station.id ?? 0;
  }

  bool get ocppConnected {
    return _currentLiveData?.ocpp?.connected ?? false;
  }

  int get totalMeterReadings {
    return _currentLiveData?.ocpp?.totalMeterReadings ?? 0;
  }

  int get meterValuesCount {
    return _currentLiveData?.energy.meterValuesCount ?? 0;
  }

  String get formattedStartedAt {
    if (_currentLiveData?.startedAt == null) return "N/A";
    final dateTime = _currentLiveData!.startedAt;
    final localTime = dateTime.toLocal();
    return "${localTime.toString().split('.')[0]}";
  }

  Future<bool> fetchLiveChargingStatus({int? sessionId}) async {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║           LIVE CHARGING CONTROLLER - FETCH DATA               ║');
    print('╚══════════════════════════════════════════════════════════════╝');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _liveChargingService.getLiveChargingStatus(
        sessionId: sessionId,
      );

      if (response.success && response.data != null) {
        _currentLiveData = response.data;
        _currentSessionId = response.data!.sessionId;
        _errorMessage = null;
        _pollingAttempts = 0; // Reset polling attempts on success

        // Save status to SharedPreferences
        await ChargingStatusService.saveChargingStatus(
          _currentLiveData!.status,
          sessionId: _currentLiveData!.sessionId,
        );

        // Save session ID
        if (_currentLiveData?.sessionId != null) {
          await ChargingStatusService.saveSessionId(_currentLiveData!.sessionId);

          // Save active session information based on status
          if (_currentLiveData!.status == 'charging') {
            await ChargingSessionService.saveActiveSession(
              sessionId: _currentLiveData!.sessionId,
              startedAt: _currentLiveData!.startedAt,
              status: _currentLiveData!.status,
            );
            print('✅ Active charging session saved: ${_currentLiveData!.sessionId}');
          } else {
            // If status is not charging, clear the active session
            await ChargingSessionService.clearActiveSession();
            print('🛑 Session not charging, cleared from storage');
          }
        }

        // Save started at
        await ChargingStatusService.saveStartedAt(
            _currentLiveData!.startedAt.toIso8601String()
        );

        print('✅ Live charging data updated successfully');
        print('   Session: ${_currentLiveData?.sessionId}');
        print('   Transaction: ${_currentLiveData?.transactionId}');
        print('   Status: ${_currentLiveData?.status}');
        print('   Session Active: ${await ChargingSessionService.hasActiveSession()}');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to fetch live charging status';
        print('❌ Error: $_errorMessage');

        // If session not found or invalid, clear it
        if (response.message?.toLowerCase().contains('not found') == true ||
            response.message?.toLowerCase().contains('invalid') == true) {
          await ChargingSessionService.clearActiveSession();
          print('⚠️ Session invalid or not found, cleared from storage');

          // Stop polling if session is invalid
          if (_pollingTimer != null && _pollingTimer!.isActive) {
            stopPolling();
          }
        }

        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Exception: $_errorMessage');

      // Increment polling attempts on error
      _pollingAttempts++;

      // If we've exceeded max attempts, stop polling
      if (_pollingAttempts >= maxPollingAttempts) {
        print('⚠️ Max polling attempts reached. Stopping polling.');
        stopPolling();
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Start polling for real-time updates
  void startPolling({int? sessionId, Duration interval = const Duration(seconds: 5)}) {
    stopPolling();
    _currentSessionId = sessionId;
    _pollingAttempts = 0;

    print('🔄 Starting live charging polling (every ${interval.inSeconds} seconds)');
    print('   Session ID: $sessionId');

    // Fetch immediately
    fetchLiveChargingStatus(sessionId: sessionId);

    // Then set up periodic polling
    _pollingTimer = Timer.periodic(interval, (timer) async {
      // Only continue polling if we have a valid session ID
      if (_currentSessionId == null) {
        print('⚠️ No session ID available, stopping polling');
        stopPolling();
        return;
      }

      print('🔄 Polling live charging data... (Attempt: ${_pollingAttempts + 1})');
      await fetchLiveChargingStatus(sessionId: _currentSessionId);
    });
  }

  // Stop polling
  void stopPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) {
      print('⏹️ Stopping live charging polling');
      _pollingTimer!.cancel();
      _pollingTimer = null;
    }
    _pollingAttempts = 0;
  }

  // Calculate estimated time to full
  String getEstimatedTimeToFull() {
    if (_currentLiveData == null) return "Calculating...";

    double currentBattery = batteryPercentage;
    double targetBattery = 100.0;
    double remainingPercent = targetBattery - currentBattery;

    if (remainingPercent <= 0) return "Complete";

    double chargingRateKw = _currentLiveData?.energy.powerKw ?? 0;
    if (chargingRateKw <= 0) {
      chargingRateKw = _currentLiveData?.charger.powerCapacity ?? 7.0;
    }

    // Estimate: minutes = (remaining kWh / charging rate) * 60
    // Assuming 50 kWh battery, remaining kWh = (remaining% * 50)/100
    double remainingKwh = (remainingPercent * 50) / 100;
    double hoursRemaining = remainingKwh / chargingRateKw;
    double minutesRemaining = hoursRemaining * 60;

    if (minutesRemaining <= 0) return "Complete";
    if (minutesRemaining < 60) {
      return "${minutesRemaining.toStringAsFixed(0)} min";
    } else {
      int hours = minutesRemaining ~/ 60;
      int minutes = (minutesRemaining % 60).toInt();
      return "$hours hr ${minutes} min";
    }
  }

  // Check if session is still active
  Future<bool> isSessionActive() async {
    return await ChargingSessionService.hasActiveSession();
  }

  // Force refresh session status from API
  Future<bool> refreshSessionStatus() async {
    if (_currentSessionId != null) {
      return await fetchLiveChargingStatus(sessionId: _currentSessionId);
    }
    return false;
  }

  // Clear data
  void clearData() {
    _currentLiveData = null;
    _currentSessionId = null;
    _errorMessage = null;
    _pollingAttempts = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

