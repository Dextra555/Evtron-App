import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleMapsService {
  static const String API_KEY = 'AIzaSyBKgPe-P7029JQIk9KYDT7Os4U96g5Mmbs';

  Future<void> openGoogleMapsWithStations(BuildContext context) async {
    try {
      final String googleMapsAppUrl = "comgooglemaps://?q=EV+charging+stations+near+me";
      final Uri appUri = Uri.parse(googleMapsAppUrl);

      final String webUrl = "https://www.google.com/maps/search/EV+charging+stations+near+me";
      final Uri webUri = Uri.parse(webUrl);

      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog(context, "Cannot open Google Maps");
      }
    } catch (e) {
      debugPrint('Error opening Google Maps: $e');
      _showErrorDialog(context, "Failed to open Google Maps: ${e.toString()}");
    }
  }

  Future<void> openGoogleMapsWithDirections({
    required BuildContext context,
    required String stationName,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final String googleMapsAppUrl = "comgooglemaps://?daddr=$latitude,$longitude&directionsmode=driving";
      final Uri appUri = Uri.parse(googleMapsAppUrl);

      final String webUrl = "https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&destination_plane=1";
      final Uri webUri = Uri.parse(webUrl);

      final String geoUrl = "geo:$latitude,$longitude?q=$latitude,$longitude($stationName)";
      final Uri geoUri = Uri.parse(geoUrl);

      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog(context, "Cannot open Google Maps");
      }
    } catch (e) {
      debugPrint('Error opening Google Maps: $e');
      _showErrorDialog(context, "Failed to open Google Maps: ${e.toString()}");
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String getStaticMapImage({
    required double latitude,
    required double longitude,
    int zoom = 15,
    int width = 400,
    int height = 200,
  }) {
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=$zoom&size=${width}x${height}&markers=color:green%7Clabel:EV%7C$latitude,$longitude&key=$API_KEY';
  }

  Future<List<String>> getPlaceSuggestions(String input) async {
    return [];
  }
}

