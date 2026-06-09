import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'ev_station_model.dart';

class MapModel {
  LatLng currentPosition = const LatLng(28.6139, 77.2090);
  List<EVStation> evStations = [];
  EVStation? selectedStation;
  double? selectedStationDistance;

  final Set<Marker> markers = {};
  final Set<Circle> circles = {};

  bool isLoading = false;
  bool isGettingLocation = true;
  int currentIndex = 0;
  GoogleMapController? mapController;

  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000;

    double lat1 = point1.latitude * pi / 180;
    double lon1 = point1.longitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double lon2 = point2.longitude * pi / 180;

    double dlat = lat2 - lat1;
    double dlon = lon2 - lon1;

    double a = sin(dlat / 2) * sin(dlat / 2) +
        cos(lat1) * cos(lat2) *
            sin(dlon / 2) * sin(dlon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return (earthRadius * c) / 1000;
  }

  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return "${(distanceInKm * 1000).toInt()} meters";
    } else {
      return "${distanceInKm.toStringAsFixed(1)} km";
    }
  }

  String getEstimatedTravelTime(double distanceInKm) {
    double timeInHours = distanceInKm / 40;
    int minutes = (timeInHours * 60).round();

    if (minutes < 60) {
      return "$minutes min";
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return "${hours} hour${hours > 1 ? 's' : ''}${remainingMinutes > 0 ? ' $remainingMinutes min' : ''}";
    }
  }

  void clearSelectedStation() {
    selectedStation = null;
    selectedStationDistance = null;
  }

  void updateMarkers(Set<Marker> newMarkers) {
    markers.clear();
    markers.addAll(newMarkers);
  }

  void updateCircles(Set<Circle> newCircles) {
    circles.clear();
    circles.addAll(newCircles);
  }

  void reset() {
    evStations.clear();
    markers.clear();
    circles.clear();
    selectedStation = null;
    selectedStationDistance = null;
    isLoading = false;
    isGettingLocation = true;
  }
}