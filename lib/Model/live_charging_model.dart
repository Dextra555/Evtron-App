class LiveChargingResponse {
  final bool success;
  final LiveChargingData? data;
  final String? message;

  LiveChargingResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory LiveChargingResponse.fromJson(Map<String, dynamic> json) {
    try {
      final success = json['success'] ?? false;
      final message = json['message'] ?? json['msg'] ?? json['error'];

      LiveChargingData? data;
      if (json['data'] != null && json['data'] is Map<String, dynamic>) {
        data = LiveChargingData.fromJson(json['data']);
      }

      return LiveChargingResponse(
        success: success,
        data: data,
        message: message,
      );
    } catch (e) {
      print('❌ Error parsing LiveChargingResponse: $e');
      return LiveChargingResponse(
        success: false,
        data: null,
        message: 'Error parsing response: $e',
      );
    }
  }

  factory LiveChargingResponse.error(String message) {
    return LiveChargingResponse(
      success: false,
      data: null,
      message: message,
    );
  }

  factory LiveChargingResponse.success(LiveChargingData data) {
    return LiveChargingResponse(
      success: true,
      data: data,
      message: null,
    );
  }
}

class LiveChargingData {
  final int sessionId;
  final String transactionId;
  final String status;
  final String phase;
  final DateTime startedAt;
  final DateTime? endedAt;
  final ElapsedTime elapsedTime;
  final Energy energy;
  final Billing billing;
  final ChargerInfo charger;
  final ConnectorInfo connector;
  final StationInfo? station;
  final VehicleInfo? vehicle;
  final OcppInfo ocpp;
  final int pollIntervalMs;
  final bool? isCompletedSummary;
  final String? stopReason;
  final bool? autoStopped;
  final String? errorDetails;

  LiveChargingData({
    required this.sessionId,
    required this.transactionId,
    required this.status,
    required this.phase,
    required this.startedAt,
    this.endedAt,
    required this.elapsedTime,
    required this.energy,
    required this.billing,
    required this.charger,
    required this.connector,
    this.station,
    this.vehicle,
    required this.ocpp,
    required this.pollIntervalMs,
    this.isCompletedSummary,
    this.stopReason,
    this.autoStopped,
    this.errorDetails,
  });

