import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/live_charging_model.dart';
import '../Service/AuthService.dart';
import '../Service/active_session_service.dart';
import '../Service/charging_session_service.dart';
import '../Service/live_charging_service.dart';
import '../Service/charging_status_service.dart';

class LiveChargingController extends ChangeNotifier {
  final LiveChargingService _liveChargingService = LiveChargingService();

  bool _isNoActiveSession = false;
  bool get isNoActiveSession => _isNoActiveSession;

  LiveChargingData? _currentLiveData;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;
  int? _currentSessionId;
  int _pollingAttempts = 0;
  static const int maxPollingAttempts = 3;

  int _consecutiveFailures = 0;
  static const int maxConsecutiveFailures = 3;
  bool _shouldPoll = true;
  bool _pollingStoppedByNetwork = false;
  bool get pollingStoppedByNetwork => _pollingStoppedByNetwork;

  Timer? _debounceTimer;
  bool _hasPendingUpdate = false;
  bool _isInBackground = false;
  DateTime? _lastUpdateTime;
  static const Duration _minUpdateInterval = Duration(milliseconds: 500);

  // ✅ Vehicle cache (same as session cache)
  String _cachedVehicleName = 'Unknown Vehicle';
  String _cachedVehicleManufacturer = '';
  String _cachedVehicleModel = '';
  String _cachedVehicleRegistration = '';
  int? _cachedVehicleId;
  bool _vehicleDataLoaded = false;

  // ==================== GETTERS ====================

  LiveChargingData? get currentLiveData => _currentLiveData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get currentSessionId => _currentSessionId;
  bool get isPollingActive => _pollingTimer != null && _pollingTimer!.isActive;

  // ==================== STATUS CHECKERS ====================

  bool get isCharging => _currentLiveData?.isCharging ?? false;
  bool get isPreparing => _currentLiveData?.isPreparing ?? false;
  bool get isSuspended => _currentLiveData?.isSuspended ?? false;
  bool get isFinishing => _currentLiveData?.isFinishing ?? false;
  bool get isCompleted => _currentLiveData?.isCompleted ?? false;
  bool get hasError => _currentLiveData?.hasError ?? false;
  bool get shouldShowCompletionSheet => _currentLiveData?.shouldShowCompletionSheet ?? false;

  bool get isSessionRequested {
    if (_currentLiveData == null) return false;
    final status = _currentLiveData!.status.toLowerCase();
    final phase = _currentLiveData!.phase.toLowerCase();
    return status == 'requesting' ||
        status == 'preparing' ||
        status == 'pending' ||
        phase == 'requesting' ||
        phase == 'preparing' ||
        phase == 'pending';
  }

  bool get shouldShowActiveIcon => isCharging;
  bool get shouldNavigateToProgress => isCharging || isPreparing;
  bool get shouldStayOnPreparing => isPreparing || isSessionRequested || _currentLiveData == null || _isLoading;
  bool get shouldShowCompletion => shouldShowCompletionSheet || isNoActiveSession;

  // ==================== STOP REASON GETTERS ====================

  String get stopReasonDisplay => _currentLiveData?.stopReasonDisplay ?? 'Charging Completed';
  String get stopReasonIcon => _currentLiveData?.stopReasonIcon ?? '✅';
  bool get isCompletedSummary => _currentLiveData?.isCompletedSummary ?? false;
  String? get stopReason => _currentLiveData?.stopReason;
  bool get autoStopped => _currentLiveData?.autoStopped ?? false;
  DateTime? get endedAt => _currentLiveData?.endedAt;

  // ==================== STATION INFO GETTERS ====================

  String get stationName => _currentLiveData?.station?.name ?? 'Unknown Station';
  String? get stationCity => _currentLiveData?.station?.city;
  String get stationFullLocation => _currentLiveData?.station?.fullLocation ?? 'Unknown Location';

  // ==================== STATUS MESSAGE ====================

  String get statusMessage {
    if (_currentLiveData == null) return '⏳ No active session';
    return _currentLiveData!.displayStatus;
  }

  // ==================== VEHICLE INFO GETTERS ====================

  /// Get vehicle name - checks live data first, then SharedPreferences
  String get vehicleName {
    // ✅ First: Try live data
    if (_currentLiveData != null && _currentLiveData!.vehicle != null) {
      final name = _currentLiveData!.vehicleFullName;
      if (name != 'Unknown Vehicle') {
        return name;
      }
    }

    // ✅ Second: Try cached vehicle data
    if (_vehicleDataLoaded && _cachedVehicleName.isNotEmpty) {
      return _cachedVehicleName;
    }

    // ✅ Third: Load from storage (async, but return cached value)
    _loadVehicleDetailsFromStorage();
    return _cachedVehicleName;
  }

