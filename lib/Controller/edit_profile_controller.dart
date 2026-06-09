import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/edit_profile_model.dart';
import '../Service/api_endpoints.dart';

class EditProfileController {
  Future<UpdateProfileResponse> updateProfile(EditProfileModel model) async {
    try {
      final String apiUrl =
          ApiEndpoints.updateProfile;

      String? token = await _getAccessToken();

      print('========== UPDATE PROFILE REQUEST ==========');
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

      print('========== UPDATE PROFILE RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================================');

      final responseData = jsonDecode(response.body);

      print('========== PARSED RESPONSE ==========');
      print('Full Response: $responseData');
      print('Status: ${responseData['status']}');
      print('Message: ${responseData['message']}');
      print('=====================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['status'] == true) {
          await _updateStoredUserData(model, responseData);
          return UpdateProfileResponse.fromJson(responseData);
        } else {
          return UpdateProfileResponse(
            success: false,
            message: responseData['message'] ?? 'Failed to update profile',
          );
        }
      } else if (response.statusCode == 401) {
        print('========== UNAUTHORIZED ==========');
        print('Token may be expired or invalid');
        print('==================================');

        return UpdateProfileResponse(
          success: false,
          message: 'Session expired. Please login again.',
        );
      } else {
        String errorMessage = 'Failed to update profile';

        if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        } else if (responseData['error'] != null) {
          errorMessage = responseData['error'];
        }

        print('========== API ERROR ==========');
        print('Status Code: ${response.statusCode}');
        print('Error Message: $errorMessage');
        print('================================');

        return UpdateProfileResponse(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      print('========== UPDATE PROFILE ERROR ==========');
      print('Error Message: $e');
      print('==========================================');

      return UpdateProfileResponse(
        success: false,
        message: "Network error. Please check your connection.",
      );
    }
  }

  Future<String?> _getAccessToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      String? tokenType = prefs.getString('token_type');

      print('========== TOKEN RETRIEVAL FOR UPDATE ==========');
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

  Future<void> _updateStoredUserData(EditProfileModel model, Map<String, dynamic> responseData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Update user data if available in response
      if (responseData.containsKey('data')) {
        final userData = responseData['data'];

        await prefs.setString('user_name', userData['name'] ?? model.name);
        await prefs.setString('user_email', userData['email'] ?? model.email);
        await prefs.setString('user_phone', userData['phone'] ?? model.phone);

        // Update full user data JSON
        String? existingUserData = prefs.getString('user_data');
        if (existingUserData != null) {
          Map<String, dynamic> userDataMap = jsonDecode(existingUserData);
          userDataMap['name'] = userData['name'] ?? model.name;
          userDataMap['email'] = userData['email'] ?? model.email;
          userDataMap['phone'] = userData['phone'] ?? model.phone;
          await prefs.setString('user_data', jsonEncode(userDataMap));
        }

        print('========== STORED USER DATA UPDATED ==========');
        print('Updated Name: ${userData['name'] ?? model.name}');
        print('Updated Email: ${userData['email'] ?? model.email}');
        print('Updated Phone: ${userData['phone'] ?? model.phone}');
        print('===============================================');
      } else {
        // If no data object in response, update with current values
        await prefs.setString('user_name', model.name);
        await prefs.setString('user_email', model.email);
        await prefs.setString('user_phone', model.phone);

        print('========== STORED USER DATA UPDATED ==========');
        print('Updated Name: ${model.name}');
        print('Updated Email: ${model.email}');
        print('Updated Phone: ${model.phone}');
        print('===============================================');
      }
    } catch (e) {
      print('Error updating stored user data: $e');
    }
  }
}