  factory LiveChargingData.fromJson(Map<String, dynamic> json) {
    try {
      return LiveChargingData(
        sessionId: _safeToInt(json['session_id']),
        transactionId: json['transaction_id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'unknown',
        phase: json['phase']?.toString() ?? 'unknown',
        startedAt: _parseDateTime(json['started_at']),
        endedAt: json['ended_at'] != null ? _parseDateTime(json['ended_at']) : null,
        elapsedTime: ElapsedTime.fromJson(json['elapsed_time'] ?? {}),
        energy: Energy.fromJson(json['energy'] ?? {}),
        billing: Billing.fromJson(json['billing'] ?? {}),
        charger: ChargerInfo.fromJson(json['charger'] ?? {}),
        connector: ConnectorInfo.fromJson(json['connector'] ?? {}),
        station: json['station'] != null && json['station'] is Map<String, dynamic>
            ? StationInfo.fromJson(json['station'])
            : null,
        vehicle: json['vehicle'] != null && json['vehicle'] is Map<String, dynamic>
            ? VehicleInfo.fromJson(json['vehicle'])
            : null,
        ocpp: OcppInfo.fromJson(json['ocpp'] ?? {}),
        pollIntervalMs: _safeToInt(json['poll_interval_ms'], defaultValue: 10000),
        isCompletedSummary: json['is_completed_summary'] as bool?,
        stopReason: json['stop_reason']?.toString(),
        autoStopped: json['auto_stopped'] as bool?,
        errorDetails: json['error_details']?.toString(),
      );
    } catch (e) {
      print('❌ Error parsing LiveChargingData: $e');
      return LiveChargingData(
        sessionId: 0,
        transactionId: '',
        status: 'error',
        phase: 'unknown',
        startedAt: DateTime.now(),
        endedAt: null,
        elapsedTime: ElapsedTime.zero(),
        energy: Energy.zero(),
        billing: Billing.zero(),
        charger: ChargerInfo.empty(),
        connector: ConnectorInfo.empty(),
        station: null,
        vehicle: null,
        ocpp: OcppInfo.empty(),
        pollIntervalMs: 10000,
        isCompletedSummary: false,
        stopReason: null,
        autoStopped: false,
        errorDetails: 'Error parsing data: $e',
      );
    }
  }

  static int _safeToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return defaultValue;
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final doubleParsed = double.tryParse(value);
      if (doubleParsed != null && !doubleParsed.isNaN && !doubleParsed.isInfinite) {
        return doubleParsed.toInt();
      }
      return defaultValue;
    }
    if (value is num) {
      if (value is double && (value.isNaN || value.isInfinite)) return defaultValue;
      return value.toInt();
    }
    return defaultValue;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('⚠️ Error parsing DateTime: $e');
        return DateTime.now();
      }
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        print('⚠️ Error parsing DateTime from int: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // ==================== STATUS CHECKERS ====================

  bool get isActive {
    final activeStatuses = ['active', 'charging', 'preparing', 'starting', 'pending', 'initializing', 'requesting'];
    return activeStatuses.contains(status.toLowerCase()) ||
        activeStatuses.contains(phase.toLowerCase());
  }

  bool get isCharging {
    return status.toLowerCase() == 'active' &&
        phase.toLowerCase() == 'charging';
  }

  bool get isPreparing {
    final preparingStatuses = ['preparing', 'starting', 'pending', 'initializing', 'requesting'];
    final activeStatuses = ['active', 'charging'];
    return preparingStatuses.contains(status.toLowerCase()) ||
        preparingStatuses.contains(phase.toLowerCase()) ||
        (status.toLowerCase() == 'active' && phase.toLowerCase() == 'preparing');
  }

  bool get isSuspended {
    return phase.toLowerCase() == 'suspended' ||
        status.toLowerCase() == 'suspended';
  }

  bool get isFinishing {
    return phase.toLowerCase() == 'finishing' ||
        status.toLowerCase() == 'finishing';
  }

  bool get isCompleted {
    return status.toLowerCase() == 'completed' ||
        status.toLowerCase() == 'stopped' ||
        status.toLowerCase() == 'finished' ||
        status.toLowerCase() == 'done' ||
        status.toLowerCase() == 'interrupted' ||
        isCompletedSummary == true;
  }

  bool get hasError {
    final errorStatuses = ['error', 'failed', 'timeout', 'interrupted'];
    return errorStatuses.contains(status.toLowerCase());
  }

  bool get shouldShowCompletionSheet {
    return isCompleted ||
        isSuspended ||
        isFinishing ||
        hasError ||
        isCompletedSummary == true;
  }

  // ==================== DISPLAY GETTERS ====================

  String get displayStatus {
    if (isSuspended) return 'SUSPENDED';
    if (isFinishing) return 'FINISHING';
    if (isCompleted) return 'COMPLETED';
    if (hasError) return 'INTERRUPTED';
    if (phase != 'unknown' && phase.isNotEmpty) {
      return phase.toUpperCase();
    }
    return status.toUpperCase();
  }

  String get statusIcon {
    if (isCharging) return '⚡';
    if (isPreparing) return '🔄';
    if (isSuspended) return '⏸️';
    if (isFinishing) return '⏳';
    if (isCompleted) return '✅';
    if (hasError) return '❌';
    return '📌';
  }

  String get stopReasonDisplay {
    if (stopReason == null) {
      if (isSuspended) return 'Charging Suspended';
      if (isFinishing) return 'Charging Finishing';
      return 'Charging Completed';
    }

    switch (stopReason) {
      case 'local':
      case 'remote':
        return 'Charging Completed';
      case 'EmergencyStop':
        return 'Emergency Stop';
      case 'DeAuthorized':
        return 'Session DeAuthorized';
      case 'ocpp_connector_faulted':
        return 'Charger Fault — Charging Stopped';
      case 'ocpp_connector_available':
        return 'Vehicle Disconnected';
      case 'charger_disconnected':
        return 'Charger Offline / Power Failure';
      default:
        if (isSuspended) return 'Charging Suspended';
        if (isFinishing) return 'Charging Finishing';
        return 'Charging Stopped';
    }
  }

  String get stopReasonIcon {
    if (isSuspended) return '⏸️';
    if (isFinishing) return '⏳';
    if (stopReason == null) return '✅';

    switch (stopReason) {
      case 'local':
      case 'remote':
        return '✅';
      case 'EmergencyStop':
        return '⚠️';
      case 'DeAuthorized':
        return '🔒';
      case 'ocpp_connector_faulted':
        return '🔧';
      case 'ocpp_connector_available':
        return '🔌';
      case 'charger_disconnected':
        return '📡';
      default:
        return '⏹️';
    }
  }

  String get completionMessage {
    if (isSuspended) return 'Charging Suspended';
    if (isFinishing) return 'Charging Finishing';
    if (isCompleted) {
      if (stopReason != null) {
        return stopReasonDisplay;
      }
      return 'Charging Completed';
    }
    if (hasError) {
      return 'Charging Interrupted';
    }
    return 'Session Ended';
  }

  bool get isOcppConnected {
    return ocpp.connected;
  }

  String get ocppStatusMessage {
    if (ocpp.connected) {
      return 'Connected';
    }
    return 'Disconnected';
  }

  bool get isChargerAvailable {
    return charger.status.toLowerCase() == 'available';
  }

  bool get isConnectorAvailable {
    return connector.status.toLowerCase() == 'available' ||
        connector.status.toLowerCase() == 'charging';
  }

  // ==================== VEHICLE HELPERS ====================

  String get vehicleManufacturer => vehicle?.manufacturer ?? '';
  String get vehicleModel => vehicle?.model ?? '';
  String get vehicleRegistration => vehicle?.registrationNumber ?? '';

  String get vehicleFullName {
    if (vehicle != null) {
      return vehicle!.fullName;
    }
    return 'Unknown Vehicle';
  }

  bool get hasVehicleData => vehicle != null && vehicle!.hasData;

  LiveChargingData copyWith({
    int? sessionId,
    String? transactionId,
    String? status,
    String? phase,
    DateTime? startedAt,
    DateTime? endedAt,
    ElapsedTime? elapsedTime,
    Energy? energy,
    Billing? billing,
    ChargerInfo? charger,
    ConnectorInfo? connector,
    StationInfo? station,
    VehicleInfo? vehicle,
    OcppInfo? ocpp,
    int? pollIntervalMs,
    bool? isCompletedSummary,
    String? stopReason,
    bool? autoStopped,
    String? errorDetails,
  }) {
    return LiveChargingData(
      sessionId: sessionId ?? this.sessionId,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      energy: energy ?? this.energy,
      billing: billing ?? this.billing,
      charger: charger ?? this.charger,
      connector: connector ?? this.connector,
      station: station ?? this.station,
      vehicle: vehicle ?? this.vehicle,
      ocpp: ocpp ?? this.ocpp,
      pollIntervalMs: pollIntervalMs ?? this.pollIntervalMs,
      isCompletedSummary: isCompletedSummary ?? this.isCompletedSummary,
      stopReason: stopReason ?? this.stopReason,
      autoStopped: autoStopped ?? this.autoStopped,
      errorDetails: errorDetails ?? this.errorDetails,
    );
  }
}

