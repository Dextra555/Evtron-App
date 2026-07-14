import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/colors.dart';

class WalletMethodsPage extends StatefulWidget {
  final double amount;
  final Function(double) onPaymentSuccess;

  const WalletMethodsPage({
    super.key,
    required this.amount,
    required this.onPaymentSuccess,
  });

  @override
  State<WalletMethodsPage> createState() => _WalletMethodsPageState();
}

class _WalletMethodsPageState extends State<WalletMethodsPage> {
  int? _selectedMethod;
  bool _isProcessing = false;
  bool _isDownloading = false;

  final double _minimumWalletBalance = 100.00;

  final List<Map<String, dynamic>> _walletMethods = [
    {"name": "Amazon Pay", "icon": Icons.shopping_bag, "number": "Balance: ₹50", "type": "wallet", "color": const Color(0xFFFF9900), "walletBalance": 50.0},
    {"name": "Paytm Wallet", "icon": Icons.payment, "number": "Balance: ₹75", "type": "wallet", "color": const Color(0xFF00BAF2), "walletBalance": 75.0},
    {"name": "PhonePe Wallet", "icon": Icons.phone_android, "number": "Balance: ₹120", "type": "wallet", "color": const Color(0xFF5C2D91), "walletBalance": 120.0},
    {"name": "Google Pay Wallet", "icon": Icons.account_balance_wallet, "number": "Balance: ₹200", "type": "wallet", "color": const Color(0xFF4285F4), "walletBalance": 200.0},
  ];

  double? _getSelectedWalletBalance() {
    if (_selectedMethod != null) {
      return _walletMethods[_selectedMethod!]["walletBalance"] as double?;
    }
    return null;
  }

  bool _isWalletSufficient() {
    final walletBalance = _getSelectedWalletBalance() ?? 0;
    return walletBalance >= _minimumWalletBalance;
  }

  void _handleWalletSelection(int methodIndex) {
    setState(() {
      _selectedMethod = methodIndex;
      if (!_isWalletSufficient()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Minimum balance required: ₹${_minimumWalletBalance.toStringAsFixed(2)}\nCurrent balance: ₹${(_getSelectedWalletBalance() ?? 0).toStringAsFixed(2)}",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _processPayment() async {
    if (_isProcessing) return;

    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a wallet",
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      widget.onPaymentSuccess(widget.amount);
      _showSuccessBottomSheet(widget.amount);
    }
  }

  void _showSuccessBottomSheet(double amount) {
    final newBalance = (_getSelectedWalletBalance() ?? 0) + amount;
    final newDuration = _calculateDuration(newBalance);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Appcolor.green.withOpacity(0.2),
                            Appcolor.green.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Appcolor.green,
                        size: 56,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  "Payment Successful!",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Text(
                      "₹${amount.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Appcolor.green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "has been successfully added to your wallet",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Appcolor.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Appcolor.green.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Appcolor.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Appcolor.green,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "New Wallet Balance",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  "₹${newBalance.toStringAsFixed(2)}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Appcolor.green,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Appcolor.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$newDuration total charging time",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Appcolor.green,
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
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Done Button
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close bottom sheet
                            Navigator.pop(context); // Close wallet page
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            "Done",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _calculateDuration(double amount) {
    int totalMinutes = amount.toInt();
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else {
      return "${minutes} min";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMethodSelected = _selectedMethod != null;
    final selectedWalletBalance = _getSelectedWalletBalance();
    final isSufficient = selectedWalletBalance != null && selectedWalletBalance >= _minimumWalletBalance;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Select Wallet",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Amount Display
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Amount to Add",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  "₹${widget.amount.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Appcolor.green,
                  ),
                ),
              ],
            ),
          ),

          if (_selectedMethod != null && !isSufficient)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Insufficient Wallet Balance",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade800,
                          ),
                        ),
                        Text(
                          "Current balance: ₹${selectedWalletBalance?.toStringAsFixed(2) ?? '0'}\nMinimum required: ₹${_minimumWalletBalance.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Available Wallets",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // List of wallet methods
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _walletMethods.length,
              itemBuilder: (context, index) {
                final method = _walletMethods[index];
                final isSelected = _selectedMethod == index;
                final walletBalance = method["walletBalance"] as double;
                final needsTopUp = walletBalance < _minimumWalletBalance;

                return GestureDetector(
                  onTap: () {
                    _handleWalletSelection(index);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Appcolor.green : (needsTopUp ? Colors.red.shade200 : Colors.grey[200]!),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Appcolor.green.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Appcolor.green.withOpacity(0.1)
                                : (needsTopUp ? Colors.red.shade50 : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            method["icon"],
                            color: isSelected
                                ? Appcolor.green
                                : (needsTopUp ? Colors.red : Colors.grey[600]),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    method["name"],
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  if (needsTopUp)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "Low Balance",
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  if (isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Appcolor.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "Selected",
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Appcolor.green,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Balance: ₹${walletBalance.toStringAsFixed(2)}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: walletBalance < _minimumWalletBalance
                                          ? Colors.red.shade700
                                          : Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Appcolor.green,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Pay Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isMethodSelected && isSufficient ? _processPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolor.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isProcessing
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  isMethodSelected && isSufficient
                      ? "Pay ₹${widget.amount.toStringAsFixed(2)}"
                      : isMethodSelected && !isSufficient
                      ? "Insufficient Balance"
                      : "Select a Wallet",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isMethodSelected && isSufficient ? Colors.white : Colors.grey[500],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}