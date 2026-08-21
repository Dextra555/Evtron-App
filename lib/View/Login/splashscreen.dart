import 'package:evtron/View/Login/splash.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:evtron/session_manager.dart';
import '../../Theme/colors.dart';
import '../Home/mapui.dart';
import 'login.dart';
import '../Home/homepage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _batteryFillAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 360.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _textSlideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _batteryFillAnimation = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();

    _checkLoginStatusAndNavigate();
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    final isLoggedIn = await SessionManager.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChargingIntroPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Appcolor.white,
              const Color(0xFFF5F7FA),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildParticleSystem(),

            _buildGradientOrbs(),

            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * pi / 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Appcolor.green.withOpacity(0.8),
                                      Appcolor.green.withOpacity(0.4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ScaleTransition(
                                  scale: _pulseAnimation,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                        radius: 0.7,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 140, // Reduced from 160
                                height: 140, // Reduced from 160
                                child: CircularProgressIndicator(
                                  value: _batteryFillAnimation.value,
                                  strokeWidth: 5, // Reduced from 6
                                  backgroundColor: Colors.grey.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Appcolor.green,
                                  ),
                                ),
                              ),
                              // Main EV Charger icon
                              Container(
                                width: 100, // Reduced from 120
                                height: 100, // Reduced from 120
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white,
                                      const Color(0xFFF0F4F8),
                                    ],
                                    radius: 0.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Appcolor.green.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.ev_station_rounded,
                                    size: 55, // Reduced from 65
                                    color: Appcolor.green,
                                  ),
                                ),
                              ),
                              // Animated charging particles
                              ...List.generate(4, (index) {
                                final angle = (2 * pi * index / 4) +
                                    (_rotationAnimation.value * pi / 180);
                                final radius = 85.0; // Reduced from 100
                                final x = cos(angle) * radius;
                                final y = sin(angle) * radius;

                                return Positioned(
                                  left: 80 + x, // Adjusted from 90
                                  top: 80 + y, // Adjusted from 90
                                  child: Container(
                                    width: 8, // Reduced from 10
                                    height: 8, // Reduced from 10
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Appcolor.green,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Appcolor.green,
                                          blurRadius: 10, // Reduced from 12
                                          spreadRadius: 2, // Reduced from 3
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.flash_on,
                                      size: 5, // Reduced from 6
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20), // Reduced from 50

                    // Animated text with slide effect
                    AnimatedBuilder(
                      animation: _textSlideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _textSlideAnimation.value),
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    Appcolor.green,
                                    const Color(0xFF2E7D32),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: const Text(
                                  'Evtron',
                                  style: TextStyle(
                                    fontSize: 42, // Reduced from 48
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2, // Reduced from 3
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8), // Reduced from 15
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, // Reduced from 20
                                  vertical: 5, // Reduced from 8
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Appcolor.green.withOpacity(0.15),
                                      Appcolor.green.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25), // Reduced from 30
                                  border: Border.all(
                                    color: Appcolor.green.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  '⚡ Your EV Journey Starts Here ⚡',
                                  style: TextStyle(
                                    fontSize: 11, // Reduced from 13
                                    color: Color(0xFF2C3E50),
                                    letterSpacing: 1, // Reduced from 1.5
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5), // Reduced from 10
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, // Reduced from 15
                                  vertical: 3, // Reduced from 5
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Find EV Stations Near You',
                                      style: TextStyle(
                                        fontSize: 10, // Reduced from 11
                                        color: Color(0xFF7F8C8D),
                                        letterSpacing: 0.5, // Reduced from 1
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 3), // Reduced from 5
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildInfoChip('🔋 Fast Charging'),
                                        const SizedBox(width: 5), // Reduced from 8
                                        _buildInfoChip('📍 2000+ Stations'),
                                        const SizedBox(width: 5), // Reduced from 8
                                        _buildInfoChip('💰 Smart Pricing'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 70), // Reduced from 60

                    // Animated loading dots
                    _buildLoadingDots(),

                    const SizedBox(height: 10), // Reduced from 20

                    // Additional EV Station text
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: 0.6 + _glowAnimation.value * 0.4,
                          child: const Text(
                            'Powered by Green Energy',
                            style: TextStyle(
                              fontSize: 9, // Reduced from 10
                              color: Color(0xFF95A5A6),
                              letterSpacing: 1, // Reduced from 1.5
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Text(
                        'Evtron v1.21',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF95A5A6),
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Appcolor.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Appcolor.green.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 8, // Reduced from 9
          color: Color(0xFF2C3E50),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildParticleSystem() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 3),
      builder: (context, value, child) {
        return CustomPaint(
          painter: ParticlePainter(progress: value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildGradientOrbs() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Top right orb (electric blue)
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 180, // Reduced from 200
                height: 180, // Reduced from 200
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.blue.withOpacity(0.2 * _glowAnimation.value), // Reduced from 0.25
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom left orb (green)
            Positioned(
              left: -70, // Reduced from -80
              bottom: -70, // Reduced from -80
              child: Container(
                width: 220, // Reduced from 250
                height: 220, // Reduced from 250
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Appcolor.green.withOpacity(0.15 * _glowAnimation.value), // Reduced from 0.2
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Center right orb (yellow/gold)
            Positioned(
              right: 10, // Reduced from 20
              bottom: 80, // Reduced from 100
              child: Container(
                width: 120, // Reduced from 150
                height: 120, // Reduced from 150
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.withOpacity(0.12 * _glowAnimation.value), // Reduced from 0.15
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Floating energy particles
            ...List.generate(6, (index) { // Reduced from 8
              final offsetX = 50.0 * sin(index * 1.2 + _animationController.value * 2.5);
              final offsetY = 60.0 * cos(index * 0.8 + _animationController.value * 1.8);

              return Positioned(
                left: (index * 35) + offsetX, // Adjusted from 40
                top: (index * 100) + offsetY, // Adjusted from 120
                child: Container(
                  width: 2.5, // Reduced from 3
                  height: 2.5, // Reduced from 3
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Appcolor.green.withOpacity(0.4), // Reduced from 0.5
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final scale = 0.5 +
                (sin((_animationController.value * 2 * pi) - delay) + 1) / 4;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4), // Reduced from 6
              width: 8, // Reduced from 10
              height: 8, // Reduced from 10
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Appcolor.green.withOpacity(0.3),
              ),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Appcolor.green,
                    boxShadow: [
                      BoxShadow(
                        color: Appcolor.green.withOpacity(0.4), // Reduced from 0.5
                        blurRadius: 4, // Reduced from 5
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double progress;

  ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint();

    for (int i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1.0 + random.nextDouble() * 1.5; // Reduced from 1.5 + random.nextDouble() * 2
      final opacity = (0.08 + progress * 0.2) * (0.5 + random.nextDouble() * 0.5); // Reduced from 0.1 + progress * 0.25

      paint.color = Appcolor.green.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw connecting lines between nearby particles (like charging network)
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.4; // Reduced from 0.5

    final particles = List.generate(30, (index) { // Reduced from 40
      return Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
    });

    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final distance = (particles[i] - particles[j]).distance;
        if (distance < 60) { // Reduced from 70
          final opacity = (1 - distance / 60) * 0.06 * progress; // Adjusted from 0.08
          paint.color = Appcolor.green.withOpacity(opacity);
          canvas.drawLine(particles[i], particles[j], paint);
        }
      }
    }

    // Draw some charging bolt symbols
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 10; i++) { // Reduced from 15
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = 0.03 + progress * 0.08; // Reduced from 0.05 + progress * 0.1
      paint.color = Colors.amber.withOpacity(opacity);

      final path = Path();
      path.moveTo(x, y - 4); // Adjusted from y - 5
      path.lineTo(x - 2.5, y + 1.5); // Adjusted from x - 3, y + 2
      path.lineTo(x - 0.8, y + 1.5); // Adjusted from x - 1, y + 2
      path.lineTo(x - 1.5, y + 6); // Adjusted from x - 2, y + 8
      path.lineTo(x + 2.5, y); // Adjusted from x + 3, y
      path.lineTo(x + 0.8, y); // Adjusted from x + 1, y
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
