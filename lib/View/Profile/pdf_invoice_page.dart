// // pdf_preview_page.dart
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
// import '../../../Theme/colors.dart';
// import '../../Model/invoice_model.dart';
// import '../../Service/invoice_pdf_service.dart';
//
// class PdfPreviewPage extends StatefulWidget {
//   final InvoiceData invoiceData;
//
//   const PdfPreviewPage({
//     Key? key,
//     required this.invoiceData,
//   }) : super(key: key);
//
//   @override
//   State<PdfPreviewPage> createState() => _PdfPreviewPageState();
// }
//
// class _PdfPreviewPageState extends State<PdfPreviewPage> {
//   bool _isGenerating = false;
//   String? _pdfPath;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Invoice Preview',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         backgroundColor: Appcolor.green,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download),
//             onPressed: _isGenerating ? null : _downloadAndOpenPdf,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // PDF Preview Area
//           Expanded(
//             child: Container(
//               color: Colors.grey[100],
//               child: Center(
//                 child: _buildPreviewContent(),
//               ),
//             ),
//           ),
//           // Download Button at Bottom
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: SafeArea(
//               child: SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: _isGenerating ? null : _downloadAndOpenPdf,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Appcolor.green,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   icon: _isGenerating
//                       ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   )
//                       : const Icon(Icons.download),
//                   label: Text(
//                     _isGenerating ? 'Generating PDF...' : 'Download Invoice',
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPreviewContent() {
//     if (_isGenerating) {
//       return Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(
//             color: Appcolor.green,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Generating your invoice...',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       );
//     }
//
//     if (_pdfPath != null) {
//       return Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.check_circle,
//             size: 64,
//             color: Appcolor.green,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Invoice Generated Successfully!',
//             style: GoogleFonts.poppins(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Appcolor.black,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Tap download to save and open',
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton.icon(
//             onPressed: _openPdf,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Appcolor.green,
//               foregroundColor: Colors.white,
//             ),
//             icon: const Icon(Icons.visibility),
//             label: const Text('Open PDF'),
//           ),
//         ],
//       );
//     }
//
//     // Initial state - show invoice summary
//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.picture_as_pdf,
//               size: 80,
//               color: Colors.red[400],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Invoice #${widget.invoiceData.invoiceNumber}',
//               style: GoogleFonts.poppins(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Appcolor.black,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               '${widget.invoiceData.billing.currency} ${widget.invoiceData.costBreakdown.total.toStringAsFixed(2)}',
//               style: GoogleFonts.poppins(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Appcolor.green,
//               ),
//             ),
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: _getStatusColor(widget.invoiceData.status).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 widget.invoiceData.status.toUpperCase(),
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: _getStatusColor(widget.invoiceData.status),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             const Divider(),
//             const SizedBox(height: 12),
//             _buildSummaryRow('Invoice Date', _formatDate(widget.invoiceData.invoiceDate)),
//             _buildSummaryRow('Station', widget.invoiceData.station.name),
//             _buildSummaryRow('Duration', _formatDuration(widget.invoiceData.session.durationMinutes)),
//             const SizedBox(height: 8),
//             Text(
//               'Tap Download to get your PDF invoice',
//               style: GoogleFonts.poppins(
//                 fontSize: 12,
//                 color: Colors.grey[500],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummaryRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: GoogleFonts.poppins(
//               fontSize: 13,
//               color: Colors.grey[600],
//             ),
//           ),
//           Text(
//             value,
//             style: GoogleFonts.poppins(
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//               color: Appcolor.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _downloadAndOpenPdf() async {
//     setState(() {
//       _isGenerating = true;
//     });
//
//     try {
//       final filePath = await PdfService.generateInvoicePdf(widget.invoiceData);
//
//       setState(() {
//         _pdfPath = filePath;
//         _isGenerating = false;
//       });
//
//       // Automatically open the PDF
//       await _openPdf();
//     } catch (e) {
//       setState(() {
//         _isGenerating = false;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to generate PDF: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   Future<void> _openPdf() async {
//     if (_pdfPath == null) return;
//
//     try {
//       await OpenFile.open(_pdfPath!);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to open PDF'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'completed':
//       case 'paid':
//         return Colors.green;
//       case 'pending':
//         return Colors.orange;
//       case 'failed':
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   String _formatDate(String dateTimeStr) {
//     try {
//       final dateTime = DateTime.parse(dateTimeStr);
//       return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
//     } catch (e) {
//       return dateTimeStr;
//     }
//   }
//
//   String _formatDuration(int minutes) {
//     if (minutes < 60) {
//       return '$minutes mins';
//     }
//     final hours = minutes ~/ 60;
//     final remainingMinutes = minutes % 60;
//     if (remainingMinutes == 0) {
//       return '$hours hr${hours > 1 ? 's' : ''}';
//     }
//     return '$hours hr ${remainingMinutes} mins';
//   }
// }
//
