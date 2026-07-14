import 'package:google_maps_flutter/google_maps_flutter.dart';

class EVStation {
  final int id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
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
  final double? rating;
  final int? activeChargers;
  final int? inactiveChargers;
  final Map<String, int>? chargerStatusCounts;

  EVStation({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.stationType,
    required this.is247,
    required this.estimatedChargingPrice,
    required this.totalChargers,
    required this.availableChargers,
    this.connectorPorts = const [],
    this.amenities = const [],
    required this.realTimeAvailability,
    required this.createdAt,
    this.rating,
    this.activeChargers,
    this.inactiveChargers,
    this.chargerStatusCounts,
  });

  factory EVStation.fromJson(Map<String, dynamic> json) {
    // Parse connector ports
    List<ConnectorPort> ports = [];
    if (json['connector_ports'] != null && json['connector_ports'] is List) {
      ports = (json['connector_ports'] as List)
          .map((port) => ConnectorPort.fromJson(port))
          .toList();
    }

    // Parse charger status counts
    Map<String, int>? statusCounts;
    if (json['charger_status_counts'] != null && json['charger_status_counts'] is Map) {
      statusCounts = {};
      (json['charger_status_counts'] as Map).forEach((key, value) {
        statusCounts![key.toString()] = (value as int);
      });
    }

    return EVStation(
      id: json['id'] ?? 0,
      name: json['station_name'] ?? 'EV Station',
      fullAddress: json['full_address'] ?? 'Address not available',
      latitude: double.parse(json['latitude']?.toString() ?? '0.0'),
      longitude: double.parse(json['longitude']?.toString() ?? '0.0'),
      status: json['status'] ?? 'active',
      stationType: json['station_type'] ?? 'public',
      is247: json['is_24_7'] ?? false,
      estimatedChargingPrice: double.parse(json['estimated_charging_price']?.toString() ?? '0.0'),
      totalChargers: json['total_chargers'] ?? 0,
      availableChargers: json['available_chargers'] ?? 0,
      connectorPorts: ports,
      amenities: (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      realTimeAvailability: json['real_time_availability'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      rating: json['rating']?.toDouble(),
      activeChargers: json['active_chargers'],
      inactiveChargers: json['inactive_chargers'],
      chargerStatusCounts: statusCounts,
    );
  }

  // Helper method to get connector status counts
  Map<String, int> getConnectorStatusCounts() {
    Map<String, int> statusCounts = {};
    for (var port in connectorPorts) {
      statusCounts[port.status] = (statusCounts[port.status] ?? 0) + 1;
    }
    return statusCounts;
  }

  // Helper method to determine overall availability status
  String getOverallStatus() {
    if (availableChargers > 0) {
      return 'available';
    }

    if (connectorPorts.isEmpty) {
      return 'unavailable';
    }

    bool hasAvailable = connectorPorts.any(
      (port) => port.status.toLowerCase() == 'available',
    );
    bool hasFault = connectorPorts.any(
      (port) => port.status.toLowerCase() == 'fault' || port.status.toLowerCase() == 'offline',
    );
    bool hasBusy = connectorPorts.any(
      (port) => port.status.toLowerCase() == 'busy' || port.status.toLowerCase() == 'charging',
    );

    if (hasAvailable) return 'available';
    if (hasBusy) return 'busy';
    if (hasFault) return 'fault';
    return 'unavailable';
  }

  LatLng get location => LatLng(latitude, longitude);
}

class ConnectorPort {
  final String chargerId;
  final int connectorId;
  final String type;
  final String status;
  final double? maxPower;

  ConnectorPort({
    required this.chargerId,
    required this.connectorId,
    required this.type,
    required this.status,
    this.maxPower,
  });

  factory ConnectorPort.fromJson(Map<String, dynamic> json) {
    return ConnectorPort(
      chargerId: json['charger_id'] ?? '',
      connectorId: json['connector_id'] ?? 0,
      type: json['type'] ?? 'Unknown',
      status: json['status'] ?? 'unknown',
      maxPower: json['max_power']?.toDouble(),
    );
  }
}

