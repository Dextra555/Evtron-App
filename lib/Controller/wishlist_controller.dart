import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:evtron/Service/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/wishlist.dart';
import '../Service/api_endpoints.dart';

class WishlistController extends ChangeNotifier {
  bool isLoading = false;
  List<WishlistItem> wishlist = [];
  String errorMessage = '';

  bool _hasLoaded = false;
  Future<void>? _inFlight;

  /// Whether the wishlist has been successfully loaded at least once.
  bool get hasLoaded => _hasLoaded;

  bool isStationInWishlist(int stationId) {
    return wishlist.any((item) => item.station.id == stationId);
  }

  int? getWishlistIdForStation(int stationId) {
    try {
      final item = wishlist.firstWhere((item) => item.station.id == stationId);
      return item.wishlistId;
    } catch (e) {
      return null;
    }
  }

  /// Fetches the wishlist, but reuses already-loaded data so reopening the
  /// Favourite page displays instantly without an unnecessary API call.
  Future<void> fetchWishlist() async {
    if (_hasLoaded) return;
    await _fetch();
  }

  Future<void> _fetch() async {
    final inFlight = _inFlight;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final future = _doFetchWishlist();
    _inFlight = future;
    try {
      await future;
    } finally {
      if (_inFlight == future) {
        _inFlight = null;
      }
    }
  }

  Future<void> _doFetchWishlist() async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      String? tokenType = prefs.getString('token_type');

      if (token == null) {
        errorMessage = "Please login to view wishlist";
        return;
      }

      final response = await NetworkService.get(
        Uri.parse(ApiEndpoints.wishlist),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': '${tokenType ?? "Bearer"} $token',
        },
      );

      print('========== FETCH WISHLIST ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('====================================');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        WishlistResponse wishlistResponse = WishlistResponse.fromJson(jsonData);
        wishlist = wishlistResponse.data;
        _hasLoaded = true;
      } else if (response.statusCode == 401) {
        errorMessage = "Session expired. Please login again.";
      } else {
        errorMessage = "Failed to load wishlist";
      }
    } on NetworkException catch (_) {
      print('⚠️ No internet connection detected while fetching wishlist');
      errorMessage = NetworkService.noInternetMessage;
    } catch (e) {
      print('Error fetching wishlist: $e');
      errorMessage = "Something went wrong";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeFromWishlist(int wishlistId) async {
    try {
      print('========== REMOVE FROM WISHLIST ==========');
      print('Wishlist ID: $wishlistId');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      String? tokenType = prefs.getString('token_type');

      print('Token exists: ${token != null}');
      print('Token Type: $tokenType');

      if (token == null) {
        print('❌ No token found - User not logged in');
        errorMessage = "Please login to remove from wishlist";
        notifyListeners();
        return false;
      }

      final response = await NetworkService.delete(
        Uri.parse(ApiEndpoints.removeWishlist(wishlistId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': '${tokenType ?? "Bearer"} $token',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      print('Parsed Response: $data');

      if (response.statusCode == 200 && data['success'] == true) {
        wishlist.removeWhere((item) => item.wishlistId == wishlistId);
        notifyListeners();
        print('✅ Successfully removed from wishlist');
        return true;
      } else {
        print('❌ Failed to remove: ${data['message'] ?? 'Unknown error'}');
        errorMessage = data['message'] ?? "Failed to remove from wishlist";
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Error removing from wishlist: $e');
      print('Stack trace: ${StackTrace.current}');
      errorMessage = "Something went wrong: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  // Add method to add to wishlist
  Future<bool> addToWishlist(int stationId, {String notes = ''}) async {
    try {
      print('========== ADD TO WISHLIST ==========');
      print('Station ID: $stationId');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      String? tokenType = prefs.getString('token_type');

      if (token == null) {
        errorMessage = "Please login to add to wishlist";
        notifyListeners();
        return false;
      }

      final response = await NetworkService.post(
        Uri.parse(ApiEndpoints.wishlist),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': '${tokenType ?? "Bearer"} $token',
        },
        body: jsonEncode({
          'charging_station_id': stationId,
          'notes': notes,
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await refreshWishlist(); // Refresh the list
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error adding to wishlist: $e');
      return false;
    }
  }

  void clearError() {
    errorMessage = '';
    notifyListeners();
  }

  /// Always fetches the wishlist from the API, even when data is already
  /// cached. Used for retry and after explicit add/remove actions.
  Future<void> refreshWishlist() async {
    await _fetch();
  }
}


