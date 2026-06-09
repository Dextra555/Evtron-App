import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Model/nearby_stations_model.dart';
import '../../Theme/colors.dart';

class StationDetailsBottomSheet extends StatelessWidget {
  final StationModel station;

  const StationDetailsBottomSheet({
    super.key,
    required this.station,
  });

  static Future<void> show({
    required BuildContext context,
    required StationModel station,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StationDetailsBottomSheet(
        station: station,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              _buildDragHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStationHeader(),
                      const SizedBox(height: 20),
                      _buildStationDetails(),
                      const SizedBox(height: 20),
                      _buildNavigateButton(),
                      const SizedBox(height: 20),
                      _buildStatusDetails(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStationHeader() {
    final bool isAvailable = station.available > 0;
    final String statusText = isAvailable ? "Available" : "Unavailable";
    final Color statusColor = isAvailable ? Appcolor.green : Colors.red;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Appcolor.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.ev_station,
            color: Appcolor.green,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                station.name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    station.distance,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.flash_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    station.power,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusText,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStationDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Station Information"),
          const SizedBox(height: 12),
          _buildDetailRow(
            "Station Name",
            station.name,
            Icons.ev_station,
            Appcolor.green,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            "Distance",
            station.distance,
            Icons.location_on,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            "Power Capacity",
            station.power,
            Icons.flash_on,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            "Available Slots",
            "${station.available} ${station.available == 1 ? 'slot' : 'slots'} available",
            Icons.local_parking,
            station.available > 0 ? Appcolor.green : Colors.red,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            "Station Type",
            "EV Charging Station",
            Icons.electrical_services,
            Colors.purple,
          ),

        ],
      ),
    );
  }

  Widget _buildStatusDetails() {
    final bool isAvailable = station.available > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable ? Appcolor.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? Appcolor.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Availability Status"),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.cancel,
                color: isAvailable ? Appcolor.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAvailable ? "Ready to Charge" : "Currently Unavailable",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isAvailable ? Appcolor.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAvailable
                          ? "This station has ${station.available} charging slot${station.available > 1 ? 's' : ''} available right now"
                          : "No charging slots available at this station at the moment",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigateButton() {
    return ElevatedButton.icon(
      onPressed: () => _openGoogleMaps(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Appcolor.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.navigation),
      label: Text(
        'Navigate to Station',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps() async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}&travelmode=driving'
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}