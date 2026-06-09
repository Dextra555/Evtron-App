import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Controller/register_controller.dart';
import '../../Model/register_model.dart';
import '../../Theme/colors.dart';
import 'login.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _agreeToTerms = false;
  bool _isLoading = false;

  final RegisterController _registerController = RegisterController();

  final Color _greenColor = const Color(0xFF66b531);
  final List<Color> _gradientColors = [
    Appcolor.green,
    const Color(0xFF7EC84A),
    const Color(0xFF9DD96E),
    const Color(0xFFC8E8A8),
    const Color(0xFFE8F5E3),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the terms and conditions',
              style: TextStyle(fontSize: 13)),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final registerModel = RegisterModel(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    final result = await _registerController.createAccount(registerModel);

    setState(() {
      _isLoading = false;
    });

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"],
              style: const TextStyle(fontSize: 13)),
          backgroundColor: _greenColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to LoginScreen after successful registration
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // Replace the current screen with LoginScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
          // OR if you want to clear all previous routes and go to LoginScreen:
          // Navigator.pushAndRemoveUntil(
          //   context,
          //   MaterialPageRoute(builder: (context) => const LoginScreen()),
          //   (route) => false,
          // );
        }
      });
    } else {
      _showError(result["message"]);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    setState(() {
      _agreeToTerms = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolor.lightGrey,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          ..._buildDecorativeCircles(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    FadeInUp(
                      delay: 0.2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Create Account",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Appcolor.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Get started with your EV journey today",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Appcolor.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      delay: 0.4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Appcolor.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Appcolor.black.withOpacity(0.08),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputField(
                                    controller: _nameController,
                                    label: "Full Name",
                                    hint: "Enter your full name",
                                    prefixIcon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      if (value.length < 2) {
                                        return 'Name must be at least 2 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _buildInputField(
                                    controller: _emailController,
                                    label: "Email Address",
                                    hint: "you@example.com",
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                      if (!emailRegex.hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _buildInputField(
                                    controller: _phoneController,
                                    label: "Phone Number",
                                    hint: "9876543210",
                                    prefixIcon: Icons.phone_android_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      final phoneRegex = RegExp(r'^\d{10}$');
                                      if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
                                        return 'Please enter a valid 10-digit phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _agreeToTerms,
                                          onChanged: (value) {
                                            setState(() {
                                              _agreeToTerms = value ?? false;
                                            });
                                          },
                                          activeColor: _greenColor,
                                          checkColor: Appcolor.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey.shade600,
                                              fontSize: 11,
                                              height: 1.4,
                                            ),
                                            children: [
                                              const TextSpan(text: "I agree to the "),
                                              TextSpan(
                                                text: "Terms of Service",
                                                style: GoogleFonts.poppins(
                                                  color: _greenColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const TextSpan(text: " and "),
                                              TextSpan(
                                                text: "Privacy Policy",
                                                style: GoogleFonts.poppins(
                                                  color: _greenColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    height: 50,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF8EC63F), Color(0xFF6AAE2A)],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _greenColor.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Appcolor.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          shadowColor: Colors.transparent,
                                        ),
                                        onPressed: _isLoading ? null : _createAccount,
                                        child: _isLoading
                                            ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                            : Text(
                                          "Create Account",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Appcolor.borderGrey,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Text(
                                          "OR",
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Appcolor.borderGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Already have an account? ",
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          "Sign In",
                                          style: GoogleFonts.poppins(
                                            color: _greenColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Appcolor.black,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Appcolor.lightGrey,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Appcolor.borderGrey,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Appcolor.black,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: Colors.grey.shade600,
                size: 18,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 14,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDecorativeCircles() {
    return [
      Positioned(
        top: -50,
        right: -50,
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Appcolor.white.withOpacity(0.15),
          ),
        ),
      ),
      Positioned(
        top: 180,
        left: -30,
        child: Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Appcolor.white.withOpacity(0.1),
          ),
        ),
      ),
      Positioned(
        bottom: 80,
        right: -20,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Appcolor.white.withOpacity(0.08),
          ),
        ),
      ),
    ];
  }
}

class FadeInUp extends StatelessWidget {
  final Widget child;
  final double delay;

  const FadeInUp({
    required this.child,
    this.delay = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, double value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

