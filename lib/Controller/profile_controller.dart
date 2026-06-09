import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/profile_model.dart';
import '../Service/api_endpoints.dart';

class ProfileController {
  Future<UserProfile?> fetchUserProfile() async {
    try {
      final String apiUrl =
          ApiEndpoints.profile;

      String? token = await _getAccessToken();

      print('========== FETCHING USER PROFILE ==========');
      print('URL: $apiUrl');
      print('Token Present: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        print('Authorization Header: $token');
      }
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

      print('========== API RESPONSE ==========');
      print('URL: $apiUrl');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==================================');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        print('========== PARSED DATA ==========');
        print('Full Response Data: $responseData');
        print('==================================');

        if (responseData['status'] == true) {
          if (responseData.containsKey('data')) {
            final userData = responseData['data'];
            print('========== USER DATA (from data field) ==========');
            print('Name: ${userData['name']}');
            print('Phone: ${userData['phone']}');
            print('Email: ${userData['email']}');
            print('User ID: ${userData['id']}');
            print('Role: ${userData['role']}');
            print('Created At: ${userData['created_at']}');
            print('Updated At: ${userData['updated_at']}');
            print('==================================================');

            return UserProfile.fromJson(userData);
          } else {
            print('========== USER DATA (from root) ==========');
            print('Name: ${responseData['name']}');
            print('Phone: ${responseData['phone']}');
            print('Email: ${responseData['email']}');
            print('User ID: ${responseData['id']}');
            print('==========================================');

            return UserProfile.fromJson(responseData);
          }
        } else {
          print('========== API STATUS ERROR ==========');
          print('Message: ${responseData['message']}');
          print('======================================');
          return null;
        }
      } else if (response.statusCode == 401) {
        print('========== UNAUTHORIZED ==========');
        print('Token may be expired or invalid');
        print('==================================');
        return null;
      } else {
        print('========== API ERROR ==========');
        print('Status Code: ${response.statusCode}');
        print('Error Body: ${response.body}');
        print('================================');
        return null;
      }
    } catch (e) {
      print('========== EXCEPTION CAUGHT ==========');
      print('Error: $e');
      print('======================================');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('========== LOGOUT ==========');
      print('User logged out successfully');
      print('=============================');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<String?> _getAccessToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      String? tokenType = prefs.getString('token_type');

      print('========== TOKEN RETRIEVAL ==========');
      print('Access Token: $token');
      print('Token Type: $tokenType');
      print('Full Token: $tokenType $token');
      print('======================================');

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