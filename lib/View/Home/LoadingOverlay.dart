import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../Model/ev_station_model.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text("Loading EV stations...", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class SearchBarWithFilterWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final VoidCallback onRefresh;

  const SearchBarWithFilterWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white54, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Search by station name...",
                hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: onSearch,
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
              onPressed: () {
                controller.clear();
                onSearch('');
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 8),
          Container(width: 1, height: 30, color: Colors.white24),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green, size: 20),
            onPressed: onRefresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class MapControlsWidget extends StatelessWidget {
  final VoidCallback onMyLocation;
  final VoidCallback onNavigate;
  final VoidCallback onList;
  final VoidCallback onZoomOut;

  const MapControlsWidget({
    super.key,
    required this.onMyLocation,
    required this.onNavigate,
    required this.onList,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _circleButton(Icons.my_location, onTap: onMyLocation),
        const SizedBox(height: 12),
        _circleButton(Icons.navigation, onTap: onNavigate),
        const SizedBox(height: 12),
        _circleButton(Icons.list, onTap: onList),
        const SizedBox(height: 12),
        _circleButton(Icons.zoom_out_map, onTap: onZoomOut),
      ],
    );
  }

  Widget _circleButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class EnhancedStationCard extends StatelessWidget {
  final EVStation station;
  final double distance;
  final VoidCallback onTap;
  final VoidCallback onNavigate;
  final String Function(double) formatDistance;
  final String Function(double) getEstimatedTravelTime;

  const EnhancedStationCard({
    super.key,
    required this.station,
    required this.distance,
    required this.onTap,
    required this.onNavigate,
    required this.formatDistance,
    required this.getEstimatedTravelTime,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDistance = formatDistance(distance);
    final travelTime = getEstimatedTravelTime(distance);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.ev_station, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(station.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(station.rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(width: 8),
                          const Icon(Icons.ev_station, color: Colors.green, size: 12),
                          const SizedBox(width: 4),
                          Text('${station.availableChargers} avail', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: station.availableChargers > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    station.availableChargers > 0 ? "AVAILABLE" : "BUSY",
                    style: TextStyle(color: station.availableChargers > 0 ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(station.fullAddress, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoChip(Icons.directions_car, formattedDistance, Colors.blue),
                const SizedBox(width: 8),
                _infoChip(Icons.access_time, travelTime, Colors.orange),
                const SizedBox(width: 8),
                _infoChip(Icons.attach_money, '₹${station.estimatedChargingPrice.toStringAsFixed(0)}', Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class StationsListWidget extends StatelessWidget {
  final List<EVStation> stations;
  final LatLng currentPosition;
  final Function(EVStation, double) onStationTap;
  final Function(EVStation) onNavigate;

  const StationsListWidget({
    super.key,
    required this.stations,
    required this.currentPosition,
    required this.onStationTap,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 50, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(16), child: Text("Nearby EV Stations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Expanded(
            child: stations.isEmpty
                ? const Center(child: Text("No stations found nearby"))
                : ListView.builder(
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                final distance = _calculateDistance(currentPosition, station.location);
                final formattedDistance = _formatDistance(distance);
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: station.availableChargers > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.ev_station, color: station.availableChargers > 0 ? Colors.green : Colors.red),
                  ),
                  title: Text(station.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(station.fullAddress, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.straighten, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(formattedDistance, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          const SizedBox(width: 8),
                          Icon(Icons.attach_money, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('₹${station.estimatedChargingPrice}/kWh', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(icon: const Icon(Icons.directions, color: Colors.green), onPressed: () => onNavigate(station)),
                  onTap: () => onStationTap(station, distance),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000;
    double lat1 = point1.latitude * pi / 180;
    double lon1 = point1.longitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double lon2 = point2.longitude * pi / 180;
    double dlat = lat2 - lat1;
    double dlon = lon2 - lon1;
    double a = sin(dlat / 2) * sin(dlat / 2) + cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (earthRadius * c) / 1000;
  }

  String _formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return "${(distanceInKm * 1000).toInt()} meters";
    } else {
      return "${distanceInKm.toStringAsFixed(1)} km";
    }
  }
}

class StationDetailsWidget extends StatelessWidget {
  final EVStation station;
  final String formattedDistance;
  final String travelTime;
  final VoidCallback onNavigate;
  final VoidCallback onClose;

  const StationDetailsWidget({
    super.key,
    required this.station,
    required this.formattedDistance,
    required this.travelTime,
    required this.onNavigate,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(child: Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.ev_station, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(station.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: station.availableChargers > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                station.availableChargers > 0 ? "AVAILABLE" : "BUSY",
                style: TextStyle(color: station.availableChargers > 0 ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _detailTile(Icons.location_on, 'Address', station.fullAddress),
        _detailTile(Icons.straighten, 'Distance', formattedDistance),
        _detailTile(Icons.access_time, 'Est. Travel Time', travelTime),
        _detailTile(Icons.flash_on, 'Total Chargers', '${station.totalChargers} ports'),
        _detailTile(Icons.battery_charging_full, 'Available Chargers', '${station.availableChargers} / ${station.totalChargers}', valueColor: station.availableChargers > 0 ? Colors.green : Colors.red),
        _detailTile(Icons.access_time, '24/7 Operation', station.is247 ? 'Yes' : 'No', valueColor: station.is247 ? Colors.green : Colors.orange),
        _detailTile(Icons.attach_money, 'Estimated Price', '₹${station.estimatedChargingPrice.toStringAsFixed(2)}/kWh'),
        _detailTile(Icons.star, 'Station Type', station.stationType.toUpperCase()),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onNavigate,
                icon: const Icon(Icons.directions_car),
                label: const Text('Navigate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _detailTile(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}