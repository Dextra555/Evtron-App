import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../Theme/colors.dart';

class AmountSelectionSection extends StatefulWidget {
  final Function(double) onAmountSelected;
  final double currentAmount;

  const AmountSelectionSection({
    super.key,
    required this.onAmountSelected,
    required this.currentAmount,
  });

  @override
  State<AmountSelectionSection> createState() => _AmountSelectionSectionState();
}

class _AmountSelectionSectionState extends State<AmountSelectionSection> {
  final TextEditingController _customAmountController = TextEditingController();
  double _selectedAmount = 100.0;
  bool _isCustomAmount = false;
  bool _isProcessing = false;
  bool _isDownloading = false;

  final List<double> _presetAmounts = [100, 200, 500, 1000, 2000, 5000];

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

  Future<void> _downloadReceiptPDF(double amount) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final pdf = pw.Document();
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
                  pw.Text("Amount Added: ₹$amount", style: pw.TextStyle(fontSize: 12)),
                  pw.Text("Duration: ${_calculateDuration(amount)}", style: pw.TextStyle(fontSize: 12)),
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
                  pw.Text("Method: Wallet Top-up", style: pw.TextStyle(fontSize: 12)),
                  pw.Text("Account: User Wallet", style: pw.TextStyle(fontSize: 12)),
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

  void _processPayment() async {
    if (_isProcessing) return;

    if (_selectedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter a valid amount",
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.red,
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

      // Call the success callback
      widget.onAmountSelected(_selectedAmount);

      // Show success bottom sheet
      _showSuccessBottomSheet();
    }
  }

  void _showSuccessBottomSheet() {
    final newBalance = widget.currentAmount + _selectedAmount;
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
                      "₹${_selectedAmount.toStringAsFixed(2)}",
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

              // Print Receipt Button
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
                            await _downloadReceiptPDF(_selectedAmount);
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

              // Done Button - Navigates back to previous page
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
                            // Close the bottom sheet and then close the current page
                            Navigator.pop(context); // Close bottom sheet
                            // Small delay to ensure bottom sheet closes first
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) {
                                Navigator.pop(context); // Close AmountSelectionSection to go back to previous page
                              }
                            });
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
                      onTap: () {
                        // Close the bottom sheet and then close the current page
                        Navigator.pop(context); // Close bottom sheet
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            Navigator.pop(context); // Close AmountSelectionSection to go back to previous page
                          }
                        });
                      },
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
    ).then((_) {
      // After bottom sheet is completely closed, navigate back to previous page
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Money",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Appcolor.green.withOpacity(0.1), Appcolor.green.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Select Amount",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "₹${_selectedAmount.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Appcolor.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preset Amounts
                  Text(
                    "Quick Select",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _presetAmounts.length,
                    itemBuilder: (context, index) {
                      final amount = _presetAmounts[index];
                      final isSelected = !_isCustomAmount && _selectedAmount == amount;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAmount = amount;
                            _isCustomAmount = false;
                            _customAmountController.clear();
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Appcolor.green : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Appcolor.green : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "₹$amount",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Custom Amount
                  Text(
                    "Custom Amount",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customAmountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        final amount = double.tryParse(value) ?? 0;
                        setState(() {
                          _selectedAmount = amount;
                          _isCustomAmount = true;
                        });
                      } else {
                        setState(() {
                          _selectedAmount = 0;
                          _isCustomAmount = true;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee),
                      hintText: "Enter custom amount",
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Appcolor.green, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pay Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolor.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Processing Payment...",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
                    : Text(
                  "Pay ₹${_selectedAmount.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

