import 'package:flutter/material.dart';
import '../../Model/ev_station_model.dart';

class StationCard extends StatelessWidget {
  final EVStation station;
  final double distance;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDetails;
  final VoidCallback onNavigate;
  final VoidCallback onClose; // Added close callback

  const StationCard({
    super.key,
    required this.station,
    required this.distance,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onDetails,
    required this.onNavigate,
    required this.onClose, // Made required
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
    return GestureDetector(
      onTap: onDetails,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.ev_station, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(station.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                          // Favorite button
                          GestureDetector(
                            onTap: onFavoriteToggle,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Close button (replaces status)
                          GestureDetector(
                            onTap: onClose,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
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
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(station.fullAddress, style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoChip(Icons.directions_car, _formatDistance(), Colors.blue),
                const SizedBox(width: 8),
                _infoChip(Icons.access_time, _getTravelTime(), Colors.orange),
                const SizedBox(width: 8),
                _infoChip(Icons.attach_money, '₹${station.estimatedChargingPrice.toStringAsFixed(0)}', Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation, size: 18),
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