// lib/Service/scan_validation_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evtron/Model/scan_validation_model.dart';
import 'package:evtron/Service/api_endpoints.dart';
import 'package:geolocator/geolocator.dart';

class ScanValidationService {

  /// Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permission permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {
      print('⚠️ Error getting location: $e');
      return null;
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      print('🔑 Token found: ${token != null ? "Yes" : "No"}');
      return token;
    } catch (e) {
      print('❌ Error getting auth token: $e');
      return null;
    }
  }

  Future<ScanValidationResponse> validateScan({
    required String scannedData,
    double? latitude,
    double? longitude,
    int? vehicleId,
  }) async {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║           SCAN VALIDATION SERVICE - STARTING                 ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('📝 Scanned Data: $scannedData');
    print('⏰ Timestamp: ${DateTime.now()}');

    try {
      // Get auth token
      final authToken = await _getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        print('❌ No auth token found!');
        return ScanValidationResponse(
          success: false,
          message: 'Please login to continue.',
          statusCode: 401,
          failedCheck: 'user_not_authenticated',
          errorCode: 'NOT_AUTHENTICATED',
          errorDescription: 'User not authenticated',
        );
      }

      // Get location if not provided
      Position? currentPosition;
      if (latitude == null || longitude == null) {
        currentPosition = await _getCurrentLocation();
      }

      // Build request body
      final Map<String, dynamic> requestBody = {
        'scanned_data': scannedData,
      };

      // Add latitude if available
      if (latitude != null) {
        requestBody['latitude'] = latitude;
      } else if (currentPosition != null) {
        requestBody['latitude'] = currentPosition.latitude;
        requestBody['longitude'] = currentPosition.longitude;
      }

      // Add longitude if available
      if (longitude != null) {
        requestBody['longitude'] = longitude;
      } else if (currentPosition != null) {
        requestBody['longitude'] = currentPosition.longitude;
      }

      // Add vehicle_id if provided
      if (vehicleId != null) {
        requestBody['vehicle_id'] = vehicleId;
      }

      final url = Uri.parse(ApiEndpoints.validateScan);
      final requestBodyJson = jsonEncode(requestBody);

      print('\n📤 REQUEST DETAILS:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🌐 URL: ${url.toString()}');
      print('📝 Method: POST');
      print('📦 Body: $requestBodyJson');
      print('🔑 Auth: Bearer ${authToken.substring(0, authToken.length > 20 ? 20 : authToken.length)}...');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: requestBodyJson,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ Request timeout after 30 seconds');
          throw TimeoutException('Request timeout');
        },
      );

      // Print raw response
      print('\n📥 RAW HTTP RESPONSE:');
      print('═══════════════════════════════════════════════════════════════');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 BODY:');
      print('────────────────────────────────────────────────────────────────');
      print(response.body);
      print('────────────────────────────────────────────────────────────────');
      print('═══════════════════════════════════════════════════════════════');

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Handle different status codes
      switch (response.statusCode) {
        case 200:
          print('\n✅✅✅ SUCCESS! Validation passed!');
          return ScanValidationResponse.fromJson(responseData, statusCode: 200);

        case 201:
          print('\n✅✅✅ SUCCESS! Validation passed!');
          return ScanValidationResponse.fromJson(responseData, statusCode: 201);

        case 400:
          print('\n❌ BAD REQUEST (400)');
          return ScanValidationResponse.fromJson(responseData, statusCode: 400);

        case 401:
          print('\n❌ UNAUTHORIZED (401)');
          return ScanValidationResponse(
            success: false,
            message: 'Please login to continue.',
            statusCode: 401,
            failedCheck: 'user_not_authenticated',
            errorCode: 'NOT_AUTHENTICATED',
            errorDescription: 'User not authenticated',
          );

        case 404:
          print('\n❌ NOT FOUND (404)');
          return ScanValidationResponse.fromJson(responseData, statusCode: 404);

        case 422:
          print('\n❌ UNPROCESSABLE ENTITY (422)');
          return ScanValidationResponse.fromJson(responseData, statusCode: 422);

        default:
          print('\n❌ UNKNOWN STATUS CODE: ${response.statusCode}');
          return ScanValidationResponse(
            success: false,
            message: responseData['message'] ?? 'An unexpected error occurred',
            statusCode: response.statusCode,
          );
      }

    } on SocketException catch (e) {
      print('\n❌ NETWORK ERROR: $e');
      return ScanValidationResponse(
        success: false,
        message: 'Network error. Please check your internet connection.',
        statusCode: 0,
      );
    } on TimeoutException catch (e) {
      print('\n❌ TIMEOUT ERROR: $e');
      return ScanValidationResponse(
        success: false,
        message: 'Request timeout. Please try again.',
        statusCode: 0,
      );
    } catch (e) {
      print('\n❌ UNEXPECTED ERROR: $e');
      return ScanValidationResponse(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
        statusCode: 500,
      );
    }
  }
}