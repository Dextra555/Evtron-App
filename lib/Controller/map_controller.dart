// import 'dart:math';
//
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../Model/ev_station_model.dart';
// import '../Service/map_service.dart';
// import '../Model/map_model.dart';
//
// class MapController extends ChangeNotifier {
//   final MapModel _model;
//   final MapService _service;
//
//   MapController(this._model, this._service);
//
//   MapModel get model => _model;
//
//   void setMapController(GoogleMapController controller) {
//     _model.mapController = controller;
//   }
//
//   void updateCurrentPosition(LatLng position) {
//     _model.currentPosition = position;
//     _model.isGettingLocation = false;
//     notifyListeners();
//   }
//
//   void setSelectedStation(EVStation? station, double? distance) {
//     _model.selectedStation = station;
//     _model.selectedStationDistance = distance;
//     notifyListeners();
//   }
//
//   void clearSelectedStation() {
//     _model.clearSelectedStation();
//     notifyListeners();
//   }
//
//   void setLoading(bool loading) {
//     _model.isLoading = loading;
//     notifyListeners();
//   }
//
//   void setGettingLocation(bool gettingLocation) {
//     _model.isGettingLocation = gettingLocation;
//     notifyListeners();
//   }
//
//   void updateEVStations(List<EVStation> stations) {
//     _model.evStations = stations;
//     notifyListeners();
//   }
//
//   void updateMarkers(Set<Marker> markers) {
//     _model.updateMarkers(markers);
//     notifyListeners();
//   }
//
//   void updateSearchRadius() {
//     _model.circles.clear();
//     _model.circles.add(
//       Circle(
//         circleId: const CircleId('search_radius'),
//         center: _model.currentPosition,
//         radius: 5000,
//         fillColor: Colors.green.withOpacity(0.1),
//         strokeColor: Colors.green.withOpacity(0.5),
//         strokeWidth: 2,
//       ),
//     );
//     notifyListeners();
//   }
//
//   void adjustMapToShowAllStations() {
//     if (_model.mapController == null || _model.evStations.isEmpty) return;
//
//     try {
//       double minLat = _model.evStations[0].location.latitude;
//       double maxLat = _model.evStations[0].location.latitude;
//       double minLng = _model.evStations[0].location.longitude;
//       double maxLng = _model.evStations[0].location.longitude;
//
//       minLat = min(minLat, _model.currentPosition.latitude);
//       maxLat = max(maxLat, _model.currentPosition.latitude);
//       minLng = min(minLng, _model.currentPosition.longitude);
//       maxLng = max(maxLng, _model.currentPosition.longitude);
//
//       for (var station in _model.evStations) {
//         minLat = min(minLat, station.location.latitude);
//         maxLat = max(maxLat, station.location.latitude);
//         minLng = min(minLng, station.location.longitude);
//         maxLng = max(maxLng, station.location.longitude);
//       }
//
//       double latPadding = (maxLat - minLat) * 0.2;
//       double lngPadding = (maxLng - minLng) * 0.2;
//
//       if (latPadding < 0.01) latPadding = 0.05;
//       if (lngPadding < 0.01) lngPadding = 0.05;
//
//       final bounds = LatLngBounds(
//         southwest: LatLng(minLat - latPadding, minLng - lngPadding),
//         northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
//       );
//
//       _model.mapController?.animateCamera(
//         CameraUpdate.newLatLngBounds(bounds, 50),
//       );
//     } catch (e) {
//       print('Error adjusting map: $e');
//       _model.mapController?.animateCamera(
//         CameraUpdate.newLatLngZoom(_model.currentPosition, 12),
//       );
//     }
//   }
//
//   Future<void> getCurrentLocation() async {
//     setGettingLocation(true);
//     setLoading(true);
//
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         _showErrorSnackBar("Please enable location services");
//         setGettingLocation(false);
//         setLoading(false);
//         return;
//       }
//
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           _showErrorSnackBar("Location permission denied");
//           setGettingLocation(false);
//           setLoading(false);
//           return;
//         }
//       }
//
//       if (permission == LocationPermission.deniedForever) {
//         _showErrorSnackBar("Location permissions permanently denied");
//         setGettingLocation(false);
//         setLoading(false);
//         return;
//       }
//
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//
//       updateCurrentPosition(LatLng(position.latitude, position.longitude));
//       await fetchNearbyStations();
//
//     } catch (e) {
//       _showErrorSnackBar("Error getting location: $e");
//       setGettingLocation(false);
//       setLoading(false);
//       await fetchNearbyStations();
//     }
//   }
//
//   /// Fetch nearby stations using the API with station name parameter
//   Future<void> fetchNearbyStations({String? stationName}) async {
//     if (_model.isGettingLocation) return;
//
//     setLoading(true);
//
//     try {
//       final stations = await _service.fetchNearbyStations(
//         latitude: _model.currentPosition.latitude,
//         longitude: _model.currentPosition.longitude,
//         radius: 5000,
//         stationName: stationName,
//       );
//
//       if (stations.isNotEmpty) {
//         print('✅ Successfully fetched ${stations.length} stations from API');
//         updateEVStations(stations);
//         await addMarkersFromStations();
//
//         Future.delayed(const Duration(milliseconds: 500), () {
//           adjustMapToShowAllStations();
//         });
//
//         _showSuccessSnackBar("Found ${_model.evStations.length} EV stations nearby");
//       } else {
//         print('⚠️ API returned no stations, loading mock data');
//         _showErrorSnackBar("No stations found nearby");
//         loadMockStations();
//       }
//     } catch (e) {
//       print('❌ Error fetching stations: $e');
//       _showErrorSnackBar("Error: $e");
//       loadMockStations();
//     } finally {
//       setLoading(false);
//     }
//   }
//
//   /// Search stations by name
//   Future<void> searchStationsByName(String stationName) async {
//     if (stationName.trim().isEmpty) {
//       await fetchNearbyStations();
//       return;
//     }
//
//     setLoading(true);
//
//     try {
//       final stations = await _service.searchStationsByName(stationName);
//
//       if (stations.isNotEmpty) {
//         updateEVStations(stations);
//         await addMarkersFromStations();
//
//         Future.delayed(const Duration(milliseconds: 500), () {
//           adjustMapToShowAllStations();
//         });
//
//         _showSuccessSnackBar("Found ${stations.length} stations matching '$stationName'");
//       } else {
//         _showErrorSnackBar("No stations found matching '$stationName'");
//         if (_model.evStations.isEmpty) {
//           loadMockStations();
//         }
//       }
//     } catch (e) {
//       _showErrorSnackBar("Search failed: $e");
//     } finally {
//       setLoading(false);
//     }
//   }
//
//   void loadMockStations() {
//     final mockStations = _service.loadMockStations();
//     updateEVStations(mockStations);
//     addMarkersFromStations();
//     Future.delayed(const Duration(milliseconds: 500), () {
//       adjustMapToShowAllStations();
//     });
//   }
//
//   Future<void> addMarkersFromStations() async {
//     final Set<Marker> newMarkers = {};
//
//     print('📍 Adding ${_model.evStations.length} markers to map');
//
//     for (int i = 0; i < _model.evStations.length; i++) {
//       final station = _model.evStations[i];
//
//       final marker = Marker(
//         markerId: MarkerId('station_${station.id}'),
//         position: station.location,
//         infoWindow: InfoWindow(
//           title: station.name,
//           snippet: '⭐ ${station.rating.toStringAsFixed(1)} | ${station.availableChargers}/${station.totalChargers} chargers available',
//           onTap: () {
//             final distance = _model.calculateDistance(_model.currentPosition, station.location);
//             setSelectedStation(station, distance);
//           },
//         ),
//         icon: await _service.getMarkerIcon(station),
//       );
//
//       newMarkers.add(marker);
//     }
//
//     updateMarkers(newMarkers);
//     updateSearchRadius();
//     print('✅ Total markers added: ${newMarkers.length}');
//   }
//
//   Future<void> openNavigation(LatLng destination, String destinationName) async {
//     try {
//       Position currentPosition = await Geolocator.getCurrentPosition();
//       String origin = "${currentPosition.latitude},${currentPosition.longitude}";
//       String destinationCoords = "${destination.latitude},${destination.longitude}";
//
//       String googleMapsUrl = "comgooglemaps://?daddr=$destinationCoords&directionsmode=driving";
//       String webUrl = "https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destinationCoords&travelmode=driving";
//
//       Uri googleMapsUri = Uri.parse(googleMapsUrl);
//       Uri webUri = Uri.parse(webUrl);
//
//       if (await canLaunchUrl(googleMapsUri)) {
//         await launchUrl(googleMapsUri);
//       } else {
//         await launchUrl(webUri);
//       }
//
//       _showSuccessSnackBar("Opening navigation to $destinationName...");
//
//     } catch (e) {
//       _showErrorSnackBar("Could not open navigation: $e");
//       if (await canLaunchUrl(Uri.parse("maps://"))) {
//         String appleMapsUrl = "maps://?daddr=${destination.latitude},${destination.longitude}";
//         await launchUrl(Uri.parse(appleMapsUrl));
//       }
//     }
//   }
//
//   void refreshStations() {
//     fetchNearbyStations();
//   }
//
//   void setCurrentIndex(int index) {
//     _model.currentIndex = index;
//     notifyListeners();
//   }
//
//   void _showErrorSnackBar(String message) {
//     // This will be handled by the view through a callback
//     print('Error: $message');
//   }
//
//   void _showSuccessSnackBar(String message) {
//     print('Success: $message');
//   }
// }