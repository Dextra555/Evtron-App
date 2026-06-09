import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Controller/edit_profile_controller.dart';
import '../../Model/edit_profile_model.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String phoneNumber;
  final String email;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.email,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  final EditProfileController _editProfileController = EditProfileController();

  bool isDarkMode = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    phoneController = TextEditingController(text: widget.phoneNumber);
    emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Validate inputs
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final editProfileModel = EditProfileModel(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
    );

    final response = await _editProfileController.updateProfile(editProfileModel);

    if (mounted) {
      setState(() {
        isLoading = false;
      });

      if (response.success) {
        _showMessage(response.message, Colors.green);

        // Navigate back with updated data
        Navigator.pop(context, {
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
        });
      } else {
        _showMessage(response.message, Colors.red);

        // Redirect to login if session expired
        if (response.message.contains('Session expired')) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          });
        }
      }
    }
  }

  bool _validateInputs() {
    if (nameController.text.trim().isEmpty) {
      _showMessage("Please enter your name", Colors.red);
      return false;
    }

    if (phoneController.text.trim().isEmpty) {
      _showMessage("Please enter your phone number", Colors.red);
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      _showMessage("Please enter your email address", Colors.red);
      return false;
    }

    // Validate email format
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regExp = RegExp(emailPattern);
    if (!regExp.hasMatch(emailController.text.trim())) {
      _showMessage("Please enter a valid email address", Colors.red);
      return false;
    }

    return true;
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildForm(),
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back,
          color: isDarkMode ? Colors.white : Colors.black,
          size: 22,
        ),
      ),
      title: Text(
        "Edit Profile",
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: isLoading ? null : _saveProfile,
          child: isLoading
              ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          )
              : Text(
            "Save",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 30),
        _buildTextField(
          controller: nameController,
          label: "Full Name",
          hint: "Enter your full name",
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: phoneController,
          label: "Phone Number",
          hint: "Enter your phone number",
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: emailController,
          label: "Email Address",
          hint: "Enter your email address",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            prefixIcon: Icon(icon, size: 20, color: Colors.green),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.green, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.green,
        ),
      ),
    );
  }
}