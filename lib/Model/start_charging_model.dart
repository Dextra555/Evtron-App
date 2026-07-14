// lib/Model/start_charging_model.dart

import 'package:flutter/material.dart';

class StartChargingRequest {
  final int connectorId;
  final int vehicleId;

  StartChargingRequest({
    required this.connectorId,
    required this.vehicleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'connector_id': connectorId,
      'vehicle_id': vehicleId,
    };
  }
}

class ChargingSessionResponse {
  final bool success;
  final String message;
  final ChargingSessionData? data;
  final String? errorCode;
  final String? failedCheck;
  final String? errorDescription;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ChargingSessionResponse({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
    this.failedCheck,
    this.errorDescription,
    this.statusCode,
    this.errors,
  });

  factory ChargingSessionResponse.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    print('🔍 Parsing ChargingSessionResponse from JSON: $json');

    // Extract error details
    String? errorCode;
    String? failedCheck;
    String? errorDescription;
    Map<String, dynamic>? errors;

    // Check for errors object (422 validation)
    if (json['errors'] != null && json['errors'] is Map<String, dynamic>) {
      errors = Map<String, dynamic>.from(json['errors']);
    }

    // Check for error object with code and description
    if (json['error'] != null && json['error'] is Map<String, dynamic>) {
      errorCode = json['error']['code']?.toString();
      errorDescription = json['error']['description']?.toString();
    }

    // Check for failed_check
    if (json['failed_check'] != null) {
      failedCheck = json['failed_check'].toString();
    }

