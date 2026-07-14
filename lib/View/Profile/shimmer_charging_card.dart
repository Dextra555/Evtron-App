import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../Theme/colors.dart';

class ShimmerChargingCard extends StatelessWidget {
  const ShimmerChargingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with date and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
                Container(
                  width: 60,
                  height: 16,
                  color: Colors.grey[300],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Station name
            Container(
              width: 150,
              height: 16,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            // Vehicle name
            Container(
              width: 100,
              height: 12,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 10),
            // Bottom row with kWh and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 60,
                      height: 12,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
                Container(
                  width: 50,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[300],
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