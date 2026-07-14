import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Controller/manufacturer_controller.dart';
import '../../Controller/vehicle_controller.dart';
import '../../Model/vehicle_model.dart';
import '../../Model/manufacturer_model.dart';
import '../../Theme/colors.dart';
import '../Home/mapui.dart';

class CarDetailsPage extends StatefulWidget {
  const CarDetailsPage({super.key});

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  final VehicleController _vehicleController = VehicleController();
  final SettingsController _settingsController = SettingsController();
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _registrationController = TextEditingController();

  // Selected values for dropdowns
  Manufacturer? _selectedManufacturer;
  VehicleModel? _selectedModel;

  // Loading state
  bool _isLoading = false;
  bool _isLoadingManufacturers = true;
  bool _isLoadingModels = false;

  // Dynamic data
  List<Manufacturer> _manufacturers = [];
  List<VehicleModel> _models = [];

  @override
  void initState() {
    super.initState();
    _fetchManufacturers();
  }

  @override
  void dispose() {
    _registrationController.dispose();
    super.dispose();
  }

  // Fetch manufacturers from API
  Future<void> _fetchManufacturers() async {
    setState(() {
      _isLoadingManufacturers = true;
    });

    try {
      final response = await _settingsController.fetchManufacturers();

      if (response.success && response.data.isNotEmpty) {
        setState(() {
          _manufacturers = response.data;
          _isLoadingManufacturers = false;
        });
        print('Manufacturers loaded: ${_manufacturers.length}');
      } else {
        setState(() {
          _isLoadingManufacturers = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load manufacturers'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingManufacturers = false;
      });
      print('Error fetching manufacturers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading manufacturers'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fetch models when manufacturer is selected
  Future<void> _fetchModels(int manufacturerId) async {
    setState(() {
      _isLoadingModels = true;
      _selectedModel = null; // Reset selected model
      _models = []; // Clear previous models
    });

    try {
      final response = await _settingsController.fetchModels(manufacturerId);

      if (response.success && response.data.isNotEmpty) {
        setState(() {
          _models = response.data;
          _isLoadingModels = false;
        });
        print('Models loaded: ${_models.length}');
      } else {
        setState(() {
          _isLoadingModels = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No models found for this manufacturer'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingModels = false;
      });
      print('Error fetching models: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading models'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      // Create vehicle model using ONLY the names (no IDs)
      final AddVehicleModel vehicleModel = AddVehicleModel(
        manufacturer: _selectedManufacturer!.name,
        model: _selectedModel!.name,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
      } else {
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
                  items: _manufacturers,
                  isLoading: _isLoadingManufacturers,
                  onChanged: (Manufacturer? manufacturer) {
                    setState(() {
                      _selectedManufacturer = manufacturer;
                      // Fetch models when manufacturer is selected
                      if (manufacturer != null) {
                        _fetchModels(manufacturer.id);
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a manufacturer';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                /// Model Dropdown
                _buildModernDropdown(
                  label: "Model",
                  hint: _selectedManufacturer == null
                      ? "Select manufacturer first"
                      : "Select model",
                  icon: Icons.directions_car_rounded,
                  value: _selectedModel,
                  items: _models,
                  isLoading: _isLoadingModels,
                  onChanged: (VehicleModel? model) {
                    setState(() {
                      _selectedModel = model;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
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

  // Updated dropdown builder with generic type support
  Widget _buildModernDropdown<T>({
    required String label,
    required String hint,
    required IconData icon,
    required T? value,
    required List<T> items,
    required bool isLoading,
    required Function(T?) onChanged,
    required String? Function(T?)? validator,
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
        DropdownButtonFormField<T>(
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
          onChanged: isLoading ? null : onChanged,
          decoration: InputDecoration(
            prefixIcon: isLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
                : Icon(
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
          items: items.map((T item) {
            String displayText = '';
            if (item is Manufacturer) {
              displayText = item.name;
            } else if (item is VehicleModel) {
              displayText = item.name;
            }
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                displayText,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Appcolor.black,
                ),
              ),
            );
          }).toList(),
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