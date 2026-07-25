import 'package:evtron/View/Payment/payamount.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../Controller/wallet_controller.dart';
import '../../Service/AuthService.dart';
import '../../Theme/colors.dart';
import '../Home/mapui.dart';
import '../Scanner/scanner.dart';
import '../Login/Bottom.dart';
import '../Profile/profile.dart';
import 'upi_methods.dart';
import 'wallet_methods.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _currentIndex = 2;
  double _walletAmount = 33.50;
  final TextEditingController _amountController = TextEditingController();
  final WalletController _walletController = WalletController();
  double _currentBalance = 0.0;
  bool _isLoadingWallet = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _amountController.text = _walletAmount.toStringAsFixed(2);
    fetchWalletData();
  }

  Future<void> fetchWalletData() async {
    try {
      setState(() {
        _isLoadingWallet = true;
        _isInitialLoading = true;
      });

      final token = await AuthService.getUserToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingWallet = false;
            _isInitialLoading = false;
          });
        }
        return;
      }

      await _walletController.fetchWallet(token);

      if (_walletController.wallet != null && mounted) {
        setState(() {
          _currentBalance = double.tryParse(
            _walletController.wallet!.walletBalance,
          ) ?? 0.0;
        });
      }
    } catch (e) {
      print('❌ Wallet Fetch Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

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

  void _handlePaymentSuccess(double amount) {
    setState(() => _currentBalance += amount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "₹${amount.toStringAsFixed(2)} added successfully!",
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: Appcolor.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _processPaymentWithAmount(double selectedAmount) {
    setState(() {
      _walletAmount = selectedAmount;
    });
    Navigator.pop(context);
  }

  void _handleAddMoney() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AmountSelectionSection(
          onAmountSelected: (selectedAmount) {
            _processPaymentWithAmount(selectedAmount);
          },
          onBalanceUpdated: (newBalance) {
            setState(() {
              _currentBalance = newBalance;
            });
          },
          currentAmount: _walletAmount,
        ),
      ),
    );
  }

  void _handleWalletButton() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalletMethodsPage(
          amount: _walletAmount,
          onPaymentSuccess: _handlePaymentSuccess,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Title (Always visible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "My Wallet",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Balance Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Appcolor.borderGrey,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Container Text (Total Balance)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Appcolor.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.wallet_outlined,
                            color: Appcolor.green,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Show shimmer only during API fetch
                        _isLoadingWallet || _isInitialLoading
                            ? _buildShimmerText(width: 80, height: 12)
                            : Text(
                          "Total Balance",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Wallet Amount
                    _isLoadingWallet || _isInitialLoading
                        ? _buildShimmerText(width: 150, height: 32)
                        : Text(
                      "₹${_currentBalance.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Info Badge (Always visible)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFE65100),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Min balance ₹100 required",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Add Money Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _isLoadingWallet || _isInitialLoading
                  ? _buildShimmerButton()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleAddMoney,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Appcolor.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Appcolor.green.withOpacity(0.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Add Money",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Add some spacing at bottom
            const Spacer(),
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

  // Reusable Shimmer Text Widget
  Widget _buildShimmerText({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildShimmerButton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}