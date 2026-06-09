import 'package:evtron/View/Home/station_details_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../Controller/nearby_stations_controller.dart';
import '../../Model/nearby_stations_model.dart';
import '../../Service/google_maps_service.dart';
import '../../Theme/colors.dart';

class NearbyStationsSection extends StatefulWidget {
  final double userLatitude;
  final double userLongitude;

  const NearbyStationsSection({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  State<NearbyStationsSection> createState() => _NearbyStationsSectionState();
}

class _NearbyStationsSectionState extends State<NearbyStationsSection> {
  final GoogleMapsService _mapsService = GoogleMapsService();
  late NearbyStationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NearbyStationsController();
    _fetchStations();
  }

  Future<void> _fetchStations() async {
    await _controller.fetchNearbyStations(
      latitude: widget.userLatitude,
      longitude: widget.userLongitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<NearbyStationsController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return _buildLoadingState();
          }

          if (controller.errorMessage.isNotEmpty) {
            return _buildErrorState(controller);
          }

          if (controller.stations.isEmpty) {
            return _buildEmptyState();
          }

          return _buildStationsList(controller);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Finding nearby stations...",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(NearbyStationsController controller) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),

              const SizedBox(height: 8),
              Text(
                controller.errorMessage,
                style: GoogleFonts.poppins(fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  controller.clearError();
                  _fetchStations();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolor.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Retry",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.ev_station_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                "No Stations Found",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "No EV charging stations found in your area. Try expanding your search or check back later.",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _fetchStations,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      "Refresh",
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Appcolor.green,
                      side: BorderSide(color: Appcolor.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _mapsService.openGoogleMapsWithStations(context),
                    icon: const Icon(Icons.map, size: 18),
                    label: Text(
                      "View on Map",
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Appcolor.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationsList(NearbyStationsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.stations.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final station = controller.stations[index];
            return _buildStationCard(
              context: context,
              index: index,
              station: station,
              controller: controller,
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Nearby Stations",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStationCard({
    required BuildContext context,
    required int index,
    required StationModel station,
    required NearbyStationsController controller,
  }) {
    // Determine status based on available count
    final bool isAvailable = station.available > 0;
    final String statusText = isAvailable ? "Available" : "Unavailable";
    final Color statusColor = isAvailable ? Appcolor.green : Colors.red;

    return GestureDetector(
      onTap: () {
        final int stationId = station.stationId ?? index + 1;
        StationDetailsBottomSheet.show(
          context: context,
          station: station,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Station Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.ev_station,
                color: Appcolor.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Station Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        station.distance,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.flash_on, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        station.power,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Buttons
            Row(
              children: [
                // Favorite Button
                GestureDetector(
                  onTap: () => controller.toggleFavorite(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      station.isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: station.isFavorited ? Colors.red : Colors.grey[400],
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Status and Arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

