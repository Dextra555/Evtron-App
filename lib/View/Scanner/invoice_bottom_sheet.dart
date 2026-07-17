import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Controller/invoice_controller.dart';
import '../../Model/invoice_model.dart';
import '../../Service/invoice_pdf_service.dart';
import '../../Theme/colors.dart';

class InvoiceBottomSheet extends StatefulWidget {
  final InvoiceController invoiceController;
  final VoidCallback? onClosed;

  const InvoiceBottomSheet({
    Key? key,
    required this.invoiceController,
    this.onClosed,
  }) : super(key: key);

  @override
  State<InvoiceBottomSheet> createState() => _InvoiceBottomSheetState();
}

class _InvoiceBottomSheetState extends State<InvoiceBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final invoiceData = widget.invoiceController.invoiceResponse?.data;

    if (invoiceData != null) {
      print('InvoiceBottomSheet response:');
      print(invoiceData.toString());
      print('InvoiceBottomSheet raw response data: ${widget.invoiceController.invoiceResponse?.toString()}');
    }

    if (widget.invoiceController.isLoading) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
              ),
              SizedBox(height: 16),
              Text(
                'Loading invoice...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (invoiceData == null) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No invoice data available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.invoiceController.errorMessage ?? 'Please try again later',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onClosed?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolor.green,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          const SizedBox(height: 20),
          _buildHeader(context),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInvoiceHeader(invoiceData),
                  const SizedBox(height: 20),
                  _buildInfoSection('User Details', [
                    _buildInfoRow('Name', invoiceData.user.name),
                    _buildInfoRow('Email', invoiceData.user.email),
                    _buildInfoRow('Phone', invoiceData.user.phone),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Station Details', [
                    _buildInfoRow('Station', invoiceData.station.name),
                    _buildInfoRow('Address', invoiceData.station.address),
                    _buildInfoRow('GSTIN', invoiceData.station.gstin.isNotEmpty ? invoiceData.station.gstin : invoiceData.gst.gstin),
                    _buildInfoRow('Charger', invoiceData.charger),
                    _buildInfoRow('Connector', invoiceData.connector),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Session Details', [
                    _buildInfoRow('Session ID', '#${invoiceData.session.id}'),
                    _buildInfoRow(
                      'Transaction ID',
                      invoiceData.tid ?? invoiceData.payment.receiptNumber ?? 'N/A',
                    ),
                    _buildInfoRow(
                      'Start Time',
                      _formatDateTimeString(invoiceData.session.startTime),
                    ),
                    _buildInfoRow(
                      'End Time',
                      _formatDateTimeString(invoiceData.session.endTime),
                    ),
                    _buildInfoRow(
                      'Duration',
                      '${invoiceData.session.durationMinutes} minutes',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Energy Details', [
                    _buildInfoRow(
                      'Consumed',
                      '${invoiceData.energy.consumedKwh.toStringAsFixed(2)} kWh',
                    ),
                    _buildInfoRow(
                      'Rate',
                      '${invoiceData.billing.currency} ${invoiceData.energy.ratePerKwh.toStringAsFixed(2)}/kWh',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Payment Details', [
                    _buildInfoRow(
                      'Method',
                      invoiceData.payment.method.toUpperCase(),
                    ),
                    if (invoiceData.payment.receiptNumber != null)
                      _buildInfoRow(
                        'Receipt Number',
                        invoiceData.payment.receiptNumber!,
                      ),
                    _buildInfoRow(
                      'Wallet Debited',
                      '${invoiceData.billing.currency} ${invoiceData.payment.walletDebits.toStringAsFixed(2)}',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('GST Details', [
                    _buildInfoRow(
                      'CGST',
                      '${invoiceData.billing.currency} ${invoiceData.gst.cgstAmount.toStringAsFixed(2)}',
                    ),
                    _buildInfoRow(
                      'SGST',
                      '${invoiceData.billing.currency} ${invoiceData.gst.sgstAmount.toStringAsFixed(2)}',
                    ),
                    _buildInfoRow(
                      'Total GST',
                      '${invoiceData.billing.currency} ${invoiceData.gst.totalGst.toStringAsFixed(2)}',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildCostBreakdown(invoiceData),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Thank you for choosing EVTRON!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Appcolor.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildDownloadButton(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 40),
        Text(
          "Invoice Details",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Appcolor.black,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onClosed?.call();
          },
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildInvoiceHeader(InvoiceData invoiceData) {
    return Container(
      width: double.infinity, // Ensure it takes full width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Appcolor.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Left side - Invoice info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice #${invoiceData.invoiceNumber}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Appcolor.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${_formatDateOnly(invoiceData.invoiceDate)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity, // Ensure full width
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Appcolor.borderGrey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Appcolor.green,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Label with flexible width
          SizedBox(
            width: 100, // Fixed width for label
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Value with expanded space
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Appcolor.black,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdown(InvoiceData invoiceData) {
    return Container(
      width: double.infinity, // Ensure full width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Appcolor.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Appcolor.black,
            ),
          ),
          const SizedBox(height: 8),
          _buildCostRow(
            'Energy Cost',
            invoiceData.costBreakdown.energyCost,
            invoiceData.billing.currency,
          ),
          if (invoiceData.costBreakdown.idleCost > 0)
            _buildCostRow(
              'Idle Cost',
              invoiceData.costBreakdown.idleCost,
              invoiceData.billing.currency,
            ),
          if (invoiceData.costBreakdown.serviceFee > 0)
            _buildCostRow(
              'Service Fee',
              invoiceData.costBreakdown.serviceFee,
              invoiceData.billing.currency,
            ),
          if (invoiceData.costBreakdown.parkingFee > 0)
            _buildCostRow(
              'Parking Fee',
              invoiceData.costBreakdown.parkingFee,
              invoiceData.billing.currency,
            ),
          if (invoiceData.billing.tax > 0) ...[
            const Divider(),
            _buildCostRow(
              'GST (${invoiceData.billing.taxPercentage.toStringAsFixed(0)}%)',
              invoiceData.billing.tax,
              invoiceData.billing.currency,
            ),
          ],
          const Divider(),
          _buildCostRow(
            'Total',
            invoiceData.billing.total,
            invoiceData.billing.currency,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(
      String label,
      double amount,
      String currency, {
        bool isTotal = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Label with flexible width
          SizedBox(
            width: 120, // Fixed width for label
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isTotal ? 14 : 13,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: isTotal ? Appcolor.black : Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Value with expanded space
          Expanded(
            child: Text(
              '$currency ${amount.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: isTotal ? 16 : 13,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Appcolor.green : Appcolor.black,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: widget.invoiceController.isLoading
              ? null
              : _downloadInvoicePdf,
          style: ElevatedButton.styleFrom(
            backgroundColor: Appcolor.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          icon: widget.invoiceController.isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(Icons.download, color: Colors.white),
          label: Text(
            widget.invoiceController.isLoading
                ? 'Generating PDF...'
                : 'Download Invoice PDF',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Format date only (YYYY-MM-DD)
  String _formatDateOnly(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final localTime = dateTime.toLocal();

      // Format: YYYY-MM-DD
      return '${localTime.year}-'
          '${localTime.month.toString().padLeft(2, '0')}-'
          '${localTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      // If parsing fails, try to extract date from the string
      try {
        if (dateTimeStr.contains('T')) {
          final parts = dateTimeStr.split('T');
          return parts[0]; // Returns "2026-07-04"
        }
        return dateTimeStr;
      } catch (_) {
        return dateTimeStr;
      }
    }
  }

  // ✅ Format date and time (YYYY-MM-DD, HH:MM)
  String _formatDateTimeString(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final localTime = dateTime.toLocal();

      // Format: YYYY-MM-DD, HH:MM
      return '${localTime.year}-'
          '${localTime.month.toString().padLeft(2, '0')}-'
          '${localTime.day.toString().padLeft(2, '0')}, '
          '${localTime.hour.toString().padLeft(2, '0')}:'
          '${localTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      // If parsing fails, try to clean up the string manually
      try {
        if (dateTimeStr.contains('T')) {
          final parts = dateTimeStr.split('T');
          final datePart = parts[0];
          String timePart = '';
          if (parts.length > 1) {
            String timeWithZone = parts[1];
            if (timeWithZone.contains('.')) {
              timeWithZone = timeWithZone.substring(0, timeWithZone.indexOf('.'));
            }
            if (timeWithZone.contains('+')) {
              timeWithZone = timeWithZone.substring(0, timeWithZone.indexOf('+'));
            }
            if (timeWithZone.contains('-')) {
              timeWithZone = timeWithZone.substring(0, timeWithZone.indexOf('-'));
            }
            // Format time to HH:MM
            if (timeWithZone.length >= 5) {
              timePart = ', ${timeWithZone.substring(0, 5)}';
            }
          }
          return datePart + timePart;
        }
        return dateTimeStr;
      } catch (_) {
        return dateTimeStr;
      }
    }
  }

  Future<void> _downloadInvoicePdf() async {
    final invoiceData = widget.invoiceController.invoiceResponse?.data;
    if (invoiceData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No invoice data to download'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final filePath = await PdfService.generateInvoicePdf(invoiceData);
      if (mounted) {
        await PdfService.openPdf(filePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