    // Parse data if present
    ChargingSessionData? data;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      try {
        data = ChargingSessionData.fromJson(json['data']);
      } catch (e) {
        print('⚠️ Error parsing data: $e');
      }
    }

    return ChargingSessionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: data,
      errorCode: errorCode,
      failedCheck: failedCheck,
      errorDescription: errorDescription,
      statusCode: statusCode,
      errors: errors,
    );
  }

  /// Get user-friendly error message based on error type
  String getUserFriendlyMessage() {
    // Check for validation errors (422)
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = errors!.entries.map((entry) {
        final field = entry.key;
        final messages = entry.value is List ? entry.value.join(', ') : entry.value.toString();
        return '$field: $messages';
      }).join('\n');
      return errorMessages;
    }

    // Check for specific error codes
    if (failedCheck != null) {
      switch (failedCheck) {
        case 'connector_not_found':
          return 'Connector not found. Please scan a valid QR code.';
        case 'charger_not_found':
          return 'Charger not found for this connector. Please try again.';
        case 'charger_offline':
          return 'Charger is currently offline. Ensure the charger is powered on and connected, then try again.';
        case 'charger_unavailable':
          return 'Charger is not available. Please try another charger.';
        case 'no_station':
          return 'Charging station not configured for this charger. Please contact support.';
        case 'low_wallet':
          return _getLowWalletMessage(message);
        case 'all_connectors_busy':
          return 'All connectors are busy or unavailable. Please wait or try another station.';
        case 'already_starting':
          return 'Another start request is already in progress. Please wait.';
        case 'not_preparing':
          return _getNotPreparingMessage(message);
        case 'ocpp_comm_fail':
          return 'Failed to communicate with charger. Please try again.';
        case 'charger_rejected':
          return 'Charger rejected the start request. Please try again.';
        default:
          return message;
      }
    }

    // Check by error code
    if (errorCode != null) {
      switch (errorCode) {
        case 'CONNECTOR_NOT_FOUND':
          return 'Connector not found. Please scan a valid QR code.';
        case 'CHARGER_NOT_FOUND':
          return 'Charger not found for this connector. Please try again.';
        case 'CHARGER_OFFLINE':
          return 'Charger is currently offline. Please ensure the charger is powered on and connected.';
        case 'CHARGER_UNAVAILABLE':
          return 'Charger is currently unavailable. Please try another charger.';
        case 'INSUFFICIENT_BALANCE':
          return _getLowWalletMessage(message);
        case 'CONNECTOR_NOT_PREPARING':
          return 'Please connect the charging gun to your vehicle first.';
        case 'OCPP_COMMUNICATION_FAILED':
          return 'Failed to communicate with charger. Please try again.';
        case 'CHARGER_REJECTED':
          return 'Charger rejected the start request. Please try again.';
        default:
          return message;
      }
    }

    return message;
  }

  String _getLowWalletMessage(String defaultMessage) {
    // Extract balance details from message if available
    final regExp = RegExp(r'Minimum required: ₹([\d.]+).*?Available balance: ₹([\d.]+)');
    final match = regExp.firstMatch(defaultMessage);
    if (match != null) {
      final min = match.group(1);
      final avail = match.group(2);
      return 'Insufficient wallet balance. Minimum required: ₹$min. Available balance: ₹$avail. Please recharge your wallet.';
    }
    return 'Insufficient wallet balance. Please recharge your wallet and try again.';
  }

  String _getNotPreparingMessage(String defaultMessage) {
    // Extract current state from message
    final regExp = RegExp(r'current: (\w+)');
    final match = regExp.firstMatch(defaultMessage);
    if (match != null) {
      final currentState = match.group(1);
      return 'Connector is not in Preparing state (current: $currentState). Please connect the charging gun first.';
    }
    return 'Please connect the charging gun to your vehicle first.';
  }

  /// Get appropriate icon for error dialog
  IconData getErrorIcon() {
    if (failedCheck != null) {
      switch (failedCheck) {
        case 'connector_not_found':
          return Icons.qr_code_scanner;
        case 'charger_not_found':
          return Icons.ev_station;
        case 'charger_offline':
          return Icons.signal_wifi_off;
        case 'charger_unavailable':
          return Icons.block;
        case 'no_station':
          return Icons.location_off;
        case 'low_wallet':
          return Icons.account_balance_wallet;
        case 'all_connectors_busy':
          return Icons.charging_station;
        case 'already_starting':
          return Icons.timer;
        case 'not_preparing':
          return Icons.power;
        case 'ocpp_comm_fail':
          return Icons.wifi_off;
        case 'charger_rejected':
          return Icons.cancel;
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
        case 'connector_not_found':
          return Colors.orange;
        case 'charger_not_found':
          return Colors.orange;
        case 'charger_offline':
          return Colors.orange;
        case 'charger_unavailable':
          return Colors.orange;
        case 'no_station':
          return Colors.red;
        case 'low_wallet':
          return Colors.amber;
        case 'all_connectors_busy':
          return Colors.orange;
        case 'already_starting':
          return Colors.amber;
        case 'not_preparing':
          return Colors.blue;
        case 'ocpp_comm_fail':
          return Colors.red;
        case 'charger_rejected':
          return Colors.red;
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
        case 'connector_not_found':
          return 'Connector Not Found';
        case 'charger_not_found':
          return 'Charger Not Found';
        case 'charger_offline':
          return 'Charger Offline';
        case 'charger_unavailable':
          return 'Charger Unavailable';
        case 'no_station':
          return 'Station Not Configured';
        case 'low_wallet':
          return 'Insufficient Balance';
        case 'all_connectors_busy':
          return 'All Connectors Busy';
        case 'already_starting':
          return 'Start Request In Progress';
        case 'not_preparing':
          return 'Connector Not Ready';
        case 'ocpp_comm_fail':
          return 'Communication Failed';
        case 'charger_rejected':
          return 'Request Rejected';
        default:
          return 'Charging Failed';
      }
    }
    return 'Charging Failed';
  }

  /// Get action buttons for error dialog
  List<ErrorAction> getErrorActions() {
    final actions = <ErrorAction>[];

    if (failedCheck != null) {
      switch (failedCheck) {
        case 'low_wallet':
          actions.add(ErrorAction(
            label: 'Recharge Wallet',
            action: 'recharge',
            isPrimary: true,
          ));
          break;
        case 'not_preparing':
          actions.add(ErrorAction(
            label: 'Connect Gun',
            action: 'connect_gun',
            isPrimary: true,
          ));
          break;
        case 'charger_offline':
        case 'charger_unavailable':
        case 'all_connectors_busy':
          actions.add(ErrorAction(
            label: 'Try Another',
            action: 'try_another',
            isPrimary: true,
          ));
          break;
        default:
          actions.add(ErrorAction(
            label: 'Try Again',
            action: 'retry',
            isPrimary: true,
          ));
          break;
      }
    }

    // Always add "Go Back" option
    actions.add(ErrorAction(
      label: 'Go Back',
      action: 'go_back',
      isPrimary: false,
    ));

    return actions;
  }
}

