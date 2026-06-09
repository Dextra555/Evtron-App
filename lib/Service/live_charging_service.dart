// lib/Services/live_charging_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/live_charging_model.dart';
import 'api_endpoints.dart';

class LiveChargingService {

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      print('========== LIVE CHARGING TOKEN DEBUG ==========');
      print('Token found: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        print('Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }
      print('================================================');
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

      final url = Uri.parse(ApiEndpoints.liveCharging);

      print('\n╔══════════════════════════════════════════════════════════════╗');
      print('║              LIVE CHARGING SERVICE - API CALL                 ║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('\n🌐 API Endpoint: ${url.toString()}');
      print('📝 HTTP Method: GET');
      print('📦 Request Headers:');
      print('   • Content-Type: application/json');
      print('   • Accept: application/json');

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

      if (sessionId != null) {
        print('📝 Query Parameters:');
        print('   • session_id: $sessionId');
      }

      print('\n⏳ Sending HTTP request to server...');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(rawResponse);

        print('\n✅ LIVE CHARGING DATA RECEIVED SUCCESSFULLY!');

        if (responseData['data'] != null) {
          final data = responseData['data'];
          print('\n📊 PARSED LIVE DATA:');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('Session ID: ${data['session_id']}');
          print('Transaction ID: ${data['transaction_id']}');
          print('Status: ${data['status']}');
          print('Started At: ${data['started_at']}');
          print('\n⏱️ Elapsed Time:');
          print('   • Formatted: ${data['elapsed_time']?['formatted']}');
          print('   • Minutes: ${data['elapsed_time']?['minutes']}');
          print('\n⚡ Energy:');
          print('   • Consumed: ${data['energy']?['consumed_kwh']} kWh');
          print('   • Power: ${data['energy']?['power_kw']} kW');
          print('\n💰 Cost:');
          print('   • Total: ${data['cost']?['total']} ${data['cost']?['currency']}');
          print('\n🔌 Charger: ${data['charger']?['name']} (${data['charger']?['power_capacity']} kW)');
          print('⚡ Connector: ${data['connector']?['name']} (${data['connector']?['type']})');
          print('📍 Station: ${data['station']?['name']}');
        }

        print('\n╔══════════════════════════════════════════════════════════════╗');
        print('║              END OF LIVE CHARGING API RESPONSE                ║');
        print('╚══════════════════════════════════════════════════════════════╝\n');

        return LiveChargingResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        print('\n❌ AUTHENTICATION ERROR: 401 Unauthorized');
        print('╔══════════════════════════════════════════════════════════════╗');
        print('║              END OF LIVE CHARGING API RESPONSE                ║');
        print('╚══════════════════════════════════════════════════════════════╝\n');

        return LiveChargingResponse(
          success: false,
          message: 'Session expired. Please login again.',
        );
      } else {
        print('\n❌ HTTP ERROR: ${response.statusCode}');
        print('╔══════════════════════════════════════════════════════════════╗');
        print('║              END OF LIVE CHARGING API RESPONSE                ║');
        print('╚══════════════════════════════════════════════════════════════╝\n');

        return LiveChargingResponse(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      print('\n❌ NETWORK ERROR: $e');
      return LiveChargingResponse(
        success: false,
        message: 'Network error. Please check your internet connection.',
      );
    } on TimeoutException catch (e) {
      print('\n❌ TIMEOUT ERROR: $e');
      return LiveChargingResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      print('\n❌ EXCEPTION: $e');
      return LiveChargingResponse(
        success: false,
        message: 'Error: ${e.toString()}',
      );
    }
  }
}