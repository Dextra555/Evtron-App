// lib/Model/scan_validation_model.dart

import 'package:flutter/material.dart';

class ScanValidationResponse {
  final bool success;
  final String message;
  final ScanValidationData? data;
  final String? failedCheck;
  final String? connectorStatus;
  final String? errorCode;
  final String? errorDescription;
  final int? statusCode;
  final Map<String, dynamic>? errors; // For validation errors (422)

  ScanValidationResponse({
    required this.success,
    required this.message,
    this.data,
    this.failedCheck,
    this.connectorStatus,
    this.errorCode,
    this.errorDescription,
    this.statusCode,
    this.errors,
  });

  factory ScanValidationResponse.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    String? failedCheck;
    String? connectorStatus;
    String? errorCode;
    String? errorDescription;
    Map<String, dynamic>? errors;

    // Extract failed_check
    if (json['failed_check'] != null) {
      failedCheck = json['failed_check'].toString();
    }

    // Extract connector_status (from success response)
    if (json['connector_status'] != null) {
      connectorStatus = json['connector_status'].toString();
    }

    // Extract error details
    if (json['error'] != null && json['error'] is Map<String, dynamic>) {
      errorCode = json['error']['code']?.toString();
      errorDescription = json['error']['description']?.toString();
    }

    // Extract validation errors (422)
    if (json['errors'] != null && json['errors'] is Map<String, dynamic>) {
      errors = Map<String, dynamic>.from(json['errors']);
    }

    // Parse data if present
    ScanValidationData? data;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      try {
        data = ScanValidationData.fromJson(json['data']);
      } catch (e) {
        print('⚠️ Error parsing data: $e');
      }
    }

    return ScanValidationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown error occurred',
      data: data,
      failedCheck: failedCheck,
      connectorStatus: connectorStatus,
      errorCode: errorCode,
      errorDescription: errorDescription,
      statusCode: statusCode,
      errors: errors,
    );
  }

  /// Get user-friendly error message based on failed_check
  String getUserFriendlyMessage() {
    // If there are validation errors (422)
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = errors!.entries.map((entry) {
        final field = entry.key;
        final messages = entry.value is List ? entry.value.join(', ') : entry.value.toString();
        return '$field: $messages';
      }).join('\n');
      return errorMessages;
    }

    // Check if it's a failed_check case
    if (failedCheck != null) {
      switch (failedCheck) {
        case 'user_not_authenticated':
          return 'Please login to continue.';
        case 'charger_not_found':
          return 'Charger not found in the system. Please scan a valid QR code.';
        case 'connector_invalid':
          return 'Connector type not supported. Please use a compatible charger.';
        case 'ocpp_offline':
          return 'Charger is offline. Please ensure the charger is powered on and connected.';
        case 'connector_not_available':
          return _getConnectorNotAvailableMessage(errorCode, message);
        case 'active_session_exists':
          return 'You already have an active charging session. Please stop it before starting a new one.';
        case 'wallet_balance_insufficient':
          return _getBalanceInsufficientMessage(message);
        default:
          return message;
      }
    }

    // Default message
    return message;
  }

  String _getConnectorNotAvailableMessage(String? errorCode, String defaultMessage) {
    switch (errorCode) {
      case 'CONNECTOR_CHARGING':
        return 'Connector is currently in use. Please try another connector.';
      case 'CONNECTOR_FAULTED':
        return 'Connector is faulted. Please try another connector or contact support.';
      case 'CONNECTOR_FINISHING':
        return 'Connector is finishing previous session. Please wait a moment.';
      case 'CONNECTOR_UNAVAILABLE':
        return 'Connector is unavailable. Please try another connector.';
      default:
        return defaultMessage;
    }
  }

  String _getBalanceInsufficientMessage(String message) {
    // Extract balance details from message if available
    final regExp = RegExp(r'Balance ₹([\d.]+), minimum ₹([\d.]+)');
    final match = regExp.firstMatch(message);
    if (match != null) {
      final balance = match.group(1);
      final minimum = match.group(2);
      return 'Insufficient wallet balance (₹$balance). Minimum required: ₹$minimum. Please recharge your wallet.';
    }
    return 'Insufficient wallet balance. Please recharge your wallet and try again.';
  }

  /// Get appropriate icon for error dialog
  IconData getErrorIcon() {
    if (failedCheck != null) {
      switch (failedCheck) {
        case 'user_not_authenticated':
          return Icons.lock_outline;
        case 'charger_not_found':
          return Icons.qr_code_scanner;
        case 'connector_invalid':
          return Icons.bolt_outlined;
        case 'ocpp_offline':
          return Icons.signal_wifi_off;
        case 'connector_not_available':
          if (errorCode == 'CONNECTOR_CHARGING') {
            return Icons.charging_station;
          }
          if (errorCode == 'CONNECTOR_FAULTED') {
            return Icons.error_outline;
          }
          return Icons.ev_station;
        case 'active_session_exists':
          return Icons.timer;
        case 'wallet_balance_insufficient':
          return Icons.account_balance_wallet;
        default:
          return Icons.error_outline;
      }
    }
    return Icons.error_outline;
  }

  /// Get appropriate color for error dialog
  Color getErrorColor() {
    if (failedCheck != null) {
      switch (failedCheck) {
        case 'user_not_authenticated':
          return Colors.red;
        case 'charger_not_found':
          return Colors.orange;
        case 'connector_invalid':
          return Colors.red;
        case 'ocpp_offline':
          return Colors.orange;
        case 'connector_not_available':
          if (errorCode == 'CONNECTOR_CHARGING') {
            return Colors.orange;
          }
          if (errorCode == 'CONNECTOR_FAULTED') {
            return Colors.red;
          }
          return Colors.orange;
        case 'active_session_exists':
          return Colors.amber;
        case 'wallet_balance_insufficient':
          return Colors.amber;
        default:
          return Colors.red;
      }
    }
    return Colors.red;
  }

  /// Get title for error dialog
  String getErrorTitle() {
    if (failedCheck != null) {
      switch (failedCheck) {
        case 'user_not_authenticated':
          return 'Not Logged In';
        case 'charger_not_found':
          return 'Charger Not Found';
        case 'connector_invalid':
          return 'Invalid Connector';
        case 'ocpp_offline':
          return 'Charger Offline';
        case 'connector_not_available':
          if (errorCode == 'CONNECTOR_CHARGING') return 'Connector In Use';
          if (errorCode == 'CONNECTOR_FAULTED') return 'Connector Faulted';
          if (errorCode == 'CONNECTOR_FINISHING') return 'Connector Finishing';
          if (errorCode == 'CONNECTOR_UNAVAILABLE') return 'Connector Unavailable';
          return 'Connector Unavailable';
        case 'active_session_exists':
          return 'Active Session Exists';
        case 'wallet_balance_insufficient':
          return 'Insufficient Balance';
        default:
          return 'Charging Failed';
      }
    }
    return 'Charging Failed';
  }
}

