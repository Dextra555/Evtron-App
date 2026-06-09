import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../Model/complaint_response_model.dart';
import '../../Service/api_endpoints.dart';

class ComplaintService {

  Future<ComplaintResponse?> submitComplaint({
    required String subject,
    required String description,
  }) async {

    try {

      final prefs =
      await SharedPreferences.getInstance();

      final token =
      prefs.getString('access_token');

      final tokenType =
      prefs.getString('token_type');

      final response = await http.post(
        Uri.parse(ApiEndpoints.complaints),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization':
          '${tokenType ?? "Bearer"} $token',
        },
        body: jsonEncode({
          "subject": subject,
          "description": description,
        }),
      );

      print("========== COMPLAINT API ==========");
      print("Status Code : ${response.statusCode}");
      print("Response Body : ${response.body}");
      print("===================================");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        final jsonData =
        jsonDecode(response.body);

        return ComplaintResponse.fromJson(
          jsonData,
        );
      }

      return null;

    } catch (e) {

      print("Complaint API Error: $e");

      return null;
    }
  }
}