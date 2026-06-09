import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/colors.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      height: 65,
      decoration: BoxDecoration(
        color: Appcolor.green,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.qr_code_scanner_outlined,
            activeIcon: Icons.qr_code_scanner,
            index: 1,
            isScanButton: true,
          ),
          _buildNavItem(
            icon: Icons.credit_card_outlined,
            activeIcon: Icons.credit_card_rounded,
            index: 2,
          ),
          _buildNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    bool isScanButton = false,
  }) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (isScanButton) {
          onScanTap();
        } else {
          onTap(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : Colors.transparent,
          ),
          child: Center(
            child: Icon(
              isSelected ? activeIcon : icon,
              size: 26,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

