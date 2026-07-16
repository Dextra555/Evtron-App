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
  late TextEditingController businessNameController;
  late TextEditingController businessAddressController;
  late TextEditingController gstinController;

  final EditProfileController _editProfileController = EditProfileController();

  bool isDarkMode = false;
  bool isLoading = false;
  bool isCustomerDetailsEnabled = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    phoneController = TextEditingController(text: widget.phoneNumber);
    emailController = TextEditingController(text: widget.email);

    businessNameController = TextEditingController();
    businessAddressController = TextEditingController();
    gstinController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();

    businessNameController.dispose();
    businessAddressController.dispose();
    gstinController.dispose();
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
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 10),
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

              // Customer Details Section with checkbox on right
              _buildCustomerDetailsSection(),

              const SizedBox(height: 20),
              _buildTextField(
                controller: businessNameController,
                label: "Business Name",
                hint: "Enter your business name",
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: businessAddressController,
                label: "Business Address",
                hint: "Enter your business address",
                icon: Icons.location_on_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildGSTINField(),
              const SizedBox(height: 30),
            ],
          ),
        ),
        // Save Button at bottom
        _buildSaveButton(),
      ],
    );
  }

  // Updated Customer Details section with checkbox on right - removed divider line
  Widget _buildCustomerDetailsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Customer Details",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Checkbox(
            value: isCustomerDetailsEnabled,
            onChanged: (bool? value) {
              setState(() {
                isCustomerDetailsEnabled = value ?? false;
              });
            },
            activeColor: Colors.green,
            checkColor: Colors.white,
            side: BorderSide(
              color: isDarkMode ? Colors.grey[400]! : Colors.grey[600]!,
              width: 2,
            ),
          ),
        ],
      ),
    );
  }

  // New method for Save button at bottom
  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isLoading ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Text(
            "Save Profile",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
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
          maxLines: maxLines,
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

  Widget _buildGSTINField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "GSTIN Number",
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: gstinController,
          maxLength: 15,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.poppins(
            fontSize: 14,
            letterSpacing: 1.2,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: "22AAAAA0000A1Z5",
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            prefixIcon: const Icon(
              Icons.assignment_outlined,
              color: Colors.green,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDarkMode
                    ? Colors.grey[800]!
                    : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDarkMode
                    ? Colors.grey[800]!
                    : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.green,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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

