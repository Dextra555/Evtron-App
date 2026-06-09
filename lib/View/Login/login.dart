import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../../Controller/login_controller.dart';
import '../../Model/login_model.dart';
import '../../Theme/colors.dart';
import '../../session_manager.dart';
import '../Home/homepage.dart';
import 'createaccount.dart';
import 'otpscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailPhoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LoginController _loginController = LoginController();

  bool _isFocused = false;
  bool _isBiometricLoading = false;
  bool _isBiometricAvailable = false;
  bool _isLoading = false;

  final LocalAuthentication _localAuth = LocalAuthentication();

  final Color _primaryGreen = Appcolor.green;
  final Color _lightGreen = const Color(0xFF7EC84A);

  final List<Color> _gradientColors = [
    Appcolor.green,
    const Color(0xFF7EC84A),
    const Color(0xFF9DD96E),
    const Color(0xFFC8E8A8),
    const Color(0xFFE8F5E3),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable && isDeviceSupported;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBiometricAvailable = false;
        });
      }
    }
  }

  Future<void> _sendOtp() async {
    if (_emailPhoneController.text.trim().length != 10) {
      _showError("Please enter a valid 10-digit phone number");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final sendOtpModel = SendOtpModel(
      phone: _emailPhoneController.text.trim(),
    );

    final result = await _loginController.sendOtp(sendOtpModel);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result["success"] == true) {
        _showSuccess(result["message"]);

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpVerificationScreen(
                  emailOrPhone: _emailPhoneController.text,
                ),
              ),
            );
          }
        });
      } else {
        _showError(result["message"]);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
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

  Future<void> _authenticateWithBiometrics() async {
    if (!_isBiometricAvailable) {
      _showError("Biometric authentication is not available");
      return;
    }

    setState(() {
      _isBiometricLoading = true;
    });

    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to access your account',
        biometricOnly: false,
      );
      if (mounted) {

        if (isAuthenticated) {
          await SessionManager.setLoggedIn(true);
          await SessionManager.setUserPhone(_emailPhoneController.text);
          _showSuccess("Welcome back! Authentication successful!");

          if (mounted) {
            Future.delayed(const Duration(milliseconds: 500), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Homepage()),
                );
            });
          }
        }

        else {
          _showError("Authentication failed. Please try again.");
        }
      }
    } catch (e) {
      if (mounted) {
        _showError("Authentication error: ${e.toString().split('(')[0]}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _focusNode.dispose();
    super.dispose();
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
                  children: [
                    const SizedBox(height: 50),
                    _buildLogoSection(),
                    const SizedBox(height: 100),
                    _buildWelcomeText(),
                    const SizedBox(height: 40),
                    _buildLoginForm(),
                    const SizedBox(height: 25),
                    _buildFooterText(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        height: 90,
        width: 90,
        decoration: BoxDecoration(
          color: Appcolor.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.ev_station,
            color: _primaryGreen,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return FadeInUp(
      delay: 0.2,
      child: Column(
        children: [
          Text(
            "Hello Again!",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Appcolor.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Welcome back to your EV charging hub",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Appcolor.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return FadeInUp(
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
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhoneInputField(),
                const SizedBox(height: 22),
                _buildContinueButton(),
                const SizedBox(height: 20),
                _buildDivider(),
                // if (_isBiometricAvailable) ...[
                //   const SizedBox(height: 16),
                //   _buildBiometricButton(),
                // ],
                const SizedBox(height: 22),
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phone Number",
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
              color: _isFocused ? _primaryGreen : Colors.transparent,
              width: 1.5,
            ),
          ),
          child:
          TextField(
            controller: _emailPhoneController,
            focusNode: _focusNode,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Appcolor.black,
            ),
            decoration: InputDecoration(
              counterText: "", // hides 0/10 counter
              hintText: "Enter your phone number",
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.phone_android_outlined,
                color: _isFocused ? _primaryGreen : Colors.grey.shade400,
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return AnimatedContainer(
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
              color: _primaryGreen.withOpacity(0.3),
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
          onPressed: _isLoading ? null : _sendOtp,
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
            "Continue",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
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
            "Or continue with",
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
    );
  }

  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _isBiometricLoading ? null : _authenticateWithBiometrics,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _primaryGreen.withOpacity(0.1),
              _lightGreen.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _primaryGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: _isBiometricLoading
              ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_primaryGreen),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fingerprint,
                color: _primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Use Biometric Login",
                style: GoogleFonts.poppins(
                  color: _primaryGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "New to EVCharge? ",
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateAccountScreen(),
              ),
            );
          },
          child: Text(
            "Create Account",
            style: GoogleFonts.poppins(
              color: _primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterText() {
    return FadeInUp(
      delay: 0.6,
      child: Center(
        child: Text(
          "By continuing, you agree to our Terms of Service\nand Privacy Policy",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Appcolor.black.withOpacity(0.7),
            height: 1.5,
          ),
        ),
      ),
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

