import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/wishlist.dart';
import '../Service/api_endpoints.dart';

class WishlistController extends ChangeNotifier {
  bool isLoading = false;
  List<WishlistItem> wishlist = [];
  String errorMessage = '';

  // Add method to check if a station is in wishlist
  bool isStationInWishlist(int stationId) {
    return wishlist.any((item) => item.station.id == stationId);
  }

  // Add method to get wishlist ID for a station
  int? getWishlistIdForStation(int stationId) {
    try {
      final item = wishlist.firstWhere((item) => item.station.id == stationId);
      return item.wishlistId;
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchWishlist() async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      String? tokenType = prefs.getString('token_type');

      if (token == null) {
        errorMessage = "Please login to view wishlist";
        isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
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
      } else if (response.statusCode == 401) {
        errorMessage = "Session expired. Please login again.";
      } else {
        errorMessage = "Failed to load wishlist";
      }
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

      final response = await http.delete(
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

      final response = await http.post(
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
          await fetchWishlist(); // Refresh the list
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

  Future<void> refreshWishlist() async {
    await fetchWishlist();
  }
}

