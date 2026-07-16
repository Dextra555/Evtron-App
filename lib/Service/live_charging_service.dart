// lib/Service/live_charging_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/live_charging_model.dart';
import 'api_endpoints.dart';

enum LiveChargingStatusState {
  charging,
  interrupted,
  completed,
  unknown,
}

class LiveChargingService {
  LiveChargingStatusState classifyChargingStatus(String? status) {
    final normalized = status?.trim().toLowerCase() ?? '';

    if (normalized == 'charging' || normalized == 'active') {
      return LiveChargingStatusState.charging;
    }

    if (['interrupted', 'error', 'failed', 'timeout'].contains(normalized)) {
      return LiveChargingStatusState.interrupted;
    }

    if (['completed', 'stopped', 'finished', 'done'].contains(normalized)) {
      return LiveChargingStatusState.completed;
    }

    return LiveChargingStatusState.unknown;
  }

  bool shouldRetryAfterFailure(String? message) {
    final normalized = message?.trim().toLowerCase() ?? '';
    return normalized.contains('timeout') ||
        normalized.contains('network') ||
        normalized.contains('socket') ||
        normalized.contains('preparing') ||
        normalized.contains('waiting');
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        print('⚠️ No auth token found');
      }
      return token;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  Future<LiveChargingResponse> getLiveChargingStatus({
    int? sessionId,
  }) async {
    try {
      final authToken = await _getAuthToken();

      final uri = Uri.parse(ApiEndpoints.liveCharging);

      print('📡 API: ${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}');
      print('🔑 Auth Token present: ${authToken != null ? 'Yes' : 'No'}');
      if (sessionId != null) {
        print('📋 Session ID: $sessionId');
      }

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      print('⏳ Sending request to server...');
      final stopwatch = Stopwatch()..start();

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          stopwatch.stop();
          print('⏰ Request timed out after ${stopwatch.elapsedMilliseconds}ms');
          throw TimeoutException('Request timeout');
        },
      );

      stopwatch.stop();
      print('⏱️ Request completed in ${stopwatch.elapsedMilliseconds}ms');

      // ✅ PRINT FULL RESPONSE DETAILS
      print('╔══════════════════════════════════════════════════════════════════╗');
      print('║                    LIVE CHARGING RESPONSE                        ║');
      print('╚══════════════════════════════════════════════════════════════════╝');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Size: ${response.body.length} bytes');
      print('📄 Headers:');
      response.headers.forEach((key, value) {
        print('   $key: $value');
      });

      // ✅ PRINT RAW RESPONSE BODY
      print('┌────────────────────────────────────────────────────────────────┐');
      print('📝 RAW RESPONSE BODY:');
      print('└────────────────────────────────────────────────────────────────┘');
      print(response.body);
      print('┌────────────────────────────────────────────────────────────────┐');
      print('📝 PARSED RESPONSE:');
      print('└────────────────────────────────────────────────────────────────┘');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // ✅ PRINT PARSED RESPONSE STRUCTURE
        print('✅ Success: ${responseData['success']}');
        print('📝 Message: ${responseData['message'] ?? 'N/A'}');

