
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/login_model.dart';
import '../Service/api_endpoints.dart';

class LoginController {
  Future<Map<String, dynamic>> sendOtp(SendOtpModel model) async {
    try {
      print('========== SEND OTP REQUEST ==========');
      print('URL: http://evtron-dev.dextragroups.com/api/mobile/send-otp');
      print('Request Body: ${jsonEncode(model.toJson())}');
      print('==========================================');

      final response = await http.post(
        Uri.parse(ApiEndpoints.sendOtp),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(model.toJson()),
      );

      print('========== SEND OTP RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================================');

      final data = jsonDecode(response.body);

      print('========== PARSED RESPONSE DATA ==========');
      print('Full Response: $data');
      print('==========================================');

      if (response.statusCode == 429) {
        return {
          "success": false,
          "message": "Too many attempts. Please wait a moment and try again.",
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {

        String otp = data['otp']?.toString() ?? '';
        return {
          "success": data["status"] == true || data["success"] == true,
          "message": data["message"] ?? "OTP sent successfully!",
          "otp": otp,
        };
      } else {
        String errorMessage = 'Failed to send OTP';

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
      print('========== SEND OTP ERROR ==========');
      print('Error Message: $e');
      print('==========================================');

      return {
        "success": false,
        "message": "Network error. Please check your connection and try again.",
      };
    }
  }
}

