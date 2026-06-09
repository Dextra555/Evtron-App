import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Theme/colors.dart';

class ChargingHistoryBottomSheet extends StatelessWidget {
  const ChargingHistoryBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              /// Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              /// Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Title
                        Text(
                          "Charging history",
                          style: GoogleFonts.poppins(
                            fontSize: 18, // Reduced from 20
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12), // Reduced from 16

                        /// Summary Card
                        _buildSummaryCard(),

                        const SizedBox(height: 16), // Reduced from 20

                        /// Month
                        Text(
                          "May 2024",
                          style: GoogleFonts.poppins(
                            fontSize: 12, // Reduced from 14
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 10), // Reduced from 12

                        const ChargingTile(
                          title: "OMV Aerogarii",
                          amount: "50 RON",
                          time: "May 26, 10:30 - 12:01",
                          energy: "50 kWh",
                        ),
                        const ChargingTile(
                          title: "Petrom Floreasca",
                          amount: "39 RON",
                          time: "May 18, 11:30 - 12:42",
                          energy: "41 kWh",
                        ),
                        const ChargingTile(
                          title: "Mol Baneasa",
                          amount: "128 RON",
                          time: "May 15, 09:21 - 13:11",
                          energy: "100 kWh",
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// SAME CARD DESIGN
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total charged",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // Reduced from 14
                ),
              ),
              Row(
                children: [
                  Text(
                    "May 2024",
                    style: GoogleFonts.poppins(
                      fontSize: 11, // Reduced from 12
                      color: Colors.grey,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 14), // Reduced from 16
                ],
              )
            ],
          ),

          const SizedBox(height: 8), // Reduced from 12

          Text(
            "389 kWh",
            style: GoogleFonts.poppins(
              fontSize: 24, // Reduced from 28
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4), // Reduced from 6

          Row(
            children: [
              Text(
                "5 charges",
                style: GoogleFonts.poppins(
                  fontSize: 11, // Reduced from 12
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8), // Reduced from 10
              Text(
                "↑ 29.26%",
                style: GoogleFonts.poppins(
                  fontSize: 11, // Reduced from 12
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8), // Reduced from 10

          _row("Money spent", "316 RON"),
          const SizedBox(height: 8), // Reduced from 10

          _row("CO2 saved", "40 kg"),
          const SizedBox(height: 8), // Reduced from 10

          _row("Money saved estimated", "39 RON"),
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 11, // Reduced from 13
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 11, // Reduced from 13
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class ChargingTile extends StatelessWidget {
  final String title;
  final String amount;
  final String time;
  final String energy;

  const ChargingTile({
    super.key,
    required this.title,
    required this.amount,
    required this.time,
    required this.energy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // Reduced from 12
      padding: const EdgeInsets.all(10), // Reduced from 12
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13, // Reduced from 14
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.poppins(
                  fontSize: 13, // Reduced from 14
                  fontWeight: FontWeight.bold,
                  color: Appcolor.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // Reduced from 8
          Row(
            children: [
              Icon(Icons.access_time, size: 11, color: Colors.grey[500]), // Reduced from 12
              const SizedBox(width: 3), // Reduced from 4
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 10, // Reduced from 11
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3), // Reduced from 4
          Row(
            children: [
              Icon(Icons.bolt, size: 11, color: Colors.grey[500]), // Reduced from 12
              const SizedBox(width: 3), // Reduced from 4
              Text(
                energy,
                style: GoogleFonts.poppins(
                  fontSize: 10, // Reduced from 11
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}