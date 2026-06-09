// // lib/services/favorite_service.dart
// import 'package:flutter/material.dart';
//
// class FavoriteService extends ChangeNotifier {
//   final List<Map<String, dynamic>> _favorites = [];
//
//   List<Map<String, dynamic>> get favorites => _favorites;
//
//   void addToFavorites(Map<String, dynamic> station) {
//     if (!_isFavorite(station)) {
//       _favorites.add(station);
//       notifyListeners();
//     }
//   }
//
//   void removeFromFavorites(Map<String, dynamic> station) {
//     _favorites.removeWhere((item) => item['name'] == station['name']);
//     notifyListeners();
//   }
//
//   bool _isFavorite(Map<String, dynamic> station) {
//     return _favorites.any((item) => item['name'] == station['name']);
//   }
//
//   bool isFavorite(Map<String, dynamic> station) {
//     return _isFavorite(station);
//   }
//
//   void toggleFavorite(Map<String, dynamic> station) {
//     if (_isFavorite(station)) {
//       removeFromFavorites(station);
//     } else {
//       addToFavorites(station);
//     }
//   }
// }