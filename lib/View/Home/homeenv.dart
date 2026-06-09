import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/colors.dart';

class EnvironmentalImpactSection extends StatelessWidget {
  const EnvironmentalImpactSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Appcolor.green,
            const Color(0xFF1B5E20),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced from 8
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10), // Reduced from 12
                ),
                child: const Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 20, // Reduced from 24
                ),
              ),
              const SizedBox(width: 10), // Reduced from 12
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Environmental Impact",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14, // Reduced from 16
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "You've reduced emissions equivalent to planting 4 trees",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11, // Reduced from 12
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14), // Reduced from 16
          LinearProgressIndicator(
            value: 0.74,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(8), // Reduced from 10
          ),
          const SizedBox(height: 6), // Reduced from 8
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Monthly Goal: 320 kWh",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 11, // Reduced from 12
                ),
              ),
              Text(
                "74%",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11, // Reduced from 12
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}