class ElapsedTime {
  final int seconds;
  final int minutes;
  final String formatted;

  ElapsedTime({
    required this.seconds,
    required this.minutes,
    required this.formatted,
  });

  factory ElapsedTime.fromJson(Map<String, dynamic> json) {
    try {
      final seconds = _safeToInt(json['seconds']);
      final minutes = _safeToInt(json['minutes']);
      final formatted = json['formatted']?.toString() ?? _formatDuration(seconds);

      return ElapsedTime(
        seconds: seconds,
        minutes: minutes,
        formatted: formatted,
      );
    } catch (e) {
      print('⚠️ Error parsing ElapsedTime: $e');
      return ElapsedTime.zero();
    }
  }

  factory ElapsedTime.zero() {
    return ElapsedTime(
      seconds: 0,
      minutes: 0,
      formatted: '00:00:00',
    );
  }

  static int _safeToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return defaultValue;
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final doubleParsed = double.tryParse(value);
      if (doubleParsed != null && !doubleParsed.isNaN && !doubleParsed.isInfinite) {
        return doubleParsed.toInt();
      }
      return defaultValue;
    }
    if (value is num) {
      if (value is double && (value.isNaN || value.isInfinite)) return defaultValue;
      return value.toInt();
    }
    return defaultValue;
  }

  static String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00:00';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Duration toDuration() {
    return Duration(seconds: seconds);
  }
}

