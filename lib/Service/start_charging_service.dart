
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/start_charging_model.dart';
import 'api_endpoints.dart';

class ChargingService {
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      print('========== TOKEN DEBUG (ChargingService) ==========');
      print('Token found: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        print('Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }
      print('====================================================');
      return token;
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  Future<ChargingSessionResponse> startCharging({
    required String chargerId,  // Changed from int to String
  }) async {
    try {
      final request = StartChargingRequest(
        chargerId: chargerId,  // Now passing string directly
      );

      final authToken = await _getAuthToken();
      final url = Uri.parse(ApiEndpoints.startCharging);
      final requestBody = jsonEncode(request.toJson());

      print('\n╔══════════════════════════════════════════════════════════════╗');
      print('║                 CHARGING SERVICE - API CALL                    ║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('\n🌐 API Endpoint: ${url.toString()}');
      print('📝 HTTP Method: POST');
      print('🔑 Charger ID (String): $chargerId');  // Updated log
      print('📤 Request Body: $requestBody');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
        print('   • Authorization: Bearer ${authToken.substring(0, authToken.length > 20 ? 20 : authToken.length)}...');
      } else {
        print('   ⚠️ No Authorization token found!');
      }

      print('\n⏳ Sending HTTP request to server...');

      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ Request timeout after 30 seconds');
          throw TimeoutException('Request timeout');
        },
      );

      print('\n📥 HTTP Response Received!');
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

      // Try to parse the response body for all status codes
      try {
        final Map<String, dynamic> responseData = jsonDecode(rawResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('\n✅ JSON PARSED SUCCESSFULLY!');
          final chargingResponse = ChargingSessionResponse.fromJson(responseData);
          return chargingResponse;
        } else {
          // For error responses (400, 401, 422, 500, etc.), extract the message from response body
          String errorMessage = responseData['message'] ?? 'HTTP Error: ${response.statusCode}';

          // Extract detailed validation errors if present
          if (responseData['errors'] != null) {
            final errors = responseData['errors'] as Map<String, dynamic>;
            final errorMessages = errors.values.map((e) => e.toString()).join(', ');
            errorMessage = '$errorMessage $errorMessages';
          }

          print('\n❌ ERROR RESPONSE: $errorMessage');

          return ChargingSessionResponse(
            success: false,
            message: errorMessage, // Return the actual error message from API
          );
        }
      } catch (parseError) {
        // If response body is not JSON, return generic error
        print('\n❌ Failed to parse response body: $parseError');
        return ChargingSessionResponse(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      print('\n❌ NETWORK ERROR: $e');
      return ChargingSessionResponse(
        success: false,
        message: 'Network error. Please check your internet connection.',
      );
    } on TimeoutException catch (e) {
      print('\n❌ TIMEOUT ERROR: $e');
      return ChargingSessionResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      print('\n❌ EXCEPTION: $e');
      return ChargingSessionResponse(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }

}