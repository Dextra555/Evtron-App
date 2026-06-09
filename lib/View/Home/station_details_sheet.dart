import 'package:flutter/material.dart';
import '../../Model/ev_station_model.dart';

class StationDetailsSheet extends StatelessWidget {
  final EVStation station;
  final double distance;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onNavigate;

  const StationDetailsSheet({
    super.key,
    required this.station,
    required this.distance,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onNavigate,
  });

  String _formatDistance() {
    return distance < 1 ? "${(distance * 1000).toInt()} meters" : "${distance.toStringAsFixed(1)} km";
  }

  String _getTravelTime() {
    int minutes = (distance / 40 * 60).round();
    if (minutes < 60) return "$minutes min";
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    return "${hours}h${remainingMinutes > 0 ? ' $remainingMinutes min' : ''}";
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.ev_station, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text(station.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                IconButton(
                  onPressed: onFavoriteToggle,
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : Colors.grey, size: 28),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: station.availableChargers > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    station.availableChargers > 0 ? "AVAILABLE" : "BUSY",
                    style: TextStyle(color: station.availableChargers > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailTile(Icons.location_on, 'Address', station.fullAddress),
            _detailTile(Icons.straighten, 'Distance', _formatDistance()),
            _detailTile(Icons.access_time, 'Est. Travel Time', _getTravelTime()),
            _detailTile(Icons.flash_on, 'Total Chargers', '${station.totalChargers} ports'),
            _detailTile(Icons.battery_charging_full, 'Available Chargers', '${station.availableChargers} / ${station.totalChargers}',
                valueColor: station.availableChargers > 0 ? Colors.green : Colors.red),
            _detailTile(Icons.access_time, '24/7 Operation', station.is247 ? 'Yes' : 'No'),
            _detailTile(Icons.attach_money, 'Estimated Price', '₹${station.estimatedChargingPrice.toStringAsFixed(2)}/kWh'),
            _detailTile(Icons.star, 'Station Type', station.stationType.toUpperCase()),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rating', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Row(children: [Text(station.rating.toStringAsFixed(1)), const SizedBox(width: 4), const Text('/ 5')]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (station.connectorPorts.isNotEmpty) ...[
              const Text('Connector Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: station.connectorPorts.map((port) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.3))),
                  child: Column(
                    children: [
                      Text(port.type, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${port.maxPower} kW', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                )).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green)),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onNavigate();
                    },
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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