        if (responseData['data'] != null) {
          final data = responseData['data'];
          final status = data['status']?.toString() ?? '';
          final phase = data['phase']?.toString() ?? '';
          final sessionIdFromData = data['session_id'];
          final state = classifyChargingStatus(status);

          // ✅ PRINT ALL DATA FIELDS
          print('╔══════════════════════════════════════════════════════════════════╗');
          print('║                    SESSION DATA DETAILS                          ║');
          print('╚══════════════════════════════════════════════════════════════════╝');
          print('📋 Session ID: $sessionIdFromData');
          print('📋 Transaction ID: ${data['transaction_id'] ?? 'N/A'}');
          print('📋 Status: $status');
          print('📋 Phase: $phase');
          print('📋 Started At: ${data['started_at'] ?? 'N/A'}');
          print('📋 Ended At: ${data['ended_at'] ?? 'N/A'}');
          print('📋 Auto Stopped: ${data['auto_stopped'] ?? false}');
          print('📋 Poll Interval: ${data['poll_interval_ms'] ?? 'N/A'}ms');

          // ✅ PRINT ELAPSED TIME
          if (data['elapsed_time'] != null) {
            print('⏱️ Elapsed Time:');
            print('   Seconds: ${data['elapsed_time']['seconds'] ?? 0}');
            print('   Minutes: ${data['elapsed_time']['minutes'] ?? 0}');
            print('   Formatted: ${data['elapsed_time']['formatted'] ?? 'N/A'}');
          }

          // ✅ PRINT ENERGY DATA
          if (data['energy'] != null) {
            print('⚡ Energy Data:');
            print('   Consumed: ${data['energy']['consumed_kwh'] ?? 0} kWh');
            print('   Power: ${data['energy']['power_kw'] ?? 0} kW');
            print('   SOC: ${data['energy']['soc_percent'] ?? 'N/A'}%');
          }

          // ✅ PRINT BILLING DATA
          if (data['billing'] != null) {
            print('💰 Billing Data:');
            print('   Current Cost: ${data['billing']['currency'] ?? '₹'}${data['billing']['current_cost'] ?? 0}');
            print('   Wallet Balance: ${data['billing']['currency'] ?? '₹'}${data['billing']['wallet_balance'] ?? 0}');
            print('   Deducted So Far: ${data['billing']['deducted_so_far'] ?? 'N/A'}');
            print('   Available Balance: ${data['billing']['available_balance'] ?? 'N/A'}');
          }

          // ✅ PRINT CHARGER DATA
          if (data['charger'] != null) {
            print('🔌 Charger Data:');
            print('   ID: ${data['charger']['id'] ?? 'N/A'}');
            print('   Name: ${data['charger']['name'] ?? 'N/A'}');
            print('   Type: ${data['charger']['type'] ?? 'N/A'}');
            print('   Status: ${data['charger']['status'] ?? 'N/A'}');
            print('   Power Capacity: ${data['charger']['power_capacity'] ?? 0} kW');
          }

          // ✅ PRINT CONNECTOR DATA
          if (data['connector'] != null) {
            print('🔗 Connector Data:');
            print('   ID: ${data['connector']['id'] ?? 'N/A'}');
            print('   UID: ${data['connector']['uid'] ?? 'N/A'}');
            print('   Name: ${data['connector']['name'] ?? 'N/A'}');
            print('   Type: ${data['connector']['type'] ?? 'N/A'}');
            print('   Status: ${data['connector']['status'] ?? 'N/A'}');
          }

          // ✅ PRINT STATION DATA
          if (data['station'] != null) {
            print('🏪 Station Data:');
            print('   ID: ${data['station']['id'] ?? 'N/A'}');
            print('   Name: ${data['station']['name'] ?? 'N/A'}');
            print('   City: ${data['station']['city'] ?? 'N/A'}');
          }

          // ✅ PRINT VEHICLE DATA
          if (data['vehicle'] != null) {
            print('🚗 Vehicle Data:');
            print('   ID: ${data['vehicle']['id'] ?? 'N/A'}');
            print('   Manufacturer: ${data['vehicle']['manufacturer'] ?? 'N/A'}');
            print('   Model: ${data['vehicle']['model'] ?? 'N/A'}');
            print('   Registration: ${data['vehicle']['registration_number'] ?? 'N/A'}');
          } else {
            print('🚗 Vehicle Data: null');
          }

          // ✅ PRINT OCPP DATA
          if (data['ocpp'] != null) {
            print('📡 OCPP Data:');
            print('   Connected: ${data['ocpp']['connected'] ?? false}');
            print('   Transaction ID: ${data['ocpp']['ocpp_transaction_id'] ?? 'N/A'}');
            print('   Meter Readings: ${data['ocpp']['meter_readings'] ?? 0}');
          }

          print('╔══════════════════════════════════════════════════════════════════╗');
          print('📊 State Classification: $state');
          print('╚══════════════════════════════════════════════════════════════════╝');

          // ✅ Parse the response
          final response = LiveChargingResponse.fromJson(responseData);

          switch (state) {
            case LiveChargingStatusState.charging:
              print('⚡ Session is still charging; continue polling');
              return response;
            case LiveChargingStatusState.interrupted:
            case LiveChargingStatusState.completed:
              if (response.data != null) {
                final updatedData = response.data!.copyWith(
                  isCompletedSummary: true,
                );

                print('⚠️ Session ended with state=$state; keeping summary data for invoice');
                print('   Session ID: ${updatedData.sessionId} will be available for invoice');

                return LiveChargingResponse(
                  success: true,
                  data: updatedData,
                  message: response.message,
                );
              }
              return response;
            case LiveChargingStatusState.unknown:
              print('❓ Unknown state for status: $status');
              return response;
          }
        }

        print('ℹ️ No session data in response');
        return LiveChargingResponse(
          success: false,
          message: 'No active session',
          data: null,
        );
      } else if (response.statusCode == 401) {
        print('❌ Auth error: 401 - Token may be expired');
        return LiveChargingResponse(
          success: false,
          message: 'Session expired. Please login again.',
        );
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        return LiveChargingResponse(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      print('❌ Network error (SocketException): $e');
      print('   Please check your internet connection');
      return LiveChargingResponse(
        success: false,
        message: 'Network error. Please check your internet connection.',
      );
    } on TimeoutException catch (e) {
      print('❌ Timeout (TimeoutException): $e');
      print('   The request took too long to complete');
      return LiveChargingResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      print('❌ Unexpected error: $e');
      print('   Stack trace: ${StackTrace.current}');
      return LiveChargingResponse(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }
}