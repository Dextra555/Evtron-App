// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:open_file/open_file.dart';
// import '../../Model/wallet_receipt_model.dart';
//
// class PdfWalletService {
//   static Future<pw.Font> _loadUnicodeFont() async {
//     final fontPaths = [
//       'assets/fonts/Arial.ttf',
//       'assets/fonts/NotoSans-Regular.ttf',
//       'assets/fonts/Roboto-Regular.ttf',
//       'assets/fonts/OpenSans-Regular.ttf',
//     ];
//
//     for (final path in fontPaths) {
//       try {
//         final fontData = await rootBundle.load(path);
//         return pw.Font.ttf(fontData);
//       } catch (_) {}
//     }
//
//     final systemFontPaths = [
//       'C:\\Windows\\Fonts\\arial.ttf',
//       'C:\\Windows\\Fonts\\segoeui.ttf',
//       'C:\\Windows\\Fonts\\segoeuib.ttf',
//       '/System/Library/Fonts/Arial.ttf',
//       '/Library/Fonts/Arial.ttf',
//       '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
//     ];
//
//     for (final path in systemFontPaths) {
//       try {
//         final fontFile = File(path);
//         if (await fontFile.exists()) {
//           final fontBytes = await fontFile.readAsBytes();
//           return pw.Font.ttf(ByteData.sublistView(fontBytes));
//         }
//       } catch (_) {}
//     }
//
//     return pw.Font.helvetica();
//   }
//
//   static Future<pw.MemoryImage?> _loadLogoImage() async {
//     try {
//       final logoData = await rootBundle.load('assets/logo.png');
//       return pw.MemoryImage(logoData.buffer.asUint8List());
//     } catch (_) {
//       return null;
//     }
//   }
//
//   static pw.Widget _buildCurrencyText(
//     double amount, {
//     required pw.Font font,
//     double fontSize = 24,
//     PdfColor? color,
//     bool useBold = true,
//   }) {
//     return pw.Text(
//       '₹${amount.toStringAsFixed(2)}',
//       style: pw.TextStyle(
//         font: font,
//         fontSize: fontSize,
//         fontWeight: useBold ? pw.FontWeight.bold : pw.FontWeight.normal,
//         color: color ?? PdfColors.black,
//       ),
//     );
//   }
//
//   static Future<File> generateReceiptPDF(WalletReceiptModel receipt) async {
//     final pdf = pw.Document();
//     final unicodeFont = await _loadUnicodeFont();
//     final logoImage = await _loadLogoImage();
//
//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(36),
//         build: (pw.Context context) {
//           return pw.Container(
//             padding: const pw.EdgeInsets.all(24),
//             decoration: pw.BoxDecoration(
//               color: PdfColors.white,
//               borderRadius: pw.BorderRadius.circular(18),
//               border: pw.Border.all(color: PdfColors.green100, width: 1),
//             ),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Row(
//                   crossAxisAlignment: pw.CrossAxisAlignment.center,
//                   children: [
//                     pw.Container(
//                       width: 64,
//                       height: 64,
//                       padding: const pw.EdgeInsets.all(8),
//                       decoration: pw.BoxDecoration(
//                         color: PdfColors.green50,
//                         borderRadius: pw.BorderRadius.circular(16),
//                       ),
//                       child: logoImage != null
//                           ? pw.Image(logoImage, fit: pw.BoxFit.contain)
//                           : pw.Text(
//                               'EV',
//                               textAlign: pw.TextAlign.center,
//                               style: pw.TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: pw.FontWeight.bold,
//                                 color: PdfColors.green700,
//                               ),
//                             ),
//                     ),
//                     pw.SizedBox(width: 14),
//                     pw.Expanded(
//                       child: pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           pw.Text(
//                             'EVTRON',
//                             style: pw.TextStyle(
//                               fontSize: 24,
//                               fontWeight: pw.FontWeight.bold,
//                               color: PdfColors.green700,
//                             ),
//                           ),
//                           pw.SizedBox(height: 4),
//                           pw.Text(
//                             'Payment Receipt',
//                             style: pw.TextStyle(
//                               fontSize: 12,
//                               color: PdfColors.grey700,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     pw.Container(
//                       padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                       decoration: pw.BoxDecoration(
//                         color: PdfColors.green700,
//                         borderRadius: pw.BorderRadius.circular(999),
//                       ),
//                       child: pw.Text(
//                         'PAID',
//                         style: pw.TextStyle(
//                           fontSize: 11,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 pw.SizedBox(height: 20),
//                 pw.Divider(color: PdfColors.grey300, thickness: 0.8),
//                 pw.SizedBox(height: 18),
//                 pw.Container(
//                   padding: const pw.EdgeInsets.all(16),
//                   decoration: pw.BoxDecoration(
//                     color: PdfColors.green50,
//                     borderRadius: pw.BorderRadius.circular(14),
//                     border: pw.Border.all(color: PdfColors.green100, width: 1),
//                   ),
//                   child: pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     children: [
//                       pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           pw.Text(
//                             'Amount Paid',
//                             style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
//                           ),
//                           pw.SizedBox(height: 6),
//                           _buildCurrencyText(
//                             receipt.amount,
//                             font: unicodeFont,
//                             fontSize: 26,
//                             color: PdfColors.green700,
//                           ),
//                         ],
//                       ),
//                       pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.end,
//                         children: [
//                           pw.Text(
//                             'Status',
//                             style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
//                           ),
//                           pw.SizedBox(height: 6),
//                           pw.Text(
//                             receipt.status.toUpperCase(),
//                             style: pw.TextStyle(
//                               fontSize: 12,
//                               fontWeight: pw.FontWeight.bold,
//                               color: receipt.status.toLowerCase() == 'success'
//                                   ? PdfColors.green700
//                                   : PdfColors.red700,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 pw.SizedBox(height: 18),
//                 pw.Row(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Expanded(
//                       child: pw.Container(
//                         padding: const pw.EdgeInsets.all(14),
//                         decoration: pw.BoxDecoration(
//                           color: PdfColors.white,
//                           borderRadius: pw.BorderRadius.circular(12),
//                           border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
//                         ),
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.start,
//                           children: [
//                             _buildInfoRow('Receipt Number', receipt.receiptNumber, unicodeFont),
//                             pw.SizedBox(height: 10),
//                             _buildInfoRow('Transaction ID', '#${receipt.transactionId}', unicodeFont),
//                             pw.SizedBox(height: 10),
//                             _buildInfoRow('Date & Time', _formatDate(receipt.date), unicodeFont),
//                           ],
//                         ),
//                       ),
//                     ),
//                     pw.SizedBox(width: 12),
//                     pw.Expanded(
//                       child: pw.Container(
//                         padding: const pw.EdgeInsets.all(14),
//                         decoration: pw.BoxDecoration(
//                           color: PdfColors.white,
//                           borderRadius: pw.BorderRadius.circular(12),
//                           border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
//                         ),
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.start,
//                           children: [
//                             _buildInfoRow('Payment Type', receipt.type.toUpperCase(), unicodeFont),
//                             pw.SizedBox(height: 10),
//                             _buildInfoRow('Reference', receipt.receiptNumber, unicodeFont),
//                             pw.SizedBox(height: 10),
//                             pw.Text(
//                               'Wallet Top-up',
//                               style: pw.TextStyle(
//                                 font: unicodeFont,
//                                 fontSize: 11,
//                                 color: PdfColors.grey700,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 pw.SizedBox(height: 18),
//                 pw.Container(
//                   padding: const pw.EdgeInsets.all(14),
//                   decoration: pw.BoxDecoration(
//                     color: PdfColors.grey50,
//                     borderRadius: pw.BorderRadius.circular(12),
//                     border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
//                   ),
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text(
//                         'Balance Details',
//                         style: pw.TextStyle(
//                           font: unicodeFont,
//                           fontSize: 12,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.grey800,
//                         ),
//                       ),
//                       pw.SizedBox(height: 10),
//                       pw.Row(
//                         children: [
//                           pw.Expanded(
//                             child: pw.Column(
//                               crossAxisAlignment: pw.CrossAxisAlignment.start,
//                               children: [
//                                 pw.Text(
//                                   'Before',
//                                   style: pw.TextStyle(font: unicodeFont, fontSize: 10, color: PdfColors.grey700),
//                                 ),
//                                 pw.SizedBox(height: 4),
//                                 _buildCurrencyText(
//                                   receipt.balanceBefore,
//                                   font: unicodeFont,
//                                   fontSize: 15,
//                                   color: PdfColors.grey800,
//                                 ),
//                               ],
//                             ),
//                           ),
//                           pw.SizedBox(width: 12),
//                           pw.Expanded(
//                             child: pw.Column(
//                               crossAxisAlignment: pw.CrossAxisAlignment.start,
//                               children: [
//                                 pw.Text(
//                                   'After',
//                                   style: pw.TextStyle(font: unicodeFont, fontSize: 10, color: PdfColors.grey700),
//                                 ),
//                                 pw.SizedBox(height: 4),
//                                 _buildCurrencyText(
//                                   receipt.balanceAfter,
//                                   font: unicodeFont,
//                                   fontSize: 15,
//                                   color: PdfColors.green700,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 pw.SizedBox(height: 18),
//                 pw.Container(
//                   padding: const pw.EdgeInsets.all(14),
//                   decoration: pw.BoxDecoration(
//                     color: PdfColors.white,
//                     borderRadius: pw.BorderRadius.circular(12),
//                     border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
//                   ),
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text(
//                         'Customer Details',
//                         style: pw.TextStyle(
//                           font: unicodeFont,
//                           fontSize: 12,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.grey800,
//                         ),
//                       ),
//                       pw.SizedBox(height: 10),
//                       _buildInfoRow('Name', receipt.user.name, unicodeFont),
//                       pw.SizedBox(height: 8),
//                       _buildInfoRow('Email', receipt.user.email, unicodeFont),
//                       pw.SizedBox(height: 8),
//                       _buildInfoRow('Phone', receipt.user.phone, unicodeFont),
//                     ],
//                   ),
//                 ),
//                 pw.SizedBox(height: 24),
//                 pw.Center(
//                   child: pw.Column(
//                     children: [
//                       pw.Text(
//                         'Thank you for choosing EVTRON!',
//                         style: pw.TextStyle(
//                           font: unicodeFont,
//                           fontSize: 13,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.green700,
//                         ),
//                       ),
//                       pw.SizedBox(height: 6),
//                       pw.Text(
//                         'This is a computer-generated receipt. No signature required.',
//                         style: pw.TextStyle(
//                           font: unicodeFont,
//                           fontSize: 9,
//                           color: PdfColors.grey700,
//                         ),
//                       ),
//                       pw.SizedBox(height: 6),
//                       pw.Text(
//                         'For support, contact us at support@evtron.com',
//                         style: pw.TextStyle(
//                           font: unicodeFont,
//                           fontSize: 8,
//                           color: PdfColors.grey700,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//
//     final directory = await getApplicationDocumentsDirectory();
//     final fileName = "receipt_${receipt.receiptNumber}.pdf";
//     final file = File("${directory.path}/$fileName");
//
//     await file.writeAsBytes(await pdf.save());
//     return file;
//   }
//
//   static pw.Widget _buildInfoRow(String label, String value, pw.Font font) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           label,
//           style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
//         ),
//         pw.SizedBox(height: 2),
//         pw.Text(
//           value,
//           style: pw.TextStyle(font: font, fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
//         ),
//       ],
//     );
//   }
//
//   static String _formatDate(String dateString) {
//     try {
//       final dateTime = DateTime.parse(dateString);
//       return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
//     } catch (e) {
//       return dateString;
//     }
//   }
//
//   static Future<void> openPDF(File file) async {
//     await OpenFile.open(file.path);
//   }
// }