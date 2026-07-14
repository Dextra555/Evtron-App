import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart';
import '../../Model/wallet_transaction_model.dart';

class PdfReceiptService {
  static Future<pw.Font> _loadUnicodeFont() async {
    final List<String> fontPaths = [
      'assets/fonts/Arial.ttf',
      'assets/fonts/NotoSans-Regular.ttf',
      'assets/fonts/Roboto-Regular.ttf',
      'assets/fonts/OpenSans-Regular.ttf',
    ];

    for (String path in fontPaths) {
      try {
        final fontData = await rootBundle.load(path);
        debugPrint('✅ Font loaded successfully from: $path');
        return pw.Font.ttf(fontData);
      } catch (e) {
        debugPrint('⚠️ Font not found at: $path');
      }
    }

    final List<String> systemFontPaths = [
      'C:\\Windows\\Fonts\\arial.ttf',
      'C:\\Windows\\Fonts\\segoeui.ttf',
      'C:\\Windows\\Fonts\\segoeuib.ttf',
      '/System/Library/Fonts/Arial.ttf',
      '/Library/Fonts/Arial.ttf',
      '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    ];

    for (String path in systemFontPaths) {
      try {
        final fontFile = File(path);
        if (await fontFile.exists()) {
          final fontBytes = await fontFile.readAsBytes();
          return pw.Font.ttf(ByteData.sublistView(fontBytes));
        }
      } catch (e) {
        debugPrint('⚠️ System font not available at: $path');
      }
    }

    debugPrint('⚠️ No custom fonts found, using default');
    return pw.Font.helvetica();
  }

  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  static pw.Widget buildCurrencyWidget(
      double amount,
      pw.Font unicodeFont, {
        double fontSize = 28,
        PdfColor? color,
        bool useBold = true,
      }) {
    return pw.Text(
      formatCurrency(amount),
      style: pw.TextStyle(
        font: unicodeFont,
        fontSize: fontSize,
        fontWeight: useBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color ?? PdfColors.black,
      ),
    );
  }

  static Future<File> generateSingleReceipt(
      WalletTransactionModel transaction,
      ) async {
    final pdf = pw.Document();
    final logoImage = await _loadLogoImage();
    final unicodeFont = await _loadUnicodeFont();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return _buildReceiptContent(transaction, logoImage, unicodeFont);
        },
      ),
    );

    return await _savePdf('receipt_${transaction.id}', pdf);
  }

  static Future<File> generateMultipleReceipts(
      List<WalletTransactionModel> transactions,
      ) async {
    final pdf = pw.Document();
    final logoImage = await _loadLogoImage();
    final unicodeFont = await _loadUnicodeFont();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return _buildMultipleReceiptsContent(transactions, logoImage, unicodeFont);
        },
      ),
    );

    return await _savePdf('payment_history_summary', pdf);
  }

  // Open PDF directly
  static Future<void> openPdf(File file) async {
    try {
      if (await file.exists()) {
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              text: 'Here is your payment receipt',
            ),
          );
        }
      } else {
        throw Exception('PDF file does not exist');
      }
    } catch (e) {
      debugPrint('Error opening PDF: $e');
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Here is your payment receipt',
        ),
      );
    }
  }

  // Share PDF
  static Future<void> sharePdf(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Here is your payment receipt',
      ),
    );
  }

  // Print PDF
  static Future<void> printPdf(File file) async {
    final pdfData = await file.readAsBytes();
    await Printing.layoutPdf(
      onLayout: (_) => pdfData,
    );
  }

  static Future<Uint8List?> _loadLogoImage() async {
    try {
      final List<String> logoPaths = ['assets/logo.png'];
      Uint8List? logoData;

      for (String path in logoPaths) {
        try {
          final ByteData data = await rootBundle.load(path);
          logoData = data.buffer.asUint8List();
          debugPrint('Logo loaded successfully from: $path');
          break;
        } catch (e) {
          debugPrint('Logo not found at: $path');
        }
      }

      if (logoData == null) {
        debugPrint('No logo found in any path');
        return null;
      }

      if (!_isValidImage(logoData)) {
        debugPrint('Logo data is not a valid image format');
        return null;
      }

      return logoData;
    } catch (e) {
      debugPrint('Error loading logo: $e');
      return null;
    }
  }

  static bool _isValidImage(Uint8List data) {
    if (data.length >= 8 &&
        data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47 &&
        data[4] == 0x0D &&
        data[5] == 0x0A &&
        data[6] == 0x1A &&
        data[7] == 0x0A) {
      return true;
    }
    if (data.length >= 3 &&
        data[0] == 0xFF &&
        data[1] == 0xD8 &&
        data[2] == 0xFF) {
      return true;
    }
    return false;
  }

  static pw.Widget _buildReceiptContent(
      WalletTransactionModel transaction,
      Uint8List? logoImage,
      pw.Font unicodeFont,
      ) {
    final receiptNumber = transaction.receiptNumber ??
        'RCP-${DateTime.parse(transaction.createdAt).year}${DateTime.parse(transaction.createdAt).month.toString().padLeft(2, '0')}${DateTime.parse(transaction.createdAt).day.toString().padLeft(2, '0')}-${transaction.id.toString().padLeft(6, '0')}';

    return pw.Container(
      width: double.infinity,
      color: PdfColor.fromInt(0xFFF1F5F9),
      child: pw.Padding(
        padding: pw.EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: pw.Center(
          child: pw.Container(
            width: 520,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(28),
              boxShadow: [
                pw.BoxShadow(
                  color: PdfColor.fromInt(0x1A000000),
                  blurRadius: 18,
                  offset: PdfPoint(0, 8),
                ),
              ],
            ),
            padding: pw.EdgeInsets.all(28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      _buildModernLogo(logoImage),
                      pw.SizedBox(height: 16),
                      pw.Text(
                        'EVtron',
                        style: pw.TextStyle(
                          font: unicodeFont,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF2E7D32),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'PAYMENT RECEIPT',
                        style: pw.TextStyle(
                          font: unicodeFont,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF1F2937),
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        receiptNumber,
                        style: pw.TextStyle(
                          font: unicodeFont,
                          fontSize: 10,
                          color: PdfColor.fromInt(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 28),

                pw.Container(
                  padding: pw.EdgeInsets.all(22),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF3F9F2),
                    borderRadius: pw.BorderRadius.circular(18),
                    border: pw.Border.all(
                      color: PdfColor.fromInt(0xFFD1E7D3),
                      width: 1,
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'AMOUNT PAID',
                            style: pw.TextStyle(
                              font: unicodeFont,
                              fontSize: 10,
                              color: PdfColor.fromInt(0xFF4B5563),
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            formatCurrency(transaction.amount),
                            style: pw.TextStyle(
                              font: unicodeFont,
                              fontSize: 34,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromInt(0xFF166534),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
                pw.SizedBox(height: 28),

                pw.Container(
                  padding: pw.EdgeInsets.all(22),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(18),
                    border: pw.Border.all(
                      color: PdfColor.fromInt(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      _buildModernInfoRow('Receipt Number', receiptNumber, unicodeFont),
                      _buildDivider(),
                      _buildModernInfoRow('Transaction ID', '#${transaction.id}', unicodeFont),
                      _buildDivider(),
                      _buildModernInfoRow('Date & Time', '${_formatDate(transaction.createdAt)} ${_formatTime(transaction.createdAt)}', unicodeFont),
                      _buildDivider(),
                      _buildModernInfoRow('Payment Type', transaction.type.toUpperCase(), unicodeFont),
                      _buildDivider(),
                      _buildModernInfoRow('Description', transaction.description, unicodeFont),
                      _buildDivider(),
                      _buildModernInfoRow('Before Balance', transaction.balanceBefore != null ? formatCurrency(transaction.balanceBefore!) : 'N/A', unicodeFont),
                      _buildDivider(),
                      _buildModernInfoRow('After Balance', transaction.balanceAfter != null ? formatCurrency(transaction.balanceAfter!) : 'N/A', unicodeFont),
                    ],
                  ),
                ),
                pw.SizedBox(height: 28),

                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Thank you for choosing EVTRON!',
                        style: pw.TextStyle(
                          font: unicodeFont,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF166534),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'This is a system-generated receipt',
                        style: pw.TextStyle(
                          font: unicodeFont,
                          fontSize: 9,
                          color: PdfColor.fromInt(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildMultipleReceiptsContent(
      List<WalletTransactionModel> transactions,
      Uint8List? logoImage,
      pw.Font unicodeFont,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(logoImage, unicodeFont),
        pw.SizedBox(height: 25),

        // Title
        pw.Column(
          children: [
            pw.Text(
              'PAYMENT HISTORY SUMMARY',
              style: pw.TextStyle(
                font: unicodeFont,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1A237E),
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Total Transactions: ${transactions.length}',
              style: pw.TextStyle(
                font: unicodeFont,
                fontSize: 12,
                color: PdfColor.fromInt(0xFF78909C),
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              width: 80,
              height: 3,
              color: PdfColor.fromInt(0xFF1A237E),
            ),
          ],
        ),
        pw.SizedBox(height: 30),

        // Stats Cards
        _buildModernSummaryStats(transactions, unicodeFont),
        pw.SizedBox(height: 25),

        pw.Divider(thickness: 1.5, color: PdfColor.fromInt(0xFFE0E0E0)),
        pw.SizedBox(height: 20),

        // Transaction List
        pw.Expanded(
          child: pw.ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildModernTransactionItem(transaction, index + 1, unicodeFont);
            },
          ),
        ),

        pw.SizedBox(height: 20),
        pw.Divider(thickness: 1, color: PdfColor.fromInt(0xFFE0E0E0)),
        pw.SizedBox(height: 16),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Etron - Payment Summary',
                style: pw.TextStyle(
                  font: unicodeFont,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF1A237E),
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'This is a system-generated summary',
                style: pw.TextStyle(
                  font: unicodeFont,
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFFB0BEC5),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHeader(Uint8List? logoImage, pw.Font unicodeFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ETRON',
              style: pw.TextStyle(
                font: unicodeFont,
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1A237E),
                letterSpacing: 3,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Payment Receipt',
              style: pw.TextStyle(
                font: unicodeFont,
                fontSize: 12,
                color: PdfColor.fromInt(0xFF78909C),
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Generated: ${DateTime.now().toString().split(' ')[0]}',
              style: pw.TextStyle(
                font: unicodeFont,
                fontSize: 9,
                color: PdfColor.fromInt(0xFFB0BEC5),
              ),
            ),
          ],
        ),
        _buildModernLogo(logoImage),
      ],
    );
  }

  static pw.Widget _buildModernLogo(Uint8List? logoImage) {
    if (logoImage != null && logoImage.isNotEmpty) {
      try {
        return pw.Container(
          width: 100,
          height: 100,
          child: pw.Image(
            pw.MemoryImage(logoImage),
            width: 100,
            height: 100,
            fit: pw.BoxFit.contain,
          ),
        );
      } catch (e) {
        return _buildFallbackLogo();
      }
    } else {
      return _buildFallbackLogo();
    }
  }

  static pw.Widget _buildFallbackLogo() {
    return pw.Container(
      width: 100,
      height: 100,
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColor.fromInt(0xFF1A237E), PdfColor.fromInt(0xFF283593)],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Icon(
              pw.IconData(0xe8b0),
              color: PdfColors.white,
              size: 32,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'ETRON',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildModernInfoRow(String label, String value, pw.Font unicodeFont) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: unicodeFont,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF546E7A),
                letterSpacing: 0.5,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: unicodeFont,
                fontSize: 12,
                color: PdfColor.fromInt(0xFF263238),
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDivider() {
    return pw.Divider(
      thickness: 0.5,
      color: PdfColor.fromInt(0xFFEEEEEE),
    );
  }

  static pw.Widget _buildBalanceItem(String label, double? amount, PdfColor color, pw.Font unicodeFont) {
    final safeAmount = amount ?? 0.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: unicodeFont,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF78909C),
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          formatCurrency(safeAmount),
          style: pw.TextStyle(
            font: unicodeFont,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildModernSummaryStats(List<WalletTransactionModel> transactions, pw.Font unicodeFont) {
    final totalCredits = transactions
        .where((t) => t.type == 'credit')
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalDebits = transactions
        .where((t) => t.type == 'debit')
        .fold<double>(0, (sum, t) => sum + t.amount);

    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColor.fromInt(0xFFF5F5F5), PdfColor.fromInt(0xFFFAFAFA)],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          _buildModernStatItem('TOTAL CREDITS', formatCurrency(totalCredits), PdfColor.fromInt(0xFF2E7D32), unicodeFont),
          _buildModernStatItem('TOTAL DEBITS', formatCurrency(totalDebits), PdfColor.fromInt(0xFFC62828), unicodeFont),
          _buildModernStatItem('NET BALANCE', formatCurrency(totalCredits - totalDebits), PdfColor.fromInt(0xFF1A237E), unicodeFont),
        ],
      ),
    );
  }

  static pw.Widget _buildModernStatItem(String label, String value, PdfColor color, pw.Font unicodeFont) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: unicodeFont,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF78909C),
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: unicodeFont,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildModernTransactionItem(
      WalletTransactionModel transaction,
      int index,
      pw.Font unicodeFont,
      ) {
    final color = transaction.type == 'credit'
        ? PdfColor.fromInt(0xFF4CAF50)
        : PdfColor.fromInt(0xFFF44336);
    final bgColor = transaction.type == 'credit'
        ? PdfColor.fromInt(0xFFE8F5E9)
        : PdfColor.fromInt(0xFFFFEBEE);

    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: 4),
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: index % 2 == 0 ? PdfColor.fromInt(0xFFFAFAFA) : PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor.fromInt(0xFFEEEEEE),
          width: 0.5,
        ),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 32,
            height: 32,
            decoration: pw.BoxDecoration(
              color: bgColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Text(
                '${index}',
                style: pw.TextStyle(
                  font: unicodeFont,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  transaction.description,
                  style: pw.TextStyle(
                    font: unicodeFont,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF263238),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '${_formatDate(transaction.createdAt)} • ${_formatTime(transaction.createdAt)}',
                  style: pw.TextStyle(
                    font: unicodeFont,
                    fontSize: 8,
                    color: PdfColor.fromInt(0xFFB0BEC5),
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: bgColor,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              formatCurrency(transaction.amount),
              style: pw.TextStyle(
                font: unicodeFont,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return dateString;
    }
  }

  static String _formatTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $ampm';
    } catch (e) {
      return '';
    }
  }

  static Future<File> _savePdf(String fileName, pw.Document pdf) async {
    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/$fileName.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}



