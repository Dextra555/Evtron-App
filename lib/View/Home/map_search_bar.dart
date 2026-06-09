import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../Model/ev_station_model.dart';

class MapSearchBar extends StatefulWidget {
  final LatLng currentPosition;
  final List<EVStation> evStations;
  final Function(EVStation) onStationSelected;
  final Function(LatLng, String) onLocationSelected;

  const MapSearchBar({
    super.key,
    required this.currentPosition,
    required this.evStations,
    required this.onStationSelected,
    required this.onLocationSelected,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  String? _error;
  bool _isFocused = false;
  static const String _apiKey = "AIzaSyBKgPe-P7029JQIk9KYDT7Os4U96g5Mmbs";

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results.clear();
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = <Map<String, dynamic>>[];

      // Search local EV stations
      for (var station in widget.evStations) {
        if (station.name.toLowerCase().contains(query.toLowerCase()) ||
            station.fullAddress.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            'type': 'EV Station',
            'name': station.name,
            'address': station.fullAddress,
            'station': station,
          });
        }
      }

      // Search Google Places
      final url = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
          "?input=$query"
          "&location=${widget.currentPosition.latitude},${widget.currentPosition.longitude}"
          "&radius=50000&types=establishment|geocode&key=$_apiKey";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['predictions'] != null) {
          for (var prediction in data['predictions']) {
            results.add({
              'type': 'Location',
              'name': prediction['description'],
              'placeId': prediction['place_id'],
              'address': prediction['description'],
            });
          }
        }
      }

      setState(() {
        _results.clear();
        _results.addAll(results);
        _isSearching = false;
        _error = results.isEmpty ? "No results found for '$query'" : null;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _error = "Error searching: $e";
      });
    }
  }

  Future<void> _selectResult(Map<String, dynamic> result) async {
    setState(() => _isSearching = true);

    if (result['type'] == 'EV Station' && result['station'] != null) {
      widget.onStationSelected(result['station']);
    } else if (result['placeId'] != null) {
      final detailsUrl = "https://maps.googleapis.com/maps/api/place/details/json"
          "?place_id=${result['placeId']}&fields=geometry,formatted_address&key=$_apiKey";

      final response = await http.get(Uri.parse(detailsUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final lat = data['result']['geometry']['location']['lat'];
          final lng = data['result']['geometry']['location']['lng'];
          widget.onLocationSelected(LatLng(lat, lng), result['name']);
        }
      }
    }

    _controller.clear();
    setState(() {
      _results.clear();
      _isSearching = false;
      _isFocused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              // ADDED BORDER HERE
              border: Border.all(
                color: _isFocused ? Colors.green : Colors.black,
                width: 0.5,
              ),
              boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 8)],
            ),
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _isFocused = hasFocus;
                });
              },
              child: TextField(
                controller: _controller,
                onChanged: _searchLocation,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search location or EV station...',
                  hintStyle: const TextStyle(color: Colors.black),
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _results.clear();
                        _error = null;
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          if (_results.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length.min(5),
                itemBuilder: (context, index) => Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        _results[index]['type'] == 'EV Station' ? Icons.ev_station : Icons.location_on,
                        color: Colors.green,
                      ),
                      title: Text(_results[index]['name'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        _results[index]['address'] ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                      onTap: () => _selectResult(_results[index]),
                    ),
                    if (index < _results.length.min(5) - 1)
                      Divider(color: Colors.white.withOpacity(0.1)),
                  ],
                ),
              ),
            ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white))),
                ],
              ),
            ),
          if (_isSearching)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)),
                  SizedBox(width: 10),
                  Text('Searching...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

extension MinExtension on int {
  int min(int other) => this < other ? this : other;
}