class Energy {
  final double consumedKwh;
  final double powerKw;
  final double? socPercent;
  final int meterValuesCount;

  Energy({
    required this.consumedKwh,
    required this.powerKw,
    this.socPercent,
    this.meterValuesCount = 0,
  });

  factory Energy.fromJson(Map<String, dynamic> json) {
    try {
      return Energy(
        consumedKwh: _safeToDouble(json['consumed_kwh']),
        powerKw: _safeToDouble(json['power_kw']),
        socPercent: _safeToDoubleNullable(json['soc_percent']),
        meterValuesCount: _safeToInt(json['meter_values_count']),
      );
    } catch (e) {
      print('⚠️ Error parsing Energy: $e');
      return Energy.zero();
    }
  }

  factory Energy.zero() {
    return Energy(
      consumedKwh: 0.0,
      powerKw: 0.0,
      socPercent: null,
      meterValuesCount: 0,
    );
  }

  static double _safeToDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return defaultValue;
      return value;
    }
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && !parsed.isNaN && !parsed.isInfinite) return parsed;
      return defaultValue;
    }
    if (value is num) {
      if (value is double && (value.isNaN || value.isInfinite)) return defaultValue;
      return value.toDouble();
    }
    return defaultValue;
  }

  static double? _safeToDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return null;
      return value;
    }
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && !parsed.isNaN && !parsed.isInfinite) return parsed;
      return null;
    }
    if (value is num) {
      if (value is double && (value.isNaN || value.isInfinite)) return null;
      return value.toDouble();
    }
    return null;
  }

  static int _safeToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return defaultValue;
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final doubleParsed = double.tryParse(value);
      if (doubleParsed != null && !doubleParsed.isNaN && !doubleParsed.isInfinite) {
        return doubleParsed.toInt();
      }
      return defaultValue;
    }
    if (value is num) {
      if (value is double && (value.isNaN || value.isInfinite)) return defaultValue;
      return value.toInt();
    }
    return defaultValue;
  }

  String get formattedEnergy => '${consumedKwh.toStringAsFixed(2)} kWh';
  String get formattedPower => '${powerKw.toStringAsFixed(1)} kW';
  String get formattedSoc => socPercent != null ? '${socPercent!.toStringAsFixed(0)}%' : 'N/A';
}

class Billing {
  final double currentCost;
  final String currency;
  final double walletBalance;
  final double? deductedSoFar;
  final double? lastDeduction;
  final double? creditLimit;
  final double? availableBalance;

