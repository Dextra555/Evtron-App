import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              const SizedBox(height: 8),

              Row(
                children: [
                  _circleButton(
                    Icons.arrow_back_ios_new,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  Expanded(
                    child: Center(
                      child: Text("Notifications",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Changed to black
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _notificationCard(
                color: Colors.green,
                title: "Charging Completed!",
                subtitle: "Charging completed from Charging Completed!",
                time: "13m",
                icon: Icons.bolt,
              ),

              const SizedBox(height: 12),

              _notificationCard(
                color: Colors.red,
                title: "Charger Occupied",
                subtitle: "Alert: Description from Charger Occupied.",
                time: "15m",
                icon: Icons.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade100, // Changed to light grey
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: 16), // Changed to black
      ),
    );
  }

  Widget _notificationCard({
    required Color color,
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, // Changed to light grey background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200, // Changed to light grey border
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), // Changed to lighter opacity
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black87, // Changed to dark color
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600, // Changed to grey
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Text(
            time,
            style: TextStyle(
              color: Colors.grey.shade500, // Changed to grey
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}