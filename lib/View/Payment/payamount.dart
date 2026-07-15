import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../Controller/wallet_controller.dart';
import '../../Model/wallet_receipt_model.dart';
import '../../Service/AuthService.dart';
import '../../Service/api_endpoints.dart';
import '../../Theme/colors.dart';

class AmountSelectionSection extends StatefulWidget {
  final Function(double) onAmountSelected;
  final Function(double) onBalanceUpdated;
  final double currentAmount;

  const AmountSelectionSection({
    super.key,
    required this.onAmountSelected,
    required this.onBalanceUpdated,
    required this.currentAmount,
  });

  @override
  State<AmountSelectionSection> createState() => _AmountSelectionSectionState();
}

class _AmountSelectionSectionState extends State<AmountSelectionSection> {
  final TextEditingController _customAmountController = TextEditingController();
  final WalletController _walletController = WalletController();

  late Razorpay _razorpay;

  double _selectedAmount = 100.0;
  bool _isCustomAmount = false;
  bool _isProcessing = false;
  bool _isDownloading = false;
  int? _currentTransactionId;
  WalletReceiptModel? _receiptData;
  File? _generatedReceiptFile;

  double _walletBalance = 0.0;

  // Track current order ID to handle cancellation
  String? _currentOrderId;
  bool _isCancelling = false;
  bool _hasAttemptedCleanup = false;

