// lib/Service/live_charging_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/live_charging_model.dart';  // Import the model
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
    return normalized.contains('timeout') || normalized.contains('network') || normalized.contains('socket');
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

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      print('📥 Response: ${response.statusCode} (${response.body.length} bytes)');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['data'] != null) {
          final data = responseData['data'];
          final status = data['status']?.toString() ?? '';
          final state = classifyChargingStatus(status);

          print('⚡ Live: session=${data['session_id']}, status=$status');

          // ✅ Parse the response first
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
        print('❌ Auth error: 401');
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
      print('❌ Network error: $e');
      return LiveChargingResponse(
        success: false,
        message: 'Network error. Please check your internet connection.',
      );
    } on TimeoutException catch (e) {
      print('❌ Timeout: $e');
      return LiveChargingResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      print('❌ Error: $e');
      return LiveChargingResponse(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }
}