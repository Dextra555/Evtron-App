// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../Model/charger_model.dart';
//
// class ChargerController extends ChangeNotifier {
//   static const String CHARGER_API_BASE_URL = 'http://evtron-dev.dextragroups.com/api/mobile/station-chargers';
//
//   List<ChargerModel> _chargers = [];
//   bool _isLoading = false;
//   String _errorMessage = '';
//
//   List<ChargerModel> get chargers => _chargers;
//   bool get isLoading => _isLoading;
//   String get errorMessage => _errorMessage;
//
//   Future<String?> _getAuthToken() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('access_token');
//       return token;
//     } catch (e) {
//       debugPrint('Error getting auth token: $e');
//       return null;
//     }
//   }
//
//   Future<void> fetchStationChargers(int stationId) async {
//     _setLoading(true);
//     _errorMessage = '';
//     _chargers = [];
//
//     print('\n');
//     print('╔══════════════════════════════════════════════════════════════╗');
//     print('║                 FETCHING STATION CHARGERS                    ║');
//     print('╠══════════════════════════════════════════════════════════════╣');
//     print('║ Station ID: $stationId');
//     print('╚══════════════════════════════════════════════════════════════╝\n');
//
//     try {
//       final token = await _getAuthToken();
//
//       if (token == null) {
//         print('❌ No token found');
//         _setError('Authentication required');
//         notifyListeners();
//         return;
//       }
//
//       final url = Uri.parse('$CHARGER_API_BASE_URL/$stationId');
//
//       print('🔗 URL: $url');
//       print('📋 Headers:');
//       print('   Authorization: Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
//
//       final response = await http.get(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       );
//
//       print('\n📦 Response Status: ${response.statusCode}');
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         await _processChargerResponse(data);
//       } else if (response.statusCode == 401) {
//         print('❌ Session expired');
//         _setError('Session expired. Please login again.');
//         notifyListeners();
//       } else {
//         print('❌ API Error: ${response.statusCode}');
//         _setError('Failed to load charger details');
//         notifyListeners();
//       }
//     } catch (e) {
//       print('❌ Exception: $e');
//       _setError('Network error: ${e.toString()}');
//       notifyListeners();
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//   Future<void> _processChargerResponse(Map<String, dynamic> data) async {
//     try {
//       print('\n╔══════════════════════════════════════════════════════════════╗');
//       print('║                    PROCESSING CHARGER DATA                    ║');
//       print('╠══════════════════════════════════════════════════════════════╣');
//
//       final bool success = data['success'] ?? false;
//       final int count = data['count'] ?? 0;
//
//       print('║ Success: $success');
//       print('║ Count: $count');
//
//       if (success && data['data'] != null) {
//         final List<dynamic> chargersData = data['data'] as List;
//
//         print('║ Number of chargers: ${chargersData.length}');
//         print('║ ───────────────────────────────────────────────────────────║');
//
//         for (var chargerJson in chargersData) {
//           final charger = ChargerModel.fromJson(chargerJson);
//           _chargers.add(charger);
//
//           print('\n║ 📍 Charger: ${charger.name}');
//           print('║    Manufacturer: ${charger.manufacturer}');
//           print('║    Status: ${charger.status}');
//           print('║    Power Capacity: ${charger.powerCapacity} kW');
//           print('║    Connectors: ${charger.connectors.length}');
//           print('║    Tariffs: ${charger.tariffs.length}');
//         }
//
//         print('\n║ ✅ Successfully loaded ${_chargers.length} charger(s)');
//         print('╚══════════════════════════════════════════════════════════════╝\n');
//
//         notifyListeners();
//       } else {
//         print('║ ❌ API returned error');
//         print('╚══════════════════════════════════════════════════════════════╝\n');
//         _setError(data['message'] ?? 'No chargers found');
//         notifyListeners();
//       }
//     } catch (e) {
//       print('║ ❌ Error processing response: $e');
//       print('╚══════════════════════════════════════════════════════════════╝\n');
//       _setError('Error processing charger data');
//       notifyListeners();
//     }
//   }
//
//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }
//
//   void _setError(String error) {
//     _errorMessage = error;
//     notifyListeners();
//   }
//
//   void clearError() {
//     _errorMessage = '';
//     notifyListeners();
//   }
// }
//
