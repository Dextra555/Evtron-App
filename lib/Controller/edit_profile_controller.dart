import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/edit_profile_model.dart';
import '../Service/api_endpoints.dart';

class EditProfileController {
  // Fetch profile data
  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final String apiUrl = ApiEndpoints.profile;
      String? token = await _getAccessToken();

      print('========== FETCH PROFILE REQUEST ==========');
      print('URL: $apiUrl');
      print('Token Present: ${token != null ? "Yes" : "No"}');
      print('==========================================');

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

      print('========== FETCH PROFILE RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == true && responseData.containsKey('data')) {
          // Store the profile data locally
          await _storeProfileData(responseData['data']);

          return responseData['data'];
        }
      } else if (response.statusCode == 401) {
        // Handle unauthorized - session expired
        print('Session expired, need to login again');
      }
      return null;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<void> _storeProfileData(Map<String, dynamic> userData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('user_name', userData['name'] ?? '');
      await prefs.setString('user_email', userData['email'] ?? '');
      await prefs.setString('user_phone', userData['phone'] ?? '');
      await prefs.setString('user_business_name', userData['business_name'] ?? '');
      await prefs.setString('user_address', userData['address'] ?? '');
      await prefs.setString('user_gst_number', userData['gst_number'] ?? '');
      await prefs.setBool('user_company_profile', userData['company_profile'] ?? false);

      // Store full user data
      await prefs.setString('user_data', jsonEncode(userData));

      print('========== PROFILE DATA STORED ==========');
      print('Name: ${userData['name']}');
      print('Business Name: ${userData['business_name']}');
      print('Address: ${userData['address']}');
      print('GST Number: ${userData['gst_number']}');
      print('Company Profile: ${userData['company_profile']}');
      print('=========================================');
    } catch (e) {
      print('Error storing profile data: $e');
    }
  }

  Future<UpdateProfileResponse> updateProfile(EditProfileModel model) async {
    try {
      final String apiUrl = ApiEndpoints.updateProfile;
      String? token = await _getAccessToken();

      print('========== UPDATE PROFILE REQUEST ==========');
      print('URL: $apiUrl');
      print('Token Present: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        print('Authorization Header: $token');
      }

      final Map<String, dynamic> requestBody = model.toJson();
      print('Request Body: ${jsonEncode(requestBody)}');
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
        body: jsonEncode(requestBody),
      );

      print('========== UPDATE PROFILE RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================================');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['status'] == true) {
          // Store updated user data
          if (responseData.containsKey('user')) {
            await _storeProfileData(responseData['user']);
          }
          return UpdateProfileResponse.fromJson(responseData);
        } else {
          return UpdateProfileResponse(
            success: false,
            message: responseData['message'] ?? 'Failed to update profile',
          );
        }
      } else if (response.statusCode == 401) {
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

class UpdateProfileResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? userData;

  UpdateProfileResponse({
    required this.success,
    required this.message,
    this.userData,
  });

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      success: json['status'] == true,
      message: json['message'] ?? (json['status'] == true ? 'Profile updated successfully' : 'Failed to update profile'),
      userData: json['user'],
    );
  }
}