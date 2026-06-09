
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Theme/colors.dart';

class PaymentHistory extends StatelessWidget {
  final List<Map<String, dynamic>> paymentData;

  const PaymentHistory({
    super.key,
    required this.paymentData,
  });

  Future<void> _shareToWhatsApp(Map<String, dynamic> payment) async {
    // Format the payment details for sharing
    final message = '''
*Payment Receipt* 📝

💰 Amount: ${payment['amount']}
📅 Date: ${payment['date']}
🆔 Payment ID: ${payment['paymentId']}
💳 Method: ${payment['method']}
🔌 Session ID: ${payment['sessionId']}
✅ Status: ${payment['status']}

Thank you for choosing our service!
    ''';

    // Encode the message for URL
    final encodedMessage = Uri.encodeComponent(message);

    // Create WhatsApp URL
    final whatsappUrl = 'whatsapp://send?text=$encodedMessage';

    try {
      await launchUrl(Uri.parse(whatsappUrl));
    } catch (e) {
      // Handle error - WhatsApp not installed
      debugPrint('Could not launch WhatsApp: $e');
    }
  }

  Future<void> _shareMultipleToWhatsApp(List<Map<String, dynamic>> payments) async {
    if (payments.isEmpty) return;

    StringBuffer buffer = StringBuffer();
    buffer.writeln('*Payment History Summary* 📊\n');
    buffer.writeln('Total Transactions: ${payments.length}\n');
    buffer.writeln('─' * 30);

    for (var payment in payments) {
      buffer.writeln('\n📌 *Payment ${payments.indexOf(payment) + 1}*');
      buffer.writeln('💰 Amount: ${payment['amount']}');
      buffer.writeln('📅 Date: ${payment['date']}');
      buffer.writeln('🆔 ID: ${payment['paymentId']}');
      buffer.writeln('💳 Method: ${payment['method']}');
      buffer.writeln('✅ Status: ${payment['status']}');
      buffer.writeln('─' * 20);
    }

    final message = buffer.toString();
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'whatsapp://send?text=$encodedMessage';

    try {
      await launchUrl(Uri.parse(whatsappUrl));
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
  }

  void _showShareOptions(BuildContext context, Map<String, dynamic> payment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Payment',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to share',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.share, color: Appcolor.green, size: 18),
              ),
              title: Text(
                'Share this payment',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                'Current transaction details',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareToWhatsApp(payment);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.history, color: Colors.blue[700], size: 18),
              ),
              title: Text(
                'Share all payments',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                'Complete payment history',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareMultipleToWhatsApp(paymentData);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: paymentData.length,
      itemBuilder: (context, index) {
        return _buildPaymentHistoryCard(paymentData[index], context);
      },
    );
  }

  Widget _buildPaymentHistoryCard(Map<String, dynamic> data, BuildContext context) {
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
                    data['date'],
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    data['amount'],
                    style: GoogleFonts.poppins(
                      color: Appcolor.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Share button
                  GestureDetector(
                    onTap: () => _showShareOptions(context, data),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Appcolor.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.share_outlined,
                        size: 16,
                        color: Appcolor.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          /// Payment ID
          Row(
            children: [
              Icon(Icons.receipt, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                "Payment ID: ",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  data['paymentId'],
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

          /// Payment Method
          Row(
            children: [
              Icon(Icons.payment, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                "Method: ",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                data['method'],
                style: GoogleFonts.poppins(
                  color: Appcolor.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// Session ID
          Row(
            children: [
              Icon(Icons.ev_station, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                "Session ID: ",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  data['sessionId'],
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

          const SizedBox(height: 10),

          /// Status
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Appcolor.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 12,
                    color: Appcolor.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data['status'],
                    style: GoogleFonts.poppins(
                      color: Appcolor.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