  Billing({
    required this.currentCost,
    required this.currency,
    required this.walletBalance,
    this.deductedSoFar,
    this.lastDeduction,
    this.creditLimit,
    this.availableBalance,
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    try {
      return Billing(
        currentCost: _safeToDouble(json['current_cost']),
        currency: json['currency']?.toString() ?? 'INR',
        walletBalance: _safeToDouble(json['wallet_balance']),
        deductedSoFar: json['deducted_so_far'] != null ? _safeToDouble(json['deducted_so_far']) : null,
        lastDeduction: json['last_deduction'] != null ? _safeToDouble(json['last_deduction']) : null,
        creditLimit: json['credit_limit'] != null ? _safeToDouble(json['credit_limit']) : null,
        availableBalance: json['available_balance'] != null ? _safeToDouble(json['available_balance']) : null,
      );
    } catch (e) {
      print('⚠️ Error parsing Billing: $e');
      return Billing.zero();
    }
  }

  factory Billing.zero() {
    return Billing(
      currentCost: 0.0,
      currency: 'INR',
      walletBalance: 0.0,
      deductedSoFar: null,
      lastDeduction: null,
      creditLimit: null,
      availableBalance: null,
    );
  }

  static double _safeToDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return defaultValue;
      return value;
    }
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && !parsed.isNaN && !parsed.isInfinite) return parsed;
      return defaultValue;
    }
    if (value is num) {
      if (value is double && (value.isNaN || value.isInfinite)) return defaultValue;
      return value.toDouble();
    }
    return defaultValue;
  }

  String get formattedCurrentCost => '$currency${currentCost.toStringAsFixed(2)}';
  String get formattedWalletBalance => '$currency${walletBalance.toStringAsFixed(2)}';
  String get formattedDeductedSoFar {
    if (deductedSoFar != null) {
      return '$currency${deductedSoFar!.toStringAsFixed(2)}';
    }
    return '$currency.00';
  }
  String get formattedAvailableBalance {
    if (availableBalance != null) {
      return '$currency${availableBalance!.toStringAsFixed(2)}';
    }
    return formattedWalletBalance;
  }
  bool get hasCreditLimit => creditLimit != null && creditLimit! > 0;
  bool get hasAvailableBalance => availableBalance != null && availableBalance != walletBalance;
}

class ChargerInfo {
  final String id;
  final String name;
  final String type;
  final double powerCapacity;
  final String status;

  ChargerInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.powerCapacity,
    required this.status,
  });

  factory ChargerInfo.fromJson(Map<String, dynamic> json) {
    try {
      return ChargerInfo(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? 'AC',
        powerCapacity: _safeToDouble(json['power_capacity']),
        status: json['status']?.toString() ?? 'unknown',
      );
    } catch (e) {
      print('⚠️ Error parsing ChargerInfo: $e');
      return ChargerInfo.empty();
    }
  }

  factory ChargerInfo.empty() {
    return ChargerInfo(
      id: '',
      name: '',
      type: 'AC',
      powerCapacity: 0.0,
      status: 'unknown',
    );
  }

  static double _safeToDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return defaultValue;
      return value;
    }
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && !parsed.isNaN && !parsed.isInfinite) return parsed;
      return defaultValue;
    }
    if (value is num) {
      if (value is double && (value.isNaN || value.isInfinite)) return defaultValue;
      return value.toDouble();
    }
    return defaultValue;
  }

  bool get isAvailable => status.toLowerCase() == 'available';
  bool get isOffline => status.toLowerCase() == 'offline' || status.toLowerCase() == 'disconnected';
  String get formattedPower => '${powerCapacity.toStringAsFixed(1)} kW';
}

class ConnectorInfo {
  final int id;
  final String uid;
  final String name;
  final String type;
  final String status;

  ConnectorInfo({
    required this.id,
    required this.uid,
    required this.name,
    required this.type,
    required this.status,
  });

  factory ConnectorInfo.fromJson(Map<String, dynamic> json) {
    try {
      return ConnectorInfo(
        id: _safeToInt(json['id']),
        uid: json['uid']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        status: json['status']?.toString() ?? 'unknown',
      );
    } catch (e) {
      print('⚠️ Error parsing ConnectorInfo: $e');
      return ConnectorInfo.empty();
    }
  }

  factory ConnectorInfo.empty() {
    return ConnectorInfo(
      id: 0,
      uid: '',
      name: '',
      type: '',
      status: 'unknown',
    );
  }

  static int _safeToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return defaultValue;
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final doubleParsed = double.tryParse(value);
      if (doubleParsed != null && !doubleParsed.isNaN && !doubleParsed.isInfinite) {
        return doubleParsed.toInt();
      }
      return defaultValue;
    }
    if (value is num) {
      if (value is double && (value.isNaN || value.isInfinite)) return defaultValue;
      return value.toInt();
    }
    return defaultValue;
  }

  bool get isAvailable => status.toLowerCase() == 'available';
  bool get isCharging => status.toLowerCase() == 'charging';
  bool get isSuspended => status.toLowerCase() == 'suspendedev' ||
      status.toLowerCase() == 'suspended';
}

