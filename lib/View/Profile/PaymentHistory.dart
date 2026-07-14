import 'package:evtron/View/Profile/pdf_receipt_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../Theme/colors.dart';
import '../../Model/wallet_transaction_model.dart';

class PaymentHistory extends StatefulWidget {
  final List<WalletTransactionModel> transactions;
  final VoidCallback? onRefresh;

  const PaymentHistory({
    super.key,
    required this.transactions,
    this.onRefresh,
  });

  @override
  State<PaymentHistory> createState() => _PaymentHistoryState();
}

class _PaymentHistoryState extends State<PaymentHistory> {
  // Track loading states for each transaction by ID
  final Map<int, bool> _downloadLoadingStates = {};

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}";
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }

  String _generateReceiptNumber(WalletTransactionModel transaction) {
    // Use receiptNumber from the model if available
    if (transaction.receiptNumber != null && transaction.receiptNumber!.isNotEmpty) {
      return transaction.receiptNumber!;
    }

    // Return "N/A" if receipt number is not available
    return "N/A";
  }

  String _formatOptionalCurrency(double? amount) {
    return amount != null ? '₹${amount.toStringAsFixed(2)}' : 'N/A';
  }

  Future<void> _downloadAndViewPDF(BuildContext context, WalletTransactionModel transaction) async {
    // Set loading state for this transaction
    setState(() {
      _downloadLoadingStates[transaction.id] = true;
    });

    try {
      // Generate PDF
      final file = await PdfReceiptService.generateSingleReceipt(transaction);

      // Show Android native "Open with" dialog directly
      await _showOpenWithDialog(context, file, transaction);
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Clear loading state
      if (mounted) {
        setState(() {
          _downloadLoadingStates[transaction.id] = false;
        });
      }
    }
  }

  Future<void> _showOpenWithDialog(BuildContext context, File file, WalletTransactionModel transaction) async {
    try {
      // Try to open with default PDF viewer
      await PdfReceiptService.openPdf(file);
      // If it succeeds, we're done
    } catch (e) {
      // If it fails or throws an error, use share_plus as fallback
      debugPrint('Could not open PDF directly: $e');
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Payment Receipt - ${_generateReceiptNumber(transaction)}',
      );
    }
  }

  Future<void> _shareToWhatsAppWithLoading(WalletTransactionModel transaction) async {
    setState(() {
      _downloadLoadingStates[transaction.id] = true;
    });

    try {
      await _shareToWhatsApp(transaction);
    } finally {
      if (mounted) {
        setState(() {
          _downloadLoadingStates[transaction.id] = false;
        });
      }
    }
  }

  Future<void> _shareToWhatsApp(WalletTransactionModel transaction) async {
    final receiptNumber = _generateReceiptNumber(transaction);

    final balanceBefore = _formatOptionalCurrency(transaction.balanceBefore);
    final balanceAfter = _formatOptionalCurrency(transaction.balanceAfter);

    final message = '''
*Payment Receipt* 📝

🧾 Receipt Number: $receiptNumber
💰 Amount: ₹${transaction.amount.toStringAsFixed(2)}
📅 Date: ${_formatDate(transaction.createdAt)}
🕐 Time: ${_formatTime(transaction.createdAt)}
🆔 Transaction ID: #${transaction.id}
📝 Description: ${transaction.description}
💳 Type: ${transaction.type.toUpperCase()}
✅ Status: ${transaction.displayStatus}

Balance Before: $balanceBefore
Balance After: $balanceAfter

Thank you for choosing our service!
    ''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'whatsapp://send?text=$encodedMessage';

    try {
      await launchUrl(Uri.parse(whatsappUrl));
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share to WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
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
              "No Payment History Found",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: widget.transactions.length,
        itemBuilder: (context, index) {
          return _buildPaymentHistoryCard(widget.transactions[index], context);
        },
      ),
    );
  }

  Widget _buildPaymentHistoryCard(WalletTransactionModel transaction, BuildContext context) {
    final receiptNumber = _generateReceiptNumber(transaction);
    final isLoading = _downloadLoadingStates[transaction.id] ?? false;

    // Determine status color and display text
    final statusColor = transaction.getStatusColor();
    final statusText = transaction.displayStatus;
    final isCredit = transaction.isCredit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
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
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(transaction.createdAt),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              Text(
                "₹${transaction.amount.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(
                  color: isCredit ? Appcolor.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.receipt_long, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                "Receipt: ",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  receiptNumber,
                  style: GoogleFonts.poppins(
                    color: Appcolor.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.description, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                "Description: ",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  transaction.description,
                  style: GoogleFonts.poppins(
                    color: Appcolor.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.payment, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                "Status: ",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                statusText,
                style: GoogleFonts.poppins(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (transaction.sourceType != null && transaction.sourceType!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    transaction.sourceType!.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          // Only show balance if available
          if (transaction.balanceAfter != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.account_balance_wallet, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  "Balance: ${_formatOptionalCurrency(transaction.balanceAfter)}",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              // Download Button - Only show for successful transactions
              if (transaction.type != 'verification_failed' && transaction.type != 'processing')
                Expanded(
                  child: InkWell(
                    onTap: isLoading ? null : () => _downloadAndViewPDF(context, transaction),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isLoading
                            ? Colors.grey[200]
                            : Appcolor.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLoading
                              ? Colors.grey[300]!
                              : Appcolor.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLoading)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Appcolor.green,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.download,
                              color: Appcolor.green,
                              size: 16,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            isLoading ? 'Generating...' : 'Download',
                            style: GoogleFonts.poppins(
                              color: isLoading ? Colors.grey[600] : Appcolor.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Add space between buttons
              const SizedBox(width: 8), // Adjust this value as needed

              // Share Button
              Expanded(
                child: InkWell(
                  onTap: transaction.type == 'verification_failed'
                      ? null
                      : () => _shareToWhatsAppWithLoading(transaction),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: transaction.type == 'verification_failed'
                          ? Colors.grey[200]
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: transaction.type == 'verification_failed'
                            ? Colors.grey[300]!
                            : Colors.green.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.share,
                          color: transaction.type == 'verification_failed'
                              ? Colors.grey[400]
                              : Colors.green.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Share',
                          style: GoogleFonts.poppins(
                            color: transaction.type == 'verification_failed'
                                ? Colors.grey[400]
                                : Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}