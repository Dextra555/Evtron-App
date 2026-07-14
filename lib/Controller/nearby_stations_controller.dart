import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/nearby_stations_model.dart';
import '../Service/WishlistService.dart';
import '../Service/api_endpoints.dart';

class NearbyStationsController extends ChangeNotifier {
  static const String API_KEY = 'AIzaSyBKgPe-P7029JQIk9KYDT7Os4U96g5Mmbs';
  static const String PLACES_API_BASE_URL = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  static const String DISTANCE_MATRIX_API_BASE_URL = 'https://maps.googleapis.com/maps/api/distancematrix/json';
  static const String EVTRON_API_BASE_URL = ApiEndpoints.nearbyStations;

  List<StationModel> _stations = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _useEvtronApi = true;
  bool _isOffline = false;
  final WishlistService _wishlistService = WishlistService();

  DateTime? _lastConnectivityCheck;
  bool _lastConnectivityResult = false;
  static const Duration _connectivityCacheTtl = Duration(seconds: 5);

  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _locationError;

  List<StationModel> get stations => _stations;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  Position? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get locationError => _locationError;

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      print('========== TOKEN DEBUG ==========');
      print('Token found: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        print('Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }
      print('==================================');
      return token;
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      if (_lastConnectivityCheck != null) {
        final elapsed = DateTime.now().difference(_lastConnectivityCheck!);
        if (elapsed < _connectivityCacheTtl) {
          print('Connectivity check cached: $_lastConnectivityResult (${elapsed.inMilliseconds}ms old)');
          return _lastConnectivityResult;
        }
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = connectivityResult != ConnectivityResult.none;
      print('Connectivity Status: $connectivityResult - Has Internet: $hasInternet');

      if (hasInternet) {
        try {
          final result = await InternetAddress.lookup('google.com');
          final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
          print('DNS Resolution Test: $isConnected');
          _lastConnectivityCheck = DateTime.now();
          _lastConnectivityResult = isConnected;
          return isConnected;
        } catch (e) {
          print('DNS Resolution Failed: $e');
          _lastConnectivityCheck = DateTime.now();
          _lastConnectivityResult = false;
          return false;
        }
      }
      _lastConnectivityCheck = DateTime.now();
      _lastConnectivityResult = false;
      return false;
    } catch (e) {
      print('Connectivity check failed: $e');
      _lastConnectivityCheck = DateTime.now();
      _lastConnectivityResult = false;
      return false;
    }
  }

  void invalidateConnectivityCache() {
    _lastConnectivityCheck = null;
  }

  Future<bool> getCurrentLocation({bool requestPermissionIfDenied = true}) async {
    setLocationLoading(true);
    _locationError = null;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = "Location services are disabled. Please enable them.";
        setLocationLoading(false);
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (requestPermissionIfDenied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _locationError = "Location permissions are denied.";
            setLocationLoading(false);
            return false;
          }
        } else {
          _locationError = "Location permissions are denied.";
          setLocationLoading(false);
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationError = "Location permissions are permanently denied. Please enable them in settings.";
        setLocationLoading(false);
        return false;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Location request timeout');
        },
      );

      _currentPosition = position;
      setLocationLoading(false);
      print('✅ Current location obtained: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      return true;
    } catch (e) {
      print('❌ Error getting location: $e');
      _locationError = "Failed to get location: ${e.toString()}";
      setLocationLoading(false);
      return false;
    }
  }

  Future<void> fetchNearbyStations({
    double? latitude,
    double? longitude,
    int radius = 2000,
    bool forceGoogleApi = false,
    bool useCurrentLocation = true,
  }) async
  {
    _setLoading(true);
    _errorMessage = '';
    _isOffline = false;

    double effectiveLat;
    double effectiveLng;

    if (useCurrentLocation && (latitude == null || longitude == null)) {
      if (_currentPosition == null) {
        bool locationObtained = await getCurrentLocation();
        if (!locationObtained) {
          _setError('Unable to get your current location. ${_locationError ?? "Please enable location services."}');
          _setLoading(false);
          return;
        }
      }

      effectiveLat = _currentPosition!.latitude;
      effectiveLng = _currentPosition!.longitude;
    } else if (latitude != null && longitude != null) {
      effectiveLat = latitude;
      effectiveLng = longitude;
    } else {
      _setError('No location available. Please provide coordinates or enable location services.');
      _setLoading(false);
      return;
    }

    print('\n');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║              FETCH NEARBY STATIONS STARTED                   ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║ Current Location: $effectiveLat, $effectiveLng');
    print('║ Radius: $radius meters');
    print('║ Use Evtron API: ${_useEvtronApi && !forceGoogleApi}');
    print('╚══════════════════════════════════════════════════════════════╝\n');

    final hasInternet = await _checkConnectivity();
    if (!hasInternet) {
      print('⚠️ No internet connection detected');
      _isOffline = true;
      _setError('No internet connection. Please check your network and try again.');
      _setLoading(false);
      return;
    }

    try {
      if (_useEvtronApi && !forceGoogleApi) {
        await _fetchFromEvtronApi(effectiveLat, effectiveLng);
      } else {
        await _fetchFromGooglePlacesApi(effectiveLat, effectiveLng, radius);
      }
      await refreshFavoritesFromApi();
    } catch (e) {
      print('❌ Fetch error: $e');
      print('Stack trace: ${StackTrace.current}');
      _setError('Failed to fetch stations: ${e.toString()}');
      _stations = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchFromEvtronApi(double latitude, double longitude) async {
    print('\n');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║                    EVTRON API REQUEST                        ║');
    print('╠══════════════════════════════════════════════════════════════╣');

    try {
      final token = await _getAuthToken();

      if (token == null) {
        print('║ ❌ ERROR: No token found in SharedPreferences              ║');
        print('╚══════════════════════════════════════════════════════════════╝');
        _setError('Authentication token not found. Please login again.');
        _stations = [];
        notifyListeners();
        return;
      }

      final url = Uri.parse('$EVTRON_API_BASE_URL?lat=$latitude&lng=$longitude');

      print('║ 📍 LOCATION:                                               ║');
      print('║    Latitude: $latitude');
      print('║    Longitude: $longitude');
      print('║                                                           ║');
      print('║ 🔗 URL: $url');
      print('║                                                           ║');
      print('║ 📋 HEADERS:                                               ║');
      print('║    Authorization: Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      print('║    Content-Type: application/json                         ║');
      print('║    Accept: application/json                               ║');
      print('╚════════════════════════════════════════════════════════════╝');


      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ Request timeout after 10 seconds');
          throw TimeoutException('Request timeout');
        },
      );

      print('\n');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║                    EVTRON API RESPONSE                      ║');
      print('╠══════════════════════════════════════════════════════════════╣');
      print('║ Status Code: ${response.statusCode}');
      print('╚══════════════════════════════════════════════════════════════╝\n');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _processEvtronResponse(data);
      } else if (response.statusCode == 401) {
        print('╔══════════════════════════════════════════════════════════════╗');
        print('║ ❌ SESSION EXPIRED - 401 Unauthorized                        ║');
        print('╚══════════════════════════════════════════════════════════════╝\n');
        _setError('Session expired. Please login again.');
        _stations = [];
        notifyListeners();
      } else {
        print('╔══════════════════════════════════════════════════════════════╗');
        print('║ ❌ API ERROR: ${response.statusCode}                                  ║');
        print('╚══════════════════════════════════════════════════════════════╝\n');
        _setError('API Error: ${response.statusCode}');
        _stations = [];
        notifyListeners();
      }
    } on SocketException catch (e) {
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║ ❌ SOCKET EXCEPTION - Network Error                          ║');
      print('║ Exception: $e');
      print('╚══════════════════════════════════════════════════════════════╝\n');
      _setError('Network error: Unable to reach the server. Please check your internet connection.');
      _stations = [];
      notifyListeners();
    } on TimeoutException catch (e) {
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║ ❌ TIMEOUT EXCEPTION                                         ║');
      print('║ Exception: $e');
      print('╚══════════════════════════════════════════════════════════════╝\n');
      _setError('Request timeout. Please try again.');
      _stations = [];
      notifyListeners();
    } catch (e) {
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║ ❌ EVTRON API EXCEPTION                                      ║');
      print('║ Exception: $e');
      print('╚══════════════════════════════════════════════════════════════╝\n');
      _setError('Failed to fetch stations: ${e.toString()}');
      _stations = [];
      notifyListeners();
    }
  }

  Future<void> _processEvtronResponse(Map<String, dynamic> data) async {
    try {
      print('\n');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║              PROCESSING EVTRON RESPONSE                      ║');
      print('╠══════════════════════════════════════════════════════════════╣');

      final String? status = data['status'];
      final bool? success = data['success'];
      final String? message = data['message'];

      print('║ Status field: $status');
      print('║ Success field: $success');
      print('║ Message field: $message');

      if ((status == 'success' || success == true) && data['data'] != null) {
        print('║ ✅ API returned success status');

        List<dynamic> stationsData = [];

        if (data['data'] is List) {
          stationsData = data['data'];
          print('║ Data is a List with ${stationsData.length} items');
        } else if (data['data'] is Map) {
          if (data['data']['stations'] != null) {
            stationsData = data['data']['stations'];
            print('║ Found stations array with ${stationsData.length} items');
          } else if (data['data']['data'] != null) {
            stationsData = data['data']['data'];
            print('║ Found nested data array with ${stationsData.length} items');
          } else {
            print('║ ⚠️ Unknown data structure');
            stationsData = [];
          }
        }

        if (stationsData.isEmpty) {
          print('║ ⚠️ No stations found in your area');
          print('╚══════════════════════════════════════════════════════════════╝\n');
          _setError('No stations found in your area');
          _stations = [];
          notifyListeners();
          return;
        }

        List<StationModel> fetchedStations = [];

        // Save current favorite statuses from existing stations
        final Map<dynamic, bool> currentFavorites = {};
        for (var station in _stations) {
          if (station.stationId != null) {
            currentFavorites[station.stationId] = station.isFavorited;
            print('║ Existing favorite - Station ID: ${station.stationId}, Status: ${station.isFavorited}');
          }
        }

        for (var station in stationsData) {
          final stationId = station['id'] ?? station['station_id'];

          // Try to get distance value from different possible field names
          dynamic distanceValue = station['distance'] ?? station['distance_km'] ?? station['distance_km'] ?? 0;

          // Try to get power value from different possible field names
          String powerValue = station['power'] ??
              station['power_output'] ??
              station['max_power'] ??
              '${15 + _getRandomNumber(20)} kW';

          // Try to get available count from different possible field names
          int availableCount = station['available'] ??
              station['available_count'] ??
              station['available_chargers'] ??
              _getRandomAvailability();

          final stationModel = StationModel(
            stationId: stationId,
            name: station['name'] ?? station['station_name'] ?? 'Unknown Station',
            distance: _formatDistance(distanceValue),
            power: powerValue.toString(),
            available: availableCount,
            latitude: double.tryParse(
              (station['latitude'] ?? station['lat'] ?? '0.0').toString(),
            ) ?? 0.0,
            longitude: double.tryParse(
              (station['longitude'] ?? station['lng'] ?? '0.0').toString(),
            ) ?? 0.0,
            // Preserve existing favorite status if available, otherwise use API value
            isFavorited: currentFavorites.containsKey(stationId)
                ? currentFavorites[stationId]!
                : (station['is_favorited'] ?? station['isFavorite'] ?? false),
          );

          fetchedStations.add(stationModel);
          print('║ Processed station: ID=$stationId, Name=${stationModel.name}, Favorite=${stationModel.isFavorited}');
        }

        if (fetchedStations.isEmpty) {
          print('║ ⚠️ No valid stations found');
          _setError('No stations found in your area');
          _stations = [];
        } else {
          _stations = fetchedStations;
          print('║ ✅ Successfully loaded ${_stations.length} stations');

          // After loading stations, refresh favorites from API to ensure sync
          await refreshFavoritesFromApi();
        }
        print('╚══════════════════════════════════════════════════════════════╝\n');
        notifyListeners();
      } else {
        print('║ ❌ API returned error status');
        final errorMsg = data['message'] ?? data['error'] ?? 'Unknown error';
        print('║ Error message: $errorMsg');
        print('╚══════════════════════════════════════════════════════════════╝\n');
        _setError('API Error: $errorMsg');
        _stations = [];
        notifyListeners();
      }
    } catch (e) {
      print('║ ❌ Error processing Evtron response: $e');
      print('║ Stack trace: ${StackTrace.current}');
      print('╚══════════════════════════════════════════════════════════════╝\n');
      _setError('Error processing station data: ${e.toString()}');
      _stations = [];
      notifyListeners();
    }
  }

  Future<void> _fetchFromGooglePlacesApi(
      double latitude,
      double longitude,
      int radius,
      ) async {
    print('\n');
    print('╔══════════════════════════════════════════════════════════════╗');
    print('║                 GOOGLE PLACES API REQUEST                    ║');
    print('╠══════════════════════════════════════════════════════════════╣');
    print('║ 📍 Location: $latitude, $longitude');
    print('║ 📏 Radius: $radius meters');
    print('╚══════════════════════════════════════════════════════════════╝\n');

    try {
      final url = Uri.parse(
        '$PLACES_API_BASE_URL'
            '?location=$latitude,$longitude'
            '&radius=$radius'
            '&keyword=ev charging station'
            '&key=$API_KEY',
      );

      print('🔗 URL: $url\n');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Google Places API timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Google Places API Status: ${data['status']}');

        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          await _processPlacesResponse(data, latitude, longitude);
        } else if (data['status'] == 'ZERO_RESULTS') {
          print('⚠️ No stations found in your area');
          _setError('No EV charging stations found in your area');
          _stations = [];
          notifyListeners();
        } else {
          print('❌ Google Places API Error: ${data['status']}');
          _setError('Failed to fetch stations: ${data['status']}');
          _stations = [];
          notifyListeners();
        }
      } else {
        print('❌ Google Places API Error: ${response.statusCode}');
        _setError('API Error: ${response.statusCode}');
        _stations = [];
        notifyListeners();
      }
    } on SocketException catch (e) {
      print('❌ Network Error: $e');
      _setError('Network error. Please check your internet connection.');
      _stations = [];
      notifyListeners();
    } on TimeoutException catch (e) {
      print('❌ Timeout: $e');
      _setError('Request timeout. Please try again.');
      _stations = [];
      notifyListeners();
    } catch (e) {
      print('❌ Google Places API Exception: $e');
      _setError('Failed to fetch stations: ${e.toString()}');
      _stations = [];
      notifyListeners();
    }
  }

  Future<void> _processPlacesResponse(Map<String, dynamic> data, double userLat, double userLng) async {
    final List<dynamic> results = data['results'] ?? [];

    if (results.isEmpty) {
      _setError('No stations found in your area');
      _stations = [];
      notifyListeners();
      return;
    }

    List<StationModel> fetchedStations = [];

    for (var place in results.take(10)) {
      final lat = place['geometry']['location']['lat'];
      final lng = place['geometry']['location']['lng'];
      final name = place['name'] ?? 'Unknown Station';
      final placeId = place['place_id'];
      final vicinity = place['vicinity'] ?? '';

      String distance = await _getDistanceFromMatrix(userLat, userLng, lat, lng);
      final powerOutput = await _getStationDetails(placeId);

      fetchedStations.add(StationModel(
        stationId: placeId.hashCode,
        name: name,
        distance: distance,
        power: powerOutput,
        available: _getRandomAvailability(),
        latitude: lat,
        longitude: lng,
        isFavorited: false,
      ));
    }

    if (fetchedStations.isEmpty) {
      _setError('No stations found in your area');
      _stations = [];
    } else {
      _stations = fetchedStations;
    }
    notifyListeners();
  }

  Future<String> _getDistanceFromMatrix(double originLat, double originLng, double destLat, double destLng) async {
    try {
      final url = Uri.parse(
          '$DISTANCE_MATRIX_API_BASE_URL?origins=$originLat,$originLng&destinations=$destLat,$destLng&key=$API_KEY'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['rows'] != null &&
            data['rows'].isNotEmpty &&
            data['rows'][0]['elements'] != null &&
            data['rows'][0]['elements'].isNotEmpty) {
          final element = data['rows'][0]['elements'][0];
          if (element['status'] == 'OK') {
            return element['distance']['text'];
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching distance: $e');
    }

    // Calculate approximate distance using Haversine formula
    return _calculateApproximateDistance(originLat, originLng, destLat, destLng);
  }

  String _calculateApproximateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth's radius in km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distance = R * c;

    if (distance < 1) {
      return '${(distance * 1000).toInt()} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  Future<String> _getStationDetails(String placeId) async {
    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_address,opening_hours,website&key=$API_KEY'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return '${15 + _getRandomNumber(20)} kW';
      }
    } catch (e) {
      debugPrint('Error fetching place details: $e');
    }

    return '${15 + _getRandomNumber(20)} kW';
  }

  String _formatDistance(dynamic distance) {
    if (distance == null) return 'N/A';

    double distInKm;
    if (distance is String) {
      distInKm = double.tryParse(distance) ?? 0;
    } else {
      distInKm = distance.toDouble();
    }

    if (distInKm < 1) {
      return '${(distInKm * 1000).toInt()} m';
    } else {
      return '${distInKm.toStringAsFixed(1)} km';
    }
  }

  int _getRandomNumber(int max) {
    return math.Random().nextInt(max);
  }

  int _getRandomAvailability() {
    return 1 + math.Random().nextInt(5);
  }

  Future<void> refreshFavoritesFromApi() async {
    try {
      print('\n╔══════════════════════════════════════════════════════════════╗');
      print('║              REFRESHING FAVORITES FROM API                    ║');
      print('╠══════════════════════════════════════════════════════════════╣');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final tokenType = prefs.getString('token_type');

      if (token == null) {
        print('║ ⚠️ No token found, skipping favorite refresh');
        print('╚══════════════════════════════════════════════════════════════╝\n');
        return;
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.wishlist),
        headers: {
          'Authorization': '${tokenType ?? "Bearer"} $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final wishlistData = data['data'] ?? [];

        // Create a set of favorite station IDs
        final favoriteIds = <int>{};
        for (var item in wishlistData) {
          // Try different possible field names for station ID
          if (item['station'] != null && item['station']['id'] != null) {
            favoriteIds.add(item['station']['id']);
          } else if (item['charging_station_id'] != null) {
            favoriteIds.add(item['charging_station_id']);
          } else if (item['station_id'] != null) {
            favoriteIds.add(item['station_id']);
          } else if (item['id'] != null) {
            favoriteIds.add(item['id']);
          }
        }

        print('║ Found ${favoriteIds.length} favorites from API');

        // Update stations with favorite status
        int updatedCount = 0;
        for (var i = 0; i < _stations.length; i++) {
          final stationId = _stations[i].stationId;
          if (stationId != null) {
            final shouldBeFavorite = favoriteIds.contains(stationId);
            if (_stations[i].isFavorited != shouldBeFavorite) {
              _stations[i].isFavorited = shouldBeFavorite;
              updatedCount++;
              print('║ Updated station ${_stations[i].name}: Favorite=$shouldBeFavorite');
            }
          }
        }

        print('║ ✅ Updated $updatedCount stations with favorite status');
        print('╚══════════════════════════════════════════════════════════════╝\n');

        notifyListeners();
      } else {
        print('║ ❌ Failed to refresh favorites: ${response.statusCode}');
        print('╚══════════════════════════════════════════════════════════════╝\n');
      }
    } catch (e) {
      print('║ ❌ Error refreshing favorites: $e');
      print('╚══════════════════════════════════════════════════════════════╝\n');
    }
  }
  Future<void> toggleFavorite(int index) async {
    try {
      final station = _stations[index];
      final bool newFavoriteStatus = !station.isFavorited;

      print("========== FAVORITE CLICKED ==========");
      print("Station ID: ${station.stationId}");
      print("Station Name: ${station.name}");
      print("New Status: $newFavoriteStatus");
      print("======================================");

      // Check if user is logged in
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        print("❌ User not logged in");
        _setError("Please login to add favorites");
        // Show snackbar to user
        return;
      }

      final bool success = await _wishlistService.addToWishlist(
        chargingStationId: station.stationId ?? 0,
        isFavorite: newFavoriteStatus,
        notes: "",
      );

      if (success) {
        // Update local state
        _stations[index].isFavorited = newFavoriteStatus;

        // Save to local storage
        await _saveFavorites();

        notifyListeners();
        print("✅ Wishlist Updated Successfully");

        // Optional: Show success message
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(newFavoriteStatus ? "Added to wishlist" : "Removed from wishlist"),
        //     duration: Duration(seconds: 1),
        //   ),
        // );
      } else {
        print("❌ Wishlist API Failed");
        // Optional: Show error message
      }
    } catch (e) {
      print("❌ Toggle Favorite Error: $e");
      _setError("Failed to update favorite: ${e.toString()}");
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = _stations
          .where((station) => station.isFavorited)
          .map((station) => station.toJson())
          .toList();
      await prefs.setString('favorite_stations', json.encode(favoritesJson));
      debugPrint('Favorites saved');
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<void> loadSavedFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('favorite_stations');
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        for (var favorite in favoritesList) {
          final station = StationModel.fromJson(favorite);
          final index = _stations.indexWhere((s) => s.name == station.name);
          if (index != -1) {
            _stations[index].isFavorited = true;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  List<StationModel> getFavoriteStations() {
    return _stations.where((station) => station.isFavorited).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void setLocationLoading(bool loading) {
    _isLoadingLocation = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    _isOffline = false;
    _locationError = null;
    invalidateConnectivityCache();
    notifyListeners();
  }

  void setApiSource(bool useEvtron) {
    _useEvtronApi = useEvtron;
    notifyListeners();
  }
}