class ScanValidationData {
  final ChargerInfo charger;
  final ConnectorInfo connector;
  final StationInfo station;
  final double userBalance;

  ScanValidationData({
    required this.charger,
    required this.connector,
    required this.station,
    required this.userBalance,
  });

  factory ScanValidationData.fromJson(Map<String, dynamic> json) {
    return ScanValidationData(
      charger: ChargerInfo.fromJson(json['charger'] ?? {}),
      connector: ConnectorInfo.fromJson(json['connector'] ?? {}),
      station: StationInfo.fromJson(json['station'] ?? {}),
      userBalance: (json['user_balance'] ?? 0).toDouble(),
    );
  }
}

class ChargerInfo {
  final String chargerId;
  final String name;
  final String manufacturer;
  final String model;
  final String status;
  final double powerCapacity;
  final String connectorType;
  final String? address;
  final String? latitude;
  final String? longitude;
  final String serialNumber;

  ChargerInfo({
    required this.chargerId,
    required this.name,
    required this.manufacturer,
    required this.model,
    required this.status,
    required this.powerCapacity,
    required this.connectorType,
    this.address,
    this.latitude,
    this.longitude,
    required this.serialNumber,
  });

  factory ChargerInfo.fromJson(Map<String, dynamic> json) {
    return ChargerInfo(
      chargerId: json['charger_id'] ?? '',
      name: json['name'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      model: json['model'] ?? '',
      status: json['status'] ?? '',
      powerCapacity: (json['power_capacity'] ?? 0).toDouble(),
      connectorType: json['connector_type'] ?? '',
      address: json['address'],
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      serialNumber: json['serial_number'] ?? '',
    );
  }
}

class ConnectorInfo {
  final int connectorId;
  final String connectorUid;
  final String connectorName;
  final String connectorType;
  final int ocppConnectorId;
  final String status;
  final dynamic maxPower;
  final dynamic powerKw;

  ConnectorInfo({
    required this.connectorId,
    required this.connectorUid,
    required this.connectorName,
    required this.connectorType,
    required this.ocppConnectorId,
    required this.status,
    this.maxPower,
    this.powerKw,
  });

  factory ConnectorInfo.fromJson(Map<String, dynamic> json) {
    return ConnectorInfo(
      connectorId: json['connector_id'] ?? 0,
      connectorUid: json['connector_uid'] ?? '',
      connectorName: json['connector_name'] ?? '',
      connectorType: json['connector_type'] ?? '',
      ocppConnectorId: json['ocpp_connector_id'] ?? 0,
      status: json['status'] ?? '',
      maxPower: json['max_power'],
      powerKw: json['power_kw'],
    );
  }
}

class StationInfo {
  final int id;
  final String? name;
  final String? address;

  StationInfo({
    required this.id,
    this.name,
    this.address,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    return StationInfo(
      id: json['id'] ?? 0,
      name: json['name'],
      address: json['address'],
    );
  }
}