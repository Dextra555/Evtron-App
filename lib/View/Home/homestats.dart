import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Theme/colors.dart';

class YourStatsSection extends StatelessWidget {
  const YourStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Your Stats",
              style: GoogleFonts.poppins(
                fontSize: 16, // Reduced from 18
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Reduced from 12,6
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(18), // Reduced from 20
              ),
              child: Text(
                "Last 30 days",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildStatsCard("Total Sessions", "18", "+2.3%", Appcolor.green)),
            const SizedBox(width: 10), // Reduced from 12
            Expanded(child: _buildStatsCard("Energy Used", "245 kWh", "+12%", Appcolor.green)),
          ],
        ),

      ],
    );
  }

  Widget _buildStatsCard(String title, String value, String change, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11, // Reduced from 12
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 3), // Reduced from 4
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18, // Reduced from 24
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 3), // Reduced from 4
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 13, // Reduced from 12
                color: color,
              ),
              const SizedBox(width: 2),
              Text(
                change,
                style: GoogleFonts.poppins(
                  fontSize: 9, // Reduced from 10
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}