import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Model/charging_history_details_model.dart';
import '../Service/api_endpoints.dart';

class ChargingHistoryDetailsController {

  Future<ChargingHistoryDetailsModel?> getChargingDetails(
      int chargerHistoryId,
      String token,
      ) async {
    try {
      final url = ApiEndpoints.chargingHistoryDetails(chargerHistoryId);

      print("================================");
      print("Charging Details API Called");
      print("URL: $url");
      print("ID: $chargerHistoryId");
      print("Token: $token");
      print("================================");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("================================");
      print("Status Code: ${response.statusCode}");
      print("Response Body:");
      print(response.body);
      print("================================");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        return ChargingHistoryDetailsModel.fromJson(
          jsonData['data'],
        );
      }

      return null;
    } catch (e) {
      print("================================");
      print("Charging Details Error");
      print(e.toString());
      print("================================");
      return null;
    }
  }


}