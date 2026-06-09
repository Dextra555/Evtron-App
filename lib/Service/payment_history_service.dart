import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Model/payment_history_model.dart';
import 'AuthService.dart';
import 'api_endpoints.dart';

class PaymentHistoryService {

  Future<List<PaymentHistoryModel>>
  getPaymentHistory() async {

    try {

      String? token =
      await AuthService.getUserToken();

      print(
        "================ PAYMENT API ================",
      );

      print(
        "TOKEN : $token",
      );

      print(
        "API URL : ${ApiEndpoints.payments}",
      );

      final response = await http.get(

        Uri.parse(ApiEndpoints.payments),

        headers: {

          "Accept": "application/json",

          "Authorization":
          "Bearer $token",
        },
      );

      print(
        "STATUS CODE : ${response.statusCode}",
      );

      print(
        "RESPONSE BODY : ${response.body}",
      );

      print(
        "============================================",
      );

      if (response.statusCode == 200) {

        final jsonData =
        jsonDecode(response.body);

        print(
          "SUCCESS : ${jsonData['success']}",
        );

        print(
          "TOTAL RECORDS : ${jsonData['data'].length}",
        );

        if (jsonData['success'] == true) {

          List data = jsonData['data'];

          return data.map((e) {

            print(
              "PAYMENT ITEM : $e",
            );

            return PaymentHistoryModel
                .fromJson(e);

          }).toList();
        }
      }

      return [];

    } catch (e) {

      print(
        "PAYMENT HISTORY ERROR : $e",
      );

      return [];
    }
  }
}