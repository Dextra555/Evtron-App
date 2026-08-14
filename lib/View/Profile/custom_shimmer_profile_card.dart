import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CustomShimmerProfileCard extends StatelessWidget {
  final bool isDarkMode;

  const CustomShimmerProfileCard({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Shimmer(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE0E0E0),
            Color(0xFFF5F5F5),
            Color(0xFFE0E0E0),
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment(-0.5, 0.0),
          end: Alignment(1.0, 0.0),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name label - static
                      Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Shimmer for name
                      Container(
                        width: 150,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 120,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 180,
                        height: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: null,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: Colors.green.withOpacity(0.5),
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

