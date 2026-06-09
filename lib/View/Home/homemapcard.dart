import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'mapui.dart';

class MapPreviewCard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final List<Map<String, dynamic>> evStations;

  const MapPreviewCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.evStations,
  });

  @override
  State<MapPreviewCard> createState() => _MapPreviewCardState();
}

class _MapPreviewCardState extends State<MapPreviewCard> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _addMarkers();
  }

  void _addMarkers() {
    Set<Marker> markers = {};

    // Add markers for EV stations
    for (int i = 0; i < widget.evStations.length; i++) {
      final station = widget.evStations[i];
      markers.add(
        Marker(
          markerId: MarkerId('station_$i'),
          position: LatLng(station['latitude'], station['longitude']),
          infoWindow: InfoWindow(
            title: station['name'],
            snippet: station['address'],
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(
            ),
          ),
        );
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(

          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.latitude, widget.longitude),
                  zoom: 14,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{}.toSet(),
              ),

              // Overlay with gradient to show it's clickable
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
