import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../Model/ev_station_model.dart';
import '../../Service/api_endpoints.dart';

class WishlistService {


  Future<void> refreshWishlist(Function(Set<int>) onUpdate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final tokenType = prefs.getString('token_type');

      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiEndpoints.wishlist),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '${tokenType ?? "Bearer"} $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final wishlistData = jsonData['data'] != null ? jsonData['data'] : (jsonData is List ? jsonData : []);

        final favoriteIds = <int>{};
        for (var item in wishlistData) {
          if (item['station'] != null) {
            favoriteIds.add(item['station']['id']);
          } else if (item['charging_station_id'] != null) {
            favoriteIds.add(item['charging_station_id']);
          } else if (item['station_id'] != null) {
            favoriteIds.add(item['station_id']);
          }
        }
        onUpdate(favoriteIds);
      }
    } catch (e) {
      print('Error refreshing wishlist: $e');
    }
  }

  Future<bool> addToWishlist({
    required int chargingStationId,
    required bool isFavorite,
    String notes = '',
  }) async
  {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final tokenType = prefs.getString('token_type');

      print('========== WISHLIST ADD ==========');
      print('Charging Station ID: $chargingStationId');
      print('Is Favorite: $isFavorite');
      print('Token exists: ${token != null}');
      print('==================================');

      if (token == null) {
        print('❌ No token found, user not logged in');
        return false;
      }

      if (isFavorite) {
        final response = await http.post(
          Uri.parse(ApiEndpoints.wishlist),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': '${tokenType ?? "Bearer"} $token',
          },
          body: jsonEncode({
            'charging_station_id': chargingStationId,
            'notes': notes,
          }),
        );

        print('Add to Wishlist Response: ${response.statusCode}');
        print('Response Body: ${response.body}');

        return response.statusCode == 200 || response.statusCode == 201;
      } else {
        final wishlistId = await _getWishlistIdForStation(chargingStationId);

        if (wishlistId == null) {
          print('❌ Wishlist ID not found for station $chargingStationId');
          return false;
        }

        final response = await http.delete(
          Uri.parse('${ApiEndpoints.wishlist}/$wishlistId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': '${tokenType ?? "Bearer"} $token',
          },
        );

        print('Remove from Wishlist Response: ${response.statusCode}');
        print('Response Body: ${response.body}');

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 &&
            data['success'] == true) {

          print(data['message']);

          return true;
        } else {

          print('Failed to remove from wishlist');

          return false;
        }
      }
    } catch (e) {
      print('❌ Error in addToWishlist: $e');
      return false;
    }
  }


  Future<bool> toggleFavorite(EVStation station, bool addToWishlist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final tokenType = prefs.getString('token_type');

      if (token == null) return false;

      if (addToWishlist) {
        final response = await http.post(
          Uri.parse(ApiEndpoints.wishlist),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': '${tokenType ?? "Bearer"} $token',
          },
          body: jsonEncode({'charging_station_id': station.id, 'notes': ''}),
        );
        return response.statusCode == 200 || response.statusCode == 201;
      } else {
        final wishlistId = await _getWishlistIdForStation(station.id);
        if (wishlistId == null) return false;

        final response = await http.delete(
          Uri.parse('${ApiEndpoints.wishlist}/$wishlistId'),
          headers: {'Authorization': '${tokenType ?? "Bearer"} $token'},
        );
        return response.statusCode == 200;
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  Future<int?> _getWishlistIdForStation(int stationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final tokenType = prefs.getString('token_type');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse(ApiEndpoints.wishlist),
        headers: {'Authorization': '${tokenType ?? "Bearer"} $token'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final wishlistData = jsonData['data'] != null ? jsonData['data'] : (jsonData is List ? jsonData : []);

        for (var item in wishlistData) {
          if (item['station'] != null && item['station']['id'] == stationId) {
            return item['id'] ?? item['wishlist_id'];
          } else if (item['charging_station_id'] == stationId) {
            return item['id'] ?? item['wishlist_id'];
          } else if (item['station_id'] == stationId) {
            return item['id'] ?? item['wishlist_id'];
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}