  /// Get vehicle manufacturer
  String get vehicleManufacturer {
    // ✅ First: Try live data
    if (_currentLiveData != null && _currentLiveData!.vehicle != null) {
      final manufacturer = _currentLiveData!.vehicleManufacturer;
      if (manufacturer.isNotEmpty) {
        return manufacturer;
      }
    }

    // ✅ Second: Try cached vehicle data
    if (_vehicleDataLoaded && _cachedVehicleManufacturer.isNotEmpty) {
      return _cachedVehicleManufacturer;
    }

    _loadVehicleDetailsFromStorage();
    return _cachedVehicleManufacturer;
  }

  /// Get vehicle model
  String get vehicleModel {
    // ✅ First: Try live data
    if (_currentLiveData != null && _currentLiveData!.vehicle != null) {
      final model = _currentLiveData!.vehicleModel;
      if (model.isNotEmpty) {
        return model;
      }
    }

    // ✅ Second: Try cached vehicle data
    if (_vehicleDataLoaded && _cachedVehicleModel.isNotEmpty) {
      return _cachedVehicleModel;
    }

    _loadVehicleDetailsFromStorage();
    return _cachedVehicleModel;
  }

  /// Get vehicle registration number
  String get vehicleRegistrationNumber {
    // ✅ First: Try live data
    if (_currentLiveData != null && _currentLiveData!.vehicle != null) {
      final registration = _currentLiveData!.vehicleRegistration;
      if (registration.isNotEmpty) {
        return registration;
      }
    }

    // ✅ Second: Try cached vehicle data
    if (_vehicleDataLoaded && _cachedVehicleRegistration.isNotEmpty) {
      return _cachedVehicleRegistration;
    }

    _loadVehicleDetailsFromStorage();
    return _cachedVehicleRegistration;
  }

  /// Get vehicle ID
  int? get vehicleId {
    if (_currentLiveData != null && _currentLiveData!.vehicle != null) {
      return _currentLiveData!.vehicle!.id;
    }

    if (_vehicleDataLoaded && _cachedVehicleId != null) {
      return _cachedVehicleId;
    }

    _loadVehicleDetailsFromStorage();
    return _cachedVehicleId;
  }

  /// Get full vehicle info map
  Map<String, String> get vehicleInfoMap {
    return {
      'manufacturer': vehicleManufacturer,
      'model': vehicleModel,
      'registrationNumber': vehicleRegistrationNumber,
      'vehicleName': vehicleName,
    };
  }

  /// Check if vehicle data exists
  bool get hasVehicleData {
    if (_currentLiveData != null && _currentLiveData!.vehicle != null) {
      return _currentLiveData!.vehicle!.hasData;
    }

    if (_vehicleDataLoaded) {
      return _cachedVehicleManufacturer.isNotEmpty || _cachedVehicleModel.isNotEmpty;
    }

    return false;
  }

  // ==================== VEHICLE DATA LOADING ====================

  /// ✅ Method to set vehicle details from storage (called by MapScreen)
  void setVehicleDetails({
    required String name,
    required String manufacturer,
    required String model,
    required String registration,
    int? vehicleId,
  }) {
    final oldName = _cachedVehicleName;
    _cachedVehicleName = name.isNotEmpty ? name : 'Unknown Vehicle';
    _cachedVehicleManufacturer = manufacturer;
    _cachedVehicleModel = model;
    _cachedVehicleRegistration = registration;
    _cachedVehicleId = vehicleId;
    _vehicleDataLoaded = true;

    // ✅ Only log when vehicle actually changes (not on every call)
    if (oldName != _cachedVehicleName) {
      print('✅ Vehicle updated: $_cachedVehicleName');
    }
    _safeNotifyListeners();
  }

  Future<void> _loadVehicleDetailsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current session ID
      final sessionId = _currentSessionId ?? prefs.getInt('active_session_id');

      String vehicleName = '';
      String manufacturer = '';
      String model = '';
      String registration = '';
      int? vehicleId;

      // ✅ 1. Try session-specific vehicle details (most reliable)
      if (sessionId != null && sessionId > 0) {
        vehicleName = prefs.getString('session_${sessionId}_vehicle_name') ?? '';
        manufacturer = prefs.getString('session_${sessionId}_vehicle_manufacturer') ?? '';
        model = prefs.getString('session_${sessionId}_vehicle_model') ?? '';
        registration = prefs.getString('session_${sessionId}_vehicle_registration') ?? '';
        vehicleId = prefs.getInt('session_${sessionId}_vehicle_id');

        // If we found session-specific data, use it
        if (vehicleName.isNotEmpty) {
          _cachedVehicleName = vehicleName;
          _cachedVehicleManufacturer = manufacturer;
          _cachedVehicleModel = model;
          _cachedVehicleRegistration = registration;
          _cachedVehicleId = vehicleId;
          _vehicleDataLoaded = true;

// ✅ Vehicle details loaded (not printing on every load to reduce log spam)

          _safeNotifyListeners();
          return;
        }
      }

      // ✅ 2. Fallback to generic vehicle details
      vehicleName = prefs.getString('vehicle_name') ?? '';
      manufacturer = prefs.getString('vehicle_manufacturer') ?? '';
      model = prefs.getString('vehicle_model') ?? '';
      registration = prefs.getString('vehicle_registration') ?? '';
      vehicleId = prefs.getInt('vehicle_id');

