// lib/Model/live_charging_model.dart

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
    return LiveChargingResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? LiveChargingData.fromJson(json['data']) : null,
      message: json['message'],
    );
  }
}

class LiveChargingData {
  final int sessionId;
  final String transactionId;
  final String status;
  final DateTime startedAt;
  final ElapsedTime elapsedTime;
  final Energy energy;
  final Cost cost;
  final ChargerInfo charger;
  final ConnectorInfo connector;
  final StationInfo station;
  final OcppInfo? ocpp;  // Added OCPP info

  LiveChargingData({
    required this.sessionId,
    required this.transactionId,
    required this.status,
    required this.startedAt,
    required this.elapsedTime,
    required this.energy,
    required this.cost,
    required this.charger,
    required this.connector,
    required this.station,
    this.ocpp,
  });

  factory LiveChargingData.fromJson(Map<String, dynamic> json) {
    return LiveChargingData(
      sessionId: json['session_id'] ?? 0,
      transactionId: json['transaction_id'] ?? '',
      status: json['status'] ?? 'unknown',
      startedAt: DateTime.parse(json['started_at'] ?? DateTime.now().toIso8601String()),
      elapsedTime: ElapsedTime.fromJson(json['elapsed_time'] ?? {}),
      energy: Energy.fromJson(json['energy'] ?? {}),
      cost: Cost.fromJson(json['cost'] ?? {}),
      charger: ChargerInfo.fromJson(json['charger'] ?? {}),
      connector: ConnectorInfo.fromJson(json['connector'] ?? {}),
      station: StationInfo.fromJson(json['station'] ?? {}),
      ocpp: json['ocpp'] != null ? OcppInfo.fromJson(json['ocpp']) : null,
    );
  }
}

class ElapsedTime {
  final double seconds;
  final double minutes;
  final String formatted;

  ElapsedTime({
    required this.seconds,
    required this.minutes,
    required this.formatted,
  });

  factory ElapsedTime.fromJson(Map<String, dynamic> json) {
    return ElapsedTime(
      seconds: (json['seconds'] ?? 0).toDouble(),
      minutes: (json['minutes'] ?? 0).toDouble(),
      formatted: json['formatted'] ?? '00:00:00',
    );
  }
}

class Energy {
  final double consumedKwh;
  final double powerKw;
  final int meterValuesCount;  // Added this field

  Energy({
    required this.consumedKwh,
    required this.powerKw,
    required this.meterValuesCount,
  });

  factory Energy.fromJson(Map<String, dynamic> json) {
    return Energy(
      consumedKwh: (json['consumed_kwh'] ?? 0).toDouble(),
      powerKw: (json['power_kw'] ?? 0).toDouble(),
      meterValuesCount: json['meter_values_count'] ?? 0,
    );
  }
}

class Cost {
  final double total;
  final String currency;

  Cost({
    required this.total,
    required this.currency,
  });

  factory Cost.fromJson(Map<String, dynamic> json) {
    return Cost(
      total: (json['total'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
    );
  }
}

class ChargerInfo {
  final String id;
  final String name;
  final double powerCapacity;
  final String status;  // Added status field

  ChargerInfo({
    required this.id,
    required this.name,
    required this.powerCapacity,
    required this.status,
  });

  factory ChargerInfo.fromJson(Map<String, dynamic> json) {
    return ChargerInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      powerCapacity: (json['power_capacity'] ?? 0).toDouble(),
      status: json['status'] ?? 'unknown',
    );
  }
}

class ConnectorInfo {
  final int id;
  final String name;
  final String type;
  final String status;  // Added status field

  ConnectorInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
  });

  factory ConnectorInfo.fromJson(Map<String, dynamic> json) {
    return ConnectorInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? 'unknown',
    );
  }
}

class StationInfo {
  final int id;
  final String name;

  StationInfo({
    required this.id,
    required this.name,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    return StationInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class OcppInfo {
  final bool connected;
  final int totalMeterReadings;

  OcppInfo({
    required this.connected,
    required this.totalMeterReadings,
  });

  factory OcppInfo.fromJson(Map<String, dynamic> json) {
    return OcppInfo(
      connected: json['connected'] ?? false,
      totalMeterReadings: json['total_meter_readings'] ?? 0,
    );
  }
}