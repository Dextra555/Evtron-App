import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Theme/colors.dart';

class EnergyUsageTrendSection extends StatelessWidget {
  const EnergyUsageTrendSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Energy Usage Trend",
          style: GoogleFonts.poppins(
            fontSize: 16, // Reduced from 18
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 14), // Reduced from 16
        Container(
          padding: const EdgeInsets.all(16), // Reduced from 20
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18), // Reduced from 20
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Weekly Consumption",
                    style: GoogleFonts.poppins(
                      fontSize: 12, // Reduced from 14
                      color: Colors.grey[600],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Appcolor.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6), // Reduced from 8
                    ),
                    child: Text(
                      "+8% vs last week",
                      style: GoogleFonts.poppins(
                        fontSize: 10, // Reduced from 11
                        color: Appcolor.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18), // Reduced from 20
              SizedBox(
                height: 160, // Reduced from 180
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBarChart(40, "Mon"), // Reduced from 45
                    _buildBarChart(55, "Tue"), // Reduced from 62
                    _buildBarChart(70, "Wed"), // Reduced from 78
                    _buildBarChart(76, "Thu"), // Reduced from 85
                    _buildBarChart(63, "Fri"), // Reduced from 70
                    _buildBarChart(47, "Sat"), // Reduced from 52
                    _buildBarChart(43, "Sun"), // Reduced from 48
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(double height, String day) {
    return Column(
      children: [
        Container(
          height: height,
          width: 7, // Reduced from 8
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Appcolor.green,
                const Color(0xFF4CAF50),
              ],
            ),
            borderRadius: BorderRadius.circular(3.5), // Reduced from 4
          ),
        ),
        const SizedBox(height: 6), // Reduced from 8
        Text(
          day,
          style: GoogleFonts.poppins(
            fontSize: 9, // Reduced from 10
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}