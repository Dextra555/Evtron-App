



import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Theme/colors.dart';
import 'PaymentHistory.dart';
import 'chargehistory.dart';

class ChargingHistoryScreen extends StatefulWidget {
  const ChargingHistoryScreen({super.key});

  @override
  State<ChargingHistoryScreen> createState() => _ChargingHistoryScreenState();
}

class _ChargingHistoryScreenState extends State<ChargingHistoryScreen> {
  bool _showChargingHistory = true;

  void _openBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const ChargingHistoryBottomSheet();
      },
    );
  }

  final List<Map<String, dynamic>> chargingData = [
    {
      'date': '12 Oct 2023',
      'amount': '₹342.25',
      'station': 'EVtron Central',
      'energy': '18.5 kWh',
      'status': 'Completed',
    },
    {
      'date': '10 Oct 2023',
      'amount': '₹287.50',
      'station': 'GreenCharge Hub',
      'energy': '15.2 kWh',
      'status': 'Completed',
    },
    {
      'date': '08 Oct 2023',
      'amount': '₹425.75',
      'station': 'PowerUp Station',
      'energy': '22.8 kWh',
      'status': 'Completed',
    },
    {
      'date': '05 Oct 2023',
      'amount': '₹189.30',
      'station': 'EcoCharge Point',
      'energy': '10.5 kWh',
      'status': 'Completed',
    },
    {
      'date': '03 Oct 2023',
      'amount': '₹512.00',
      'station': 'TurboCharge EV',
      'energy': '28.0 kWh',
      'status': 'Completed',
    },
  ];

  final List<Map<String, dynamic>> paymentData = [
    {
      'date': '12 Oct 2023',
      'amount': '₹342.25',
      'paymentId': 'PAY_123456789',
      'method': 'Google Pay',
      'status': 'Success',
      'sessionId': 'CHG_001',
    },
    {
      'date': '10 Oct 2023',
      'amount': '₹287.50',
      'paymentId': 'PAY_987654321',
      'method': 'PhonePe',
      'status': 'Success',
      'sessionId': 'CHG_002',
    },
    {
      'date': '08 Oct 2023',
      'amount': '₹425.75',
      'paymentId': 'PAY_456789123',
      'method': 'Credit Card',
      'status': 'Success',
      'sessionId': 'CHG_003',
    },
    {
      'date': '05 Oct 2023',
      'amount': '₹189.30',
      'paymentId': 'PAY_789123456',
      'method': 'Paytm',
      'status': 'Success',
      'sessionId': 'CHG_004',
    },
    {
      'date': '03 Oct 2023',
      'amount': '₹512.00',
      'paymentId': 'PAY_321654987',
      'method': 'Net Banking',
      'status': 'Success',
      'sessionId': 'CHG_005',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolor.white,
      appBar: AppBar(
        backgroundColor: Appcolor.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "History",
          style: GoogleFonts.poppins(
            color: Appcolor.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                padding: const EdgeInsets.all(14),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Total Sessions", "18"),
                    Container(
                      height: 35,
                      width: 1,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    _buildStatItem("Total Energy", "245 kWh"),
                    Container(
                      height: 35,
                      width: 1,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    _buildStatItem("Total Spent", "₹3,420"),
                  ],
                ),
              ),
            ),

            /// Toggle Options
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showChargingHistory = true;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            "Charging History",
                            style: GoogleFonts.poppins(
                              color: _showChargingHistory
                                  ? Appcolor.green
                                  : Colors.grey,
                              fontSize: 13,
                              fontWeight: _showChargingHistory
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (_showChargingHistory)
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              height: 2,
                              width: 28,
                              color: Appcolor.green,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 22),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showChargingHistory = false;
                        });
                      },
                      child: Column(
                        children: [
                          Text(
                            "Payment History",
                            style: GoogleFonts.poppins(
                              color: !_showChargingHistory
                                  ? Appcolor.green
                                  : Colors.grey,
                              fontSize: 13,
                              fontWeight: !_showChargingHistory
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (!_showChargingHistory)
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              height: 2,
                              width: 28,
                              color: Appcolor.green,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Dynamic List based on selection
            Expanded(
              child: _showChargingHistory
                  ? ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: chargingData.length,
                itemBuilder: (context, index) {
                  return _buildChargingHistoryCard(chargingData[index]);
                },
              )
                  : PaymentHistory(paymentData: paymentData), // Using the separate PaymentHistory class
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildChargingHistoryCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        _openBottomSheet(); // 👈 THIS LINE
      },
      child:
      Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 11, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text(
                      data['date'],
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Text(
                  data['amount'],
                  style: GoogleFonts.poppins(
                    color: Appcolor.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                )
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.ev_station, size: 13, color: Appcolor.green),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    data['station'],
                    style: GoogleFonts.poppins(
                      color: Appcolor.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
                    Icon(Icons.bolt, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text(
                      data['energy'],
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Appcolor.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data['status'],
                    style: GoogleFonts.poppins(
                      color: Appcolor.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

}