class StationInfo {
  final int id;
  final String name;
  final String? city;

  StationInfo({
    required this.id,
    required this.name,
    this.city,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    try {
      return StationInfo(
        id: _safeToInt(json['id']),
        name: json['name']?.toString() ?? '',
        city: json['city']?.toString(),
      );
    } catch (e) {
      print('⚠️ Error parsing StationInfo: $e');
      return StationInfo.empty();
    }
  }

  factory StationInfo.empty() {
    return StationInfo(
      id: 0,
      name: '',
      city: null,
    );
  }

  static int _safeToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return defaultValue;
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final doubleParsed = double.tryParse(value);
      if (doubleParsed != null && !doubleParsed.isNaN && !doubleParsed.isInfinite) {
        return doubleParsed.toInt();
      }
      return defaultValue;
    }
    if (value is num) {
      if (value is double && (value.isNaN || value.isInfinite)) return defaultValue;
      return value.toInt();
    }
    return defaultValue;
  }

  String get fullLocation => city != null && city!.isNotEmpty ? '$name, $city' : name;
}

class VehicleInfo {
  final int? id;
  final String? manufacturer;
  final String? model;
  final String? registrationNumber;

  VehicleInfo({
    this.id,
    this.manufacturer,
    this.model,
    this.registrationNumber,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    try {
      final manufacturer = json['manufacturer']?.toString() ?? '';
      final model = json['model']?.toString() ?? '';
      final registration = json['registration_number']?.toString() ??
          json['registrationNumber']?.toString() ?? '';

      return VehicleInfo(
        id: json['id'] as int?,
        manufacturer: manufacturer.isNotEmpty ? manufacturer : null,
        model: model.isNotEmpty ? model : null,
        registrationNumber: registration.isNotEmpty ? registration : null,
      );
    } catch (e) {
      print('⚠️ Error parsing VehicleInfo: $e');
      return VehicleInfo(
        id: null,
        manufacturer: null,
        model: null,
        registrationNumber: null,
      );
    }
  }

  String get fullName {
    final m = manufacturer ?? '';
    final mdl = model ?? '';
    if (m.isNotEmpty && mdl.isNotEmpty) {
      return '$m $mdl'.trim();
    }
    if (m.isNotEmpty) return m;
    if (mdl.isNotEmpty) return mdl;
    return 'Unknown Vehicle';
  }

  bool get hasData {
    return (manufacturer != null && manufacturer!.isNotEmpty) ||
        (model != null && model!.isNotEmpty) ||
        (registrationNumber != null && registrationNumber!.isNotEmpty);
  }

  String get displayRegistration => (registrationNumber != null && registrationNumber!.isNotEmpty)
      ? registrationNumber!
      : 'N/A';
}

class OcppInfo {
  final bool connected;
  final String ocppTransactionId;
  final int meterReadings;

  OcppInfo({
    required this.connected,
    required this.ocppTransactionId,
    required this.meterReadings,
  });

  factory OcppInfo.fromJson(Map<String, dynamic> json) {
    try {
      return OcppInfo(
        connected: json['connected'] ?? false,
        ocppTransactionId: json['ocpp_transaction_id']?.toString() ?? '0',
        meterReadings: _safeToInt(json['meter_readings']),
      );
    } catch (e) {
      print('⚠️ Error parsing OcppInfo: $e');
      return OcppInfo.empty();
    }
  }

  factory OcppInfo.empty() {
    return OcppInfo(
      connected: false,
      ocppTransactionId: '0',
      meterReadings: 0,
    );
  }

  static int _safeToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return defaultValue;
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final doubleParsed = double.tryParse(value);
      if (doubleParsed != null && !doubleParsed.isNaN && !doubleParsed.isInfinite) {
        return doubleParsed.toInt();
      }
      return defaultValue;
    }
    if (value is num) {
      if (value is double && (value.isNaN || value.isInfinite)) return defaultValue;
      return value.toInt();
    }
    return defaultValue;
  }

  bool get isConnected => connected;
  String get statusMessage => connected ? 'Connected' : 'Disconnected';
  String get statusColor => connected ? 'green' : 'red';
}