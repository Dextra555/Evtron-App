import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/ev_station_model.dart';
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

  Future<List<EVStation>> fetchStations({
    LatLng? currentPosition,
  }) async {
    try {
      final customStations = await _fetchFromCustomAPI();

      if (customStations.isNotEmpty) {
        print("✅ Loaded ${customStations.length} stations from Custom API");
        return customStations;
      }

      print("⚠️ Custom API returned no stations");
      return [];
    } on AuthSessionExpiredException {
      rethrow;
    } catch (e) {
      print("❌ Error fetching stations: $e");
      return [];
    }
  }

  Future<List<EVStation>> _fetchFromCustomAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Debug: Check all stored keys
      print("🔑 All stored keys: ${prefs.getKeys()}");

      // Try different possible token keys
      String? token = prefs.getString('auth_token');

      // If not found, try other possible keys
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
        print("   Please login again to get a valid token");
        return [];
      }

      print("🔑 Token found: ${token.substring(0, min(20, token.length))}...");

      final response = await _httpClient.get(
        Uri.parse(_customApiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print("📡 API STATUS CODE: ${response.statusCode}");

      // Log response body for debugging
      if (response.statusCode != 200) {
        print("📡 Error Response Body: ${response.body}");
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        final payload = _tryDecodeResponse(response.body);
        final errorText = payload != null && payload.containsKey('error')
            ? payload['error']?.toString().toLowerCase() ?? ''
            : '';
        final isInvalidToken = errorText.contains('invalid token') || errorText.contains('token expired');

        print("❌ Token is invalid or expired");
        print("   Please logout and login again");

        if (isInvalidToken || response.statusCode == 401 || response.statusCode == 403) {
          throw AuthSessionExpiredException('Your session is invalid or expired. Please log in again.');
        }
      }

      if (response.statusCode != 200) {
        print("❌ API returned non-200 status: ${response.statusCode}");
        return [];
      }

      final Map<String, dynamic> data = json.decode(response.body);
      print("📡 Full API Response: $data");

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

      print("✅ Total Stations from Custom API: ${stations.length}");

      for (var station in stations) {
        print('📍 Station: ${station.name}, Available: ${station.availableChargers}/${station.totalChargers}');
      }

      return stations;
    } on AuthSessionExpiredException {
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

  // Remove the Google API method entirely since we don't need it

  Future<BitmapDescriptor> getMarkerIcon(EVStation station) async {
    print("📍 Getting marker for: ${station.name}, Available: ${station.availableChargers}/${station.totalChargers}");

    if (station.availableChargers > 0) {
      print("   → 🟢 GREEN marker (${station.availableChargers} charger(s) available)");
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else {
      print("   → 🔴 RED marker (no chargers available)");
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  LatLngBounds calculateBounds(List<EVStation> stations, LatLng currentPosition) {
    if (stations.isEmpty) {
      // Return a default bounds centered on current position
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

