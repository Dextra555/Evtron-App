import 'package:evtron/View/Home/scanner.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/colors.dart';
import '../Payment/paymentpage.dart';
import '../myev/myevs.dart';
import 'homeContent.dart';
import '../Profile/profile.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = [
    const HomeContent(),
    const MyVehiclesPage(),
    const PaymentScreen(),
    ProfileScreen(isDarkMode: false, onToggle: () {},),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showChargerDetailsBottomSheet(BuildContext context) {
    String selectedChargerModel = 'Delta AC-22';
    String selectedChargerType = 'CCS2';

    final List<String> chargerModels = [
      'Delta AC-22',
      'ABB Terra 54',
      'ABB Terra 124',
      'Tata Power EZ Charge',
      'BP Pulse 60kW',
      'Shell Recharge 150kW',
      'Tesla Wall Connector',
      'ChargePoint CP50',
      'EvBox Elvi',
      'Allegro 50kW'
    ];

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
                                        "Select charger information",
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

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),

                                _buildLabel("Charger Model *"),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedChargerModel,
                                      icon: Icon(Icons.arrow_drop_down, color: Appcolor.green),
                                      iconSize: 24,
                                      isExpanded: true,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      items: chargerModels.map((String model) {
                                        return DropdownMenuItem<String>(
                                          value: model,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.ev_station,
                                                  size: 18,
                                                  color: Appcolor.green,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(model),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setStateBottomSheet(() {
                                          selectedChargerModel = newValue!;
                                        });
                                      },
                                    ),
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
                                          // Validate selections
                                          if (selectedChargerModel.isEmpty) {
                                            _showErrorDialog(context, "Please select charger model");
                                            return;
                                          }
                                          if (selectedChargerType.isEmpty) {
                                            _showErrorDialog(context, "Please select charger type");
                                            return;
                                          }

                                          // Store charger details
                                          Map<String, String> chargerDetails = {
                                            'chargerModel': selectedChargerModel,
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernBottomNav() {
    return SizedBox(
      height: 85,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: BottomNavBorderPainter(),
              child: ClipPath(
                clipper: BottomNavClipper(),
                child: Container(
                  height: 65,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(
                              icon: Icons.home_outlined,
                              activeIcon: Icons.home_rounded,
                              index: 0,
                            ),
                            _buildNavItem(
                              icon: Icons.electric_car_outlined,
                              activeIcon: Icons.electric_car_rounded,
                              index: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 70),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(
                              icon: Icons.credit_card,
                              activeIcon: Icons.credit_card_rounded,
                              index: 2,
                            ),
                            _buildNavItem(
                              icon: Icons.person_outline_rounded,
                              activeIcon: Icons.person_rounded,
                              index: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 2,
            child: GestureDetector(
              onTap: () {
                _showChargerDetailsBottomSheet(context);
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Appcolor.green, Appcolor.green.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Appcolor.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular highlight background only
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Appcolor.green.withOpacity(0.15) : Colors.transparent,
              ),
              child: Center(
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 24,
                  color: isSelected ? Appcolor.green : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.moveTo(0, 0);

    path.quadraticBezierTo(
      size.width * 0.15,
      0,
      size.width * 0.32,
      0,
    );

    // First part of the center dip (left side of the raised area)
    path.quadraticBezierTo(
      size.width * 0.38,
      0,
      size.width * 0.40,
      15,
    );

    // Bottom part of the dip (left side)
    path.quadraticBezierTo(
      size.width * 0.44,
      43,
      size.width * 0.50,
      43,
    );

    // Bottom part of the dip (right side)
    path.quadraticBezierTo(
      size.width * 0.56,
      43,
      size.width * 0.60,
      12,
    );

    // Second part of the center dip (right side of the raised area)
    path.quadraticBezierTo(
      size.width * 0.62,
      0,
      size.width * 0.68,
      0,
    );

    path.quadraticBezierTo(
      size.width * 0.85,
      0,
      size.width,
      0,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomNavBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = BottomNavClipper().getClip(size);

    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
