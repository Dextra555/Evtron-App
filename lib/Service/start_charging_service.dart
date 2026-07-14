// lib/Service/start_charging_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/start_charging_model.dart';
import 'api_endpoints.dart';

class ChargingService {
  static int extractSessionIdFromResponse(Map<String, dynamic> responseData) {
    int? parseValue(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    int? findInMap(Map<String, dynamic> data) {
      final directKeys = ['session_id', 'sessionId', 'id'];
      for (final key in directKeys) {
        final value = data[key];
        final parsed = parseValue(value);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }

      for (final value in data.values) {
        if (value is Map) {
          final nested = Map<String, dynamic>.from(value);
          final parsed = findInMap(nested);
          if (parsed != null && parsed > 0) {
            return parsed;
          }
        }
      }

      return null;
    }

    final direct = findInMap(responseData);
    if (direct != null && direct > 0) {
      return direct;
    }

    final dataValue = responseData['data'];
    if (dataValue is Map) {
      final nested = Map<String, dynamic>.from(dataValue);
      final nestedId = findInMap(nested);
      if (nestedId != null && nestedId > 0) {
        return nestedId;
      }
    }

    return 0;
  }

  static int resolveSessionId({
    required ChargingSessionResponse? response,
    int? fallbackSessionId,
  }) {
    final responseSessionId = response?.data?.sessionId ?? 0;
    if (responseSessionId > 0) {
      return responseSessionId;
    }

    if (fallbackSessionId != null && fallbackSessionId > 0) {
      return fallbackSessionId;
    }

    return 0;
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      print('🔑 Token found: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        print('   Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }
      return token;
    } catch (e) {
      print('❌ Error getting auth token: $e');
      return null;
    }
  }

