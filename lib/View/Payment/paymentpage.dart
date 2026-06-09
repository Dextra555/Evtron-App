import 'package:evtron/View/Payment/payamount.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/colors.dart';
import '../Home/mapui.dart';
import '../Home/scanner.dart';
import '../Login/Bottom.dart';
import '../Profile/profile.dart';
import 'PaymentMethodsPage.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedTab = 0;
  bool _isProcessing = false;
  int _currentIndex = 2; // Payment screen index

  // Amount related variables
  double _walletAmount = 33.50;
  final TextEditingController _amountController = TextEditingController();
  bool _isCustomAmount = false;

  // Current wallet balance (existing balance)
  double _currentBalance = 25.50;

  // Navigation Methods
  void _onTabTapped(int index) {
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

  void _handleAmountSelected(double amount) {
    setState(() {
      _walletAmount = amount;
    });
  }

  @override
  void initState() {
    super.initState();
    _amountController.text = _walletAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(double amount) {
    setState(() {
      _currentBalance += amount;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "₹${amount.toStringAsFixed(2)} added successfully!",
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        backgroundColor: Appcolor.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToAmountSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AmountSelectionSection(
          onAmountSelected: _handleAmountSelected,
          currentAmount: _walletAmount,
        ),
      ),
    ).then((_) {
      // Refresh the UI when coming back
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Add Amount to Wallet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Gradient Wallet Card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child:
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2E7D32),
                              Color(0xFF4CAF50),
                              Color(0xFF66B531),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E7D32).withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: Text(
                                "Current Balance",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Center(
                              child: Text(
                                "₹${_currentBalance.toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Minimum Balance Required: ₹100",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            Center(
                              child: Text(
                                "Add money instantly to continue charging sessions.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ),

                    const SizedBox(height: 10),

                    PaymentMethodsPage(
                      amount: _walletAmount,
                      onPaymentSuccess: _handlePaymentSuccess,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onScanTap: () => _onTabTapped(1),
      ),
    );
  }
}