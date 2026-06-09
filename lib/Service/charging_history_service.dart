import 'dart:convert';

import 'package:http/http.dart' as http;
import '../Model/charging_history_model.dart';
import 'api_endpoints.dart';

class ChargingHistoryService {

  Future<List<ChargingHistoryModel>>
  getChargingHistory() async {

    try {

      print(
        "API URL : ${ApiEndpoints.chargingHistory}",
      );

      final response = await http.get(
        Uri.parse(ApiEndpoints.chargingHistory),
      );

      /// STATUS CODE
      print(
        "STATUS CODE : ${response.statusCode}",
      );

      /// FULL RESPONSE
      print(
        "RESPONSE BODY : ${response.body}",
      );

      if (response.statusCode == 200) {

        final jsonData =
        jsonDecode(response.body);

        print(
          "JSON RESPONSE : $jsonData",
        );

        if (jsonData['success'] == true) {

          List data = jsonData['data'];

          print(
            "TOTAL RECORDS : ${data.length}",
          );

          return data.map((e) {

            print(
              "ITEM : $e",
            );

            return ChargingHistoryModel
                .fromJson(e);

          }).toList();
        }
      }

      return [];

    } catch (e) {

      print(
        "CHARGING HISTORY ERROR : $e",
      );

      return [];
    }
  }
}