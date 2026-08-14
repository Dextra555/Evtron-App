// station_cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/ev_station_model.dart';

class StationCacheService {
  static const String _stationsKey = 'cached_stations';
  static const String _timestampKey = 'cached_stations_timestamp';
  static const Duration _cacheDuration = Duration(seconds: 10); // ✅ Changed to 10 seconds

  Future<void> saveStations(List<EVStation> stations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = stations.map((s) => s.toJson()).toList();
      await prefs.setString(_stationsKey, jsonEncode(jsonList));
      await prefs.setString(_timestampKey, DateTime.now().toIso8601String());

      print('💾 Cached ${stations.length} stations (expires in 10 seconds)');
    } catch (e) {
      print('❌ Error caching stations: $e');
    }
  }

  Future<List<EVStation>> getCachedStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache exists
      final cachedData = prefs.getString(_stationsKey);
      if (cachedData == null) {
        print('ℹ️ No cached stations found');
        return [];
      }

      // Check if cache is expired
      final timestamp = prefs.getString(_timestampKey);
      if (timestamp != null) {
        final cacheTime = DateTime.parse(timestamp);
        final age = DateTime.now().difference(cacheTime);
        if (age > _cacheDuration) {
          print('⏰ Cache expired (${age.inSeconds} seconds old) - max 10 seconds');
          return [];
        }
        print('✅ Cache valid (${age.inSeconds} seconds old)');
      }

      final List<dynamic> jsonList = jsonDecode(cachedData);
      final stations = jsonList.map((json) => EVStation.fromJson(json)).toList();
      print('📦 Loaded ${stations.length} stations from cache');
      return stations;
    } catch (e) {
      print('❌ Error getting cached stations: $e');
      return [];
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stationsKey);
      await prefs.remove(_timestampKey);
      print('🗑️ Cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_timestampKey);
      if (timestamp == null) return false;

      final cacheTime = DateTime.parse(timestamp);
      final age = DateTime.now().difference(cacheTime);
      final isValid = age < _cacheDuration;
      print('🔍 Cache validity check: ${isValid ? "✅ Valid" : "❌ Expired"} (${age.inSeconds}s old, max 10s)');
      return isValid;
    } catch (e) {
      return false;
    }
  }

  Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_stationsKey);
      if (cachedData == null) return 0;

      final List<dynamic> jsonList = jsonDecode(cachedData);
      return jsonList.length;
    } catch (e) {
      return 0;
    }
  }

  // ✅ Add method to force refresh cache
  Future<void> refreshCache() async {
    await clearCache();
    print('🔄 Cache refreshed (cleared)');
  }
}