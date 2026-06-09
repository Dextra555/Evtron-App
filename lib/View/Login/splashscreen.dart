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
            // Animated particles with EV theme
            _buildParticleSystem(),

            // Animated gradient orbs (EV themed)
            _buildGradientOrbs(),

            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated EV Charger icon with rotation
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * pi / 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ring with battery level indicator
                              Container(
                                width: 180,
                                height: 180,
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
                              // Battery level ring
                              SizedBox(
                                width: 160,
                                height: 160,
                                child: CircularProgressIndicator(
                                  value: _batteryFillAnimation.value,
                                  strokeWidth: 6,
                                  backgroundColor: Colors.grey.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Appcolor.green,
                                  ),
                                ),
                              ),
                              // Main EV Charger icon
                              Container(
                                width: 120,
                                height: 120,
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
                                    size: 65,
                                    color: Appcolor.green,
                                  ),
                                ),
                              ),
                              // Animated charging particles
                              ...List.generate(4, (index) {
                                final angle = (2 * pi * index / 4) +
                                    (_rotationAnimation.value * pi / 180);
                                final radius = 100.0;
                                final x = cos(angle) * radius;
                                final y = sin(angle) * radius;

                                return Positioned(
                                  left: 90 + x,
                                  top: 90 + y,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Appcolor.green,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Appcolor.green,
                                          blurRadius: 12,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.flash_on,
                                      size: 6,
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

                    const SizedBox(height: 50),

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
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Appcolor.green.withOpacity(0.15),
                                      Appcolor.green.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Appcolor.green.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  '⚡ Your EV Journey Starts Here ⚡',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF2C3E50),
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 5,
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Find EV Stations Near You',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF7F8C8D),
                                        letterSpacing: 1,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildInfoChip('🔋 Fast Charging'),
                                        const SizedBox(width: 8),
                                        _buildInfoChip('📍 2000+ Stations'),
                                        const SizedBox(width: 8),
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

                    const SizedBox(height: 60),

                    // Animated loading dots
                    _buildLoadingDots(),

                    const SizedBox(height: 20),

                    // Additional EV Station text
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: 0.6 + _glowAnimation.value * 0.4,
                          child: const Text(
                            'Powered by Green Energy',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF95A5A6),
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Appcolor.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Appcolor.green.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
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
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.blue.withOpacity(0.25 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom left orb (green)
            Positioned(
              left: -80,
              bottom: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Appcolor.green.withOpacity(0.2 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Center right orb (yellow/gold)
            Positioned(
              right: 20,
              bottom: 100,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.withOpacity(0.15 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Floating energy particles
            ...List.generate(8, (index) {
              final offsetX = 60.0 * sin(index * 1.2 + _animationController.value * 2.5);
              final offsetY = 80.0 * cos(index * 0.8 + _animationController.value * 1.8);

              return Positioned(
                left: (index * 40) + offsetX,
                top: (index * 120) + offsetY,
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Appcolor.green.withOpacity(0.5),
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
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 10,
              height: 10,
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
                        color: Appcolor.green.withOpacity(0.5),
                        blurRadius: 5,
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

    // Draw floating energy particles
    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1.5 + random.nextDouble() * 2;
      final opacity = (0.1 + progress * 0.25) * (0.5 + random.nextDouble() * 0.5);

      paint.color = Appcolor.green.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw connecting lines between nearby particles (like charging network)
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.5;

    final particles = List.generate(40, (index) {
      return Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
    });

    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final distance = (particles[i] - particles[j]).distance;
        if (distance < 70) {
          final opacity = (1 - distance / 70) * 0.08 * progress;
          paint.color = Appcolor.green.withOpacity(opacity);
          canvas.drawLine(particles[i], particles[j], paint);
        }
      }
    }

    // Draw some charging bolt symbols
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = 0.05 + progress * 0.1;
      paint.color = Colors.amber.withOpacity(opacity);

      final path = Path();
      path.moveTo(x, y - 5);
      path.lineTo(x - 3, y + 2);
      path.lineTo(x - 1, y + 2);
      path.lineTo(x - 2, y + 8);
      path.lineTo(x + 3, y);
      path.lineTo(x + 1, y);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}


