import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:evtron/Service/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/profile_model.dart';
import '../Service/api_endpoints.dart';

class ProfileController {

  Future<UserProfile?> fetchUserProfile() async {
    try {
      final String apiUrl = ApiEndpoints.profile;

      String? token = await _getAccessToken();

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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          if (responseData.containsKey('data')) {
            return UserProfile.fromJson(responseData['data']);
          } else {
            return UserProfile.fromJson(responseData);
          }
        } else {
          throw Exception(responseData['message'] ?? "Failed to load profile");
        }
      }

      if (response.statusCode == 401) {
        throw Exception("UNAUTHORIZED");
      }

      throw Exception("SERVER_ERROR");

    } on NetworkException catch (_) {
      print('⚠️ No internet connection detected while loading profile');
      throw Exception("NO_INTERNET");
    } on SocketException {
      throw Exception("NO_INTERNET");
    } on HttpException {
      throw Exception("NO_INTERNET");
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow;
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
