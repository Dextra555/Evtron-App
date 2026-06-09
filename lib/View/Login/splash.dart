import 'package:flutter/material.dart';

import '../../Theme/colors.dart';
import 'login.dart';

class ChargingIntroPage extends StatelessWidget {
  const ChargingIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🔹 Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/tear.png',
              fit: BoxFit.cover,
            ),
          ),

          /// 🔹 Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// 🔹 Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Spacer(),

                  /// 🔹 Title
                  const Text(
                    "Charge Anywhere.\nDrive Everywhere.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// 🔹 Description
                  Text(
                    "Charge your electric vehicle with confidence wherever life takes you. Our smart charging solutions support home, office, and public locations—keeping you powered, connected, and ready for every journey.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolor.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginScreen()));
                      },
                      child: const Text(
                        "Get Started",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // better contrast with green
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}