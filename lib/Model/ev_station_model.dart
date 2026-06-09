// lib/Model/ev_station_model.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';

class ConnectorPort {
  final String type;
  final String status;
  final int maxPower;

  ConnectorPort({
    required this.type,
    required this.status,
    required this.maxPower,
  });

  factory ConnectorPort.fromJson(Map<String, dynamic> json) {
    return ConnectorPort(
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      maxPower: json['max_power'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'status': status,
      'max_power': maxPower,
    };
  }
}

class EVStation {
  final int id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String? distanceFromUser;
  final String status;
  final String stationType;
  final bool is247;
  final double estimatedChargingPrice;
  final int totalChargers;
  final int availableChargers;
  final List<ConnectorPort> connectorPorts;
  final List<String> amenities;
  final bool realTimeAvailability;
  final DateTime createdAt;
  final double rating; // Keep this as final property

  EVStation({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.distanceFromUser,
    required this.status,
    required this.stationType,
    required this.is247,
    required this.estimatedChargingPrice,
    required this.totalChargers,
    required this.availableChargers,
    required this.connectorPorts,
    required this.amenities,
    required this.realTimeAvailability,
    required this.createdAt,
    this.rating = 0.0, // Default value
  });

  // Helper getter for LatLng
  LatLng get location => LatLng(latitude, longitude);

  // Helper getter for vicinity (using full address)
  String get vicinity => fullAddress;

  // REMOVE THIS DUPLICATE GETTER - it's causing the conflict
  // double get rating => 4.5; // DELETE THIS LINE

  factory EVStation.fromJson(Map<String, dynamic> json) {
    // Debug print to see what we're parsing
    print('Parsing station: ${json['station_name']}');
    print('Connector ports: ${json['connector_ports']}');
    print('Amenities: ${json['amenities']}');

    return EVStation(
      id: json['id'] ?? 0,
      name: json['station_name'] ?? 'Unknown Station',
      fullAddress: json['full_address'] ?? 'Address not available',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0,
      distanceFromUser: json['distance_from_user']?.toString(),
      status: json['status'] ?? 'unknown',
      stationType: json['station_type'] ?? 'public',
      is247: json['is_24_7'] ?? false,
      estimatedChargingPrice: double.tryParse(json['estimated_charging_price']?.toString() ?? '0') ?? 0,
      totalChargers: json['total_chargers'] ?? 0,
      availableChargers: json['available_chargers'] ?? 0,
      connectorPorts: (json['connector_ports'] as List?)
          ?.map((port) => ConnectorPort.fromJson(port))
          .toList() ?? [],
      amenities: (json['amenities'] as List?)
          ?.map((item) => item.toString())
          .toList() ?? [],
      realTimeAvailability: json['real_time_availability'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      rating: (json['rating'] ?? 0.0).toDouble(), // Parse rating from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'station_name': name,
      'full_address': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'distance_from_user': distanceFromUser,
      'status': status,
      'station_type': stationType,
      'is_24_7': is247,
      'estimated_charging_price': estimatedChargingPrice,
      'total_chargers': totalChargers,
      'available_chargers': availableChargers,
      'connector_ports': connectorPorts.map((port) => port.toJson()).toList(),
      'amenities': amenities,
      'real_time_availability': realTimeAvailability,
      'created_at': createdAt.toIso8601String(),
      'rating': rating,
    };
  }
}
