import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:evtron/Service/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/manufacturer_model.dart';
import '../Service/api_endpoints.dart';

class SettingsController {

  Future<ManufacturerResponse> fetchManufacturers() async {
    try {
      final String apiUrl = ApiEndpoints.manufacturers;
      String? token = await _getAccessToken();

      print('========== FETCHING MANUFACTURERS ==========');
      print('URL: $apiUrl');
      print('============================================');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = token;
      }

      final response = await NetworkService.get(
        Uri.parse(apiUrl),
        headers: headers,
      );

      print('========== MANUFACTURERS RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('============================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ManufacturerResponse.fromJson(responseData);
      } else {
        return ManufacturerResponse(
          success: false,
          data: [],
        );
      }
    } on SocketException catch (e) {
      print('NETWORK ERROR: No internet connection while fetching manufacturers');
      print('Error Message: $e');
      rethrow;
    } on TimeoutException catch (e) {
      print('NETWORK ERROR: Request timed out while fetching manufacturers');
      print('Error Message: $e');
      rethrow;
    } on http.ClientException catch (e) {
      print('NETWORK ERROR: ClientException while fetching manufacturers');
      print('Error Message: $e');
      rethrow;
    } on FormatException catch (e) {
      print('PARSE ERROR: Invalid manufacturer response');
      print('Error Message: $e');
      return ManufacturerResponse(
        success: false,
        data: [],
      );
    } catch (e, stackTrace) {
      print('UNKNOWN ERROR: Failed to fetch manufacturers');
      print('Error Message: $e');
      print(stackTrace);
      return ManufacturerResponse(
        success: false,
        data: [],
      );
    }
  }

  Future<VehicleModelResponse> fetchModels(int manufacturerId) async {
    try {
      final String apiUrl = ApiEndpoints.models(manufacturerId);
      String? token = await _getAccessToken();

      print('========== FETCHING MODELS ==========');
      print('URL: $apiUrl');
      print('Manufacturer ID: $manufacturerId');
      print('=====================================');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = token;
      }

      final response = await NetworkService.get(
        Uri.parse(apiUrl),
        headers: headers,
      );

      print('========== MODELS RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=====================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return VehicleModelResponse.fromJson(responseData);
      } else {
        return VehicleModelResponse(
          success: false,
          data: [],
        );
      }
    } catch (e) {
      print('========== FETCH MODELS ERROR ==========');
      print('Error Message: $e');
      print('========================================');
      return VehicleModelResponse(
        success: false,
        data: [],
      );
    }
  }

  Future<String?> _getAccessToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      String? tokenType = prefs.getString('token_type');

      print('========== TOKEN RETRIEVAL FOR VEHICLES ==========');
      print('Access Token: $token');
      print('Token Type: $tokenType');

      if (token != null && tokenType != null) {
        return '$tokenType $token';
      } else if (token != null) {
        return 'Bearer $token';
      }
      return null;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

}
