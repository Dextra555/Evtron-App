import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/filter_master_model.dart';
import 'AuthService.dart';
import 'api_endpoints.dart';

class FilterService {
  static final FilterService _instance = FilterService._internal();
  factory FilterService() => _instance;
  FilterService._internal();

  FilterMasterResponse? _cachedFilterData;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 30);

  Future<FilterMasterResponse> getFilterMasterData({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh &&
        _cachedFilterData != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      print('📦 Using cached filter master data');
      print('📦 Cache age: ${DateTime.now().difference(_cacheTimestamp!).inMinutes} minutes old');
      return _cachedFilterData!;
    }

    try {
      print('\n🔍 ========== FETCHING FILTER MASTER DATA ==========');
      print('📡 URL: ${ApiEndpoints.filterMasterData}');

      final token = await AuthService.getUserToken();
      print('🔑 Token present: ${token != null && token.isNotEmpty}');

      final response = await http.get(
        Uri.parse(ApiEndpoints.filterMasterData),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      print('📡 Response Status Code: ${response.statusCode}');
      print('📡 Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('📄 Raw Response Body:');
        print('========================================');
        print(responseBody);
        print('========================================');

        final Map<String, dynamic> data = json.decode(responseBody);

        // Print formatted JSON
        print('📊 Parsed Response Data:');
        print('========================================');
        print(const JsonEncoder.withIndent('  ').convert(data));
        print('========================================');

        final filterData = FilterMasterResponse.fromJson(data);

        // Print specific data
        print('✅ Filter Master Data loaded successfully:');
        print('   Success: ${filterData.success}');
        print('   Message: ${filterData.message}');
        print('   Charger Types (${filterData.data.chargerTypes.length}):');
        for (var type in filterData.data.chargerTypes) {
          print('      - ID: ${type.id}, Name: ${type.name}');
        }
        print('   Connector Types (${filterData.data.connectorTypes.length}):');
        for (var type in filterData.data.connectorTypes) {
          print('      - ID: ${type.id}, Name: ${type.name}');
        }
        print('========================================\n');

        // Cache the data
        _cachedFilterData = filterData;
        _cacheTimestamp = DateTime.now();

        return filterData;
      } else {
        print('❌ API Error - Status Code: ${response.statusCode}');
        print('❌ Error Response Body: ${response.body}');
        print('========================================\n');

        if (response.statusCode == 401) {
          throw Exception('Session expired. Please login again.');
        } else {
          throw Exception('Failed to load filter master data: ${response.statusCode}');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Exception fetching filter master data:');
      print('   Error: $e');
      print('   Stack Trace: $stackTrace');
      print('========================================\n');

      // Return cached data even if expired if available
      if (_cachedFilterData != null) {
        print('⚠️ Using stale cached data due to error');
        print('⚠️ Cache age: ${DateTime.now().difference(_cacheTimestamp!).inMinutes} minutes old');
        return _cachedFilterData!;
      }

      // Fallback to default values
      print('⚠️ Using default filter data as fallback');
      return _getDefaultFilterData();
    }
  }

  FilterMasterResponse _getDefaultFilterData() {
    print('📋 Creating default filter data:');
    print('   Charger Types: AC, DC');
    print('   Connector Types: CCS, Type 2, CHAdeMO, Tesla, GB/T');

    return FilterMasterResponse(
      success: true,
      data: FilterMasterData(
        chargerTypes: [
          FilterOption(id: 1, name: 'AC'),
          FilterOption(id: 2, name: 'DC'),
        ],
        connectorTypes: [
          FilterOption(id: 1, name: 'CCS'),
          FilterOption(id: 2, name: 'Type 2'),
          FilterOption(id: 3, name: 'CHAdeMO'),
          FilterOption(id: 4, name: 'Tesla'),
          FilterOption(id: 5, name: 'GB/T'),
        ],
      ),
      message: 'Default filter data (fallback)',
    );
  }

  void clearCache() {
    _cachedFilterData = null;
    _cacheTimestamp = null;
    print('🧹 Filter cache cleared');
  }
}

