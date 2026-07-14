import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/colors.dart';
import '../Scanner/scanner.dart';
import '../Payment/paymentpage.dart';
import '../Profile/myevs.dart';
import './homeContent.dart';
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
    ProfileScreen(isDarkMode: false, onToggle: () {}),
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
                  if (selectedChargerModel.isEmpty) {
                  _showErrorDialog(context, "Please select charger model");
                  return;
                  }
                  if (selectedChargerType.isEmpty) {
                  _showErrorDialog(context, "Please select charger type");
                  return;
                  }

                  Map<String, String> chargerDetails = {
                  'chargerModel': selectedChargerModel,
                  'chargerType': selectedChargerType,
                  };

                  Navigator.pop(context);

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
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildCustomBottomNavBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Appcolor.green,
            Appcolor.green.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Appcolor.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.qr_code_scanner_outlined,
            activeIcon: Icons.qr_code_scanner_rounded,
            label: 'Scan',
            isCenter: true,
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.credit_card_outlined,
            activeIcon: Icons.credit_card_rounded,
            label: 'Pay',
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool isCenter = false,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 1) {
          _showChargerDetailsBottomSheet(context);
        } else {
          _onTap(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isCenter ? 55 : 45,
              height: isCenter ? 55 : 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : Colors.transparent,
                border: isSelected && !isCenter
                    ? Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                )
                    : null,
              ),
              child: Center(
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: isCenter ? 30 : 24,
                  color: Colors.white,
                ),
              ),
            ),
            if (!isCenter) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


