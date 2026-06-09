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

  Future<void> fetchWishlist() async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      String? tokenType = prefs.getString('token_type');

      // Check if token exists
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

      // Get authentication token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      String? tokenType = prefs.getString('token_type');

      print('Token exists: ${token != null}');
      print('Token Type: $tokenType');

      // Check if token exists
      if (token == null) {
        print('❌ No token found - User not logged in');
        errorMessage = "Please login to remove from wishlist";
        notifyListeners();
        return false;
      }

      // Make DELETE request with authentication headers
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

      // Parse response
      final data = jsonDecode(response.body);
      print('Parsed Response: $data');

      // Check if deletion was successful
      if (response.statusCode == 200 && data['success'] == true) {
        // Remove from local list
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

  // Add this method to clear error message
  void clearError() {
    errorMessage = '';
    notifyListeners();
  }

  // Add this method to refresh wishlist
  Future<void> refreshWishlist() async {
    await fetchWishlist();
  }
}