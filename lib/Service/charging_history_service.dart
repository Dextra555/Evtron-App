import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/charging_history_model.dart';
import 'api_endpoints.dart';

class ChargingHistoryService {

  Future<List<ChargingHistoryModel>> getChargingHistory(String token) async {
    try {
      print('========== CHARGING HISTORY API DEBUG ==========');
      print('Token length: ${token.length}');
      print('Token preview: ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
      print('API URL: ${ApiEndpoints.chargingHistory}');
      print('================================================');

      final response = await http.get(
        Uri.parse(ApiEndpoints.chargingHistory),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection.');
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        List data;
        if (jsonData['data'] != null) {
          data = jsonData['data'];
          print('📊 Found ${data.length} records in jsonData["data"]');
        } else if (jsonData is List) {
          data = jsonData;
          print('📊 Found ${data.length} records in jsonData list');
        } else {
          data = [];
          print('⚠️ No data field found and response is not a list');
        }

        if (data.isEmpty) {
          print('ℹ️ No charging history records found');
          return [];
        }

        final historyList = data.map((e) => ChargingHistoryModel.fromJson(e)).toList();
        print('✅ Successfully parsed ${historyList.length} charging history records');
        return historyList;

      } else if (response.statusCode == 401) {
        print('❌ Unauthorized! Token may be invalid or expired');
        throw Exception('Session expired. Please login again.');
      } else {
        print('❌ Failed with status code: ${response.statusCode}');
        throw Exception('Failed to load charging history. Status: ${response.statusCode}');
      }

    } catch (e) {
      print('❌ Exception in getChargingHistory: $e');
      throw Exception(e.toString());
    }
  }
}

