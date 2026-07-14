import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Theme/colors.dart';
import '../../Controller/invoice_controller.dart';
import '../../Model/invoice_model.dart';

class ChargingHistoryBottomSheet extends StatefulWidget {
  final int chargerHistoryId;

  const ChargingHistoryBottomSheet({
    Key? key,
    required this.chargerHistoryId,
  }) : super(key: key);

  @override
  State<ChargingHistoryBottomSheet> createState() => _ChargingHistoryBottomSheetState();
}

class _ChargingHistoryBottomSheetState extends State<ChargingHistoryBottomSheet> {
  final InvoiceController _invoiceController = InvoiceController();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInvoiceData();
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoiceData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final success = await _invoiceController.fetchInvoice(widget.chargerHistoryId);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!success) {
            _hasError = true;
            _errorMessage = _invoiceController.errorMessage ?? 'Failed to load invoice';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Appcolor.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invoice Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Appcolor.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Appcolor.green,
            ),
            SizedBox(height: 16),
            Text(
              'Loading invoice details...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.orange[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Invoice Not Available',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Appcolor.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage.isNotEmpty ? _errorMessage : 'The invoice for this session is not yet generated or available.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadInvoiceData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Appcolor.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final invoice = _invoiceController.invoiceResponse;
    if (invoice == null || !invoice.success || invoice.data == null) {
      return const Center(
        child: Text('No invoice data available'),
      );
    }

    return _buildInvoiceDetails(invoice.data!);
  }

  Widget _buildInvoiceDetails(InvoiceData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(data.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(data.status).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(data.status),
                  size: 14,
                  color: _getStatusColor(data.status),
                ),
                const SizedBox(width: 6),
                Text(
                  data.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(data.status),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Invoice Header
          _buildSectionHeader('Invoice Information'),
          const SizedBox(height: 8),
          _buildInfoRow('Invoice Number', data.invoiceNumber),
          _buildInfoRow('Invoice Date', _formatTime(data.invoiceDate)),

          const SizedBox(height: 16),

          // Station Details
          _buildSectionHeader('Station Details'),
          const SizedBox(height: 8),
          _buildInfoRow('Station', data.station.name),
          _buildInfoRow('Address', data.station.address),
          _buildInfoRow('Charger', data.charger),
          _buildInfoRow('Connector', data.connector),

          if (data.vehicle != null) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('Vehicle Details'),
            const SizedBox(height: 8),
            if (data.vehicle!.manufacturer != null && data.vehicle!.manufacturer!.isNotEmpty)
              _buildInfoRow('Manufacturer', data.vehicle!.manufacturer!),
            if (data.vehicle!.model != null && data.vehicle!.model!.isNotEmpty)
              _buildInfoRow('Model', data.vehicle!.model!),
            if (data.vehicle!.registrationNumber != null && data.vehicle!.registrationNumber!.isNotEmpty)
              _buildInfoRow('Registration', data.vehicle!.registrationNumber!),
          ],

          const SizedBox(height: 16),

          // Session Details
          _buildSectionHeader('Session Details'),
          const SizedBox(height: 8),
          _buildInfoRow('Session ID', data.session.id.toString()),
          _buildInfoRow('Start Time', _formatTime(data.session.startTime)),
          _buildInfoRow('End Time', _formatTime(data.session.endTime)),
          _buildInfoRow('Duration', _formatDuration(data.session.durationMinutes)),

          const SizedBox(height: 16),

          // Energy Details
          _buildSectionHeader('Energy Details'),
          const SizedBox(height: 8),
          _buildInfoRow('Energy Consumed', '${data.energy.consumedKwh.toStringAsFixed(2)} kWh'),
          _buildInfoRow('Rate per kWh', '${data.billing.currency} ${data.energy.ratePerKwh.toStringAsFixed(2)}'),

          const SizedBox(height: 16),

          // Cost Breakdown
          _buildSectionHeader('Cost Breakdown'),
          const SizedBox(height: 8),
          _buildInfoRow('Energy Cost', '${data.billing.currency} ${data.costBreakdown.energyCost.toStringAsFixed(2)}'),
          if (data.costBreakdown.idleCost > 0)
            _buildInfoRow('Idle Cost', '${data.billing.currency} ${data.costBreakdown.idleCost.toStringAsFixed(2)}'),
          if (data.costBreakdown.serviceFee > 0)
            _buildInfoRow('Service Fee', '${data.billing.currency} ${data.costBreakdown.serviceFee.toStringAsFixed(2)}'),
          if (data.costBreakdown.parkingFee > 0)
            _buildInfoRow('Parking Fee', '${data.billing.currency} ${data.costBreakdown.parkingFee.toStringAsFixed(2)}'),

          const Divider(height: 16, thickness: 1),

          _buildInfoRow('Subtotal', '${data.billing.currency} ${data.costBreakdown.subtotal.toStringAsFixed(2)}'),
          _buildInfoRow('Tax (${data.billing.taxPercentage.toStringAsFixed(0)}%)', '${data.billing.currency} ${data.costBreakdown.tax.toStringAsFixed(2)}'),

          // Total
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Appcolor.green.withOpacity(0.1),
                  Appcolor.green.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Appcolor.green.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Appcolor.black,
                  ),
                ),
                Text(
                  '${data.billing.currency} ${data.costBreakdown.total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Appcolor.green,
                  ),
                ),
              ],
            ),
          ),

          // Payment Method
          if (data.payment.method.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionHeader('Payment Method'),
            const SizedBox(height: 8),
            _buildInfoRow('Method', data.payment.method),
            if (data.payment.receiptNumber != null && data.payment.receiptNumber!.isNotEmpty)
              _buildInfoRow('Receipt', data.payment.receiptNumber!),
            _buildInfoRow('Wallet Debits', '${data.billing.currency} ${data.payment.walletDebits.toStringAsFixed(2)}'),
          ],

          // Close Button
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolor.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Appcolor.green,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Appcolor.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeString) {
    try {
      if (timeString.isEmpty) return 'N/A';
      final DateTime dateTime = DateTime.parse(timeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeString;
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes mins';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours hr${hours > 1 ? 's' : ''}';
    }
    return '$hours hr ${remainingMinutes} mins';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}

