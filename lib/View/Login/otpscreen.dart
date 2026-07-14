import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Controller/otp_controller.dart';
import '../../Controller/vehicle_controller.dart';
import '../../Model/otp_model.dart';
import '../../Theme/colors.dart';
import '../../session_manager.dart';
import '../Home/homepage.dart';
import '../Home/mapui.dart';
import 'cardetails.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? emailOrPhone;
  final String? otp;

  const OtpVerificationScreen({
    super.key,
    this.emailOrPhone,
    this.otp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  final OtpController _otpController = OtpController();
  final VehicleController _vehicleController = VehicleController();

  String _errorMessage = '';
  bool _isLoading = false;
  bool _isResendLoading = false;
  int _resendTimerSeconds = 0;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    // Auto-fill OTP if provided
    if (widget.otp != null && widget.otp!.length == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoFillOtp(widget.otp!);
      });
    }
  }

  void _autoFillOtp(String otp) {
    for (int i = 0; i < otp.length && i < 4; i++) {
      _otpControllers[i].text = otp[i];
    }
    // Auto-verify after filling
    Future.delayed(const Duration(milliseconds: 500), () {
      _verifyOtp();
    });
  }


  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimerSeconds = 60;
    });

    Future.delayed(const Duration(seconds: 1), _updateTimer);
  }

  void _updateTimer() {
    if (_resendTimerSeconds > 0) {
      setState(() {
        _resendTimerSeconds--;
      });
      Future.delayed(const Duration(seconds: 1), _updateTimer);
    } else {
      setState(() {
        _canResend = true;
      });
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    bool allFilled = _otpControllers.every((controller) => controller.text.isNotEmpty);
    if (allFilled) {
      _verifyOtp();
    }
  }

  String _getOtp() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    String otp = _getOtp();

    if (otp.length != 4) {
      setState(() {
        _errorMessage = 'Please enter the 4-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final verifyOtpModel = VerifyOtpModel(
      phone: widget.emailOrPhone?.trim() ?? '',
      otp: otp,
    );

    final result = await _otpController.verifyOtp(verifyOtpModel);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Check if OTP verification was successful
      if (result["success"] == true) {
        _showSuccess(result["message"]);

        // ✅ Save user session after successful OTP verification
        await SessionManager.setLoggedIn(true);
        await SessionManager.setUserPhone(widget.emailOrPhone?.trim() ?? '');

        // ✅ Fetch vehicles to check if user has any
        final vehicleResponse = await _vehicleController.fetchVehicles();

        if (mounted) {
          if (vehicleResponse.status && vehicleResponse.totalVehicles > 0) {
            // User has vehicles - go to MapScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
            );
          } else {
            // User has no vehicles - go to CarDetailsPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CarDetailsPage()),
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = result["message"];
          for (var controller in _otpControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        });
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend || _isResendLoading) return;

    setState(() {
      _isResendLoading = true;
      _errorMessage = '';
    });

    final resendOtpModel = ResendOtpModel(
      phone: widget.emailOrPhone?.trim() ?? '',
    );

    final result = await _otpController.resendOtp(resendOtpModel);

    if (mounted) {
      setState(() {
        _isResendLoading = false;
      });

      if (result["success"] == true) {
        _startResendTimer();
        _showSuccess(result["message"]);

        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      } else {
        _showError(result["message"]);
        setState(() {
          _canResend = true;
        });
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 13)),
        backgroundColor: Appcolor.green,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                _buildHeaderText(),
                const SizedBox(height: 28),
                _buildOtpInputFields(),
                if (_errorMessage.isNotEmpty) _buildErrorMessage(),
                const SizedBox(height: 24),
                _buildVerifyButton(),
                const SizedBox(height: 16),
                _buildResendSection(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.black87,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeaderText() {
    return Column(
      children: [
        Text(
          "Verification Code",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "We've sent a 4-digit verification code to",
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Appcolor.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            widget.emailOrPhone ?? "your registered email/phone",
            style: GoogleFonts.poppins(
              color: Appcolor.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fieldWidth = (constraints.maxWidth - 20) / 4;
        fieldWidth = fieldWidth.clamp(55.0, 65.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              width: fieldWidth,
              height: 55,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _errorMessage.isNotEmpty
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _errorMessage.isNotEmpty
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Appcolor.green,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (value) => _onOtpChanged(value, index),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage,
                style: GoogleFonts.poppins(
                  color: Colors.red.shade700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Appcolor.green, Appcolor.green.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Appcolor.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _verifyOtp,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _isLoading
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
              ),
            )
                : Text(
              "Verify & Continue",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the code? ",
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (_canResend)
          GestureDetector(
            onTap: _isResendLoading ? null : _handleResendOtp,
            child: _isResendLoading
                ? SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
              ),
            )
                : Text(
              "Resend",
              style: GoogleFonts.poppins(
                color: Appcolor.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        if (!_canResend)
          Text(
            "Resend in ${_formatTime(_resendTimerSeconds)}",
            style: GoogleFonts.poppins(
              color: Appcolor.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}