      // ✅ 3. Update cache
      _cachedVehicleName = vehicleName.isNotEmpty ? vehicleName : 'Unknown Vehicle';
      _cachedVehicleManufacturer = manufacturer;
      _cachedVehicleModel = model;
      _cachedVehicleRegistration = registration;
      _cachedVehicleId = vehicleId;
      _vehicleDataLoaded = true;

      // ✅ Vehicle details loaded from storage

      _safeNotifyListeners();
    } catch (e) {
      print('⚠️ Error loading vehicle details from storage: $e');
    }
  }

  /// Async version of vehicleName getter
  Future<String> getVehicleNameAsync() async {
    // First check live data
    if (_currentLiveData != null && _currentLiveData!.vehicle != null) {
      final name = _currentLiveData!.vehicleFullName;
      if (name != 'Unknown Vehicle') {
        return name;
      }
    }

    // Check storage
    await _loadVehicleDetailsFromStorage();
    return _cachedVehicleName;
  }

  /// Async version of vehicle manufacturer getter
  Future<String> getVehicleManufacturerAsync() async {
    if (_currentLiveData != null && _currentLiveData!.vehicle != null) {
      final manufacturer = _currentLiveData!.vehicleManufacturer;
      if (manufacturer.isNotEmpty) {
        return manufacturer;
      }
    }

    await _loadVehicleDetailsFromStorage();
    return _cachedVehicleManufacturer;
  }

  /// Async version of vehicle model getter
  Future<String> getVehicleModelAsync() async {
    if (_currentLiveData != null && _currentLiveData!.vehicle != null) {
      final model = _currentLiveData!.vehicleModel;
      if (model.isNotEmpty) {
        return model;
      }
    }

    await _loadVehicleDetailsFromStorage();
    return _cachedVehicleModel;
  }

  /// Async version of vehicle registration getter
  Future<String> getVehicleRegistrationAsync() async {
    if (_currentLiveData != null && _currentLiveData!.vehicle != null) {
      final registration = _currentLiveData!.vehicleRegistration;
      if (registration.isNotEmpty) {
        return registration;
      }
    }

    await _loadVehicleDetailsFromStorage();
    return _cachedVehicleRegistration;
  }

  /// Get full vehicle data asynchronously
  Future<Map<String, String>> getVehicleDataAsync() async {
    // First check live data
    if (_currentLiveData != null && _currentLiveData!.vehicle != null) {
      final vehicle = _currentLiveData!.vehicle!;
      if (vehicle.hasData) {
        return {
          'manufacturer': vehicle.manufacturer ?? '',
          'model': vehicle.model ?? '',
          'registrationNumber': vehicle.registrationNumber ?? '',
          'vehicleName': vehicle.fullName,
        };
      }
    }

    // Then check storage
    await _loadVehicleDetailsFromStorage();
    return {
      'manufacturer': _cachedVehicleManufacturer,
      'model': _cachedVehicleModel,
      'registrationNumber': _cachedVehicleRegistration,
      'vehicleName': _cachedVehicleName,
    };
  }

  // ==================== ENERGY GETTERS ====================

  double get batteryPercentage {
    if (_currentLiveData != null && _currentLiveData!.energy.socPercent != null) {
      final soc = _currentLiveData!.energy.socPercent!;
      if (!soc.isNaN && !soc.isInfinite) {
        return soc.clamp(0, 100);
      }
    }
    return 0.0;
  }

  String get chargingStatus {
    if (_currentLiveData == null) return "Charging";
    if (_currentLiveData!.isSuspended) return "SUSPENDED";
    if (_currentLiveData!.isFinishing) return "FINISHING";
    if (_currentLiveData!.isCompleted) return "COMPLETED";
    if (_currentLiveData!.hasError) return "INTERRUPTED";
    final phase = _currentLiveData!.phase;
    if (phase != 'unknown' && phase.isNotEmpty && !_currentLiveData!.isCompleted) {
      return phase.toUpperCase();
    }
    return _currentLiveData!.status.toUpperCase();
  }

  String get formattedElapsedTime => _currentLiveData?.elapsedTime.formatted ?? "00:00:00";

  String get energyConsumed {
    return "${_currentLiveData?.energy.consumedKwh.toStringAsFixed(2) ?? '0'} kWh";
  }

  String get currentPower {
    final powerKw = _currentLiveData?.energy.powerKw ?? 0;
    if (powerKw.isNaN || powerKw.isInfinite) return "0.0 kW";
    if (_currentLiveData?.isCompleted == true ||
        _currentLiveData?.isSuspended == true ||
        _currentLiveData?.isFinishing == true) {
      return "0.0 kW";
    }
    return "${powerKw.toStringAsFixed(1)} kW";
  }

  String get totalCost {
    final cost = _currentLiveData?.billing.currentCost ?? 0;
    if (cost.isNaN || cost.isInfinite) return "₹0.00";
    final currency = _currentLiveData?.billing.currency ?? '₹';
    return "$currency${cost.toStringAsFixed(2)}";
  }

  String get walletBalance {
    final balance = _currentLiveData?.billing.walletBalance ?? 0;
    if (balance.isNaN || balance.isInfinite) return "₹0.00";
    return "₹${balance.toStringAsFixed(2)}";
  }

  // ==================== CHARGER INFO GETTERS ====================

  String get chargerName => _currentLiveData?.charger.name ?? "Charging Unit";
  String get chargerId => _currentLiveData?.charger.id ?? "N/A";
  String get chargerPowerCapacity {
    final power = _currentLiveData?.charger.powerCapacity ?? 0;
    if (power.isNaN || power.isInfinite) return "0 kW";
    return "${power.toStringAsFixed(1)} kW";
  }
  String get chargerStatus => _currentLiveData?.charger.status ?? "unknown";
  String get chargerType => _currentLiveData?.charger.type ?? "AC";

  // ==================== CONNECTOR INFO GETTERS ====================

  String get connectorType => _currentLiveData?.connector.type ?? "Type 2";
  String get connectorName => _currentLiveData?.connector.name ?? "N/A";
  String get connectorStatus => _currentLiveData?.connector.status ?? "unknown";
  bool get isConnectorSuspended => _currentLiveData?.connector.isSuspended ?? false;

  // ==================== OCPP INFO GETTERS ====================

  bool get ocppConnected => _currentLiveData?.ocpp.connected ?? false;
  int get totalMeterReadings => _currentLiveData?.ocpp.meterReadings ?? 0;
  String get ocppTransactionId => _currentLiveData?.ocpp.ocppTransactionId ?? '0';
  int get meterValuesCount => _currentLiveData?.energy.meterValuesCount ?? 0;
  int get pollIntervalMs => _currentLiveData?.pollIntervalMs ?? 10000;

  // ==================== DATE/TIME FORMATTING ====================

  String get formattedStartedAt {
    if (_currentLiveData?.startedAt == null) return "N/A";

    try {
      final dateTime = _currentLiveData!.startedAt;
      // The dateTime is already parsed correctly, just format it for display
      final localTime = dateTime.toLocal();

      String day = localTime.day.toString().padLeft(2, '0');
      String month = localTime.month.toString().padLeft(2, '0');
      String year = localTime.year.toString();

      int hour12 = localTime.hour % 12;
      if (hour12 == 0) hour12 = 12;
      String hour = hour12.toString().padLeft(2, '0');
      String minute = localTime.minute.toString().padLeft(2, '0');
      String second = localTime.second.toString().padLeft(2, '0');

      String amPm = localTime.hour >= 12 ? 'PM' : 'AM';

      return '$day/$month/$year $hour:$minute:$second $amPm';
    } catch (e) {
      print('⚠️ Error formatting startedAt: $e');
      return _currentLiveData?.startedAt.toString() ?? "N/A";
    }
  }

  String get formattedEndedAt {
    if (_currentLiveData?.endedAt == null) return "N/A";
    final dateTime = _currentLiveData!.endedAt!;
    final localTime = dateTime.toLocal();
    return "${localTime.toString().split('.')[0]}";
  }

  // ==================== ESTIMATED TIME ====================

  String getEstimatedTimeToFull() {
    if (_currentLiveData == null) return "Calculating...";
    if (_currentLiveData!.isCompleted ||
        _currentLiveData!.isSuspended ||
        _currentLiveData!.isFinishing) {
      return "Complete";
    }

    try {
      double currentBattery = batteryPercentage;
      if (currentBattery.isNaN || currentBattery.isInfinite) return "Calculating...";

      double targetBattery = 100.0;
      double remainingPercent = targetBattery - currentBattery;
      if (remainingPercent <= 0) return "Complete";

      double chargingRateKw = _currentLiveData?.energy.powerKw ?? 0;
      if (chargingRateKw.isNaN || chargingRateKw.isInfinite) {
        chargingRateKw = _currentLiveData?.charger.powerCapacity ?? 7.4;
      }
      if (chargingRateKw <= 0) {
        chargingRateKw = _currentLiveData?.charger.powerCapacity ?? 7.4;
      }

      double remainingKwh = (remainingPercent * 50) / 100;
      double hoursRemaining = remainingKwh / chargingRateKw;
      double minutesRemaining = hoursRemaining * 60;

      if (minutesRemaining.isNaN || minutesRemaining.isInfinite) return "Calculating...";
      if (minutesRemaining <= 0) return "Complete";
      if (minutesRemaining < 60) {
        return "${minutesRemaining.toStringAsFixed(0)} min";
      } else {
        int hours = minutesRemaining.toInt() ~/ 60;
        int minutes = (minutesRemaining % 60).toInt();
        return "$hours hr $minutes min";
      }
    } catch (e) {
      print('❌ Error calculating estimated time: $e');
      return "Calculating...";
    }
  }

  // ==================== SESSION COMPLETION DATA ====================

  Map<String, dynamic> getSessionCompletionData() {
    if (_currentLiveData == null) return {};
    return {
      'sessionId': _currentLiveData!.sessionId,
      'status': _currentLiveData!.status,
      'phase': _currentLiveData!.phase,
      'startedAt': _currentLiveData!.startedAt.toIso8601String(),
      'endedAt': _currentLiveData!.endedAt?.toIso8601String(),
      'elapsedTime': {
        'seconds': _currentLiveData!.elapsedTime.seconds,
        'minutes': _currentLiveData!.elapsedTime.minutes,
        'formatted': _currentLiveData!.elapsedTime.formatted,
      },
      'energy': {
        'consumedKwh': _currentLiveData!.energy.consumedKwh,
        'powerKw': _currentLiveData!.energy.powerKw,
        'socPercent': _currentLiveData!.energy.socPercent,
      },
      'billing': {
        'currentCost': _currentLiveData!.billing.currentCost,
        'currency': _currentLiveData!.billing.currency,
        'walletBalance': _currentLiveData!.billing.walletBalance,
        'deductedSoFar': _currentLiveData!.billing.deductedSoFar,
        'lastDeduction': _currentLiveData!.billing.lastDeduction,
        'availableBalance': _currentLiveData!.billing.availableBalance,
      },
      'charger': {
        'id': _currentLiveData!.charger.id,
        'name': _currentLiveData!.charger.name,
        'status': _currentLiveData!.charger.status,
      },
      'connector': {
        'id': _currentLiveData!.connector.id,
        'name': _currentLiveData!.connector.name,
        'status': _currentLiveData!.connector.status,
      },
      'station': {
        'id': _currentLiveData!.station?.id,
        'name': _currentLiveData!.station?.name,
        'city': _currentLiveData!.station?.city,
      },
      'vehicle': {
        'manufacturer': _currentLiveData!.vehicle?.manufacturer ?? '',
        'model': _currentLiveData!.vehicle?.model ?? '',
        'registrationNumber': _currentLiveData!.vehicle?.registrationNumber ?? '',
        'fullName': _currentLiveData!.vehicle?.fullName ?? '',
      },
      'isCompletedSummary': _currentLiveData!.isCompletedSummary ?? false,
      'stopReason': _currentLiveData!.stopReason,
      'stopReasonDisplay': _currentLiveData!.stopReasonDisplay,
      'autoStopped': _currentLiveData!.autoStopped ?? false,
      'ocppConnected': _currentLiveData!.ocpp.connected,
      'isSuspended': _currentLiveData!.isSuspended,
      'isFinishing': _currentLiveData!.isFinishing,
    };
  }

  // ==================== FETCH LIVE CHARGING STATUS ====================

