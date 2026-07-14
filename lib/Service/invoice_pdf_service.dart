import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../Model/invoice_model.dart';

class PdfService {
  static String _formatDateOnly(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final localTime = dateTime.toLocal();

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

  static String _formatDateTimeString(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final localTime = dateTime.toLocal();

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

  static Future<String> generateInvoicePdf(InvoiceData invoiceData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green700,
                        ),
                      ),
                      pw.Text(
                        'EV Charging Session',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        invoiceData.invoiceNumber,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: ${_formatDateOnly(invoiceData.invoiceDate)}', // ✅ UPDATED
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'Status: ${invoiceData.status.toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: invoiceData.status == 'generated'
                              ? PdfColors.green700
                              : PdfColors.orange,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Divider
              pw.Container(
                height: 1,
                color: PdfColors.grey300,
              ),
              pw.SizedBox(height: 20),

              // User & Station Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Bill To:',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(invoiceData.user.name),
                        pw.Text(invoiceData.user.email),
                        pw.Text(invoiceData.user.phone),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Station:',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(invoiceData.station.name),
                        pw.Text(invoiceData.station.address),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Session Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Session ID: ${invoiceData.session.id}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Charger: ${invoiceData.charger}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.Text(
                            'Connector: ${invoiceData.connector}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Start: ${_formatDateTimeString(invoiceData.session.startTime)}', // ✅ UPDATED
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.Text(
                            'End: ${_formatDateTimeString(invoiceData.session.endTime)}', // ✅ UPDATED
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.Text(
                            'Duration: ${invoiceData.session.durationMinutes} minutes',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Energy Details
              pw.Text(
                'Energy Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildRow('Energy Consumed', '${invoiceData.energy.consumedKwh.toStringAsFixed(2)} kWh'),
                    _buildRow('Rate per kWh', '${invoiceData.billing.currency} ${invoiceData.energy.ratePerKwh.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Cost Breakdown
              pw.Text(
                'Cost Breakdown',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildRow('Energy Cost', '${invoiceData.billing.currency} ${invoiceData.costBreakdown.energyCost.toStringAsFixed(2)}'),
                    if (invoiceData.costBreakdown.idleCost > 0)
                      _buildRow('Idle Cost', '${invoiceData.billing.currency} ${invoiceData.costBreakdown.idleCost.toStringAsFixed(2)}'),
                    if (invoiceData.costBreakdown.serviceFee > 0)
                      _buildRow('Service Fee', '${invoiceData.billing.currency} ${invoiceData.costBreakdown.serviceFee.toStringAsFixed(2)}'),
                    if (invoiceData.costBreakdown.parkingFee > 0)
                      _buildRow('Parking Fee', '${invoiceData.billing.currency} ${invoiceData.costBreakdown.parkingFee.toStringAsFixed(2)}'),
                    pw.Divider(),
                    if (invoiceData.billing.tax > 0)
                      _buildRow('Tax (${invoiceData.billing.taxPercentage.toStringAsFixed(0)}%)', '${invoiceData.billing.currency} ${invoiceData.billing.tax.toStringAsFixed(2)}'),
                    _buildRow(
                      'Total',
                      '${invoiceData.billing.currency} ${invoiceData.billing.total.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Payment Details
              pw.Text(
                'Payment Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildRow('Payment Method', invoiceData.payment.method.toUpperCase()),
                    if (invoiceData.payment.receiptNumber != null)
                      _buildRow('Receipt Number', invoiceData.payment.receiptNumber!),
                    _buildRow('Wallet Debited', '${invoiceData.billing.currency} ${invoiceData.payment.walletDebits.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for choosing EVTRON!',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'This is a system generated invoice',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/invoice_${invoiceData.invoiceNumber}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  static pw.Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColors.green700 : null,
            ),
          ),
        ],
      ),
    );
  }


  static Future<void> openPdf(String filePath) async {
    await OpenFile.open(filePath);
  }
}

