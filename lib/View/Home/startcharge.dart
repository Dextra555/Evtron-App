import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/colors.dart';

class ChargingScreen extends StatefulWidget {
  final Map<String, dynamic>? chargingDetails;

  const ChargingScreen({super.key, this.chargingDetails});

  @override
  State<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends State<ChargingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  // Charging data
  String stationId = '';
  String stationName = '';
  String chargerModel = '';
  String chargerType = '';
  String powerRating = '';

  // Dynamic charging values
  double currentProgress = 0.76; // 76%
  int currentSpeed = 135; // kW
  String duration = "24:15";
  String energy = "18.4";
  int cost = 340;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 360).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    // Load charging details if provided
    if (widget.chargingDetails != null) {
      stationId = widget.chargingDetails!['stationId'] ?? '';
      stationName = widget.chargingDetails!['stationName'] ?? '';
      chargerModel = widget.chargingDetails!['chargerModel'] ?? '';
      chargerType = widget.chargingDetails!['chargerType'] ?? '';
      powerRating = widget.chargingDetails!['powerRating'] ?? '';

      // Set speed based on power rating
      if (powerRating.isNotEmpty) {
        int rating = int.tryParse(powerRating) ?? 0;
        if (rating > 0) {
          currentSpeed = rating;
        }
      }
    }

    _startChargingSimulation();
  }

  void _startChargingSimulation() {
    Future.delayed(const Duration(seconds: 2), _updateChargingProgress);
  }

  void _updateChargingProgress() {
    if (mounted && currentProgress < 1.0) {
      setState(() {
        // Increase progress by 1-3%
        double increment = (Random().nextInt(3) + 1) / 100;
        currentProgress = (currentProgress + increment).clamp(0.0, 1.0);

        // Update percentage display
        int percentage = (currentProgress * 100).toInt();

        // Update energy and cost based on progress
        energy = (double.parse(energy) + 0.5).toStringAsFixed(1);
        cost = (cost + 5);

        // Update duration
        List<String> timeParts = duration.split(':');
        int minutes = int.parse(timeParts[0]);
        int seconds = int.parse(timeParts[1]);
        seconds += 30;
        if (seconds >= 60) {
          minutes++;
          seconds = seconds % 60;
        }
        duration = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      });

      // Continue simulation until 100%
      if (currentProgress < 1.0) {
        Future.delayed(const Duration(seconds: 2), _updateChargingProgress);
      } else {
        // Show completion message
        _showChargingComplete();
      }
    }
  }

  void _showChargingComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Charging Complete! 🎉", style: TextStyle(fontSize: 13)),
        backgroundColor: Appcolor.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _stopCharging() {
    setState(() {
      _animationController.stop();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Charging stopped", style: TextStyle(fontSize: 13)),
        backgroundColor: Appcolor.green,
      ),
    );

    // Optionally go back after stopping
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentPercentage = (currentProgress * 100).toInt();

    return Scaffold(
      backgroundColor: Appcolor.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar with station info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Appcolor.lightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Appcolor.black,
                        size: 16,
                      ),
                    ),
                  ),
                  if (stationName.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            stationName,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Appcolor.black.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (chargerModel.isNotEmpty)
                            Text(
                              chargerModel,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Appcolor.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Main Charging Section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    /// Animated Charging Indicator
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Appcolor.green.withOpacity(0.15),
                                  Appcolor.green.withOpacity(0.05),
                                ],
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                /// Outer rotating ring
                                AnimatedBuilder(
                                  animation: _rotationAnimation,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _rotationAnimation.value *
                                          3.14159 /
                                          180,
                                      child: CustomPaint(
                                        size: const Size(230, 230),
                                        painter: DashPainter(),
                                      ),
                                    );
                                  },
                                ),

                                /// Main Progress Circle
                                SizedBox(
                                  width: 210,
                                  height: 210,
                                  child: CircularProgressIndicator(
                                    value: currentProgress,
                                    strokeWidth: 7,
                                    backgroundColor: Appcolor.black.withOpacity(0.08),
                                    valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                      Appcolor.green,
                                    ),
                                  ),
                                ),

                                /// Inner Content with Percentage Symbol
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: currentPercentage.toString(),
                                            style: GoogleFonts.poppins(
                                              color: Appcolor.black,
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                          ),
                                          TextSpan(
                                            text: "%",
                                            style: GoogleFonts.poppins(
                                              color: Appcolor.green,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Appcolor.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                            color: Appcolor.green.withOpacity(0.2)),
                                      ),
                                      child: Text(
                                        chargerType.isNotEmpty ? chargerType.toUpperCase() : "FAST CHARGING",
                                        style: GoogleFonts.poppins(
                                          color: Appcolor.green,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    /// Charging Speed Card
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Appcolor.lightGrey,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                            color: Appcolor.borderGrey, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Appcolor.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.flash_on,
                              color: Appcolor.green,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Current Speed",
                                style: GoogleFonts.poppins(
                                  color: Appcolor.black.withOpacity(0.54),
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                "$currentSpeed kW",
                                style: GoogleFonts.poppins(
                                  color: Appcolor.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Statistics Panel
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Appcolor.lightGrey,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: Appcolor.borderGrey, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    duration,
                    "Duration",
                    Icons.timer_outlined,
                  ),
                  Container(
                    width: 1,
                    height: 35,
                    color: Appcolor.borderGrey,
                  ),
                  _buildStatCard(
                    energy,
                    "Energy",
                    Icons.bolt_outlined,
                    suffix: " kWh",
                  ),
                  Container(
                    width: 1,
                    height: 35,
                    color: Appcolor.borderGrey,
                  ),
                  _buildStatCard(
                    cost.toString(),
                    "Cost",
                    Icons.currency_rupee,
                    suffix: "",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Stop Charging Button
            GestureDetector(
              onTap: _stopCharging,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Appcolor.green, Appcolor.green.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Appcolor.green.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.power_settings_new, color: Appcolor.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Stop Charging",
                        style: TextStyle(
                          color: Appcolor.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon,
      {String suffix = ""}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Appcolor.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Appcolor.borderGrey),
          ),
          child: Icon(icon, color: Appcolor.green, size: 18),
        ),
        const SizedBox(height: 10),
        Text(
          "$value$suffix",
          style: GoogleFonts.poppins(
            color: Appcolor.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Appcolor.black.withOpacity(0.54),
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for dashed rotating ring
class DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Appcolor.green.withOpacity(0.3)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 360; i += 15) {
      final radian = i * 3.14159 / 180;
      final startPoint = Offset(
        center.dx + radius * cos(radian),
        center.dy + radius * sin(radian),
      );
      final endPoint = Offset(
        center.dx + radius * cos(radian + 0.1),
        center.dy + radius * sin(radian + 0.1),
      );
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}