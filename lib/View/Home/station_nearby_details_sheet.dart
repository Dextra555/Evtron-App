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

  static Future<void> navigate({
    required BuildContext context,
    required StationModel station,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StationDetailsBottomSheet(
          station: station,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context), // Pass context here
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStationHeader(),
            const SizedBox(height: 20),
            _buildInfoCards(),
            const SizedBox(height: 20),
            _buildNavigateButton(context),
            const SizedBox(height: 12),
            _buildFooterInfo(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Station Details",
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildStationHeader() {
    final bool isAvailable = station.available > 0;
    final String statusText = isAvailable ? "Available" : "Unavailable";
    final Color statusColor = isAvailable ? Appcolor.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Appcolor.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.ev_station,
              color: Appcolor.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text(
                      station.distance,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.flash_on, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 3),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    final bool isAvailable = station.available > 0;

    return Column(
      children: [
        // Availability Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAvailable ? Appcolor.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAvailable ? Appcolor.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.cancel,
                color: isAvailable ? Appcolor.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 2),
                    Text(
                      isAvailable
                          ? "${station.available} charging slot${station.available > 1 ? 's' : ''} available"
                          : "No charging slots available at the moment",
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
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),

          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Appcolor.green),
                  const SizedBox(width: 8),
                  Text(
                    "Station Information",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInfoRow(
                "Name",
                station.name,
                Icons.ev_station,
                Appcolor.green,
              ),
              _buildDivider(),
              _buildInfoRow(
                "Distance",
                station.distance,
                Icons.location_on,
                Colors.blue,
              ),
              _buildDivider(),
              _buildInfoRow(
                "Power",
                station.power,
                Icons.flash_on,
                Colors.orange,
              ),
              _buildDivider(),
              _buildInfoRow(
                "Slots",
                "${station.available} available",
                Icons.local_parking,
                station.available > 0 ? Appcolor.green : Colors.red,
              ),
              _buildDivider(),
              _buildInfoRow(
                "Type",
                "EV Charging",
                Icons.electrical_services,
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 2,
      thickness: 1,
      color: Colors.grey[100],
    );
  }

  Widget _buildNavigateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _openGoogleMaps(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Appcolor.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.navigation, size: 20),
            const SizedBox(width: 8),
            Text(
              'Navigate to Station',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Operating Hours: 24/7",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}&travelmode=driving'
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open Google Maps',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

