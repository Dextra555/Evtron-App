import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {

  // Add this stream controller at the top of your class
  // You'll need to add: import 'dart:async';

  Future<LatLng?> getCurrentLocation({Function(String)? onError}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        onError?.call("Please enable location services");
        return null;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          onError?.call("Location permission denied");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        onError?.call("Location permissions permanently denied");
        return null;
      }

      Position position =
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(
        position.latitude,
        position.longitude,
      );

    } catch (e) {
      onError?.call("Error getting location: $e");
      return null;
    }
  }

  // ADD THIS METHOD - Real-time location stream
  Stream<LatLng?> getLocationStream() {
    // First check if location services are enabled
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: Duration(seconds: 5), // Or every 5 seconds
      ),
    ).map((Position position) {
      return LatLng(
        position.latitude,
        position.longitude,
      );
    }).handleError((error) {
      print("Location stream error: $error");
      return null;
    });
  }

  // Alternative: Get single current position (you already have this but renamed)
  Future<LatLng?> getCurrentPosition() async {
    try {
      Position position =
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(
        position.latitude,
        position.longitude,
      );

    } catch (e) {
      return null;
    }
  }

  double calculateDistance(
      LatLng point1,
      LatLng point2,
      ) {

    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    ) /
        1000;
  }

  String formatDistance(double distanceInKm) {
    return distanceInKm < 1
        ? "${(distanceInKm * 1000).toInt()} meters"
        : "${distanceInKm.toStringAsFixed(1)} km";
  }

  String getEstimatedTravelTime(double distanceInKm) {

    int minutes = (distanceInKm / 40 * 60).round();

    if (minutes < 60) return "$minutes min";

    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;

    return "$hours hour${hours > 1 ? 's' : ''}"
        "${remainingMinutes > 0 ? ' $remainingMinutes min' : ''}";
  }

  Future<void> openNavigation(
      LatLng origin,
      LatLng destination,
      String name,
      ) async {

    String googleMapsUrl =
        "comgooglemaps://?daddr=${destination.latitude},${destination.longitude}&directionsmode=driving";

    String webUrl =
        "https://www.google.com/maps/dir/?api=1"
        "&origin=${origin.latitude},${origin.longitude}"
        "&destination=${destination.latitude},${destination.longitude}"
        "&travelmode=driving";

    Uri googleMapsUri = Uri.parse(googleMapsUrl);
    Uri webUri = Uri.parse(webUrl);

    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri);
    } else {
      await launchUrl(webUri);
    }
  }
}

