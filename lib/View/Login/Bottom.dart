import 'package:flutter/material.dart';
import '../../Theme/colors.dart';
import '../Profile/favourites.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onScanTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 85, // Reduced from 115 to 85
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Bottom Bar
          Positioned(
            bottom: 5,
            left: 10,
            right: 10,
            child: ClipPath(
              clipper: BottomNavCurveClipper(),
              child: Container(
                height: 60, // Reduced from 72 to 60
                decoration: BoxDecoration(
                  color: Appcolor.green,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      context: context,
                      icon: Icons.home_rounded,
                      activeIcon: Icons.home_rounded,
                      index: 0,
                    ),

                    _buildNavItem(
                      context: context,
                      icon: Icons.favorite,
                      activeIcon: Icons.favorite,
                      index: 1,
                      isFavoriteButton: true,
                    ),

                    const SizedBox(width: 60),

                    _buildNavItem(
                      context: context,
                      icon: Icons.wallet,
                      activeIcon: Icons.wallet,
                      index: 2,
                    ),

                    _buildNavItem(
                      context: context,
                      icon: Icons.person,
                      activeIcon: Icons.person,
                      index: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center QR Scanner Button
          Positioned(
            top: -15,
            child: GestureDetector(
              onTap: onScanTap,
              child: Container(
                width: 60, // Reduced from 70 to 60
                height: 60, // Reduced from 70 to 60
                decoration: BoxDecoration(
                  color: Appcolor.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 30, // Reduced from 34 to 30
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required int index,
    bool isFavoriteButton = false,
  }) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (isFavoriteButton) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const FavoriteStationsScreen(),
            ),
          );
        } else {
          onTap(index);
        }
      },
      child: SizedBox(
        width: 50, // Reduced from 60 to 50
        height: 50, // Reduced from 60 to 50
        child: Icon(
          isSelected ? activeIcon : icon,
          color: Colors.white,
          size: 24, // Reduced from 28 to 24
        ),
      ),
    );
  }
}

class BottomNavCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double notchWidth = 30; // Reduced from 35 to 30
    const double notchDepth = 30; // Reduced from 35 to 30
    const double cornerRadius = 16; // Reduced from 20 to 16

    Path path = Path();

    // Start from bottom-left rounded corner
    path.moveTo(0, cornerRadius);

    // Top left corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Left side before notch
    path.lineTo(size.width / 2 - notchWidth * 1.6, 0);

    // Left notch curve
    path.cubicTo(
      size.width / 2 - notchWidth,
      0,
      size.width / 2 - notchWidth,
      notchDepth,
      size.width / 2,
      notchDepth,
    );

    // Right notch curve
    path.cubicTo(
      size.width / 2 + notchWidth,
      notchDepth,
      size.width / 2 + notchWidth,
      0,
      size.width / 2 + notchWidth * 1.6,
      0,
    );

    // Top right corner
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(
      size.width,
      0,
      size.width,
      cornerRadius,
    );

    // Bottom right corner
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    );

    // Bottom left corner
    path.lineTo(cornerRadius, size.height);
    path.quadraticBezierTo(
      0,
      size.height,
      0,
      size.height - cornerRadius,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

