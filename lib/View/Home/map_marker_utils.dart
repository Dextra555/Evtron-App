import 'package:google_maps_flutter/google_maps_flutter.dart';

LatLng buildMarkerPosition(LatLng base, int index) {
  const offset = 0.0003;
  return LatLng(
    base.latitude + (index * offset),
    base.longitude + (index * offset),
  );
}

String buildMarkerId(int stationId, int index) {
  return index == 0 ? 'station_$stationId' : 'station_${stationId}_$index';
}
