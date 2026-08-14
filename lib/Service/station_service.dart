import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:evtron/Service/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/ev_station_model.dart';
import '../View/Home/CustomMarkerlocation.dart';
import 'StationCacheService.dart';
import 'api_endpoints.dart';

class AuthSessionExpiredException implements Exception {
  AuthSessionExpiredException([this.message = 'Your session has expired. Please log in again.']);

  final String message;

  @override
  String toString() => message;
}

class StationService {
  StationService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  static const String _customApiUrl = ApiEndpoints.stations;
  final http.Client _httpClient;

  final StationCacheService _cacheService = StationCacheService();

  Future<List<EVStation>> fetchStations({
    LatLng? currentPosition,
    bool useCache = true,
  }) async {
    try {
      if (useCache) {
        final cachedStations = await _cacheService.getCachedStations();
        if (cachedStations.isNotEmpty) {
          print("✅ Returning ${cachedStations.length} stations from cache");
          return cachedStations;
        }
      }

      print("📡 Fetching stations from Custom API...");
      final customStations = await _fetchFromCustomAPI();

      if (customStations.isNotEmpty) {
        print("✅ Loaded ${customStations.length} stations from Custom API");

        // Cache the results (expires in 10 seconds)
        await _cacheService.saveStations(customStations);
        print("💾 Cached ${customStations.length} stations (10s expiry)");

        return customStations;
      }

      print("⚠️ Custom API returned no stations");
      return [];
    } on AuthSessionExpiredException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      print("❌ Error fetching stations: $e");
      print(stackTrace);

      final fallbackStations = await _cacheService.getCachedStations();
      if (fallbackStations.isNotEmpty) {
        print("⚠️ API failed, returning ${fallbackStations.length} cached stations as fallback");
        return fallbackStations;
      }

      return [];
    }
  }

  // ✅ IMMEDIATE REFRESH - ALWAYS fetches fresh data and updates cache
  Future<List<EVStation>> refreshStations({
    LatLng? currentPosition,
  }) async {
    try {
      print('🔄 FORCE REFRESH: Fetching fresh stations immediately...');

      // ✅ Fetch fresh data from API (always)
      final stations = await _fetchFromCustomAPI();

      if (stations.isNotEmpty) {
        // ✅ Update cache with fresh data immediately (10 seconds expiry)
        await _cacheService.saveStations(stations);
        print("✅ REFRESH COMPLETE: ${stations.length} stations loaded and cached (10s expiry)");
        return stations;
      }

      // If API returns empty, try to return cached data
      final cachedStations = await _cacheService.getCachedStations();
      if (cachedStations.isNotEmpty) {
        print("⚠️ API returned empty, showing cached stations");
        return cachedStations;
      }

      return [];
    } on AuthSessionExpiredException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      print("❌ Error refreshing stations: $e");
      print(stackTrace);

      // Return cached data as fallback
      final cachedStations = await _cacheService.getCachedStations();
      if (cachedStations.isNotEmpty) {
        print("⚠️ Error, showing cached stations as fallback");
        return cachedStations;
      }

      return [];
    }
  }

  // ✅ Get stations immediately from cache (for initial load)
  Future<List<EVStation>> getStationsImmediately({
    LatLng? currentPosition,
  }) async {
    try {
      // Get cached stations immediately
      final cachedStations = await _cacheService.getCachedStations();

      // If cache exists and is valid (within 10 seconds), return it immediately
      if (cachedStations.isNotEmpty) {
        print("✅ Returning ${cachedStations.length} stations from cache (immediate)");

        // Start background refresh (will update if cache expired)
        _refreshInBackground(currentPosition);

        return cachedStations;
      }

      // No cache - fetch from API
      print("📡 No cache available, fetching from API...");
      final stations = await _fetchFromCustomAPI();

      if (stations.isNotEmpty) {
        await _cacheService.saveStations(stations);
        print("💾 Cached ${stations.length} stations (10s expiry)");
      }

      return stations;
    } catch (e) {
      print("❌ Error getting stations immediately: $e");
      return [];
    }
  }

  // ✅ Background refresh with 10-second expiry check
  Future<void> _refreshInBackground(LatLng? currentPosition) async {
    try {
      // Check if cache is still valid (within 10 seconds)
      final isValid = await _cacheService.isCacheValid();

      if (!isValid) {
        print("🔄 Background refresh: Cache expired (>10s), fetching fresh stations...");
        final freshStations = await _fetchFromCustomAPI();

        if (freshStations.isNotEmpty) {
          // Cache fresh data (10 seconds expiry)
          await _cacheService.saveStations(freshStations);
          print("🔄 Background refresh completed: ${freshStations.length} stations cached (10s expiry)");
        }
      } else {
        print("✅ Background refresh: Cache still valid (<10s), no update needed");
      }
    } catch (e) {
      print("⚠️ Background refresh failed: $e");
    }
  }

  Future<List<EVStation>> _fetchFromCustomAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try different possible token keys
      String? token = prefs.getString('auth_token');
      if (token == null) {
        token = prefs.getString('token');
        print("🔑 Found token under 'token' key");
      }
      if (token == null) {
        token = prefs.getString('access_token');
        print("🔑 Found token under 'access_token' key");
      }
      if (token == null) {
        print("❌ No authentication token found in SharedPreferences");
        return [];
      }

      print("🔑 Token found: ${token.substring(0, min(20, token.length))}...");

      final response = await NetworkService.get(
        Uri.parse(_customApiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print("📡 API STATUS CODE: ${response.statusCode}");

      if (response.statusCode != 200) {
        print("📡 Error Response Body: ${response.body}");
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        final payload = _tryDecodeResponse(response.body);
        final errorText = payload != null && payload.containsKey('error')
            ? payload['error']?.toString().toLowerCase() ?? ''
            : '';
        final isInvalidToken = errorText.contains('invalid token') || errorText.contains('token expired');

        if (isInvalidToken || response.statusCode == 401 || response.statusCode == 403) {
          throw AuthSessionExpiredException('Your session is invalid or expired. Please log in again.');
        }
      }

      if (response.statusCode != 200) {
        print("❌ API returned non-200 status: ${response.statusCode}");
        return [];
      }

      final Map<String, dynamic> data = json.decode(response.body);

      if (data['success'] != true) {
        print("❌ API success is false");
        print("   Message: ${data['message'] ?? 'No message'}");
        return [];
      }

      if (data['data'] == null) {
        print("❌ API response has no 'data' field");
        return [];
      }

      // Handle different data formats
      List stationsData = [];
      if (data['data'] is List) {
        stationsData = data['data'] as List;
      } else if (data['data'] is Map) {
        if (data['data']['stations'] != null) {
          stationsData = data['data']['stations'] as List;
        } else {
          stationsData = [data['data']];
        }
      } else {
        print("❌ Unexpected data format: ${data['data'].runtimeType}");
        return [];
      }

      if (stationsData.isEmpty) {
        print("ℹ️ No stations found in response");
        return [];
      }

      final stations = stationsData
          .map((json) => EVStation.fromJson(json))
          .where((station) => station.latitude != 0 && station.longitude != 0)
          .toList();

      // Debug: Print available/total for each station
      for (var station in stations) {
        print("📍 Station: ${station.name}, Available: ${station.availableChargers}/${station.totalChargers}");
      }

      print("✅ Total Stations from Custom API: ${stations.length}");

      return stations;
    } on AuthSessionExpiredException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      print("❌ CUSTOM API ERROR: $e");
      print("   Stack trace: $stackTrace");
      return [];
    }
  }

  Map<String, dynamic>? _tryDecodeResponse(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  // ✅ Updated to use custom marker with proper values
  Future<BitmapDescriptor> getMarkerIcon(EVStation station) async {
    print("📍 Getting marker for: ${station.name}");
    print("   Available: ${station.availableChargers}/${station.totalChargers}");
    print("   Status: ${station.status}");

    // Determine if station has faults or offline chargers
    bool hasFault = false;
    bool hasOffline = false;

    if (station.chargerStatusCounts != null) {
      hasFault = station.chargerStatusCounts!['fault'] != null && station.chargerStatusCounts!['fault']! > 0;
      hasOffline = station.chargerStatusCounts!['offline'] != null && station.chargerStatusCounts!['offline']! > 0;
    }

    // Check if any connector ports have fault or offline status
    if (!hasFault || !hasOffline) {
      for (var port in station.connectorPorts) {
        if (port.status.toLowerCase() == 'fault') hasFault = true;
        if (port.status.toLowerCase() == 'offline') hasOffline = true;
        if (hasFault && hasOffline) break;
      }
    }

    // Determine if available
    bool isAvailable = station.availableChargers > 0;

    // Get overall status
    String status = station.getOverallStatus();

    print("   → Using custom marker with available: ${station.availableChargers}, total: ${station.totalChargers}");
    print("   → isAvailable: $isAvailable, status: $status, hasFault: $hasFault, hasOffline: $hasOffline");

    // Create the custom marker
    return await LargeChargerMarker.createLargeMarker(
      available: station.availableChargers,
      total: station.totalChargers,
      isAvailable: isAvailable,
      status: status,
      hasFault: hasFault,
      hasOffline: hasOffline,
    );
  }

  LatLngBounds calculateBounds(List<EVStation> stations, LatLng currentPosition) {
    if (stations.isEmpty) {
      return LatLngBounds(
        southwest: LatLng(currentPosition.latitude - 0.1, currentPosition.longitude - 0.1),
        northeast: LatLng(currentPosition.latitude + 0.1, currentPosition.longitude + 0.1),
      );
    }

    double minLat = currentPosition.latitude;
    double maxLat = currentPosition.latitude;
    double minLng = currentPosition.longitude;
    double maxLng = currentPosition.longitude;

    for (var station in stations) {
      minLat = minLat < station.location.latitude ? minLat : station.location.latitude;
      maxLat = maxLat > station.location.latitude ? maxLat : station.location.latitude;
      minLng = minLng < station.location.longitude ? minLng : station.location.longitude;
      maxLng = maxLng > station.location.longitude ? maxLng : station.location.longitude;
    }

    double latPadding = (maxLat - minLat) * 0.2;
    double lngPadding = (maxLng - minLng) * 0.2;

    if (latPadding < 0.01) latPadding = 0.05;
    if (lngPadding < 0.01) lngPadding = 0.05;

    return LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }
}


