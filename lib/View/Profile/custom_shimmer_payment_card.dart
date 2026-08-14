import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../Theme/colors.dart';

class CustomShimmerPaymentCard extends StatelessWidget {
  const CustomShimmerPaymentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Shimmer(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE0E0E0),
            Color(0xFFF5F5F5),
            Color(0xFFE0E0E0),
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment(-0.5, 0.0),
          end: Alignment(1.0, 0.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Static icon - no shimmer
                    Icon(Icons.calendar_today, size: 11, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    // Shimmer for date
                    Container(
                      width: 80,
                      height: 11,
                      color: Colors.white,
                    ),
                  ],
                ),
                // Shimmer for amount
                Container(
                  width: 70,
                  height: 13,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Static icon - no shimmer
                Icon(Icons.payment, size: 12, color: Appcolor.green),
                const SizedBox(width: 5),
                // Shimmer for payment method
                Expanded(
                  child: Container(
                    height: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Static icon - no shimmer
                    Icon(Icons.credit_card, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    // Shimmer for transaction ID
                    Container(
                      width: 100,
                      height: 11,
                      color: Colors.white,
                    ),
                  ],
                ),
                // Static Status badge - no shimmer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "SUCCESS",
                    style: GoogleFonts.poppins(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}