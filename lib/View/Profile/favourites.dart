import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../../Controller/wishlist_controller.dart';
import '../../Model/wishlist.dart';
import '../../Theme/colors.dart';
import '../Login/Bottom.dart';
import '../Scanner/scanner.dart';
import '../Payment/paymentpage.dart';
import '../Profile/profile.dart';
import '../Home/mapui.dart';

class FavoriteStationsScreen extends StatefulWidget {
  const FavoriteStationsScreen({super.key});

  @override
  State<FavoriteStationsScreen> createState() => _FavoriteStationsScreenState();
}

class _FavoriteStationsScreenState extends State<FavoriteStationsScreen> {
  bool _isRemoving = false;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  void _loadWishlist() {
    context.read<WishlistController>().fetchWishlist();
  }

  Future<void> _openInMaps(double latitude, double longitude, String stationName, String fullAddress) async {
    try {
      if (latitude == 0.0 && longitude == 0.0) {
        final encodedAddress = Uri.encodeComponent(fullAddress);
        final searchUrl = Uri.parse(
            "https://www.google.com/maps/search/?api=1&query=$encodedAddress"
        );

        if (await canLaunchUrl(searchUrl)) {
          await launchUrl(
            searchUrl,
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw 'Could not launch map';
        }
        return;
      }

      final googleMapsUrl = Uri.parse(
          "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude"
      );

      final appleMapsUrl = Uri.parse(
          "http://maps.apple.com/?ll=$latitude,$longitude&q=${Uri.encodeComponent(stationName)}"
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(
          appleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        final browserUrl = Uri.parse(
            "https://www.google.com/maps/place/$latitude,$longitude"
        );
        if (await canLaunchUrl(browserUrl)) {
          await launchUrl(
            browserUrl,
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw 'Could not launch map';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Unable to open maps: ${e.toString()}",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onTabTapped(int index) async {
    if (index == _currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const MapScreen();
        break;
      case 1:
        page = const ScannerPage();
        break;
      case 2:
        page = const PaymentScreen();
        break;
      case 3:
        page = ProfileScreen(isDarkMode: false, onToggle: () {});
        break;
      default:
        page = const MapScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _onScanTap() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ScannerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          "Favorite Stations",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<WishlistController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return _buildShimmerList(isSmallScreen);
          }

          if (controller.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      controller.refreshWishlist();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Appcolor.green,
                    ),
                    child: Text(
                      "Retry",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (controller.wishlist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No Favorite Stations",
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Start adding stations to your favorites",
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
            itemCount: controller.wishlist.length,
            itemBuilder: (context, index) {
              final item = controller.wishlist[index];
              return _buildStationCard(item, index, screenWidth);
            },
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onScanTap: _onScanTap,
      ),
    );
  }

  // Shimmer loader with individual text shimmers inside one container
  Widget _buildShimmerList(bool isSmallScreen) {
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
          padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Station icon placeholder
                    Container(
                      width: isSmallScreen ? 40 : 50,
                      height: isSmallScreen ? 40 : 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Station name shimmer
                          Container(
                            height: isSmallScreen ? 14 : 16,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          // Address line 1 shimmer
                          Container(
                            height: isSmallScreen ? 10 : 12,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                          SizedBox(height: 2),
                          // Address line 2 shimmer
                          Container(
                            height: isSmallScreen ? 10 : 12,
                            width: MediaQuery.of(context).size.width * 0.6,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    // Favorite icon placeholder
                    Container(
                      width: isSmallScreen ? 20 : 24,
                      height: isSmallScreen ? 20 : 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                // Status chips shimmer
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Available slots chip
                    Container(
                      height: isSmallScreen ? 20 : 24,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // 24/7 chip
                    Container(
                      height: isSmallScreen ? 20 : 24,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Chargers count chip
                    Container(
                      height: isSmallScreen ? 20 : 24,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),
                // Navigation hint shimmer
                Container(
                  height: isSmallScreen ? 20 : 24,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStationCard(WishlistItem item, int index, double screenWidth) {
    final station = item.station;
    final isAvailable = station.availableChargers > 0;
    final controller = Provider.of<WishlistController>(context, listen: false);

    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

    final double latitude = double.tryParse(station.latitude) ?? 0.0;
    final double longitude = double.tryParse(station.longitude) ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final addressMaxLines = availableWidth < 400 ? 3 : 2;

        return Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _openInMaps(latitude, longitude, station.stationName, station.fullAddress);
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: isSmallScreen ? 40 : 50,
                          height: isSmallScreen ? 40 : 50,
                          decoration: BoxDecoration(
                            color: Appcolor.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                          ),
                          child: Icon(
                            Icons.ev_station,
                            color: Appcolor.green,
                            size: isSmallScreen ? 24 : 28,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                station.stationName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 13 : 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isSmallScreen ? 4 : 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: isSmallScreen ? 10 : 12,
                                    color: Colors.grey[500],
                                  ),
                                  SizedBox(width: isSmallScreen ? 2 : 4),
                                  Expanded(
                                    child: Text(
                                      station.fullAddress,
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 10 : 11,
                                        color: Colors.grey[600],
                                        height: 1.4,
                                      ),
                                      maxLines: addressMaxLines,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        StatefulBuilder(
                          builder: (context, setState) {
                            return GestureDetector(
                              onTap: _isRemoving ? null : () async {
                                setState(() => _isRemoving = true);

                                final shouldRemove = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      "Remove Station",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    content: Text(
                                      "Are you sure you want to remove ${station.stationName} from favorites?",
                                      style: GoogleFonts.poppins(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text(
                                          "Cancel",
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text(
                                          "Remove",
                                          style: GoogleFonts.poppins(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldRemove == true) {
                                  final success = await controller.removeFromWishlist(
                                    item.wishlistId,
                                  );

                                  if (mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "${station.stationName} removed from favorites",
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Failed to remove ${station.stationName}",
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                }

                                if (mounted) {
                                  setState(() => _isRemoving = false);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                child: _isRemoving
                                    ? SizedBox(
                                  width: isSmallScreen ? 16 : 20,
                                  height: isSmallScreen ? 16 : 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: isSmallScreen ? 20 : 24,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8,
                            vertical: isSmallScreen ? 3 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? Appcolor.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isAvailable
                                ? "${station.availableChargers} Slots Available"
                                : "Unavailable",
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 10 : 11,
                              color: isAvailable
                                  ? Appcolor.green
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8,
                            vertical: isSmallScreen ? 3 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: station.is24_7
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                station.is24_7 ? Icons.schedule : Icons.schedule_outlined,
                                size: isSmallScreen ? 10 : 12,
                                color: station.is24_7 ? Colors.green : Colors.grey,
                              ),
                              SizedBox(width: isSmallScreen ? 2 : 4),
                              Text(
                                station.is24_7 ? "Open 24/7" : "Closed",
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 10 : 11,
                                  color: station.is24_7 ? Colors.green : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8,
                            vertical: isSmallScreen ? 3 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.ev_station,
                                size: isSmallScreen ? 10 : 12,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: isSmallScreen ? 2 : 4),
                              Text(
                                "${station.totalChargers} Chargers",
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 10 : 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 10),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 3 : 4
                      ),
                      decoration: BoxDecoration(
                        color: Appcolor.green.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.navigation,
                            size: isSmallScreen ? 12 : 14,
                            color: Appcolor.green,
                          ),
                          SizedBox(width: isSmallScreen ? 4 : 6),
                          Text(
                            isSmallScreen ? "Tap to navigate" : "Tap to navigate to this station",
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 10 : 11,
                              color: Appcolor.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}