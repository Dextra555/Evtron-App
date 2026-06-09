import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Controller/vehicle_controller.dart';
import '../../Model/vehicle_model.dart';
import '../../Theme/colors.dart';
import '../Home/mapui.dart';
// Adjust path as needed

class CarDetailsPage extends StatefulWidget {
  const CarDetailsPage({super.key});

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  final VehicleController _vehicleController = VehicleController();
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _registrationController = TextEditingController();

  // Selected values for dropdowns
  String? _selectedManufacturer;
  String? _selectedModel;

  // Loading state
  bool _isLoading = false;

  // Static data for manufacturers and models
  final Map<String, List<String>> _carsData = {
    'Toyota': ['Camry', 'Corolla', 'Fortuner', 'Innova', 'Land Cruiser', 'Prius', 'Rav4', 'Yaris'],
    'Honda': ['Civic', 'Accord', 'City', 'CR-V', 'HR-V', 'Pilot', 'Odyssey'],
    'Hyundai': ['Elantra', 'Sonata', 'Tucson', 'Santa Fe', 'i10', 'i20', 'Creta', 'Verna'],
    'Mahindra': ['Thar', 'Scorpio', 'XUV700', 'XUV300', 'Bolero', 'Marazzo'],
    'Tata': ['Nexon', 'Harrier', 'Safari', 'Punch', 'Tiago', 'Tigor', 'Altroz'],
    'Maruti Suzuki': ['Swift', 'Dzire', 'Baleno', 'Vitara Brezza', 'Ertiga', 'Alto', 'WagonR', 'Ciaz'],
    'Kia': ['Seltos', 'Sonet', 'Carens', 'EV6'],
    'Volkswagen': ['Polo', 'Vento', 'Taigun', 'Tiguan', 'Virtus'],
    'Ford': ['EcoSport', 'Figo', 'Aspire', 'Endeavour'],
    'Renault': ['Kwid', 'Triber', 'Kiger'],
    'Nissan': ['Magnite', 'Sunny', 'Micra'],
    'BMW': ['3 Series', '5 Series', 'X1', 'X3', 'X5'],
    'Mercedes-Benz': ['C-Class', 'E-Class', 'S-Class', 'GLA', 'GLC', 'GLE'],
    'Audi': ['A4', 'A6', 'Q3', 'Q5', 'Q7'],
    'Volvo': ['XC40', 'XC60', 'XC90', 'S60'],
  };

  List<String> get _availableModels {
    if (_selectedManufacturer != null && _carsData.containsKey(_selectedManufacturer)) {
      return _carsData[_selectedManufacturer]!;
    }
    return [];
  }

  @override
  void dispose() {
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create vehicle model
      final AddVehicleModel vehicleModel = AddVehicleModel(
        manufacturer: _selectedManufacturer!,
        model: _selectedModel!,
        registrationNumber: _registrationController.text.trim(),
      );

      print('========== UI: SAVING VEHICLE ==========');
      print('Manufacturer: ${vehicleModel.manufacturer}');
      print('Model: ${vehicleModel.model}');
      print('Registration Number: ${vehicleModel.registrationNumber}');
      print('==========================================');

      // Call API
      final response = await _vehicleController.addVehicle(vehicleModel);

      print('========== UI: API RESPONSE ==========');
      print('Status: ${response.status}');
      print('Message: ${response.message}');
      if (response.data != null && response.data!.isNotEmpty) {
        print('Vehicle ID: ${response.data![0].id}');
        print('Vehicle Display: ${response.data![0].displayName}');
      }
      print('==========================================');

      if (response.status) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to map screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('========== UI: EXCEPTION ==========');
      print('Error: $e');
      print('==========================================');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolor.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 90),

                /// Title Section
                Text(
                  "Add Your Car",
                  style: GoogleFonts.inter(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Appcolor.black,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Enter your vehicle details",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Appcolor.black.withOpacity(0.45),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 36),

                /// Manufacturer Dropdown
                _buildModernDropdown(
                  label: "Manufacturer",
                  hint: "Select manufacturer",
                  icon: Icons.business_rounded,
                  value: _selectedManufacturer,
                  items: _carsData.keys.toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedManufacturer = value;
                      _selectedModel = null; // Reset model when manufacturer changes
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a manufacturer';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildModernDropdown(
                  label: "Model",
                  hint: "Select model",
                  icon: Icons.directions_car_rounded,
                  value: _selectedModel,
                  items: _availableModels,
                  onChanged: (value) {
                    setState(() {
                      _selectedModel = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a model';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildModernTextField(
                  label: "Registration Number",
                  hint: "GJ-12-DD-0000",
                  icon: Icons.assignment_ind_rounded,
                  controller: _registrationController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter registration number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 36),

                /// Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveVehicle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Appcolor.green,
                      foregroundColor: Appcolor.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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
                      "Save Vehicle",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                /// Skip Link
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MapScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: Text(
                      "Skip for now",
                      style: GoogleFonts.inter(
                        color: Appcolor.black.withOpacity(0.35),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,  // This should NOT be nullable
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Appcolor.black.withOpacity(0.65),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              color: Appcolor.black.withOpacity(0.25),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          validator: validator,
          onChanged: onChanged,  // Now accepts nullable or non-nullable
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: Appcolor.green.withOpacity(0.7),
              size: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Appcolor.borderGrey,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Appcolor.borderGrey,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Appcolor.green,
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            filled: true,
            fillColor: Appcolor.white,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Appcolor.black,
                ),
              ),
            );
          }).toList(),
          // Remove selectedItemBuilder - it's not needed and can cause issues
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Appcolor.black.withOpacity(0.65),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Appcolor.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: Appcolor.black.withOpacity(0.25),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: Appcolor.green.withOpacity(0.7),
              size: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Appcolor.borderGrey,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Appcolor.borderGrey,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Appcolor.green,
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            filled: true,
            fillColor: Appcolor.white,
          ),
        ),
      ],
    );
  }
}