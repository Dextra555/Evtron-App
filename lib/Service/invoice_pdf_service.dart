import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../Model/invoice_model.dart';

class PdfService {
  static pw.MemoryImage? _cachedLogo;

  static Future<pw.MemoryImage?> _loadLogoImage() async {
    if (_cachedLogo != null) return _cachedLogo!;

    final logoPaths = [
      'assets/logo.png',
      'assets/images/logo.png',
      'assets/logo/logo.png',
      'assets/icon/icon.png',
      'assets/logo.jpg',
    ];

    for (final path in logoPaths) {
      try {
        final logoData = await rootBundle.load(path);
        final bytes = logoData.buffer.asUint8List();
        if (bytes.isNotEmpty) {
          _cachedLogo = pw.MemoryImage(bytes);
          return _cachedLogo!;
        }
      } catch (_) {}
    }
    return null;
  }

  static String _formatDateOnly(String? value) {
    if (value == null || value.trim().isEmpty) return '-';

    try {
      // Check if the date is in DD-MM-YYYY format
      if (value.contains('-') && value.length >= 10) {
        // Check if it's DD-MM-YYYY (first part is day, not year)
        final parts = value.trim().split(' ');
        final datePart = parts[0];
        final dateComponents = datePart.split('-');

        if (dateComponents.length == 3) {
          // If first part is day (1-31), second is month (1-12), third is year (4 digits)
          final day = int.tryParse(dateComponents[0]);
          final month = int.tryParse(dateComponents[1]);
          final year = int.tryParse(dateComponents[2]);

          if (day != null && month != null && year != null && day >= 1 && day <= 31 && month >= 1 && month <= 12) {
            // This is DD-MM-YYYY format
            return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
          }
        }
      }

      // Try parsing as ISO format
      final dt = DateTime.parse(value).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (e) {
      // If parsing fails, try to extract date from DD-MM-YYYY format directly
      try {
        final trimmed = value.trim();
        if (trimmed.contains(' ')) {
          final datePart = trimmed.split(' ')[0];
          final dateComponents = datePart.split('-');
          if (dateComponents.length == 3) {
            final day = dateComponents[0].padLeft(2, '0');
            final month = dateComponents[1].padLeft(2, '0');
            final year = dateComponents[2];
            return '$day/$month/$year';
          }
        }
      } catch (_) {}
      return value;
    }
  }

  static String _formatFullDateTime(String dateTimeStr) {
    try {
      // Check if it's in DD-MM-YYYY format with time
      if (dateTimeStr.contains('-') && dateTimeStr.contains(' ')) {
        final parts = dateTimeStr.trim().split(' ');
        if (parts.length >= 2) {
          final datePart = parts[0];
          final timePart = parts[1];
          final dateComponents = datePart.split('-');

          if (dateComponents.length == 3) {
            final day = int.tryParse(dateComponents[0]);
            final month = int.tryParse(dateComponents[1]);
            final year = int.tryParse(dateComponents[2]);

            if (day != null && month != null && year != null &&
                day >= 1 && day <= 31 && month >= 1 && month <= 12) {
              // Parse time and convert to 12-hour format with AM/PM
              final timeComponents = timePart.split(':');
              if (timeComponents.length >= 2) {
                int hour = int.parse(timeComponents[0]);
                int minute = int.parse(timeComponents[1]);
                String ampm = hour >= 12 ? 'PM' : 'AM';

                // Convert to 12-hour format
                if (hour > 12) {
                  hour = hour - 12;
                } else if (hour == 0) {
                  hour = 12;
                }

                final timeFormatted = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
                return '${day.toString().padLeft(2, '0')}/'
                    '${month.toString().padLeft(2, '0')}/'
                    '$year $timeFormatted';
              }
            }
          }
        }
      }

      // Try ISO format
      final dateTime = DateTime.parse(dateTimeStr);
      final localTime = dateTime.toLocal();
      int hour = localTime.hour;
      int minute = localTime.minute;
      String ampm = hour >= 12 ? 'PM' : 'AM';

      if (hour > 12) {
        hour = hour - 12;
      } else if (hour == 0) {
        hour = 12;
      }

      return '${localTime.day.toString().padLeft(2, '0')}/'
          '${localTime.month.toString().padLeft(2, '0')}/'
          '${localTime.year} '
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
    } catch (e) {
      // Fallback: try to extract from DD-MM-YYYY format
      try {
        final trimmed = dateTimeStr.trim();
        if (trimmed.contains(' ')) {
          final parts = trimmed.split(' ');
          final datePart = parts[0];
          final timePart = parts.length > 1 ? parts[1] : '';
          final dateComponents = datePart.split('-');
          if (dateComponents.length == 3) {
            final day = dateComponents[0].padLeft(2, '0');
            final month = dateComponents[1].padLeft(2, '0');
            final year = dateComponents[2];

            // Try to format time
            if (timePart.isNotEmpty) {
              final timeComponents = timePart.split(':');
              if (timeComponents.length >= 2) {
                int hour = int.parse(timeComponents[0]);
                int minute = int.parse(timeComponents[1]);
                String ampm = hour >= 12 ? 'PM' : 'AM';

                if (hour > 12) {
                  hour = hour - 12;
                } else if (hour == 0) {
                  hour = 12;
                }

                return '$day/$month/$year ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
              }
            }
            return '$day/$month/$year $timePart';
          }
        }
      } catch (_) {}
      return dateTimeStr;
    }
  }

  static String _formatDateTimeString(String dateTimeStr) {
    try {
      // Check if it's in DD-MM-YYYY format with time
      if (dateTimeStr.contains('-') && dateTimeStr.contains(' ')) {
        final parts = dateTimeStr.trim().split(' ');
        if (parts.length >= 2) {
          final datePart = parts[0];
          final timePart = parts[1];
          final dateComponents = datePart.split('-');

          if (dateComponents.length == 3) {
            final day = int.tryParse(dateComponents[0]);
            final month = int.tryParse(dateComponents[1]);
            final year = int.tryParse(dateComponents[2]);

            if (day != null && month != null && year != null &&
                day >= 1 && day <= 31 && month >= 1 && month <= 12) {
              // Parse time and convert to 12-hour format with AM/PM
              final timeComponents = timePart.split(':');
              if (timeComponents.length >= 2) {
                int hour = int.parse(timeComponents[0]);
                int minute = int.parse(timeComponents[1]);
                String ampm = hour >= 12 ? 'PM' : 'AM';

                // Convert to 12-hour format
                if (hour > 12) {
                  hour = hour - 12;
                } else if (hour == 0) {
                  hour = 12;
                }

                return '${day.toString().padLeft(2, '0')}/'
                    '${month.toString().padLeft(2, '0')}/'
                    '$year, ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
              }
            }
          }
        }
      }

      // Try ISO format
      final dateTime = DateTime.parse(dateTimeStr);
      final localTime = dateTime.toLocal();
      int hour = localTime.hour;
      int minute = localTime.minute;
      String ampm = hour >= 12 ? 'PM' : 'AM';

      if (hour > 12) {
        hour = hour - 12;
      } else if (hour == 0) {
        hour = 12;
      }

      return '${localTime.day.toString().padLeft(2, '0')}/'
          '${localTime.month.toString().padLeft(2, '0')}/'
          '${localTime.year}, '
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
    } catch (e) {
      // Fallback
      return dateTimeStr;
    }
  }

  static Future<String> generateInvoicePdf(InvoiceData invoiceData) async {
    print('Invoice PDF payload:');
    print(invoiceData.toString());

    final pdf = pw.Document();
    final logoImage = await _loadLogoImage();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          // Get company name or use default static name
          final companyName = invoiceData.company?.name?.isNotEmpty == true
              ? invoiceData.company!.name!
              : 'ZEON ELECTRIC PRIVATE LIMITED';
          final companyAddress = invoiceData.company?.address?.isNotEmpty == true
              ? invoiceData.company!.address!
              : '';
          final companyCityLine = [
            invoiceData.company?.city,
            invoiceData.company?.state,
            invoiceData.company?.pincode,
          ].where((value) => value != null && value!.isNotEmpty).map((value) => value!).join(', ');
          final companyGstin = (invoiceData.station.gstin.isNotEmpty
              ? invoiceData.station.gstin
              : invoiceData.gst.gstin.isNotEmpty
              ? invoiceData.gst.gstin
              : 'NA');

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // FIRST ROW - Logo and TAX INVOICE with spacing
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left side - TAX INVOICE text with spacing
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 8), // Space after TAX INVOICE
                      // Invoice details in a separate row below
                      pw.Container(
                        width: 220,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        'INVOICE DATE : ${_formatDateOnly(invoiceData.invoiceDate)}',
                                        style: pw.TextStyle(
                                          fontSize: 10,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.SizedBox(height: 4),
                                      pw.Text(
                                        'INVOICE NUMBER : ${invoiceData.invoiceNumber}',
                                        style: pw.TextStyle(
                                          fontSize: 10,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.SizedBox(height: 4),
                                      pw.Text(
                                        'TRANSACTION ID : ${invoiceData.tid ?? invoiceData.payment.receiptNumber ?? 'N/A'}',
                                        style: pw.TextStyle(
                                          fontSize: 10,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Right side - Logo
                  if (logoImage != null)
                    pw.Container(
                      width: 120,
                      height: 80,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                ],
              ),

              pw.SizedBox(height: 18), // Space after first row

              // SECOND ROW - Company and Billed To information
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyName,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        if (companyAddress.isNotEmpty)
                          pw.Text(
                            companyAddress,
                            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                          ),
                        if (companyCityLine.isNotEmpty)
                          pw.Text(
                            companyCityLine,
                            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                          ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'GSTIN: $companyGstin',
                          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILLED TO',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoiceData.user.name,
                          style: pw.TextStyle(fontSize: 11),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'BUSINESS NAME: ${invoiceData.user.businessName ?? 'NA'}',
                          style: pw.TextStyle(fontSize: 11),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'ADDRESS: ${invoiceData.user.address ?? 'NA'}',
                          style: pw.TextStyle(fontSize: 11),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'GSTIN: ${invoiceData.user.gstin ?? 'NA'}',
                          style: pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                height: 1,
                color: PdfColors.grey300,
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'STATION',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoiceData.station.name,
                          style: pw.TextStyle(fontSize: 11),
                        ),
                        pw.Text(
                          invoiceData.station.address,
                          style: pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CHARGE POINT: ${invoiceData.charger}',
                          style: pw.TextStyle(fontSize: 11),
                        ),
                        pw.Text(
                          'CONNECTOR TYPE: ${invoiceData.connector}',
                          style: pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // RESTRUCTURED TABLE - WITHOUT DIVIDER LINES
              pw.Container(
                child: pw.Column(
                  children: [
                    // HEADER ROW
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      child: pw.Row(
                        children: [
                          _buildTableHeaderCellWithoutDivider('HSN CODE', flex: 2),
                          _buildTableHeaderCellWithoutDivider('ENERGY', flex: 2),
                          _buildTableHeaderCellWithoutDivider('TARIFF', flex: 2),
                          _buildTableHeaderCellWithoutDivider('CHARGED ON', flex: 3),
                          _buildTableHeaderCellWithoutDivider('DURATION & FEES', flex: 4),
                          _buildTableHeaderCellWithoutDivider(
                            'AMOUNT (${invoiceData.billing.currency})',
                            flex: 3,
                            alignment: pw.Alignment.centerRight,
                          ),
                        ],
                      ),
                    ),

                    // DATA VALUES ROW (First row with main values)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          _buildTableDataCellWithoutDivider(
                            invoiceData.gst.hsnSac.isNotEmpty ? invoiceData.gst.hsnSac : 'NA',
                            flex: 2,
                            alignment: pw.Alignment.center,
                          ),
                          _buildTableDataCellWithoutDivider(
                            '${invoiceData.energy.consumedKwh.toStringAsFixed(2)} kWh',
                            flex: 2,
                            alignment: pw.Alignment.center,
                          ),
                          _buildTableDataCellWithoutDivider(
                            '${invoiceData.energy.ratePerKwh.toStringAsFixed(1)} /kWh',
                            flex: 2,
                            alignment: pw.Alignment.center,
                          ),
                          _buildTableDataCellWithoutDivider(
                            _formatFullDateTime(invoiceData.session.startTime), // Shows: 13/07/2026 12:23 PM
                            flex: 3,
                            alignment: pw.Alignment.center,
                          ),
                          // MODIFIED: DURATION in HH:MM:SS format
                          _buildTableDataCellWithoutDivider(
                            '${_formatDurationHHMMSS(invoiceData.session.durationMinutes)} \n (hh:mm:ss)',
                            flex: 4,
                            alignment: pw.Alignment.center,
                          ),
                          _buildTableDataCellWithoutDivider(
                            '${invoiceData.costBreakdown.energyCost.toStringAsFixed(2)}',
                            flex: 3,
                            alignment: pw.Alignment.center,
                          ),
                        ],
                      ),
                    ),

                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Expanded(flex: 9, child: pw.Container()),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                'Session Fee:',
                                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '${invoiceData.costBreakdown.serviceFee.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // IDLE FEE ROW
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Expanded(flex: 9, child: pw.Container()),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                'Idle Fee:',
                                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '${invoiceData.costBreakdown.idleCost.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // CGST ROW
                    // CGST ROW (updated with dynamic rate)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Expanded(flex: 9, child: pw.Container()),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                'CGST (${invoiceData.gst.cgstRate.toStringAsFixed(0)}%):',
                                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '${invoiceData.gst.cgstAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Expanded(flex: 9, child: pw.Container()),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                'SGST (${invoiceData.gst.sgstRate.toStringAsFixed(0)}%):',
                                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '${invoiceData.gst.sgstAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 5),
                    // TOTAL ROW
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                      ),
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Expanded(flex: 9, child: pw.Container()),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                'TOTAL:',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '${invoiceData.billing.total.toStringAsFixed(2)}', // Shows as integer (no decimal places)
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Payment Method
              pw.Text(
                'PAYMENT METHOD : ${invoiceData.payment.method.toUpperCase()}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              // Amount in Words
              pw.Text(
                'AMOUNT IN WORDS : ${_numberToWords(invoiceData.billing.total)}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 50),
              // Removed footer text completely
              pw.Center(
                child: pw.Text(
                  'THIS IS A COMPUTER GENERATED INVOICE',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/invoice_${invoiceData.invoiceNumber}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  static String _formatDurationHHMMSS(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:00';
  }

  static String _formatTimeWithSeconds(String? value) {
    if (value == null || value.trim().isEmpty) return '-';

    try {
      final dt = DateTime.parse(value).toLocal();

      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return value;
    }
  }

  static pw.Widget _buildTableDataCellWithTwoLines(
      String line1,
      String line2, {
        int flex = 1,
        pw.Alignment alignment = pw.Alignment.center,
      }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Align(
          alignment: alignment,
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                line1,
                style: pw.TextStyle(
                  fontSize: 9,
                ),
              ),
              pw.Text(
                line2,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildTableHeaderCellWithoutDivider(
      String text, {
        int flex = 1,
        pw.Alignment alignment = pw.Alignment.center,
      }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Align(
          alignment: alignment,
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildTableDataCellWithoutDivider(
      String text, {
        int flex = 1,
        bool isBold = false,
        pw.Alignment alignment = pw.Alignment.centerLeft,
      }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Align(
          alignment: alignment,
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  static String _formatTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final localTime = dateTime.toLocal();
      final hour = localTime.hour;
      final minute = localTime.minute;
      final ampm = hour >= 12 ? 'pm' : 'am';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return '';
    }
  }

  static String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:00';
  }

  static String _numberToWords(double number) {
    if (number == 0) return 'Zero Rupees Only';

    final parts = number.toStringAsFixed(2).split('.');
    final whole = int.parse(parts[0]);
    final decimal = int.parse(parts[1]);

    final units = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
      'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen',
      'Eighteen', 'Nineteen'];
    final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    String convertHundreds(int num) {
      if (num == 0) return '';
      if (num < 20) return units[num];
      if (num < 100) {
        final ten = tens[num ~/ 10];
        final unit = num % 10;
        return unit == 0 ? ten : '$ten ${units[unit]}';
      }
      final hundred = units[num ~/ 100];
      final remainder = num % 100;
      return remainder == 0 ? '$hundred Hundred' : '$hundred Hundred and ${convertHundreds(remainder)}';
    }

    String convertThousands(int num) {
      if (num == 0) return '';

      // Handle lakhs (100,000) and crores (10,000,000) for Indian number system
      final crore = num ~/ 10000000;
      final lakh = (num % 10000000) ~/ 100000;
      final thousand = (num % 100000) ~/ 1000;
      final remainder = num % 1000;

      String result = '';

      if (crore > 0) {
        result += '${convertHundreds(crore)} Crore ';
      }
      if (lakh > 0) {
        result += '${convertHundreds(lakh)} Lakh ';
      }
      if (thousand > 0) {
        result += '${convertHundreds(thousand)} Thousand ';
      }
      if (remainder > 0) {
        result += convertHundreds(remainder);
      }

      return result.trim();
    }

    String result = '';
    if (whole >= 1000) {
      result = convertThousands(whole);
    } else {
      result = convertHundreds(whole);
    }

    // Handle decimal/paise
    String paiseWords = '';
    if (decimal > 0) {
      if (decimal < 20) {
        paiseWords = units[decimal];
      } else {
        final ten = tens[decimal ~/ 10];
        final unit = decimal % 10;
        paiseWords = unit == 0 ? ten : '$ten ${units[unit]}';
      }
    }

    String totalWords = '${result.trim()} Rupees';
    if (paiseWords.isNotEmpty) {
      totalWords += ' And ${paiseWords} Paise';
    }
    totalWords += ' Only';

    return totalWords;
  }
  static Future<void> openPdf(String filePath) async {
    await OpenFile.open(filePath);
  }
}

