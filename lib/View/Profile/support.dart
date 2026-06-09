import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black, size: 20),
        ),
        title: Text(
          "Help & Support",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          // Contact Support Section
          _buildSectionHeader("Contact Support", Icons.support_agent),
          const SizedBox(height: 8),

          // Phone Number Card
          _buildContactCard(
            icon: Icons.phone_in_talk,
            title: "Customer Support",
            subtitle: "Available 24/7",
            details: "+91 98765 43210",
            onTap: () => _makePhoneCall("+919876543210"),
          ),
          const SizedBox(height: 8),

          // Email Card
          _buildContactCard(
            icon: Icons.email_outlined,
            title: "Email Support",
            subtitle: "Response within 24h",
            details: "support@evtron.in",
            onTap: () => _sendEmail("support@evtron.in"),
          ),
          const SizedBox(height: 8),

          // Live Chat Card
          _buildContactCard(
            icon: Icons.chat_bubble_outline,
            title: "Live Chat",
            subtitle: "Mon-Fri, 9 AM - 6 PM",
            details: "Start conversation",
            onTap: () => _showComingSoon(context),
          ),

          const SizedBox(height: 20),

          // Legal Information Section
          _buildSectionHeader("Legal", Icons.gavel),
          const SizedBox(height: 8),

          // Terms & Conditions Card
          _buildLegalCard(
            icon: Icons.description_outlined,
            title: "Terms & Conditions",
            description: "Terms of service",
            onTap: () => _showLegalContent(context, "Terms & Conditions", _getTermsContent()),
          ),
          const SizedBox(height: 8),

          // Privacy Policy Card
          _buildLegalCard(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            description: "How we protect your data",
            onTap: () => _showLegalContent(context, "Privacy Policy", _getPrivacyContent()),
          ),
          const SizedBox(height: 8),

          // About Us Card
          _buildLegalCard(
            icon: Icons.info_outline,
            title: "About Us",
            description: "Learn about EVtron",
            onTap: () => _showLegalContent(context, "About Us", _getAboutContent()),
          ),

          const SizedBox(height: 20),

          // App Version
          Center(
            child: Text(
              "Version 1.0.0",
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDarkMode ? Colors.white : Colors.black),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String details,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isDarkMode ? Colors.white : Colors.black, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: isDarkMode ? Colors.white : Colors.black, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showErrorDialog("Cannot make call");
      }
    } catch (e) {
      _showErrorDialog("Error: $e");
    }
  }

  void _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support Request&body=Hello Support Team,%0A%0A',
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _showErrorDialog("Cannot open email");
      }
    } catch (e) {
      _showErrorDialog("Error: $e");
    }
  }

  void _showLegalContent(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 18, color: isDarkMode ? Colors.white : Colors.black),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    content,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.5,
                      color: isDarkMode ? Colors.grey[300] : Colors.black,
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Coming soon!",
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _getTermsContent() {
    return """
TERMS AND CONDITIONS

Last updated: December 2024

1. ACCEPTANCE OF TERMS
By using EVtron, you agree to these terms.

2. DESCRIPTION OF SERVICE
EVtron provides EV charging station locator, booking, and payment services.

3. USER REGISTRATION
You must register for an account with accurate information.

4. PAYMENT TERMS
All payments are processed securely through the app.

5. CANCELLATION AND REFUNDS
Cancellation policies vary by charging station partner.

6. USER CONDUCT
You agree not to misuse the app or engage in illegal activities.

7. PRIVACY
Your use is governed by our Privacy Policy.

8. LIMITATION OF LIABILITY
EVtron is not liable for indirect damages.

9. MODIFICATIONS
Terms may be updated. Continued use means acceptance.

10. CONTACT
Questions? Email legal@evtron.in
""";
  }

  String _getPrivacyContent() {
    return """
PRIVACY POLICY

Last updated: December 2024

1. INFORMATION WE COLLECT
- Name and contact information
- Payment information
- Location data
- Vehicle information
- Usage history

2. HOW WE USE YOUR INFORMATION
- Provide and improve services
- Process transactions
- Send notifications
- Analyze usage

3. LOCATION DATA
We collect location to find nearby charging stations.

4. PAYMENT INFORMATION
Processed by secure third-party providers.

5. DATA SECURITY
We protect your information with reasonable measures.

6. INFORMATION SHARING
We don't sell your data. We share only to provide services.

7. YOUR RIGHTS
Access, correct, or delete your information.

8. CHILDREN'S PRIVACY
Service not directed to children under 13.

9. CHANGES
Policy may be updated periodically.

10. CONTACT
privacy@evtron.in
""";
  }

  String _getAboutContent() {
    return """
ABOUT EVTRON

Innovating for a Greener Tomorrow

EVtron provides EV charging solutions across India.

OUR MISSION
Accelerate EV adoption through reliable charging infrastructure.

WHAT WE OFFER
- AC Chargers (3.3kW - 22kW)
- DC Fast Chargers (30kW - 360kW)
- Smart charging software
- 24/7 customer support

OUR ACHIEVEMENTS
- 22+ Chargers installed
- 870+ Successful sessions

CONTACT
Website: https://evtron.in
Email: info@evtron.in

© 2024 EVtron
""";
  }
}