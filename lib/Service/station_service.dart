import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../Model/ev_station_model.dart';

class StationService {
  static const String _apiKey = "AIzaSyBKgPe-P7029JQIk9KYDT7Os4U96g5Mmbs";
  static const String _customApiUrl = "http://evtron-dev.dextragroups.com/api/public/mobile/stations";

  Future<List<EVStation>> fetchStations({
    LatLng? currentPosition,
  }) async {
    try {
      final customStations = await _fetchFromCustomAPI();

      if (customStations.isNotEmpty) {
        print("✅ Loaded ${customStations.length} stations from Custom API");
        return customStations;
      }

      print("⚠️ Custom API returned no stations, using fallback");

      if (currentPosition != null) {
        return await _fetchFromGoogleAPI(currentPosition);
      }

      return [];
    } catch (e) {
      print("❌ Error fetching stations: $e");

      if (currentPosition != null) {
        return await _fetchFromGoogleAPI(currentPosition);
      }

      return [];
    }
  }

  Future<List<EVStation>> _fetchFromCustomAPI() async {
    try {
      final response = await http.get(Uri.parse(_customApiUrl));

      print("📡 API STATUS CODE: ${response.statusCode}");

      if (response.statusCode != 200) {
        print("❌ API returned non-200 status: ${response.statusCode}");
        return [];
      }

      final Map<String, dynamic> data = json.decode(response.body);

      if (data['success'] != true || data['data'] == null) {
        print("❌ API response missing success flag or data");
        return [];
      }

      final stations = (data['data'] as List)
          .map((json) => EVStation.fromJson(json))
          .where((station) => station.latitude != 0 && station.longitude != 0)
          .toList();

      print("✅ Total Stations from Custom API: ${stations.length}");

      for (var station in stations.take(5)) { // Print first 5 only
        print("📍 Station: ${station.name} (${station.latitude}, ${station.longitude})");
      }

      return stations;
    } catch (e) {
      print("❌ CUSTOM API ERROR: $e");
      return [];
    }
  }

  Future<List<EVStation>> _fetchFromGoogleAPI(LatLng position) async {
    try {
      final String url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
          "?location=${position.latitude},${position.longitude}"
          "&radius=5000&type=electric_vehicle_charging_station&key=$_apiKey";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print("❌ Google API error: ${response.statusCode}");
        return [];
      }

      final data = json.decode(response.body);
      if (data['status'] != 'OK') {
        print("❌ Google API status: ${data['status']}");
        return [];
      }

      final stations = (data['results'] as List).map((result) => EVStation(
        id: DateTime.now().millisecondsSinceEpoch + (data['results'] as List).indexOf(result),
        name: result['name'] ?? 'EV Station',
        fullAddress: result['vicinity'] ?? 'Address not available',
        latitude: result['geometry']['location']['lat'],
        longitude: result['geometry']['location']['lng'],
        status: 'active',
        stationType: 'public',
        is247: result['opening_hours']?['open_now'] ?? false,
        estimatedChargingPrice: 20.0,
        totalChargers: 2,
        availableChargers: result['business_status'] == 'OPERATIONAL' ? 1 : 0,
        connectorPorts: [],
        amenities: [],
        realTimeAvailability: false,
        createdAt: DateTime.now(),
        rating: result['rating']?.toDouble() ?? 0.0,
      )).toList();

      print("✅ Loaded ${stations.length} stations from Google API");
      return stations;
    } catch (e) {
      print("❌ GOOGLE API ERROR: $e");
      return [];
    }
  }

  Future<BitmapDescriptor> getMarkerIcon(EVStation station) async {
    if (station.availableChargers > 0) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (station.status == 'active') {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  LatLngBounds calculateBounds(List<EVStation> stations, LatLng currentPosition) {
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