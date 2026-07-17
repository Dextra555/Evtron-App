import 'package:evtron/View/Profile/pdf_invoice_page.dart';
import 'package:evtron/View/Profile/shimmer_charging_card.dart';
import 'package:evtron/View/Profile/shimmer_payment_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../Theme/colors.dart';
import '../../Controller/charging_history_controller.dart';
import '../../Controller/invoice_controller.dart';
import '../../Controller/wallet_transaction_controller.dart';
import '../../Service/AuthService.dart';
import '../../Service/invoice_pdf_service.dart';
import '../../model/charging_history_model.dart';
import 'PaymentHistory.dart';
import 'chargehistory_bottomsheet.dart';

class ChargingHistoryScreen extends StatefulWidget {
  const ChargingHistoryScreen({super.key});

  @override
  State<ChargingHistoryScreen> createState() => _ChargingHistoryScreenState();
}

class _ChargingHistoryScreenState extends State<ChargingHistoryScreen> {
  bool _showChargingHistory = true;
  final ChargingHistoryController controller = ChargingHistoryController();
  final WalletTransactionController _transactionController = WalletTransactionController();

  @override
  void initState() {
    super.initState();
    _checkTokenAndLoadHistory();
  }

  Future<void> _checkTokenAndLoadHistory() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await AuthService.debugPrintAllData();

    final isLoggedIn = await AuthService.isLoggedIn();
    print('Is user logged in? $isLoggedIn');

    if (!isLoggedIn) {
      print('❌ User not logged in');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please login to view history"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final token = await AuthService.getUserToken();
    print('Token from AuthService: ${token != null ? "Token exists (${token.length} chars)" : "NULL"}');

    if (token == null || token.isEmpty) {
      print('❌ No valid token found');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication error. Please login again."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    print('Token preview: ${token.substring(0, token.length > 30 ? 30 : token.length)}...');

    await loadChargingHistory();
    await loadTransactions();
  }

  Future<void> loadChargingHistory() async {
    print("=== Starting loadChargingHistory ===");

    final token = await AuthService.getUserToken();

    if (token == null || token.isEmpty) {
      print("❌ No token found in loadChargingHistory");
      controller.setError("Authentication error. Please login again.");
      controller.setLoading(false);
      if (mounted) setState(() {});
      return;
    }

    print("Token found, length: ${token.length}");
    controller.setLoading(true);
    await controller.fetchChargingHistory(token);

    if (mounted) {
      setState(() {});
      if (controller.errorMessage != null && controller.chargingHistory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> loadTransactions() async {
    print("=== Starting loadTransactions ===");

    final token = await AuthService.getUserToken();

    if (token == null || token.isEmpty) {
      print("❌ No token found in loadTransactions");
      return;
    }

    _transactionController.setLoading(true);
    await _transactionController.fetchTransactions(
      token: token,
      limit: 20,
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _openInvoicePreview(int chargerHistoryId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Appcolor.green,
        ),
      ),
    );

    try {
      // Fetch invoice data using the controller
      final invoiceController = InvoiceController();
      final success = await invoiceController.fetchInvoice(chargerHistoryId);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success && invoiceController.invoiceResponse?.data != null) {
        final invoiceData = invoiceController.invoiceResponse!.data!;

        // Generate PDF directly from the fetched invoice data
        final String pdfPath = await PdfService.generateInvoicePdf(invoiceData);

        // Open the generated PDF file
        await PdfService.openPdf(pdfPath);

      } else {
        // Show error if invoice not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(invoiceController.errorMessage ?? 'Invoice not found for this session'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolor.white,
      appBar: AppBar(
        backgroundColor: Appcolor.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "History",
          style: GoogleFonts.poppins(
            color: Appcolor.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadChargingHistory();
          await loadTransactions();
        },
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleOption("Charging History", true),
                      const SizedBox(width: 22),
                      _buildToggleOption("Payment History", false),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _showChargingHistory
                    ? _buildChargingHistoryContent()
                    : _buildPaymentHistoryContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChargingHistoryContent() {
    if (controller.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: 5,
        itemBuilder: (context, index) {
          return const ShimmerChargingCard();
        },
      );
    }

    if (controller.chargingHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 50,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage != null
                  ? " ${controller.errorMessage}"
                  : "No Charging History Found",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: controller.errorMessage != null ? Colors.red : Colors.grey,
                fontSize: 16,
              ),
            ),
            if (controller.errorMessage != null)
              TextButton(
                onPressed: () => loadChargingHistory(),
                child: Text(
                  "Retry",
                  style: GoogleFonts.poppins(
                    color: Appcolor.green,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: controller.chargingHistory.length,
      itemBuilder: (context, index) {
        return _buildChargingHistoryCard(
          controller.chargingHistory[index],
        );
      },
    );
  }

  Widget _buildPaymentHistoryContent() {
    if (_transactionController.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: 5,
        itemBuilder: (context, index) {
          return const ShimmerPaymentCard();
        },
      );
    }

    if (_transactionController.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _transactionController.errorMessage ?? "No Payment History Found",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: _transactionController.errorMessage != null ? Colors.red : Colors.grey,
                fontSize: 16,
              ),
            ),
            if (_transactionController.errorMessage != null)
              TextButton(
                onPressed: () => loadTransactions(),
                child: Text(
                  "Retry",
                  style: GoogleFonts.poppins(
                    color: Appcolor.green,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return PaymentHistory(
      transactions: _transactionController.transactions,
      onRefresh: loadTransactions,
    );
  }

  Widget _buildToggleOption(String title, bool isCharging) {
    final isSelected = _showChargingHistory == isCharging;
    return GestureDetector(
      onTap: () {
        setState(() {
          _showChargingHistory = isCharging;
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: isSelected ? Appcolor.green : Colors.grey,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 3),
              height: 2,
              width: 28,
              color: Appcolor.green,
            ),
        ],
      ),
    );
  }

  Widget _buildChargingHistoryCard(ChargingHistoryModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 11, color: Colors.grey[500]),
                  const SizedBox(width: 3),
                  Text(
                    data.startTime.split('T').first,
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
              Text(
                "₹${data.amount.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(
                  color: Appcolor.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.ev_station, size: 13, color: Appcolor.green),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  data.stationName,
                  style: GoogleFonts.poppins(
                    color: Appcolor.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.directions_car, size: 12, color: Colors.grey),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  data.vehicleName,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 3),
                  Text(
                    "${data.units.toStringAsFixed(2)} kWh",
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  // Download Button
                  GestureDetector(
                    onTap: () => _openInvoicePreview(data.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Appcolor.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Appcolor.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.download,
                            size: 12,
                            color: Appcolor.green,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "Invoice",
                            style: GoogleFonts.poppins(
                              color: Appcolor.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: data.status.toLowerCase() == "completed"
                          ? Colors.green.withOpacity(0.1)
                          : data.status.toLowerCase() == "pending"
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      data.status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: data.status.toLowerCase() == "completed"
                            ? Colors.green
                            : data.status.toLowerCase() == "pending"
                            ? Colors.orange
                            : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}