import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationService {
  Future<void> openNavigation(LatLng destination, String destinationName) async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition();
      String origin = "${currentPosition.latitude},${currentPosition.longitude}";
      String destinationCoords = "${destination.latitude},${destination.longitude}";

      String googleMapsUrl = "comgooglemaps://?daddr=$destinationCoords&directionsmode=driving";
      String webUrl = "https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destinationCoords&travelmode=driving";

      Uri googleMapsUri = Uri.parse(googleMapsUrl);
      Uri webUri = Uri.parse(webUrl);

      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri);
      } else {
        await launchUrl(webUri);
      }
      // Don't return anything here - just let the function complete
    } catch (e) {
      // Try Apple Maps as fallback for iOS
      if (await canLaunchUrl(Uri.parse("maps://"))) {
        String appleMapsUrl = "maps://?daddr=${destination.latitude},${destination.longitude}";
        await launchUrl(Uri.parse(appleMapsUrl));
      } else {
        throw Exception("Could not open navigation: $e");
      }
    }
  }
}