// In LiveChargingController - Update fetchLiveChargingStatus

  Future<bool> fetchLiveChargingStatus({int? sessionId}) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final response = await _liveChargingService.getLiveChargingStatus(sessionId: sessionId);

      if (response.success && response.data != null) {
        final data = response.data!;
        _currentLiveData = data;
        _currentSessionId = data.sessionId;

        // ✅ Load vehicle details from storage (same as session ID)
        await _loadVehicleDetailsFromStorage();

        // ✅ Check if it's "preparing" state - this is normal during start
        // Don't treat preparing as terminal or error
        if (data.isPreparing) {
          print('⏳ Charger is preparing - waiting for it to start...');
          _errorMessage = null;
          _pollingAttempts = 0;
          _consecutiveFailures = 0; // Reset failures for preparing state
          _isNoActiveSession = false;
          _shouldPoll = true;
          _pollingStoppedByNetwork = false;

          await _saveSessionData(data);
          _isLoading = false;
          _scheduleDebouncedUpdate();
          return true;
        }

        // ✅ Check if it's "suspended" or "finishing" - these are intermediate states
        if (data.isSuspended || data.isFinishing) {
          print('⏳ Session is ${data.phase} - continuing to monitor...');
          _errorMessage = null;
          _pollingAttempts = 0;
          _consecutiveFailures = 0;
          _isNoActiveSession = false;
          _shouldPoll = true;
          _pollingStoppedByNetwork = false;

          await _saveSessionData(data);
          _isLoading = false;
          _scheduleDebouncedUpdate();
          return true;
        }

        // Check if it's a terminal session (completed or error)
        final isTerminal = data.isCompleted ||
            data.hasError ||
            data.status.toLowerCase() == 'stopped' ||
            data.status.toLowerCase() == 'finished' ||
            data.status.toLowerCase() == 'interrupted';

        if (isTerminal) {
          print('⚠️ Session is terminal (${data.status}) - stopping polling but keeping data');
          _isNoActiveSession = false;
          _errorMessage = null;
          _shouldPoll = false;
          _isLoading = false;

          await _saveSessionData(data);
          stopPolling();
          _scheduleDebouncedUpdate();
          return true;
        }

        // Normal active session (charging state)
        _errorMessage = null;
        _pollingAttempts = 0;
        _consecutiveFailures = 0;
        _isNoActiveSession = false;
        _shouldPoll = true;
        _pollingStoppedByNetwork = false;

        await _saveSessionData(data);

        // ✅ Only log on significant status changes (not on every polling cycle)
        if (_currentLiveData == null || _currentLiveData!.status != data.status) {
          print('✅ Status changed: ${data.status} (Session: ${data.sessionId}, SOC: ${data.energy.socPercent ?? 'N/A'}%)');
        }

        _isLoading = false;
        _scheduleDebouncedUpdate();
        return true;
      } else {
        // ⚠️ Response was not successful
        final shouldRetry = _liveChargingService.shouldRetryAfterFailure(response.message);

        if (shouldRetry) {
          print('⏳ Temporary failure (${response.message}), keeping existing session state');
          _errorMessage = response.message;
          _isNoActiveSession = false;
          _isLoading = false;
          _consecutiveFailures++;

          if (_consecutiveFailures >= maxConsecutiveFailures) {
            print('⚠️ Max consecutive failures reached. Stopping polling.');
            _shouldPoll = false;
            _pollingStoppedByNetwork = true;
            stopPolling();
          }

          _scheduleDebouncedUpdate();
          return false;
        }

        // ❌ No active session - clear everything
        _isNoActiveSession = true;
        _currentLiveData = null;
        _currentSessionId = null;
        _errorMessage = response.message ?? 'No active session';
        _isLoading = false;
        await _clearSessionStorage();
        stopPolling();
        _scheduleDebouncedUpdate();
        return false;
      }
    } catch (e) {
      // 🚨 Exception occurred
      _errorMessage = e.toString();
      _pollingAttempts++;
      _consecutiveFailures++;

      // Check if we should retry based on error type
      final shouldRetry = _liveChargingService.shouldRetryAfterFailure(_errorMessage) ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('SocketException');

      if (!shouldRetry) {
        _consecutiveFailures = maxConsecutiveFailures;
      }

      if (_consecutiveFailures >= maxConsecutiveFailures) {
        print('⚠️ Max consecutive failures reached. Stopping polling.');
        _shouldPoll = false;
        _pollingStoppedByNetwork = true;
        stopPolling();
      }

      _isLoading = false;
      _scheduleDebouncedUpdate();
      return false;
    }
  }

  Future<void> _saveSessionData(LiveChargingData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('session_id', data.sessionId);
      await prefs.setString('session_status', data.status);
      await prefs.setString('session_phase', data.phase);
      await prefs.setString('transaction_id', data.transactionId);
      await prefs.setString('started_at', data.startedAt.toIso8601String());

      if (data.endedAt != null) {
        await prefs.setString('ended_at', data.endedAt!.toIso8601String());
      }
      if (data.stopReason != null) {
        await prefs.setString('stop_reason', data.stopReason!);
      }
      if (data.autoStopped != null) {
        await prefs.setBool('auto_stopped', data.autoStopped!);
      }
      if (data.isCompletedSummary != null) {
        await prefs.setBool('is_completed_summary', data.isCompletedSummary!);
      }

      // ✅ SAVE VEHICLE DATA - Use AuthService with session-specific keys
      if (data.vehicle != null && data.vehicle!.hasData) {
        final vehicle = data.vehicle!;
        final vehicleName = vehicle.fullName;
        final sessionId = data.sessionId;
        final manufacturer = vehicle.manufacturer ?? '';
        final model = vehicle.model ?? '';
        final registration = vehicle.registrationNumber ?? '';
        final vehicleId = vehicle.id;

        // ✅ Save generic vehicle data
        await prefs.setString('vehicle_manufacturer', manufacturer);
        await prefs.setString('vehicle_model', model);
        await prefs.setString('vehicle_registration', registration);
        await prefs.setString('vehicle_name', vehicleName);
        if (vehicleId != null) {
          await prefs.setInt('vehicle_id', vehicleId);
        }

        // ✅ Save session-specific vehicle keys (MOST IMPORTANT)
        await prefs.setString('session_${sessionId}_vehicle_name', vehicleName);
        await prefs.setString('session_${sessionId}_vehicle_manufacturer', manufacturer);
        await prefs.setString('session_${sessionId}_vehicle_model', model);
        await prefs.setString('session_${sessionId}_vehicle_registration', registration);
        if (vehicleId != null) {
          await prefs.setInt('session_${sessionId}_vehicle_id', vehicleId);
        }

        // Update cached vehicle data
        _cachedVehicleName = vehicleName;
        _cachedVehicleManufacturer = manufacturer;
        _cachedVehicleModel = model;
        _cachedVehicleRegistration = registration;
        _cachedVehicleId = vehicleId;
        _vehicleDataLoaded = true;

        // ✅ Only log once per session (no verbose logging)
        print('💾 Vehicle saved: $vehicleName (Session: $sessionId)');
      } else {
        // ✅ If API doesn't return vehicle data, check storage
        final hasExisting = await AuthService.hasVehicleData();
        if (hasExisting) {
          await _loadVehicleDetailsFromStorage();
        } else {
          _vehicleDataLoaded = false;
          _cachedVehicleName = 'Unknown Vehicle';
          _cachedVehicleManufacturer = '';
          _cachedVehicleModel = '';
          _cachedVehicleRegistration = '';
          _cachedVehicleId = null;
        }
      }

      // Save active session status
      if (data.isCharging) {
        await prefs.setInt('active_session_id', data.sessionId);
        await prefs.setString('session_status_active', 'charging');
      } else if (data.shouldShowCompletionSheet) {
        await prefs.remove('active_session_id');
        await prefs.remove('session_status_active');
        await prefs.setBool('has_completed_session', true);
        if (data.isSuspended) await prefs.setBool('is_suspended', true);
        if (data.isFinishing) await prefs.setBool('is_finishing', true);
      }

      // Save active session status
      if (data.isCharging) {
        await prefs.setInt('active_session_id', data.sessionId);
        await prefs.setString('session_status_active', 'charging');
      } else if (data.shouldShowCompletionSheet) {
        await prefs.remove('active_session_id');
        await prefs.remove('session_status_active');
        await prefs.setBool('has_completed_session', true);
        if (data.isSuspended) await prefs.setBool('is_suspended', true);
        if (data.isFinishing) await prefs.setBool('is_finishing', true);
      }

      // Save station info
      if (data.station != null) {
        await prefs.setString('station_name', data.station!.name);
        if (data.station!.city != null) {
          await prefs.setString('station_city', data.station!.city!);
        }
      }

      // Save charger info
      await prefs.setString('charger_name', data.charger.name);
      await prefs.setString('charger_type', data.charger.type);
      await prefs.setDouble('charger_power', data.charger.powerCapacity);
      await prefs.setString('charger_status', data.charger.status);

      // Save connector info
      await prefs.setString('connector_name', data.connector.name);
      await prefs.setString('connector_status', data.connector.status);

      // Save billing info
      await prefs.setDouble('current_cost', data.billing.currentCost);
      await prefs.setDouble('wallet_balance', data.billing.walletBalance);
      await prefs.setString('currency', data.billing.currency);
      if (data.billing.deductedSoFar != null) {
        await prefs.setDouble('deducted_so_far', data.billing.deductedSoFar!);
      }

      // Save energy info
      await prefs.setDouble('consumed_kwh', data.energy.consumedKwh);
      await prefs.setDouble('power_kw', data.energy.powerKw);
      if (data.energy.socPercent != null) {
        await prefs.setDouble('soc_percent', data.energy.socPercent!);
      }

      // Save OCPP info
      await prefs.setBool('ocpp_connected', data.ocpp.connected);
      await prefs.setString('ocpp_transaction_id', data.ocpp.ocppTransactionId);
      await prefs.setInt('meter_readings', data.ocpp.meterReadings);

      print('💾 Session data saved to SharedPreferences');
    } catch (e) {
      print('❌ Error saving session data: $e');
    }
  }

  Future<void> _clearSessionStorage() async {
    try {
      await ChargingSessionService.clearActiveSession();
      await ChargingStatusService.clearChargingStatus();
      await ChargingStatusService.clearSessionId();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('vehicle_manufacturer');
      await prefs.remove('vehicle_model');
      await prefs.remove('vehicle_registration');
      await prefs.remove('vehicle_name');

      // ✅ Clear session-specific vehicle keys
      if (_currentSessionId != null) {
        await prefs.remove('session_${_currentSessionId}_vehicle_name');
        await prefs.remove('session_${_currentSessionId}_vehicle_manufacturer');
        await prefs.remove('session_${_currentSessionId}_vehicle_model');
        await prefs.remove('session_${_currentSessionId}_vehicle_registration');
        await prefs.remove('session_${_currentSessionId}_vehicle_id');
      }

      _vehicleDataLoaded = false;
      _cachedVehicleName = 'Unknown Vehicle';
      _cachedVehicleManufacturer = '';
      _cachedVehicleModel = '';
      _cachedVehicleRegistration = '';
      _cachedVehicleId = null;

      print('🗑️ Session storage cleared');
    } catch (e) {
      print('⚠️ Error clearing session storage: $e');
    }
  }

  // ==================== RECOVER ACTIVE SESSION ====================

  Future<bool> recoverActiveSession() async {
    print('🔄 Attempting to recover active session...');

    try {
      final sessionData = await ActiveSessionService.getActiveSessionFromServer().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏰ Timeout recovering active session');
          return null;
        },
      );

      if (sessionData != null && sessionData['sessionId'] != null) {
        final sessionId = sessionData['sessionId'];
        print('✅ Recovered session ID: $sessionId');

        final success = await fetchLiveChargingStatus(sessionId: sessionId);
        if (success && _currentLiveData != null) {
          print('✅ Session data fetched successfully');
          return true;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final hasCompleted = prefs.getBool('has_completed_session') ?? false;
      if (hasCompleted) {
        print('📌 Found completed session in storage');
        final sessionId = prefs.getInt('session_id');
        if (sessionId != null) {
          final success = await fetchLiveChargingStatus(sessionId: sessionId);
          if (success && _currentLiveData != null && _currentLiveData!.shouldShowCompletionSheet) {
            print('✅ Session data fetched successfully');
            return true;
          }
        }
      }

      print('❌ Could not recover active session');
      return false;
    } catch (e) {
      print('❌ Error recovering session: $e');
      return false;
    }
  }

  // ==================== POLLING ====================

  void startPolling({int? sessionId, Duration? interval}) {
    stopPolling();
    _currentSessionId = sessionId;
    _pollingAttempts = 0;
    _consecutiveFailures = 0;
    _shouldPoll = true;
    _pollingStoppedByNetwork = false;
    _isInBackground = false;

    final pollInterval = interval ?? const Duration(seconds: 10);

    print('🔄 Starting live charging polling (every ${pollInterval.inSeconds} seconds)');
    print('   Session ID: $sessionId');

    // Load vehicle data from storage when polling starts
    _loadVehicleDetailsFromStorage();

    fetchLiveChargingStatus(sessionId: sessionId);

    _pollingTimer = Timer.periodic(pollInterval, (timer) async {
      if (!_shouldPoll) {
        print('⏹️ Polling stopped by flag');
        stopPolling();
        return;
      }

      if (_isInBackground) {
        print('📱 App in background, skipping poll');
        return;
      }

      if (_currentSessionId == null) {
        print('⚠️ No session ID available, stopping polling');
        stopPolling();
        return;
      }

      if (_consecutiveFailures >= maxConsecutiveFailures) {
        print('⚠️ Too many consecutive failures, stopping polling');
        _shouldPoll = false;
        stopPolling();
        return;
      }

      if (_currentLiveData != null && _currentLiveData!.shouldShowCompletionSheet) {
        print('✅ Session is in terminal state, stopping polling');
        stopPolling();
        return;
      }

      // ✅ Fetch status silently (no log spam during polling)
      await fetchLiveChargingStatus(sessionId: _currentSessionId);
      _pollingAttempts++;
    });
  }

  void stopPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) {
      print('⏹️ Stopping live charging polling');
      _pollingTimer!.cancel();
      _pollingTimer = null;
    }
    _debounceTimer?.cancel();
    _pollingAttempts = 0;
    _consecutiveFailures = 0;
    _shouldPoll = false;
  }

  void resetNetworkFailures() {
    _consecutiveFailures = 0;
    _shouldPoll = true;
    _pollingStoppedByNetwork = false;
    _pollingAttempts = 0;
  }

  // ==================== APP LIFECYCLE ====================

  void onAppPaused() {
    _isInBackground = true;
    print('📱 App paused, reducing polling activity');
  }

  void onAppResumed() {
    _isInBackground = false;
    print('📱 App resumed, checking for active session');

    // Reload vehicle data when app resumes
    _loadVehicleDetailsFromStorage();

    if (_currentSessionId != null) {
      fetchLiveChargingStatus(sessionId: _currentSessionId);
    }
  }

  // ==================== DEBOUNCED UPDATE ====================

  void _scheduleDebouncedUpdate() {
    if (_isDisposed) {
      return;
    }

    _debounceTimer?.cancel();

    final now = DateTime.now();
    if (_lastUpdateTime != null) {
      final elapsed = now.difference(_lastUpdateTime!);
      if (elapsed < _minUpdateInterval) {
        _hasPendingUpdate = true;
        _debounceTimer = Timer(_minUpdateInterval - elapsed, () {
          if (_isDisposed) {
            return;
          }
          _lastUpdateTime = DateTime.now();
          _hasPendingUpdate = false;
          _safeNotifyListeners();
        });
        return;
      }
    }

    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (_isDisposed) {
        return;
      }
      _lastUpdateTime = DateTime.now();
      _hasPendingUpdate = false;
      _safeNotifyListeners();
    });
  }

  // ==================== UTILITY METHODS ====================

  Future<bool> isSessionActive() async {
    return await ChargingSessionService.hasActiveSession();
  }

  Future<bool> refreshSessionStatus() async {
    if (_currentSessionId != null) {
      return await fetchLiveChargingStatus(sessionId: _currentSessionId);
    }
    return false;
  }

  /// Refresh vehicle data from storage
  Future<void> refreshVehicleData() async {
    await _loadVehicleDetailsFromStorage();
    _safeNotifyListeners();
  }

  void clearData() {
    _currentLiveData = null;
    _currentSessionId = null;
    _errorMessage = null;
    _pollingAttempts = 0;
    _consecutiveFailures = 0;
    _isNoActiveSession = false;
    _shouldPoll = false;
    _debounceTimer?.cancel();
    _vehicleDataLoaded = false;
    _cachedVehicleName = 'Unknown Vehicle';
    _cachedVehicleManufacturer = '';
    _cachedVehicleModel = '';
    _cachedVehicleRegistration = '';
    _cachedVehicleId = null;
    _safeNotifyListeners();
  }

  bool get isDisposed => _isDisposed;
  bool _isDisposed = false;

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    stopPolling();
    _debounceTimer?.cancel();
    super.dispose();
  }
}