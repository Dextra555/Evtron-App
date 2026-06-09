import 'package:evtron/View/Home/homemapcard.dart' show MapPreviewCard;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Theme/colors.dart';
import 'card.dart';
import 'notification.dart';
import 'homeenergy.dart';
import 'homeenv.dart';
import 'homenearby.dart';
import 'homestats.dart';
import 'mapui.dart';
import 'scanner.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Store charger data globally or pass it to scanner
  static Map<String, String>? chargerDetails;

  // Location variables
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String? _locationError;

  // User data
  String _userName = "Guest";
  bool _isLoadingUser = true;

  // Sample EV stations data (you can replace with actual data from API)
  List<Map<String, dynamic>> _evStations = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // _loadEvStations();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    setState(() {
      _isLoadingUser = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('user_name');

      // Try alternative keys if 'user_name' doesn't exist
      final String? alternativeName = prefs.getString('name') ??
          prefs.getString('full_name') ??
          prefs.getString('username');

      setState(() {
        _userName = name ?? alternativeName ?? "Guest";
        _isLoadingUser = false;
      });

      print('========== USER NAME LOADED ==========');
      print('User Name: $_userName');
      print('======================================');
    } catch (e) {
      print('Error loading user name: $e');
      setState(() {
        _userName = "Guest";
        _isLoadingUser = false;
      });
    }
  }

  // void _loadEvStations() {
  //   // Sample EV stations data - replace with actual API call
  //   _evStations = [
  //     {
  //       'name': 'Green Charge Station',
  //       'address': '123 Main St, Downtown',
  //       'latitude': 37.7749,
  //       'longitude': -122.4194,
  //       'available': true,
  //       'price': 0.35,
  //       'type': 'CCS2',
  //     },
  //     {
  //       'name': 'EcoCharge Hub',
  //       'address': '456 Park Ave',
  //       'latitude': 37.7812,
  //       'longitude': -122.4125,
  //       'available': false,
  //       'price': 0.42,
  //       'type': 'CHAdeMO',
  //     },
  //     {
  //       'name': 'Tesla Supercharger',
  //       'address': '789 Market St',
  //       'latitude': 37.7689,
  //       'longitude': -122.4256,
  //       'available': true,
  //       'price': 0.48,
  //       'type': 'Tesla',
  //     },
  //   ];
  // }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = "Location services are disabled. Please enable them.";
          _isLoadingLocation = false;
        });
        return;
      }

      // Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = "Location permissions are denied.";
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = "Location permissions are permanently denied. Please enable them in settings.";
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = "Failed to get location: ${e.toString()}";
        _isLoadingLocation = false;
      });
    }
  }

  void _showChargerDetailsBottomSheet(BuildContext context) {
    final TextEditingController chargerModelController = TextEditingController();
    String selectedChargerType = 'CCS2';

    final List<String> chargerTypes = ['CCS2', 'CHAdeMO', 'Type 2', 'GB/T', 'Tesla Supercharger'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.65,
                minChildSize: 0.5,
                maxChildSize: 0.8,
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Appcolor.green.withOpacity(0.1),
                                        Appcolor.green.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
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
                                        "Charger Details",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Enter charger information",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Form fields
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),

                                // Charger Model
                                _buildLabel("Charger Model *"),
                                TextField(
                                  controller: chargerModelController,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: _buildInputDecoration(
                                    hint: "e.g., Delta AC-22, ABB Terra 54",
                                    icon: Icons.model_training,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                _buildLabel("Charger Type *"),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedChargerType,
                                      icon: Icon(Icons.arrow_drop_down, color: Appcolor.green),
                                      iconSize: 24,
                                      isExpanded: true,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      items: chargerTypes.map((String type) {
                                        return DropdownMenuItem<String>(
                                          value: type,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _getChargerIcon(type),
                                                  size: 18,
                                                  color: Appcolor.green,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(type),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setStateBottomSheet(() {
                                          selectedChargerType = newValue!;
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.grey.shade300),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Text(
                                          "Cancel",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Validate form
                                          if (chargerModelController.text.trim().isEmpty) {
                                            _showErrorDialog(context, "Please enter charger model");
                                            return;
                                          }

                                          chargerDetails = {
                                            'chargerModel': chargerModelController.text.trim(),
                                            'chargerType': selectedChargerType,
                                          };

                                          Navigator.pop(context);

                                          // Navigate to scanner page after a short delay
                                          Future.delayed(const Duration(milliseconds: 100), () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ScannerPage(
                                                  chargerDetails: chargerDetails,
                                                ),
                                              ),
                                            );
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Appcolor.green,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          "Continue to Scan",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: Colors.grey.shade400,
      ),
      prefixIcon: Icon(icon, size: 18, color: Appcolor.green),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Appcolor.green, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  IconData _getChargerIcon(String type) {
    switch (type) {
      case 'CCS2':
        return Icons.ev_station;
      case 'CHAdeMO':
        return Icons.bolt;
      case 'Type 2':
        return Icons.electrical_services;
      case 'GB/T':
        return Icons.charging_station;
      case 'Tesla Supercharger':
        return Icons.speed;
      default:
        return Icons.ev_station;
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back,",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _isLoadingUser
                        ? Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                        : Text(
                      "$_userName 👋",
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    iconSize: 20,
                    color: Colors.black87,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>NotificationScreen()));
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // MapPreviewCard with required parameters
                  MapPreviewCard(
                    latitude: _currentPosition?.latitude ?? 37.7749,
                    longitude: _currentPosition?.longitude ?? -122.4194,
                    evStations: _evStations,
                  ),
                  const SizedBox(height: 20),
                  // const SwipeableVehicleCards(),
                  // const SizedBox(height: 20),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Text(
                  //       "Quick Actions",
                  //       style: GoogleFonts.poppins(
                  //         fontSize: 16,
                  //         fontWeight: FontWeight.bold,
                  //         color: Colors.black87,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 10),
                  // Row(
                  //   children: [
                  //     Expanded(child: _buildQuickActionCard(
                  //         Icons.qr_code_scanner_sharp,
                  //         "Scanner",
                  //         Appcolor.green,
                  //         onTap: () {
                  //           _showChargerDetailsBottomSheet(context);
                  //         }
                  //     )),
                  //     const SizedBox(width: 12),
                  //     Expanded(child: _buildQuickActionCard(
                  //         Icons.location_on,
                  //         "Find Station",
                  //         Appcolor.green,
                  //         onTap: () {
                  //           Navigator.push(context, MaterialPageRoute(builder: (context)=>MapScreen()));
                  //         }
                  //     )),
                  //   ],
                  // ),
                  const SizedBox(height: 20),

                  _buildNearbyStationsSection(),

                  const SizedBox(height: 20),
                  const YourStatsSection(),
                  const SizedBox(height: 20),
                  const EnergyUsageTrendSection(),
                  const SizedBox(height: 20),
                  const EnvironmentalImpactSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyStationsSection() {
    if (_isLoadingLocation) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Getting your location..."),
            ],
          ),
        ),
      );
    }

    if (_locationError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.location_off, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text(
              _locationError!,
              style: GoogleFonts.poppins(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolor.green,
              ),
              child: Text("Retry", style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_currentPosition != null) {
      return NearbyStationsSection(
        userLatitude: _currentPosition!.latitude,
        userLongitude: _currentPosition!.longitude,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildQuickActionCard(IconData icon, String label, Color color,{
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}