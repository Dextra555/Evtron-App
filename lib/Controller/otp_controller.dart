import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/otp_model.dart';
import '../Service/api_endpoints.dart';

class OtpController {
  Future<Map<String, dynamic>> verifyOtp(VerifyOtpModel model) async {
    try {
      print('========== VERIFY OTP REQUEST ==========');
      print('URL: http://evtron-dev.dextragroups.com/api/mobile/verify-otp');
      print('Request Body: ${jsonEncode(model.toJson())}');
      print('==========================================');

      final response = await http.post(
        Uri.parse(ApiEndpoints.verifyOtp),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(model.toJson()),
      );

      print('========== VERIFY OTP RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================================');

      final data = jsonDecode(response.body);

      print('========== PARSED RESPONSE DATA ==========');
      print('Full Response: $data');
      print('Status: ${data['status']}');
      print('Message: ${data['message']}');
      print('Access Token: ${data['access_token']}');
      print('Token Type: ${data['token_type']}');
      if (data['data'] != null) {
        print('User Data: ${data['data']}');
      }
      print('==========================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == true) {

          await _storeUserData(data);

          return {
            "success": true,
            "message": data['message'] ?? 'OTP Verified Successfully!',
          };
        } else {
          return {
            "success": false,
            "message": data['message'] ?? 'Invalid OTP. Please try again.',
          };
        }
      } else {
        String errorMessage = 'Invalid OTP. Please try again.';

        if (data['message'] != null) {
          errorMessage = data['message'];
        } else if (data['error'] != null) {
          errorMessage = data['error'];
        }

        return {
          "success": false,
          "message": errorMessage,
        };
      }
    } catch (e) {
      print('========== VERIFY OTP ERROR ==========');
      print('Error Message: $e');
      print('==========================================');

      return {
        "success": false,
        "message": "Network error. Please check your connection and try again.",
      };
    }
  }

  Future<Map<String, dynamic>> resendOtp(ResendOtpModel model) async {
    try {
      print('========== RESEND OTP REQUEST ==========');
      print('URL: http://evtron-dev.dextragroups.com/api/mobile/resend-otp');
      print('Request Body: ${jsonEncode(model.toJson())}');
      print('==========================================');

      final response = await http.post(
        Uri.parse(ApiEndpoints.resendOtp),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(model.toJson()),
      );

      print('========== RESEND OTP RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================================');

      final data = jsonDecode(response.body);

      print('========== PARSED RESPONSE DATA ==========');
      print('Full Response: $data');
      print('==========================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == true || data['success'] == true) {
          return {
            "success": true,
            "message": data['message'] ?? 'OTP resent successfully!',
          };
        } else {
          return {
            "success": false,
            "message": data['message'] ?? 'Failed to resend OTP',
          };
        }
      } else {
        String errorMessage = 'Failed to resend OTP';

        if (data['message'] != null) {
          errorMessage = data['message'];
        } else if (data['error'] != null) {
          errorMessage = data['error'];
        }

        return {
          "success": false,
          "message": errorMessage,
        };
      }
    } catch (e) {
      print('========== RESEND OTP ERROR ==========');
      print('Error Message: $e');
      print('==========================================');

      return {
        "success": false,
        "message": "Network error. Please check your connection and try again.",
      };
    }
  }

  Future<void> _storeUserData(Map<String, dynamic> responseData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String accessToken = responseData['access_token'] ?? '';
      String tokenType = responseData['token_type'] ?? 'Bearer';

      await prefs.setString('access_token', accessToken);
      await prefs.setString('token_type', tokenType);
      await prefs.setString('full_token', '$tokenType $accessToken');

      if (responseData.containsKey('data')) {
        final userData = responseData['data'];

        await prefs.setInt('user_id', userData['id'] ?? 0);
        await prefs.setString('user_name', userData['name'] ?? '');
        await prefs.setString('user_email', userData['email'] ?? '');
        await prefs.setString('user_phone', userData['phone'] ?? '');
        await prefs.setString('user_role', userData['role'] ?? 'user');
        await prefs.setString('user_created_at', userData['created_at'] ?? '');
        await prefs.setString('user_updated_at', userData['updated_at'] ?? '');

        await prefs.setString('user_data', jsonEncode(userData));
      }

      await prefs.setBool('is_logged_in', true);

      print('========== STORED IN SHARED PREFERENCES ==========');
      print('Access Token: $accessToken');
      print('Token Type: $tokenType');
      print('User ID: ${prefs.getInt('user_id')}');
      print('User Name: ${prefs.getString('user_name')}');
      print('User Email: ${prefs.getString('user_email')}');
      print('User Phone: ${prefs.getString('user_phone')}');
      print('Is Logged In: ${prefs.getBool('is_logged_in')}');
      print('===================================================');

    } catch (e) {
      print('Error storing user data: $e');
    }
  }
}

