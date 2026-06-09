import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/vehicle_model.dart';
import '../Service/api_endpoints.dart';

class VehicleController {

  Future<bool> hasVehicles() async {
    final response = await fetchVehicles();
    return response.totalVehicles > 0;
  }

  Future<int> getTotalVehicles() async {
    final response = await fetchVehicles();
    return response.totalVehicles;
  }

  Future<VehicleResponse> fetchVehicles() async {
    try {
      final String apiUrl = ApiEndpoints.vehicles;
      String? token = await _getAccessToken();

      print('========== FETCHING VEHICLES ==========');
      print('URL: $apiUrl');
      print('Token Present: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        print('Authorization Header: $token');
      }
      print('========================================');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = token;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: headers,
      );

      print('========== FETCH VEHICLES RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=============================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check the status field (not success)
        if (responseData['status'] == true) {
          return VehicleResponse.fromJson(responseData);
        } else {
          return VehicleResponse(
            status: false,
            message: responseData['message'] ?? 'Failed to fetch vehicles',
            data: [],
            totalVehicles: 0,
          );
        }
      } else if (response.statusCode == 401) {
        print('========== UNAUTHORIZED ==========');
        print('Token may be expired or invalid');
        print('==================================');
        return VehicleResponse(
          status: false,
          message: 'Session expired. Please login again.',
          data: [],
          totalVehicles: 0,
        );
      } else {
        print('========== API ERROR ==========');
        print('Status Code: ${response.statusCode}');
        print('Error Body: ${response.body}');
        print('================================');
        return VehicleResponse(
          status: false,
          message: 'Failed to fetch vehicles',
          data: [],
          totalVehicles: 0,
        );
      }
    } catch (e) {
      print('========== FETCH VEHICLES ERROR ==========');
      print('Error Message: $e');
      print('==========================================');
      return VehicleResponse(
        status: false,
        message: "Network error. Please check your connection.",
        data: [],
        totalVehicles: 0,
      );
    }
  }

  Future<VehicleResponse> addVehicle(AddVehicleModel model) async {
    try {
      final String apiUrl = ApiEndpoints.addVehicle;
      String? token = await _getAccessToken();

      print('========== ADD VEHICLE REQUEST ==========');
      print('URL: $apiUrl');
      print('Token Present: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        print('Authorization Header: $token');
      }
      print('Request Body: ${jsonEncode(model.toJson())}');
      print('==========================================');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = token;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(model.toJson()),
      );

      print('========== ADD VEHICLE RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================================');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['status'] == true) {
          return VehicleResponse(
            status: true,
            message: responseData['message'] ?? 'Vehicle added successfully!',
            data: responseData['data'] != null ? [Vehicle.fromJson(responseData['data'])] : [],
          );
        } else {
          return VehicleResponse(
            status: false,
            message: responseData['message'] ?? 'Failed to add vehicle',
            data: [],
          );
        }
      } else if (response.statusCode == 401) {
        return VehicleResponse(
          status: false,
          message: 'Session expired. Please login again.',
          data: [],
        );
      } else {
        String errorMessage = 'Failed to add vehicle';
        if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        } else if (responseData['error'] != null) {
          errorMessage = responseData['error'];
        }
        return VehicleResponse(
          status: false,
          message: errorMessage,
          data: [],
        );
      }
    } catch (e) {
      print('========== ADD VEHICLE EXCEPTION ==========');
      print('Error Message: $e');
      print('==========================================');
      return VehicleResponse(
        status: false,
        message: "Network error. Please check your connection.",
        data: [],
      );
    }
  }

  Future<VehicleResponse> updateVehicle(String vehicleId, UpdateVehicleModel model) async {
    try {
      final String apiUrl = ApiEndpoints.updateVehicle(vehicleId);
      String? token = await _getAccessToken();

      print('========== UPDATE VEHICLE REQUEST ==========');
      print('URL: $apiUrl');
      print('Vehicle ID: $vehicleId');
      print('Token Present: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        print('Authorization Header: $token');
      }
      print('Request Body: ${jsonEncode(model.toJson())}');
      print('============================================');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = token;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(model.toJson()),
      );

      print('========== UPDATE VEHICLE RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=============================================');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['status'] == true) {
          return VehicleResponse(
            status: true,
            message: responseData['message'] ?? 'Vehicle updated successfully!',
            data: responseData['data'] != null ? [Vehicle.fromJson(responseData['data'])] : [],
          );
        } else {
          return VehicleResponse(
            status: false,
            message: responseData['message'] ?? 'Failed to update vehicle',
            data: [],
          );
        }
      } else if (response.statusCode == 401) {
        return VehicleResponse(
          status: false,
          message: 'Session expired. Please login again.',
          data: [],
        );
      } else {
        String errorMessage = 'Failed to update vehicle';
        if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        } else if (responseData['error'] != null) {
          errorMessage = responseData['error'];
        }
        return VehicleResponse(
          status: false,
          message: errorMessage,
          data: [],
        );
      }
    } catch (e) {
      print('========== UPDATE VEHICLE EXCEPTION ==========');
      print('Error Message: $e');
      print('==============================================');
      return VehicleResponse(
        status: false,
        message: "Network error. Please check your connection.",
        data: [],
      );
    }
  }

  Future<VehicleResponse> deleteVehicle(String vehicleId) async {
    try {
      final String apiUrl = ApiEndpoints.deleteVehicle(vehicleId);
      String? token = await _getAccessToken();

      print('========== DELETE VEHICLE REQUEST ==========');
      print('URL: $apiUrl');
      print('Vehicle ID: $vehicleId');
      print('Token Present: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        print('Authorization Header: $token');
      }
      print('============================================');

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = token;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode({}),
      );

      print('========== DELETE VEHICLE RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=============================================');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['status'] == true) {
          return VehicleResponse(
            status: true,
            message: responseData['message'] ?? 'Vehicle deleted successfully!',
            data: [],
          );
        } else {
          return VehicleResponse(
            status: false,
            message: responseData['message'] ?? 'Failed to delete vehicle',
            data: [],
          );
        }
      } else if (response.statusCode == 401) {
        return VehicleResponse(
          status: false,
          message: 'Session expired. Please login again.',
          data: [],
        );
      } else {
        String errorMessage = 'Failed to delete vehicle';
        if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        } else if (responseData['error'] != null) {
          errorMessage = responseData['error'];
        }
        return VehicleResponse(
          status: false,
          message: errorMessage,
          data: [],
        );
      }
    } catch (e) {
      print('========== DELETE VEHICLE EXCEPTION ==========');
      print('Error Message: $e');
      print('==============================================');
      return VehicleResponse(
        status: false,
        message: "Network error. Please check your connection.",
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