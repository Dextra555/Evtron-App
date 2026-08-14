import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:evtron/Service/network_service.dart';
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

      final response = await NetworkService.get(
        Uri.parse(ApiEndpoints.chargingHistory),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
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

    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      print('❌ Exception in getChargingHistory: $e');
      print(stackTrace);
      throw Exception('Failed to load charging history. Please try again.');
    }
  }
}


