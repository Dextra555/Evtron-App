// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/widgets.dart' as pw;
// import '../../Model/wallet_receipt_model.dart';
// import '../../Theme/colors.dart';
//
// class WalletSuccessPage extends StatefulWidget {
//   final WalletReceiptModel? receipt;
//   final double walletBalance;
//   final double enteredAmount;
//   final VoidCallback onDone;
//
//   const WalletSuccessPage({
//     super.key,
//     this.receipt,
//     required this.walletBalance,
//     required this.enteredAmount,
//     required this.onDone,
//   });
//
//   @override
//   State<WalletSuccessPage> createState() => _WalletSuccessPageState();
// }
//
// class _WalletSuccessPageState extends State<WalletSuccessPage> {
//   bool _isDownloading = false;
//   WalletReceiptModel? _receiptData;
//
//   @override
//   void initState() {
//     super.initState();
//     _receiptData = widget.receipt;
//   }
//
//   String _formatDate(String dateString) {
//     try {
//       final dateTime = DateTime.parse(dateString);
//       return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
//     } catch (e) {
//       return dateString;
//     }
//   }
//
//   Future<void> _generateReceiptPDF(WalletReceiptModel receipt) async {
//     setState(() {
//       _isDownloading = true;
//     });
//
//     try {
//       final pdf = pw.Document();
//
//       pdf.addPage(
//         pw.Page(
//           build: (pw.Context context) {
//             return pw.Padding(
//               padding: const pw.EdgeInsets.all(20),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Center(
//                     child: pw.Text(
//                       "PAYMENT RECEIPT",
//                       style: pw.TextStyle(
//                         fontSize: 22,
//                         fontWeight: pw.FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   pw.SizedBox(height: 25),
//                   pw.Text(
//                     "Receipt Details",
//                     style: pw.TextStyle(
//                       fontSize: 14,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                   ),
//                   pw.SizedBox(height: 8),
//                   pw.Text("Receipt Number: ${receipt.receiptNumber}",
//                       style: pw.TextStyle(fontSize: 12)),
//                   pw.Text("Transaction ID: #${receipt.transactionId}",
//                       style: pw.TextStyle(fontSize: 12)),
//                   pw.Text("Type: ${receipt.type.toUpperCase()}",
//                       style: pw.TextStyle(fontSize: 12)),
//                   pw.Text("Amount: ₹${receipt.amount.toStringAsFixed(2)}",
//                       style: pw.TextStyle(fontSize: 12)),
//                   pw.Text("Status: ${receipt.status.toUpperCase()}",
//                       style: pw.TextStyle(fontSize: 12)),
//                   pw.Text("Date: ${_formatDate(receipt.date)}",
//                       style: pw.TextStyle(fontSize: 12)),
//                   pw.Divider(),
//                   pw.SizedBox(height: 8),
//                   pw.Text(
//                     "Balance Details",
//                     style: pw.TextStyle(
//                       fontSize: 14,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                   ),
//                   pw.SizedBox(height: 8),
//                   pw.Text(
//                       "Balance Before: ₹${receipt.balanceBefore.toStringAsFixed(2)}",
//                       style: pw.TextStyle(fontSize: 12)),
//                   pw.Text(
//                       "Balance After: ₹${receipt.balanceAfter.toStringAsFixed(2)}",
//                       style: pw.TextStyle(fontSize: 12)),
//                   pw.Divider(),
//                   pw.SizedBox(height: 8),
//                   pw.Text(
//                     "User Details",
//                     style: pw.TextStyle(
//                       fontSize: 14,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                   ),
//                   pw.SizedBox(height: 8),
//                   pw.Text("Name: ${receipt.user.name}",
//                       style: pw.TextStyle(fontSize: 12)),
//                   pw.Text("Email: ${receipt.user.email}",
//                       style: pw.TextStyle(fontSize: 12)),
//                   pw.Text("Phone: ${receipt.user.phone}",
//                       style: pw.TextStyle(fontSize: 12)),
//                   pw.SizedBox(height: 25),
//                   pw.Center(
//                     child: pw.Column(
//                       children: [
//                         pw.Text(
//                           "Thank you for your payment!",
//                           style: pw.TextStyle(
//                             fontSize: 12,
//                             fontWeight: pw.FontWeight.bold,
//                           ),
//                         ),
//                         pw.SizedBox(height: 8),
//                         pw.Text(
//                           "This is a computer generated receipt",
//                           style: pw.TextStyle(fontSize: 9),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       );
//
//       final directory = await getApplicationDocumentsDirectory();
//       final fileName = "receipt_${receipt.receiptNumber}.pdf";
//       final file = File("${directory.path}/$fileName");
//
//       await file.writeAsBytes(await pdf.save());
//
//       await OpenFile.open(file.path);
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "Receipt downloaded: $fileName",
//               style: GoogleFonts.poppins(fontSize: 12),
//             ),
//             backgroundColor: Appcolor.green,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "Error downloading receipt: $e",
//               style: GoogleFonts.poppins(fontSize: 12),
//             ),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isDownloading = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _handleReceiptDownload() async {
//     if (_receiptData != null) {
//       await _generateReceiptPDF(_receiptData!);
//       return;
//     }
//
//     if (widget.receipt != null) {
//       await _generateReceiptPDF(widget.receipt!);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             "Receipt data not available",
//             style: GoogleFonts.poppins(fontSize: 12),
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final hasReceipt = _receiptData != null;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         title: Text(
//           "Payment Successful",
//           style: GoogleFonts.poppins(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(height: 20),
//
//               // Success Icon
//               Container(
//                 height: 100,
//                 width: 100,
//                 decoration: BoxDecoration(
//                   color: Appcolor.green.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.check_circle,
//                   color: Appcolor.green,
//                   size: 64,
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // Amount
//               Text(
//                 "₹${widget.enteredAmount.toStringAsFixed(2)}",
//                 style: GoogleFonts.poppins(
//                   fontSize: 36,
//                   fontWeight: FontWeight.bold,
//                   color: Appcolor.green,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "Payment Successful",
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 30),
//
//               // Receipt Details Card (only if receipt data is available)
//               if (hasReceipt) ...[
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[50],
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: Colors.grey[200]!),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Receipt Details",
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       _buildReceiptRow("Receipt Number", _receiptData!.receiptNumber),
//                       _buildReceiptRow("Transaction ID", "#${_receiptData!.transactionId}"),
//                       _buildReceiptRow("Type", _receiptData!.type.toUpperCase()),
//                       _buildReceiptRow("Status", _receiptData!.status.toUpperCase()),
//                       _buildReceiptRow("Date", _formatDate(_receiptData!.date)),
//                       const Divider(height: 20),
//                       _buildReceiptRow("Balance Before",
//                           "₹${_receiptData!.balanceBefore.toStringAsFixed(2)}"),
//                       _buildReceiptRow("Balance After",
//                           "₹${_receiptData!.balanceAfter.toStringAsFixed(2)}"),
//                       const Divider(height: 20),
//                       Text(
//                         "User Details",
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       _buildReceiptRow("Name", _receiptData!.user.name),
//                       _buildReceiptRow("Email", _receiptData!.user.email),
//                       _buildReceiptRow("Phone", _receiptData!.user.phone),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//
//               // New Wallet Balance
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Appcolor.green, Appcolor.green.withOpacity(0.8)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Icon(
//                             Icons.account_balance_wallet,
//                             color: Colors.white,
//                             size: 24,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Text(
//                           "New Balance",
//                           style: GoogleFonts.poppins(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.white.withOpacity(0.9),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       "₹${widget.walletBalance.toStringAsFixed(2)}",
//                       style: GoogleFonts.poppins(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 30),
//
//               // Action Buttons
//               if (hasReceipt) ...[
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: widget.onDone,
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           side: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         child: Text(
//                           "Done",
//                           style: GoogleFonts.poppins(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _isDownloading ? null : _handleReceiptDownload,
//                         icon: _isDownloading
//                             ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor:
//                             AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         )
//                             : const Icon(Icons.download, color: Colors.white),
//                         label: Text(
//                           _isDownloading ? "Downloading..." : "Download Receipt",
//                           style: GoogleFonts.poppins(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Appcolor.green,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ] else ...[
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: widget.onDone,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Appcolor.green,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: Text(
//                       "Done",
//                       style: GoogleFonts.poppins(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildReceiptRow(String label, String value) {
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
//               color: Colors.black87,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }