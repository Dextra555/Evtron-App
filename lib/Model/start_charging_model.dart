
class ChargingSessionResponse {
  final bool success;
  final String message;
  final ChargingSessionData? data;

  ChargingSessionResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ChargingSessionResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing ChargingSessionResponse from JSON: $json');

    return ChargingSessionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? ChargingSessionData.fromJson(json['data'])
          : null,
    );
  }
}

class ChargingSessionData {
  final int sessionId;
  final String transactionId;
  final String startedAt;
  final ChargerInfo charger;
  final ConnectorInfo connector;
  final StationInfo station;
  final PricingInfo pricing;
  final UserInfo user;

  ChargingSessionData({
    required this.sessionId,
    required this.transactionId,
    required this.startedAt,
    required this.charger,
    required this.connector,
    required this.station,
    required this.pricing,
    required this.user,
  });

  factory ChargingSessionData.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing ChargingSessionData from JSON: $json');

    return ChargingSessionData(
      sessionId: json['session_id'] ?? 0,
      transactionId: json['transaction_id'] ?? '',
      startedAt: json['started_at'] ?? '',
      charger: ChargerInfo.fromJson(json['charger'] ?? {}),
      connector: ConnectorInfo.fromJson(json['connector'] ?? {}),
      station: StationInfo.fromJson(json['station'] ?? {}),
      pricing: PricingInfo.fromJson(json['pricing'] ?? {}),
      user: UserInfo.fromJson(json['user'] ?? {}),
    );
  }
}

class ChargerInfo {
  final String id;
  final String name;
  final int powerCapacity;
  final String model;

  ChargerInfo({
    required this.id,
    required this.name,
    required this.powerCapacity,
    required this.model,
  });

  factory ChargerInfo.fromJson(Map<String, dynamic> json) {
    return ChargerInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      powerCapacity: json['power_capacity'] ?? 0,
      model: json['model'] ?? '',
    );
  }
}

class ConnectorInfo {
  final int id;
  final String name;
  final String type;
  final String currentType;
  final int maxPower;

  ConnectorInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.currentType,
    required this.maxPower,
  });

  factory ConnectorInfo.fromJson(Map<String, dynamic> json) {
    return ConnectorInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      currentType: json['current_type'] ?? '',
      maxPower: json['max_power'] ?? 0,
    );
  }
}

class StationInfo {
  final int id;
  final String name;
  final LocationInfo location;

  StationInfo({
    required this.id,
    required this.name,
    required this.location,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    return StationInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      location: LocationInfo.fromJson(json['location'] ?? {}),
    );
  }
}

class LocationInfo {
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String latitude;
  final String longitude;

  LocationInfo({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postal_code'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
    );
  }
}

class PricingInfo {
  final int hourlyRate;
  final bool isPeakHour;
  final int peakHourRate;
  final double estimatedCostPerKwh;
  final String currency;

  PricingInfo({
    required this.hourlyRate,
    required this.isPeakHour,
    required this.peakHourRate,
    required this.estimatedCostPerKwh,
    required this.currency,
  });

  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    return PricingInfo(
      hourlyRate: json['hourly_rate'] ?? 0,
      isPeakHour: json['is_peak_hour'] ?? false,
      peakHourRate: json['peak_hour_rate'] ?? 0,
      estimatedCostPerKwh: (json['estimated_cost_per_kwh'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
    );
  }
}

class UserInfo {
  final int id;
  final String name;
  final String walletBalance;

  UserInfo({
    required this.id,
    required this.name,
    required this.walletBalance,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      walletBalance: json['wallet_balance'] ?? '0.00',
    );
  }
}

class StartChargingRequest {
  final String chargerId;  // Changed from int to String

  StartChargingRequest({
    required this.chargerId,  // Now accepts String
  });

  Map<String, dynamic> toJson() {
    return {
      'charger_id': chargerId,  // Sending as string
    };
  }
}