class ErrorAction {
  final String label;
  final String action;
  final bool isPrimary;

  ErrorAction({
    required this.label,
    required this.action,
    this.isPrimary = false,
  });
}

// Keep existing data classes unchanged...
class ChargingSessionData {
  final int sessionId;
  final String transactionId;
  final dynamic ocppTransactionId;
  final String? ocppMessageId;
  final bool ocppSent;
  final String startedAt;
  final ChargerInfo charger;
  final ConnectorInfo connector;
  final StationInfo station;
  final PricingInfo pricing;
  final WalletInfo wallet;
  final dynamic vehicle;

  ChargingSessionData({
    required this.sessionId,
    required this.transactionId,
    this.ocppTransactionId,
    this.ocppMessageId,
    required this.ocppSent,
    required this.startedAt,
    required this.charger,
    required this.connector,
    required this.station,
    required this.pricing,
    required this.wallet,
    this.vehicle,
  });

  factory ChargingSessionData.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing ChargingSessionData from JSON: $json');

    final sessionIdValue = json['session_id'] ?? json['sessionId'] ?? json['id'];

    return ChargingSessionData(
      sessionId: sessionIdValue is int
          ? sessionIdValue
          : int.tryParse(sessionIdValue?.toString() ?? '0') ?? 0,
      transactionId: json['transaction_id'] ?? '',
      ocppTransactionId: json['ocpp_transaction_id'],
      ocppMessageId: json['ocpp_message_id'],
      ocppSent: json['ocpp_sent'] ?? false,
      startedAt: json['started_at'] ?? '',
      charger: ChargerInfo.fromJson(json['charger'] ?? {}),
      connector: ConnectorInfo.fromJson(json['connector'] ?? {}),
      station: StationInfo.fromJson(json['station'] ?? {}),
      pricing: PricingInfo.fromJson(json['pricing'] ?? {}),
      wallet: WalletInfo.fromJson(json['wallet'] ?? {}),
      vehicle: json['vehicle'],
    );
  }
}

class ChargerInfo {
  final String id;
  final String name;
  final String type;
  final double powerCapacity;
  final String model;
  final String manufacturer;

  ChargerInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.powerCapacity,
    required this.model,
    required this.manufacturer,
  });

  factory ChargerInfo.fromJson(Map<String, dynamic> json) {
    return ChargerInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      powerCapacity: (json['power_capacity'] ?? 0).toDouble(),
      model: json['model'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
    );
  }
}

class ConnectorInfo {
  final int id;
  final String uid;
  final String name;
  final String type;
  final String currentType;
  final dynamic maxPower;

  ConnectorInfo({
    required this.id,
    required this.uid,
    required this.name,
    required this.type,
    required this.currentType,
    this.maxPower,
  });

  factory ConnectorInfo.fromJson(Map<String, dynamic> json) {
    return ConnectorInfo(
      id: json['id'] ?? 0,
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      currentType: json['current_type'] ?? '',
      maxPower: json['max_power'],
    );
  }
}

class StationInfo {
  final int id;
  final String name;
  final String address;
  final String latitude;
  final String longitude;

  StationInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory StationInfo.fromJson(Map<String, dynamic> json) {
    return StationInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
    );
  }
}

class PricingInfo {
  final String type;
  final int rate;
  final String unit;
  final String currency;

  PricingInfo({
    required this.type,
    required this.rate,
    required this.unit,
    required this.currency,
  });

  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    return PricingInfo(
      type: json['type'] ?? 'per_hour',
      rate: json['rate'] ?? 0,
      unit: json['unit'] ?? 'per kWh',
      currency: json['currency'] ?? 'INR',
    );
  }
}

class WalletInfo {
  final double balanceBefore;
  final String currency;

  WalletInfo({
    required this.balanceBefore,
    required this.currency,
  });

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      balanceBefore: (json['balance_before'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
    );
  }
}