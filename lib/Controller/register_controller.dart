import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/register_model.dart';
import '../Service/AuthService.dart';
import '../Service/api_endpoints.dart';

class RegisterController {
  Future<Map<String, dynamic>> createAccount(RegisterModel model) async {
    try {
      print('========== REGISTRATION REQUEST ==========');
      print('URL: http://evtron-dev.dextragroups.com/api/mobile/register');
      print('Request Body: ${jsonEncode(model.toJson())}');
      print('==========================================');

      final response = await http.post(
        Uri.parse(ApiEndpoints.register),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(model.toJson()),
      );

      print('========== REGISTRATION RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================================');

      final data = jsonDecode(response.body);

      print('========== PARSED RESPONSE DATA ==========');
      print('Status: ${data['status']}');
      print('Message: ${data['message']}');
      print('Data: ${data['data']}');
      print('==========================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if registration was successful
        if (data["status"] == true || data["status"] == "success") {
          // Extract user data from response
          String? userName = model.name; // Use the name from registration model
          String? userPhone = model.phone;
          String? userEmail = model.email;
          String? userToken = data['data']['token'] ?? data['token']; // Adjust based on API response

          // Save user data including name
          await AuthService.setLoggedIn(
            true,
            phone: userPhone,
            token: userToken,
            name: userName,
            email: userEmail,
          );

          return {
            "success": true,
            "message": data["message"] ?? "Account created successfully",
            "data": data["data"],
          };
        }

        return {
          "success": false,
          "message": data["message"] ?? "Registration failed",
        };
      } else {
        // Handle validation errors from Laravel
        if (data['errors'] != null) {
          final errors = data['errors'];
          String errorMessage = '';

          if (errors is Map) {
            // Extract first error message
            errorMessage = errors.values.first.first;
            print('Validation Error: $errorMessage');
          }

          return {
            "success": false,
            "message": errorMessage.isNotEmpty ? errorMessage : (data["message"] ?? "Registration failed")
          };
        }

        return {
          "success": false,
          "message": data["message"] ?? "Registration failed"
        };
      }
    } catch (e) {
      print('========== REGISTRATION ERROR ==========');
      print('Error Message: $e');
      print('==========================================');

      return {
        "success": false,
        "message": "Network error. Please check your connection and try again."
      };
    }
  }
}