  final List<double> _presetAmounts = [100, 200, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _cleanupPendingOrdersOnInit();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _customAmountController.dispose();
    _cleanupPendingOrdersOnDispose();
    super.dispose();
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

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      // Check if this is a user cancellation
      if (response.code == 0 || response.message?.contains('cancelled') == true) {
        // User cancelled the payment, we should cancel the order
        _handlePaymentCancellation();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Payment failed: ${response.message}",
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _cleanupPendingOrdersOnInit() async {
    if (_hasAttemptedCleanup) return;
    _hasAttemptedCleanup = true;

    try {
      final token = await AuthService.getUserToken();
      if (token == null || token.isEmpty) return;

      // Check if there's any pending order for this user
      // We'll check during the payment flow instead
    } catch (e) {
      debugPrint('Cleanup on init error: $e');
    }
  }

  // Clean up pending orders when widget disposes
  Future<void> _cleanupPendingOrdersOnDispose() async {
    if (_currentOrderId != null && !_isProcessing) {
      await _handlePaymentCancellation();
    }
  }

  Future<void> _cleanupPendingOrders(String token) async {
    try {
      // First, check if we have a stored order ID
      if (_currentOrderId != null && !_isCancelling) {
        debugPrint('Cleaning up existing order: $_currentOrderId');
        await _handlePaymentCancellation();
        // Wait a moment for the cancellation to process
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Also check for any pending orders via the wallet controller
      // This ensures we catch any orders that might be in a pending state
      // but not tracked by this widget
      try {
        // Call the backend to cancel any pending orders for this user
        final response = await http.post(
          Uri.parse('${ApiEndpoints.baseUrl}/wallet/recharge/cancel-all-pending'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        debugPrint('Cancel all pending orders response: ${response.statusCode}');
      } catch (e) {
        // If the endpoint doesn't exist, that's fine - we'll rely on forceNew
        debugPrint('Cancel all pending orders error (expected if endpoint not available): $e');
      }
    } catch (e) {
      debugPrint('Cleanup pending orders error: $e');
      // If cleanup fails, still try to proceed with forceNew
    }
  }


// Handle payment cancellation - UPDATED with better error handling
  Future<void> _handlePaymentCancellation() async {
    if (_currentOrderId == null || _isCancelling) {
      // Reset state even if no order ID
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      final token = await AuthService.getUserToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isProcessing = false;
          _isCancelling = false;
        });
        return;
      }

      debugPrint('Cancelling order: $_currentOrderId');

      // Cancel the order on the backend
      final cancelResponse = await _walletController.cancelOrder(
        token: token,
        orderId: _currentOrderId!,
      );

      if (mounted) {
        if (cancelResponse != null && cancelResponse.success) {
          // Order cancelled successfully or auto-recovered
          _currentOrderId = null;

          // If auto-recovered, update wallet balance
          if (cancelResponse.autoRecovered && cancelResponse.walletBalance != null) {
            widget.onBalanceUpdated(cancelResponse.walletBalance!);
            setState(() {
              _walletBalance = cancelResponse.walletBalance!;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                cancelResponse.autoRecovered
                    ? "Payment was already processed. Balance updated."
                    : "Payment cancelled. You can try again.",
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              backgroundColor: cancelResponse.autoRecovered ? Appcolor.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // If cancel fails, try to verify and cleanup
          await _verifyAndCleanupOrder(token);
        }
      }
    } catch (e) {
      debugPrint('Cancel order error: $e');
      // Try alternative cleanup
      try {
        final token = await AuthService.getUserToken();
        if (token != null && token.isNotEmpty && _currentOrderId != null) {
          await _verifyAndCleanupOrder(token);
        }
      } catch (_) {
        // If all fails, reset the order ID
        _currentOrderId = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Payment cancelled. Please try again.",
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isCancelling = false;
          // Ensure order ID is cleared even if cancellation partially failed
          _currentOrderId = null;
        });
      }
    }
  }
  // Verify and cleanup order status
  Future<void> _verifyAndCleanupOrder(String token) async {
    if (_currentOrderId == null) return;

    try {
      final statusResponse = await _walletController.verifyOrderStatus(
        token: token,
        orderId: _currentOrderId!,
      );

      if (statusResponse != null) {
        if (statusResponse.isValid &&
            (statusResponse.status?.toLowerCase() == 'paid' ||
                statusResponse.status?.toLowerCase() == 'completed')) {
          // Order is already paid, handle as success
          if (mounted) {
            // Fetch updated wallet balance
            final balance = await _walletController.getCurrentWalletBalance(token);
            if (balance != null) {
              widget.onBalanceUpdated(balance);
              setState(() {
                _walletBalance = balance;
              });
            }
            _currentOrderId = null;
          }
          return;
        } else if (statusResponse.isValid &&
            (statusResponse.status?.toLowerCase() == 'cancelled' ||
                statusResponse.status?.toLowerCase() == 'expired')) {
          // Order is already cancelled or expired
          _currentOrderId = null;
          return;
        }
      }

      // If we can't determine status, try to cancel anyway with alternative payload
      await _forceCancelOrder(token);
    } catch (e) {
      debugPrint('Verify and cleanup error: $e');
      // Force reset the order ID
      _currentOrderId = null;
    }
  }

  Future<void> _forceCancelOrder(String token) async {
    if (_currentOrderId == null) return;

    try {
      // Try alternative cancellation with just the order ID
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/wallet/recharge/cancel'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'order_id': _currentOrderId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 404) {
        // Either cancelled or not found - both are acceptable states
        _currentOrderId = null;
      }
    } catch (e) {
      debugPrint('Force cancel error: $e');
      // Reset order ID anyway to allow new orders
      _currentOrderId = null;
    }
  }


  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "External wallet: ${response.walletName}",
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<pw.Font> _loadUnicodeFont() async {
    final fontPaths = [
      'assets/fonts/Arial.ttf',
      'assets/fonts/NotoSans-Regular.ttf',
      'assets/fonts/Roboto-Regular.ttf',
      'assets/fonts/OpenSans-Regular.ttf',
    ];

    for (final path in fontPaths) {
      try {
        final fontData = await rootBundle.load(path);
        return pw.Font.ttf(fontData);
      } catch (_) {}
    }

    return pw.Font.helvetica();
  }

  Future<pw.MemoryImage?> _loadLogoImage() async {
    try {
      final logoData = await rootBundle.load('assets/logo.png');
      final bytes = logoData.buffer.asUint8List();
      if (bytes.isEmpty) return null;
      return pw.MemoryImage(bytes);
    } catch (e) {
      debugPrint('Logo load failed: $e');
      return null;
    }
  }

  pw.Widget _buildCurrencyText(
      double amount, {
        required pw.Font font,
        double fontSize = 24,
        PdfColor? color,
        bool useBold = true,
      }) {
    return pw.Text(
      '₹${amount.toStringAsFixed(2)}',
      style: pw.TextStyle(
        font: font,
        fontSize: fontSize,
        fontWeight: useBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? PdfColors.black,
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value, pw.Font font) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: font,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }


  Future<File> _createReceiptPDFFile(WalletReceiptModel receipt) async {
    final pdf = pw.Document();
    final unicodeFont = await _loadUnicodeFont();
    final logoImage = await _loadLogoImage();

    // Fetch user data from AuthService as fallback
    String userName = receipt.user.name;
    String userEmail = receipt.user.email;
    String userPhone = receipt.user.phone;

    // If receipt data is empty, try to get from AuthService
    if (userName.isEmpty || userEmail.isEmpty || userPhone.isEmpty) {
      try {
        final token = await AuthService.getUserToken();
        if (token != null && token.isNotEmpty) {
          final name = await AuthService.getUserName() ?? '';
          final email = await AuthService.getUserEmail() ?? '';
          final phone = await AuthService.getUserPhone() ?? '';

          if (name.isNotEmpty) userName = name;
          if (email.isNotEmpty) userEmail = email;
          if (phone.isNotEmpty) userPhone = phone;
        }
      } catch (e) {
        debugPrint('Error fetching user data from AuthService: $e');
      }
    }

    // Define colors
    final PdfColor primaryGreen = PdfColor.fromInt(0xFF1F7A29);
    final PdfColor primaryDark = PdfColor.fromInt(0xFF1A1A1A);
    final PdfColor textGray = PdfColor.fromInt(0xFF6B7280);
    final PdfColor lightGray = PdfColor.fromInt(0xFFF8FAFC);
    final PdfColor borderGray = PdfColor.fromInt(0xFFE5E7EB);
    final PdfColor successGreen = PdfColor.fromInt(0xFF22C55E);

    // Helper function to create PdfColor with opacity
    PdfColor colorWithOpacity(PdfColor color, double opacity) {
      final int alpha = (opacity * 255).round();
      final int colorValue = color.toInt();
      final int r = (colorValue >> 16) & 0xFF;
      final int g = (colorValue >> 8) & 0xFF;
      final int b = colorValue & 0xFF;
      return PdfColor.fromInt((alpha << 24) | (r << 16) | (g << 8) | b);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topCenter,
                end: pw.Alignment.bottomCenter,
                colors: [
                  PdfColors.white,
                  PdfColors.white,
                  PdfColor.fromInt(0xFFF0FDF4),
                ],
              ),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header with Logo and Title
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (logoImage != null)
                            pw.Container(
                              width: 150,
                              height: 150,
                              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                            ),
                          pw.SizedBox(height: 8),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 24),

                  // Amount Card - Modern Design
                  pw.Container(
                    padding: const pw.EdgeInsets.all(24),
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        begin: pw.Alignment.topLeft,
                        end: pw.Alignment.bottomRight,
                        colors: [
                          primaryGreen,
                          PdfColor.fromInt(0xFF2D8F3A),
                        ],
                      ),
                      borderRadius: pw.BorderRadius.circular(16),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AMOUNT PAID',
                          style: pw.TextStyle(
                            font: unicodeFont,
                            fontSize: 10,
                            color: colorWithOpacity(PdfColors.white, 0.7),
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          '₹${receipt.amount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            font: unicodeFont,
                            fontSize: 40,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Successfully added to your wallet',
                          style: pw.TextStyle(
                            font: unicodeFont,
                            fontSize: 12,
                            color: colorWithOpacity(PdfColors.white, 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 24),

                  // Transaction Details - Two Column Layout
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(16),
                          decoration: pw.BoxDecoration(
                            color: lightGray,
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'TRANSACTION INFO',
                                style: pw.TextStyle(
                                  font: unicodeFont,
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textGray,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              pw.SizedBox(height: 16),
                              _buildModernInfoRow(
                                'Transaction ID',
                                '#${receipt.transactionId}',
                                unicodeFont,
                              ),
                              _buildDivider(),
                              _buildModernInfoRow(
                                'Date & Time',
                                _formatDate(receipt.date),
                                unicodeFont,
                              ),
                              _buildDivider(),
                              _buildModernInfoRow(
                                'Payment Method',
                                'Razorpay',
                                unicodeFont,
                              ),
                              _buildDivider(),
                              _buildModernInfoRow(
                                'Type',
                                receipt.type.toUpperCase(),
                                unicodeFont,
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      // Right Column
                      pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(16),
                          decoration: pw.BoxDecoration(
                            color: lightGray,
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'WALLET DETAILS',
                                style: pw.TextStyle(
                                  font: unicodeFont,
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textGray,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              pw.SizedBox(height: 16),
                              _buildModernInfoRow(
                                'Receipt Number',
                                receipt.receiptNumber,
                                unicodeFont,
                              ),
                              _buildDivider(),
                              _buildModernInfoRow(
                                'Balance Before',
                                '₹${receipt.balanceBefore.toStringAsFixed(2)}',
                                unicodeFont,
                              ),
                              _buildDivider(),
                              _buildModernInfoRow(
                                'Balance After',
                                '₹${receipt.balanceAfter.toStringAsFixed(2)}',
                                unicodeFont,
                              ),
                              _buildDivider(),
                              _buildModernInfoRow(
                                'Status',
                                receipt.status.toUpperCase(),
                                unicodeFont,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 20),

                  // Customer Section - Modern Design
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(
                        color: borderGray,
                        width: 1,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.SizedBox(width: 8),
                            pw.Text(
                              'CUSTOMER INFORMATION',
                              style: pw.TextStyle(
                                font: unicodeFont,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryDark,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 18),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 1,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildModernInfoRow(
                                    'Name',
                                    userName.isNotEmpty ? userName : 'Not available',
                                    unicodeFont,
                                  ),
                                ],
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildModernInfoRow(
                                    'Email',
                                    userEmail.isNotEmpty ? userEmail : 'Not available',
                                    unicodeFont,
                                  ),
                                ],
                              ),
                            ),
                            pw.Expanded(
                              flex: 1,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildModernInfoRow(
                                    'Phone',
                                    userPhone.isNotEmpty ? userPhone : 'Not available',
                                    unicodeFont,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 50),

                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Thank you for choosing EVTRON!',
                          style: pw.TextStyle(
                            font: unicodeFont,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryGreen,
                            letterSpacing: 0.5,
                          ),
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

    final directory = await getApplicationDocumentsDirectory();
    final fileName = "receipt_${receipt.receiptNumber}.pdf";
    final file = File("${directory.path}/$fileName");

    await file.writeAsBytes(await pdf.save());
    _generatedReceiptFile = file;
    return file;
  }

  pw.Widget _buildModernInfoRow(String label, String value, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: PdfColor.fromInt(0xFF9CA3AF),
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold, // Changed from w600 to bold
            color: PdfColor.fromInt(0xFF1F2937),
          ),
        ),
      ],
    );
  }

// Helper method for divider
  pw.Widget _buildDivider() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: PdfColor.fromInt(0xFFE5E7EB),
    );
  }

  Future<void> _generateReceiptPDF(WalletReceiptModel receipt) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final file = await _createReceiptPDFFile(receipt);
      await OpenFile.open(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Receipt downloaded: ${file.uri.pathSegments.last}",
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

  String _formatDate(String dateString) {
    try {
      // Parse the UTC datetime from the API response
      final dateTime = DateTime.parse(dateString);
<<<<<<< HEAD

=======
>>>>>>> a87d3c38a1a46d0b90ae00ee07752ae2d55e98d0
      // Convert UTC to IST (UTC+5:30)
      // Check if it's already in UTC
      if (!dateTime.isUtc) {
        // If not UTC, convert to UTC first (assuming it might be local)
        final utcDateTime = dateTime.toUtc();
        // Then add IST offset
        final istDateTime = utcDateTime.add(const Duration(hours: 5, minutes: 30));
        return _formatTo12Hour(istDateTime);
      } else {
        // If it's UTC, directly add IST offset
        final istDateTime = dateTime.add(const Duration(hours: 5, minutes: 30));
        return _formatTo12Hour(istDateTime);
      }
    } catch (e) {
      return dateString;
    }
  }

<<<<<<< HEAD
=======
// Helper method to format datetime in 12-hour format with AM/PM
>>>>>>> a87d3c38a1a46d0b90ae00ee07752ae2d55e98d0
  String _formatTo12Hour(DateTime dateTime) {
    // Format: DD/MM/YYYY hh:mm AM/PM
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
<<<<<<< HEAD

=======
>>>>>>> a87d3c38a1a46d0b90ae00ee07752ae2d55e98d0
    // Get hour in 12-hour format
    int hour = dateTime.hour;
    final String amPm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = dateTime.minute.toString().padLeft(2, '0');
<<<<<<< HEAD

=======
>>>>>>> a87d3c38a1a46d0b90ae00ee07752ae2d55e98d0
    return "$day/$month/$year $hourStr:$minuteStr $amPm";
  }

  Future<void> _handleReceiptDownload() async {
    if (_receiptData != null) {
      if (_generatedReceiptFile != null && await _generatedReceiptFile!.exists()) {
        await OpenFile.open(_generatedReceiptFile!.path);
        return;
      }

      await _generateReceiptPDF(_receiptData!);
      return;
    }

    if (_currentTransactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No transaction found",
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final token = await AuthService.getUserToken();
      if (token == null || token.isEmpty) {
        throw Exception("Token not found");
      }

      final success = await _walletController.fetchWalletReceipt(
        token: token,
        transactionId: _currentTransactionId!,
      );

      if (success && mounted && _walletController.receiptResponse != null) {
        _receiptData = _walletController.receiptResponse;
        final file = await _createReceiptPDFFile(_receiptData!);
        await OpenFile.open(file.path);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Receipt not found",
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
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

    try {
      final token = await AuthService.getUserToken();
      if (token == null || token.isEmpty) {
        throw Exception("Token not found");
      }

      await _cleanupPendingOrders(token);

      final orderResponse = await _walletController.createRazorpayOrder(
        token: token,
        amount: _selectedAmount,
        forceNew: true,
      );

      if (orderResponse == null) {
        throw Exception("Failed to create order. Please try again.");
      }

      if (!orderResponse.success) {
        final message = orderResponse.message ?? 'Failed to create order. Please try again.';
        throw Exception(message);
      }

      final orderData = orderResponse.data;
      final hasValidOrderData = orderData.orderId.isNotEmpty &&
          orderData.key.isNotEmpty &&
          orderData.amount > 0;

      if (!hasValidOrderData) {
        final message = orderResponse.message ??
            'Unable to open payment gateway because the order response was incomplete.';
        throw Exception(message);
      }

      // Store the current order ID for cancellation handling
      _currentOrderId = orderData.orderId;

      // If there was an existing order, show a message but proceed
      if (orderResponse.existingOrder) {
        final existingMessage = orderResponse.message ??
            'A previous pending order was cancelled. New payment initiated.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingMessage,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      var options = {
        'key': orderData.key,
        'amount': orderData.amount,
        'name': 'EVTRON',
        'description': 'Wallet Recharge',
        'order_id': orderData.orderId,
        'prefill': {
          'contact': await AuthService.getUserPhone() ?? '',
          'email': await AuthService.getUserEmail() ?? '',
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay.open(options);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: ${e.toString()}",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showExpiredOrderDialog(String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Payment Expired',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Appcolor.green),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Handle payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final token = await AuthService.getUserToken();
      if (token == null || token.isEmpty) {
        throw Exception("Token not found");
      }

      // Access the properties directly from the response object
      final orderId = response.orderId;
      final paymentId = response.paymentId;
      final signature = response.signature;

      // Verify payment with your backend - include signature
      final verifyResponse = await _walletController.verifyRazorpayPayment(
        token: token,
        orderId: orderId!,
        paymentId: paymentId!,
        signature: signature!,
      );

      if (verifyResponse != null) {
        final normalizedStatus = verifyResponse.status?.toLowerCase();
        final normalizedErrorKey = verifyResponse.errorKey?.toLowerCase();

        if (verifyResponse.success || normalizedStatus == 'success') {
          // Clear the current order ID on success
          _currentOrderId = null;

          // Get the wallet balance from the response
          double walletBalance = verifyResponse.walletBalance ?? 0.0;

          // Update the local wallet balance
          _walletBalance = walletBalance;

          // Update the parent widget's balance
          widget.onBalanceUpdated(walletBalance);

          // Get transaction ID from response
          _currentTransactionId = verifyResponse.transactionId != null
              ? int.tryParse(verifyResponse.transactionId!)
              : null;

          // If transaction ID is not in the response, show simple success
          if (_currentTransactionId == null) {
            final balance = await _walletController.getCurrentWalletBalance(token);
            widget.onAmountSelected(_selectedAmount);

            if (mounted) {
              _showSimpleSuccessBottomSheet(
                enteredAmount: _selectedAmount,
                walletBalance: verifyResponse.walletBalance ?? balance ?? 0.0,
              );
            }
            return;
          }

          // Fetch the receipt data using the transaction ID
          final success = await _walletController.fetchWalletReceipt(
            token: token,
            transactionId: _currentTransactionId!,
          );

          if (success && mounted && _walletController.receiptResponse != null) {
            _receiptData = _walletController.receiptResponse;

            try {
              await _createReceiptPDFFile(_receiptData!);
            } catch (e) {
              debugPrint('Receipt PDF preparation failed: $e');
            }

            // Get updated wallet balance
            final balance = await _walletController.getCurrentWalletBalance(token);

            widget.onAmountSelected(_selectedAmount);

            if (mounted) {
              // Show receipt in bottom sheet
              _showReceiptBottomSheet(
                receipt: _receiptData!,
                walletBalance: verifyResponse.walletBalance ?? balance ?? 0.0,
              );
            }
          } else {
            // If receipt fetch fails, show simple success
            final balance = await _walletController.getCurrentWalletBalance(token);
            if (mounted) {
              _showSimpleSuccessBottomSheet(
                enteredAmount: _selectedAmount,
                walletBalance: verifyResponse.walletBalance ?? balance ?? 0.0,
              );
            }
          }
        } else if (normalizedErrorKey == 'order_is_cancelled' ||
            normalizedErrorKey == 'order_not_found') {
          _currentOrderId = null;
          if (mounted) {
            await _showExpiredOrderDialog(
              verifyResponse.userFriendlyMessage,
            );
          }
          return;
        } else {
          final message = verifyResponse.userFriendlyMessage;
          throw Exception(message);
        }
      } else {
        throw Exception('Payment verification failed.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Payment verification failed: ${e.toString()}",
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Show Receipt Bottom Sheet
  void _showReceiptBottomSheet({
    required WalletReceiptModel receipt,
    required double walletBalance,
  }) {
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
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.black87),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Success Icon
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: Appcolor.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Appcolor.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 12),

              // Amount
              Text(
                "₹${receipt.amount.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Appcolor.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Payment Successful",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              // Receipt Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReceiptRow("Receipt Number", receipt.receiptNumber),
                    _buildReceiptRow("Transaction ID", "#${receipt.transactionId}"),
                    _buildReceiptRow("Type", receipt.type.toUpperCase()),
                    _buildReceiptRow("Status", receipt.status.toUpperCase()),
                    _buildReceiptRow("Date", _formatDate(receipt.date)),
                    const Divider(height: 16),
                    _buildReceiptRow("Balance Before", "₹${receipt.balanceBefore.toStringAsFixed(2)}"),
                    _buildReceiptRow("Balance After", "₹${receipt.balanceAfter.toStringAsFixed(2)}"),
                    const Divider(height: 16),
                    _buildReceiptRow("Name", receipt.user.name),
                    _buildReceiptRow("Email", receipt.user.email),
                    _buildReceiptRow("Phone", receipt.user.phone),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // New Wallet Balance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Appcolor.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Appcolor.green.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Appcolor.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: Appcolor.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "New Balance",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "₹${walletBalance.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Appcolor.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _handleReceiptDownload,
                      icon: _isDownloading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.download, color: Colors.white),
                      label: Text(
                        _isDownloading ? "Downloading..." : "Download Receipt",
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _dismissReceiptFlow() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Show Simple Success Bottom Sheet (fallback)
  void _showSimpleSuccessBottomSheet({
    required double enteredAmount,
    required double walletBalance,
  }) {
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
      builder: (BuildContext context) {
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
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Appcolor.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Appcolor.green,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              // Payment Amount
              Text(
                "₹${enteredAmount.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Appcolor.green,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Payment Successful",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              // Wallet Balance Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Appcolor.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Appcolor.green.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Appcolor.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: Appcolor.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "New Balance",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "₹${walletBalance.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Appcolor.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onBalanceUpdated(walletBalance);
                    _dismissReceiptFlow();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Appcolor.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Done",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(AmountSelectionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the widget is re-displayed, reset cancellation state
    if (oldWidget != widget) {
      _currentOrderId = null;
      _isCancelling = false;
      _isProcessing = false;
    }
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
          onPressed: () {
            // Handle back navigation - cancel any pending order
            if (_currentOrderId != null && !_isProcessing) {
              _handlePaymentCancellation();
            }
            Navigator.pop(context);
          },
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
                        const SizedBox(height: 12),
                        Text(
                          "Select Amount to Add",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${_selectedAmount.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Appcolor.black,
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
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
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

