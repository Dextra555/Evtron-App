import 'package:flutter/material.dart';
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

  // ✅ ADD THIS toJson METHOD
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'station_name': name,
      'full_address': fullAddress,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'status': status,
      'station_type': stationType,
      'is_24_7': is247,
      'estimated_charging_price': estimatedChargingPrice.toString(),
      'total_chargers': totalChargers,
      'available_chargers': availableChargers,
      'connector_ports': connectorPorts.map((port) => port.toJson()).toList(),
      'amenities': amenities,
      'real_time_availability': realTimeAvailability,
      'created_at': createdAt.toIso8601String(),
      'rating': rating,
      'active_chargers': activeChargers,
      'inactive_chargers': inactiveChargers,
      'charger_status_counts': chargerStatusCounts,
    };
  }

  // Helper method to get connector status counts
  Map<String, int> getConnectorStatusCounts() {
    Map<String, int> statusCounts = {};
    for (var port in connectorPorts) {
      statusCounts[port.status] = (statusCounts[port.status] ?? 0) + 1;
    }
    return statusCounts;
  }

  List<ConnectorPort> getFilteredConnectorPorts(Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) {
      return List<ConnectorPort>.from(connectorPorts);
    }

    final chargerType = _normalizeFilterValue(filters['chargerType']?.toString());
    final connectorType = _normalizeFilterValue(filters['connectorType']?.toString());
    final status = _normalizeFilterValue(filters['status']?.toString());
    final powerRange = filters['powerRange'] as RangeValues?;

    return connectorPorts.where((port) {
      if (chargerType.isNotEmpty && chargerType != 'both' && !_matchesChargerType(port, chargerType)) {
        return false;
      }

      if (connectorType.isNotEmpty && !_matchesConnectorType(port.type, connectorType)) {
        return false;
      }

      if (status.isNotEmpty && !_matchesStatus(port.status, status)) {
        return false;
      }

      if (powerRange != null && !(powerRange.start == 0.0 && powerRange.end == 350.0)) {
        final power = port.kw ?? port.maxPower ?? 0.0;
        if (!_matchesPowerRange(power, powerRange)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool hasMatchingConnectorPorts(Map<String, dynamic>? filters) {
    return getFilteredConnectorPorts(filters).isNotEmpty;
  }

  bool matchesPowerRange(RangeValues? powerRange) {
    if (powerRange == null || (powerRange.start == 0.0 && powerRange.end == 350.0)) {
      return true;
    }

    if (connectorPorts.isEmpty) {
      return false;
    }

    final parsedPowers = connectorPorts.map((port) => _parsePower(port.kw) ?? _parsePower(port.maxPower)).whereType<double>().toList();
    print('🔍 Station ${name}: selected range ${powerRange.start} - ${powerRange.end} kW, connector powers: $parsedPowers');

    for (final power in parsedPowers) {
      if (_matchesPowerRange(power, powerRange)) {
        print('✅ Station ${name}: connector power $power matched selected range');
        return true;
      }
    }

    print('❌ Station ${name}: no connector power matched selected range');
    return false;
  }

  bool _matchesPowerRange(double power, RangeValues? powerRange) {
    if (powerRange == null || (powerRange.start == 0.0 && powerRange.end == 350.0)) {
      return true;
    }

    const tolerance = 1e-9;
    return power >= powerRange.start - tolerance && power <= powerRange.end + tolerance;
  }

  double? _parsePower(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return double.tryParse(value.toString());
  }

  bool _matchesChargerType(ConnectorPort port, String selectedChargerType) {
    final normalizedSelected = selectedChargerType.toLowerCase().trim();
    final chargerType = (port.chargerType ?? '').trim().toLowerCase();
    final connectorType = (port.type ?? '').trim().toLowerCase();
    final power = port.kw ?? port.maxPower ?? 0.0;

    if (chargerType.contains('dc')) {
      return normalizedSelected == 'dc';
    }

    if (chargerType.contains('ac')) {
      return normalizedSelected == 'ac';
    }

    if (connectorType.contains('ccs') ||
        connectorType.contains('chademo') ||
        connectorType.contains('gb/t') ||
        connectorType.contains('tesla')) {
      return normalizedSelected == 'dc' ? power > 50 : normalizedSelected == 'ac';
    }

    if (connectorType.contains('type 2') || connectorType.contains('type2')) {
      return normalizedSelected == 'ac';
    }

    return normalizedSelected == 'dc' ? power > 50 : normalizedSelected == 'ac';
  }

  bool _matchesConnectorType(String type, String selectedConnectorType) {
    final normalizedPortType = _normalizeConnectorType(type).toLowerCase().trim();
    final normalizedSelectedType = _normalizeConnectorType(selectedConnectorType).toLowerCase().trim();
    return normalizedPortType == normalizedSelectedType;
  }

  bool _matchesStatus(String status, String selectedStatus) {
    final normalizedStatus = status.toLowerCase().trim();
    final normalizedSelected = selectedStatus.toLowerCase().trim();

    if (normalizedSelected == 'available') {
      return normalizedStatus == 'available' || normalizedStatus == 'idle';
    }

    if (normalizedSelected == 'busy') {
      return normalizedStatus == 'busy' ||
          normalizedStatus == 'charging' ||
          normalizedStatus == 'active' ||
          normalizedStatus == 'in-use' ||
          normalizedStatus == 'occupied';
    }

    if (normalizedSelected == 'fault') {
      return normalizedStatus == 'fault' || normalizedStatus == 'error' || normalizedStatus == 'failed';
    }

    if (normalizedSelected == 'unavailable') {
      return normalizedStatus == 'offline' ||
          normalizedStatus == 'unavailable' ||
          normalizedStatus == 'disconnected' ||
          normalizedStatus == 'maintenance';
    }

    return normalizedStatus == normalizedSelected;
  }

  String _normalizeFilterValue(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  String _normalizeConnectorType(String value) {
    final lower = value.toLowerCase();
    if (lower == 'type2' || lower == 'type 2' || lower == 'type_2') {
      return 'Type 2';
    } else if (lower == 'type1' || lower == 'type 1' || lower == 'type_1') {
      return 'Type 1';
    } else if (lower == 'ccs2' || lower == 'ccs' || lower == 'ccs_2') {
      return 'CCS';
    } else if (lower == 'ccs1' || lower == 'ccs_1') {
      return 'CCS1';
    } else if (lower == 'chademo') {
      return 'CHAdeMO';
    } else if (lower == 'gbt' || lower == 'gb/t' || lower == 'gb_t') {
      return 'GB/T';
    } else if (lower == 'tesla' || lower == 'nacs') {
      return 'Tesla';
    }
    return value;
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
  final double? kw;
  final String chargerType;
  final String connectorUid;

  ConnectorPort({
    required this.chargerId,
    required this.connectorId,
    required this.type,
    required this.status,
    this.maxPower,
    this.kw,
    required this.chargerType,
    required this.connectorUid,

  });

  factory ConnectorPort.fromJson(Map<String, dynamic> json) {
    return ConnectorPort(
      chargerId: json['charger_id'] ?? '',
      connectorId: json['connector_id'] ?? 0,
      type: json['type'] ?? 'Unknown',
      status: json['status'] ?? 'unknown',
      maxPower: json['max_power']?.toDouble(),
      kw: json['kw']?.toDouble(),
      chargerType: json['charger_type'] ?? 'Unknown',
      connectorUid: json['connector_uid'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'charger_id': chargerId,
      'connector_id': connectorId,
      'connector_uid': connectorUid,
      'type': type,
      'status': status,
      'max_power': maxPower,
      'kw': kw,
      'charger_type': chargerType,
    };
  }
}


