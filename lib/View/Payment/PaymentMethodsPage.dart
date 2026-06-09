import 'dart:io';
import 'package:evtron/Theme/colors.dart';
import 'package:evtron/View/Payment/payamount.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class PaymentMethodsPage extends StatefulWidget {
  final double amount;
  final Function(double) onPaymentSuccess;

  const PaymentMethodsPage({
    super.key,
    required this.amount,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  int _selectedTab = 1;
  int? _selectedMethod;
  bool _isProcessing = false;
  bool _isDownloading = false;
  bool _isAddingMoney = false;

  final double _minimumWalletBalance = 100.00;

  final List<Map<String, dynamic>> _upiMethods = [
    {"name": "Google Pay", "icon": Icons.account_balance_wallet, "number": "****1234", "type": "upi", "color": const Color(0xFF4285F4)},
    {"name": "PhonePe", "icon": Icons.phone_android, "number": "****5678", "type": "upi", "color": const Color(0xFF5C2D91)},
    {"name": "Paytm", "icon": Icons.payment, "number": "****9012", "type": "upi", "color": const Color(0xFF00BAF2)},
    {"name": "Amazon Pay UPI", "icon": Icons.shopping_bag, "number": "****3456", "type": "upi", "color": const Color(0xFFFF9900)},
  ];

  final List<Map<String, dynamic>> _walletMethods = [
    {"name": "Amazon Pay", "icon": Icons.shopping_bag, "number": "Balance: ₹50", "type": "wallet", "color": const Color(0xFFFF9900), "walletBalance": 50.0},
    {"name": "MobiKwik", "icon": Icons.account_balance_wallet, "number": "Balance: ₹1,200", "type": "wallet", "color": const Color(0xFF6A1B9A), "walletBalance": 1200.0},
    {"name": "FreeCharge", "icon": Icons.flash_on, "number": "Balance: ₹500", "type": "wallet", "color": const Color(0xFF00BCD4), "walletBalance": 500.0},
    {"name": "Ola Money", "icon": Icons.car_rental, "number": "Balance: ₹800", "type": "wallet", "color": const Color(0xFF1E88E5), "walletBalance": 800.0},
  ];

  List<Map<String, dynamic>> get _filteredMethods {
    if (_selectedTab == 1) return _upiMethods;
    if (_selectedTab == 3) return _walletMethods;
    return _upiMethods;
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

  Future<void> _downloadReceiptPDF() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final pdf = pw.Document();
      final selectedMethod = _filteredMethods[_selectedMethod ?? 0];
      final now = DateTime.now();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      "PAYMENT RECEIPT",
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 25),
                  pw.Text(
                    "Order Details",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text("Amount Added: ₹${widget.amount}", style: pw.TextStyle(fontSize: 12)),
                  pw.Text("Duration: ${_calculateDuration(widget.amount)}", style: pw.TextStyle(fontSize: 12)),
                  pw.Text("Status: SUCCESSFUL", style: pw.TextStyle(fontSize: 12)),
                  pw.Text(
                      "Date: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}",
                      style: pw.TextStyle(fontSize: 12)),
                  pw.Text(
                      "Time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}",
                      style: pw.TextStyle(fontSize: 12)),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    "Payment Method",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text("Method: ${selectedMethod["name"]}", style: pw.TextStyle(fontSize: 12)),
                  pw.Text("Account: ${selectedMethod["number"]}", style: pw.TextStyle(fontSize: 12)),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    "Transaction Details",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text("Transaction ID: TXN${now.millisecondsSinceEpoch}", style: pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 25),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          "Thank you for your payment!",
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          "This is a computer generated receipt",
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName = "receipt_${now.millisecondsSinceEpoch}.pdf";
      final file = File("${directory.path}/$fileName");

      await file.writeAsBytes(await pdf.save());

      await OpenFile.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Receipt downloaded: $fileName",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Appcolor.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error downloading receipt: $e",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  bool _isWalletMethod(int methodIndex) {
    if (_selectedTab == 3) return true;
    return _filteredMethods[methodIndex]["type"] == "wallet";
  }

  double? _getSelectedWalletBalance() {
    if (_selectedMethod != null && _isWalletMethod(_selectedMethod!) && _selectedTab == 3) {
      return _walletMethods[_selectedMethod!]["walletBalance"] as double?;
    }
    return null;
  }

  double _getRemainingAmountNeeded() {
    final walletBalance = _getSelectedWalletBalance() ?? 0;
    final remaining = _minimumWalletBalance - walletBalance;
    return remaining > 0 ? remaining : 0;
  }

  bool _isWalletSufficient() {
    final walletBalance = _getSelectedWalletBalance() ?? 0;
    return walletBalance >= _minimumWalletBalance;
  }

  bool _validateWalletPayment() {
    if (_selectedMethod != null && _isWalletMethod(_selectedMethod!)) {
      final finalBalance = (_getSelectedWalletBalance() ?? 0) + widget.amount;
      if (finalBalance < _minimumWalletBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Wallet balance after adding will be ₹${finalBalance.toStringAsFixed(2)}\nMinimum balance required: ₹${_minimumWalletBalance.toStringAsFixed(2)}",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return false;
      }
    }
    return true;
  }

  void _handleWalletSelection(int methodIndex) {
    setState(() {
      _selectedMethod = methodIndex;
      if (_isWalletMethod(methodIndex) && !_isWalletSufficient()) {
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

  void _navigateToAmountSelection() {
    // Check if a payment method is selected
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a payment method",
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to AmountSelectionSection
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AmountSelectionSection(
          onAmountSelected: (selectedAmount) {
            _processPaymentWithAmount(selectedAmount);
          },
          currentAmount: widget.amount,
        ),
      ),
    );
  }

  void _processPaymentWithAmount(double amount) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      // Call the success callback with the selected amount
      widget.onPaymentSuccess(amount);

      // Show success bottom sheet
      _showSuccessBottomSheet(amount);
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

              // Print Receipt Button with Download Indicator
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOut,
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isDownloading ? null : () async {
                            await _downloadReceiptPDF();
                          },
                          icon: _isDownloading
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Icon(Icons.download, color: Colors.white, size: 18),
                          label: Text(
                            _isDownloading ? "Downloading..." : "Download Receipt PDF",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Appcolor.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

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
                            Navigator.popUntil(context, (route) => route.isFirst);
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
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          "Tap outside to close",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
            _selectedMethod = null; // Reset selected method when switching tabs
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Appcolor.green : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWalletSelected = _selectedTab == 3;
    final walletSufficient = isWalletSelected && _selectedMethod != null ? _isWalletSufficient() : true;
    final currentWalletBalance = _getSelectedWalletBalance();
    final isMethodSelected = _selectedMethod != null;

    return Column(
      children: [
        if (isWalletSelected && _selectedMethod != null && !walletSufficient)
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
                        "Current balance: ₹${currentWalletBalance?.toStringAsFixed(2) ?? '0'}\nMinimum required: ₹${_minimumWalletBalance.toStringAsFixed(2)}",
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

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildTab("UPI", 1),
              const SizedBox(width: 24),
              _buildTab("Wallets", 3),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List of payment methods
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.35,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredMethods.length,
            itemBuilder: (context, index) {
              final method = _filteredMethods[index];
              final isSelected = _selectedMethod == index;
              final isWallet = _selectedTab == 3;
              final walletBalance = isWallet ? (method["walletBalance"] as double?) : null;
              final needsTopUp = isWallet && (walletBalance ?? 0) < _minimumWalletBalance;

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
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
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
                          size: 20,
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                if (needsTopUp)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "Low Balance",
                                      style: GoogleFonts.poppins(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              method["number"],
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (isWallet && walletBalance != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      size: 12,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Balance: ₹${walletBalance.toStringAsFixed(2)}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: walletBalance < _minimumWalletBalance
                                            ? Colors.red.shade700
                                            : Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Appcolor.green,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Continue Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isMethodSelected ? _navigateToAmountSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolor.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                "Continue",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isMethodSelected ? Colors.white : Colors.grey[500],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}