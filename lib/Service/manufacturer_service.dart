import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/manufacturer_model.dart';
import 'api_endpoints.dart';

class ManufacturerService {

  Future<ManufacturerResponse> fetchManufacturers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final tokenType = prefs.getString('token_type');

      if (token == null) {
        return ManufacturerResponse(
          success: false,
          data: [],
        );
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.manufacturers),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': '${tokenType ?? "Bearer"} $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ManufacturerResponse.fromJson(responseData);
      } else {
        return ManufacturerResponse(
          success: false,
          data: [],
        );
      }
    } catch (e) {
      print('Error fetching manufacturers: $e');
      return ManufacturerResponse(
        success: false,
        data: [],
      );
    }
  }

  // Fetch models by manufacturer ID
  Future<VehicleModelResponse> fetchModels(int manufacturerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final tokenType = prefs.getString('token_type');

      if (token == null) {
        return VehicleModelResponse(
          success: false,
          data: [],
        );
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.models(manufacturerId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': '${tokenType ?? "Bearer"} $token',
        },
      );

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
      print('Error fetching models: $e');
      return VehicleModelResponse(
        success: false,
        data: [],
      );
    }
  }
}