  Future<ChargingSessionResponse> startCharging({
    required int connectorId,
    required int vehicleId,
  }) async {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║              START CHARGING SERVICE - API CALL               ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('\n📝 Request Parameters:');
    print('   • Connector ID: $connectorId');
    print('   • Vehicle ID: $vehicleId');

    try {
      // Validate parameters
      if (connectorId <= 0) {
        print('❌ ERROR: Invalid connector ID: $connectorId');
        return ChargingSessionResponse(
          success: false,
          message: 'Invalid connector ID. Please scan a valid QR code.',
          statusCode: 422,
          failedCheck: 'connector_invalid',
        );
      }

      if (vehicleId <= 0) {
        print('❌ ERROR: Invalid vehicle ID: $vehicleId');
        return ChargingSessionResponse(
          success: false,
          message: 'Invalid vehicle ID. Please select a valid vehicle.',
          statusCode: 422,
          failedCheck: 'vehicle_invalid',
        );
      }

      final request = StartChargingRequest(
        connectorId: connectorId,
        vehicleId: vehicleId,
      );

      final authToken = await _getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        print('❌ No auth token found!');
        return ChargingSessionResponse(
          success: false,
          message: 'Please login to continue.',
          statusCode: 401,
          failedCheck: 'user_not_authenticated',
          errorCode: 'NOT_AUTHENTICATED',
        );
      }

      final url = Uri.parse(ApiEndpoints.startCharging);
      final requestBody = jsonEncode(request.toJson());

      print('\n📤 REQUEST DETAILS:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🌐 URL: ${url.toString()}');
      print('📝 Method: POST');
      print('📦 Body: $requestBody');
      print('🔑 Auth: Bearer ${authToken.substring(0, authToken.length > 20 ? 20 : authToken.length)}...');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      print('\n⏳ Sending HTTP request to server...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ Request timeout after 30 seconds');
          throw TimeoutException('Request timeout');
        },
      );

      print('\n📥 HTTP RESPONSE RECEIVED!');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 RAW RESPONSE BODY:');
      print('┌────────────────────────────────────────────────────────────────┐');
      final rawResponse = response.body;
      final lines = rawResponse.split('\n');
      for (var line in lines) {
        print('│ $line');
      }
      print('└────────────────────────────────────────────────────────────────┘');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Parse response body
      try {
        final Map<String, dynamic> responseData = jsonDecode(rawResponse);

        // Handle different status codes
        switch (response.statusCode) {
          case 200:
          case 201:
            print('\n✅✅✅ SUCCESS! Charging started successfully!');
            return _handleSuccessfulResponse(responseData, response.statusCode);

          case 202:
            print('\n⏳ ACCEPTED - Charging request is being processed');
            return _handleSuccessfulResponse(responseData, response.statusCode);

          case 400:
            print('\n❌ BAD REQUEST (400)');
            return _handleErrorResponse(responseData, 400);

          case 401:
            print('\n❌ UNAUTHORIZED (401)');
            return ChargingSessionResponse(
              success: false,
              message: 'Please login to continue.',
              statusCode: 401,
              failedCheck: 'user_not_authenticated',
              errorCode: 'NOT_AUTHENTICATED',
            );

          case 403:
            print('\n❌ FORBIDDEN (403)');
            return ChargingSessionResponse(
              success: false,
              message: 'You do not have permission to start charging.',
              statusCode: 403,
              failedCheck: 'permission_denied',
              errorCode: 'PERMISSION_DENIED',
            );

          case 404:
            print('\n❌ NOT FOUND (404)');
            return _handleErrorResponse(responseData, 404);

          case 409:
            print('\n❌ CONFLICT (409) - Active session exists');
            return ChargingSessionResponse(
              success: false,
              message: responseData['message'] ?? 'An active charging session already exists.',
              statusCode: 409,
              failedCheck: 'active_session_exists',
              errorCode: 'ACTIVE_SESSION_EXISTS',
            );

          case 422:
            print('\n❌ UNPROCESSABLE ENTITY (422)');
            return _handleErrorResponse(responseData, 422);

          case 429:
            print('\n❌ TOO MANY REQUESTS (429)');
            return ChargingSessionResponse(
              success: false,
              message: responseData['message'] ?? 'Another start request is already in progress. Please wait.',
              statusCode: 429,
              failedCheck: 'already_starting',
              errorCode: 'TOO_MANY_REQUESTS',
            );

          case 502:
            print('\n❌ BAD GATEWAY (502) - OCPP Communication Error');
            return ChargingSessionResponse(
              success: false,
              message: 'Failed to communicate with charger. Please try again.',
              statusCode: 502,
              failedCheck: 'ocpp_comm_fail',
              errorCode: 'OCPP_COMMUNICATION_FAILED',
            );

          case 503:
            print('\n❌ SERVICE UNAVAILABLE (503)');
            return ChargingSessionResponse(
              success: false,
              message: 'Charging service is currently unavailable. Please try again later.',
              statusCode: 503,
              failedCheck: 'service_unavailable',
              errorCode: 'SERVICE_UNAVAILABLE',
            );

          default:
            print('\n❌ UNKNOWN STATUS CODE: ${response.statusCode}');
            // Check if it's actually a success response
            if (responseData['success'] == true) {
              return _handleSuccessfulResponse(responseData, response.statusCode);
            }
            return ChargingSessionResponse(
              success: false,
              message: responseData['message'] ?? 'An unexpected error occurred.',
              statusCode: response.statusCode,
            );
        }
      } catch (parseError) {
        print('\n❌ Failed to parse response: $parseError');
        return ChargingSessionResponse(
          success: false,
          message: 'Invalid server response. Please try again.',
          statusCode: 500,
        );
      }
    } on SocketException catch (e) {
      print('\n❌ NETWORK ERROR: $e');
      return ChargingSessionResponse(
        success: false,
        message: 'Network error. Please check your internet connection.',
        statusCode: 0,
        failedCheck: 'network_error',
      );
    } on TimeoutException catch (e) {
      print('\n❌ TIMEOUT ERROR: $e');
      return ChargingSessionResponse(
        success: false,
        message: 'Request timeout. Please try again.',
        statusCode: 0,
        failedCheck: 'timeout_error',
      );
    } catch (e) {
      print('\n❌ UNEXPECTED EXCEPTION: $e');
      return ChargingSessionResponse(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
        statusCode: 500,
        failedCheck: 'unexpected_error',
      );
    }
  }

  /// Handles successful responses from the API
  ChargingSessionResponse _handleSuccessfulResponse(
      Map<String, dynamic> responseData,
      int statusCode,
      ) {
    print('\n✅ Handling successful response');
    final message = responseData['message'] ?? 'Charging started successfully';
    print('📝 Message: $message');

    // Check if we have full data in the response
    if (responseData['data'] != null && responseData['data'] is Map<String, dynamic>) {
      try {
        print('📦 Full data object found, parsing...');
        final response = ChargingSessionResponse.fromJson(responseData, statusCode: statusCode);
        if (response.data != null) {
          print('✅ Successfully parsed full data object');
          return response;
        } else {
          print('⚠️ Data parsing failed, falling back to minimal response');
        }
      } catch (e) {
        print('⚠️ Error parsing data: $e');
        // Fall through to create minimal response
      }
    }

    final sessionId = extractSessionIdFromResponse(responseData);
    if (sessionId > 0) {
      print('📌 Found session ID in response: $sessionId');
    } else {
      print('⚠️ No session ID found in response payload');
    }

    if (responseData['transaction_id'] != null) {
      print('📌 Found transaction_id in response: ${responseData['transaction_id']}');
    }

    // Create minimal response with whatever data we have
    print('📝 Creating minimal session response');
    return ChargingSessionResponse(
      success: true,
      message: message,
      statusCode: statusCode,
      data: ChargingSessionData(
        sessionId: sessionId,
        transactionId: responseData['transaction_id']?.toString() ?? '',
        ocppTransactionId: responseData['ocpp_transaction_id'],
        ocppMessageId: responseData['ocpp_message_id']?.toString(),
        ocppSent: responseData['ocpp_sent'] ?? true,
        startedAt: responseData['started_at'] ?? DateTime.now().toIso8601String(),
        charger: _createChargerInfo(responseData),
        connector: _createConnectorInfo(responseData),
        station: _createStationInfo(responseData),
        pricing: _createPricingInfo(responseData),
        wallet: _createWalletInfo(responseData),
        vehicle: responseData['vehicle'],
      ),
    );
  }

  /// Creates ChargerInfo from response data
  ChargerInfo _createChargerInfo(Map<String, dynamic> data) {
    if (data['charger'] != null && data['charger'] is Map<String, dynamic>) {
      return ChargerInfo.fromJson(data['charger']);
    }
    // Try to extract from flat structure
    return ChargerInfo(
      id: data['charger_id']?.toString() ?? '',
      name: data['charger_name']?.toString() ?? '',
      type: data['charger_type']?.toString() ?? '',
      powerCapacity: (data['charger_power'] ?? 0).toDouble(),
      model: data['charger_model']?.toString() ?? '',
      manufacturer: data['charger_manufacturer']?.toString() ?? '',
    );
  }

  /// Creates ConnectorInfo from response data
  ConnectorInfo _createConnectorInfo(Map<String, dynamic> data) {
    if (data['connector'] != null && data['connector'] is Map<String, dynamic>) {
      return ConnectorInfo.fromJson(data['connector']);
    }
    // Try to extract from flat structure
    return ConnectorInfo(
      id: data['connector_id'] is int
          ? data['connector_id']
          : int.tryParse(data['connector_id']?.toString() ?? '0') ?? 0,
      uid: data['connector_uid']?.toString() ?? '',
      name: data['connector_name']?.toString() ?? '',
      type: data['connector_type']?.toString() ?? '',
      currentType: data['current_type']?.toString() ?? '',
      maxPower: data['max_power'],
    );
  }

  /// Creates StationInfo from response data
  StationInfo _createStationInfo(Map<String, dynamic> data) {
    if (data['station'] != null && data['station'] is Map<String, dynamic>) {
      return StationInfo.fromJson(data['station']);
    }
    // Try to extract from flat structure
    return StationInfo(
      id: data['station_id'] is int
          ? data['station_id']
          : int.tryParse(data['station_id']?.toString() ?? '0') ?? 0,
      name: data['station_name']?.toString() ?? '',
      address: data['station_address']?.toString() ?? '',
      latitude: data['latitude']?.toString() ?? '',
      longitude: data['longitude']?.toString() ?? '',
    );
  }

  /// Creates PricingInfo from response data
  PricingInfo _createPricingInfo(Map<String, dynamic> data) {
    if (data['pricing'] != null && data['pricing'] is Map<String, dynamic>) {
      return PricingInfo.fromJson(data['pricing']);
    }
    // Try to extract from flat structure
    return PricingInfo(
      type: data['pricing_type']?.toString() ?? 'per_hour',
      rate: data['pricing_rate'] is int
          ? data['pricing_rate']
          : int.tryParse(data['pricing_rate']?.toString() ?? '0') ?? 0,
      unit: data['pricing_unit']?.toString() ?? 'per kWh',
      currency: data['currency']?.toString() ?? 'INR',
    );
  }

  /// Creates WalletInfo from response data
  WalletInfo _createWalletInfo(Map<String, dynamic> data) {
    if (data['wallet'] != null && data['wallet'] is Map<String, dynamic>) {
      return WalletInfo.fromJson(data['wallet']);
    }
    // Try to extract from flat structure
    return WalletInfo(
      balanceBefore: (data['balance_before'] ?? 0).toDouble(),
      currency: data['currency']?.toString() ?? 'INR',
    );
  }

  /// Handles error responses from the API
  ChargingSessionResponse _handleErrorResponse(
      Map<String, dynamic> responseData,
      int statusCode,
      ) {
    // Extract error details
    String? errorCode;
    String? failedCheck;
    String? errorDescription;
    Map<String, dynamic>? errors;

    // Check for errors object (422 validation)
    if (responseData['errors'] != null && responseData['errors'] is Map<String, dynamic>) {
      errors = Map<String, dynamic>.from(responseData['errors']);
    }

    // Check for error object
    if (responseData['error'] != null && responseData['error'] is Map<String, dynamic>) {
      errorCode = responseData['error']['code']?.toString();
      errorDescription = responseData['error']['description']?.toString();
    }

    // Check for error_code in root
    if (responseData['error_code'] != null) {
      errorCode = responseData['error_code'].toString();
    }

    // Check for failed_check
    if (responseData['failed_check'] != null) {
      failedCheck = responseData['failed_check'].toString();
    }

    final message = responseData['message'] ?? 'An error occurred. Please try again.';

    // Special handling for "Not Preparing" error
    if (failedCheck == 'not_preparing' ||
        message.toLowerCase().contains('not preparing') ||
        message.toLowerCase().contains('preparing')) {
      return ChargingSessionResponse(
        success: false,
        message: message,
        statusCode: statusCode,
        failedCheck: 'not_preparing',
        errorCode: errorCode ?? 'CONNECTOR_NOT_PREPARING',
        errorDescription: errorDescription,
        errors: errors,
      );
    }

    // Special handling for low wallet
    if (failedCheck == 'low_wallet' ||
        message.toLowerCase().contains('insufficient') ||
        message.toLowerCase().contains('balance')) {
      return ChargingSessionResponse(
        success: false,
        message: message,
        statusCode: statusCode,
        failedCheck: 'low_wallet',
        errorCode: errorCode ?? 'INSUFFICIENT_BALANCE',
        errorDescription: errorDescription,
        errors: errors,
      );
    }

    // Special handling for connector not found
    if (failedCheck == 'connector_not_found' ||
        message.toLowerCase().contains('connector not found')) {
      return ChargingSessionResponse(
        success: false,
        message: message,
        statusCode: statusCode,
        failedCheck: 'connector_not_found',
        errorCode: errorCode ?? 'CONNECTOR_NOT_FOUND',
        errorDescription: errorDescription,
        errors: errors,
      );
    }

    // Special handling for charger offline
    if (failedCheck == 'charger_offline' ||
        message.toLowerCase().contains('charger offline') ||
        message.toLowerCase().contains('charger is offline')) {
      return ChargingSessionResponse(
        success: false,
        message: message,
        statusCode: statusCode,
        failedCheck: 'charger_offline',
        errorCode: errorCode ?? 'CHARGER_OFFLINE',
        errorDescription: errorDescription,
        errors: errors,
      );
    }

    if (statusCode == 409 ||
        message.toLowerCase().contains('active session') ||
        message.toLowerCase().contains('already charging')) {
      return ChargingSessionResponse(
        success: false,
        message: message,
        statusCode: statusCode,
        failedCheck: 'active_session_exists',
        errorCode: errorCode ?? 'ACTIVE_SESSION_EXISTS',
        errorDescription: errorDescription,
        errors: errors,
      );
    }

    return ChargingSessionResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      failedCheck: failedCheck,
      errorCode: errorCode,
      errorDescription: errorDescription,
      errors: errors,
    );
  }

  /// Checks if there's an active charging session
  Future<bool> hasActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getInt('active_session_id');
      final status = prefs.getString('session_status');
      return sessionId != null && status == 'charging' && sessionId > 0;
    } catch (e) {
      print('❌ Error checking active session: $e');
      return false;
    }
  }

  /// Gets the active session ID
  Future<int?> getActiveSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('active_session_id');
    } catch (e) {
      print('❌ Error getting active session ID: $e');
      return null;
    }
  }

  /// Saves session data locally
  Future<void> saveSessionData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (data['session_id'] != null) {
        final sessionId = data['session_id'] is int
            ? data['session_id']
            : int.tryParse(data['session_id'].toString()) ?? 0;

        if (sessionId > 0) {
          await prefs.setInt('active_session_id', sessionId);
          await prefs.setInt('current_session_id', sessionId);
          await prefs.setString('session_status', 'charging');
          await prefs.setString('charging_status', 'charging');

          if (data['started_at'] != null) {
            await prefs.setString('session_started_at', data['started_at'].toString());
          }

          if (data['transaction_id'] != null) {
            await prefs.setString('transaction_id', data['transaction_id'].toString());
          }

          print('✅ Session data saved successfully:');
          print('   Session ID: $sessionId');
          print('   Status: charging');
        }
      }
    } catch (e) {
      print('⚠️ Error saving session data: $e');
    }
  }
}