import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Theme/colors.dart';
import '../../Controller/vehicle_controller.dart';
import '../../Model/vehicle_model.dart';
import '../Scanner/scanner.dart';

class MyVehiclesPage extends StatefulWidget {
  const MyVehiclesPage({super.key});

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  final VehicleController _vehicleController = VehicleController();
  final TextEditingController _registrationController = TextEditingController();

  List<Vehicle> vehicles = [];
  String? _selectedManufacturer;
  String? _selectedModel;

  bool _isAddingVehicle = false;
  bool _isLoadingVehicles = true;
  bool _isDeleting = false;
  bool _isUpdating = false;

  int _currentIndex = 1;

  final List<String> _manufacturers = [
    'Tesla', 'MG', 'Hyundai', 'Nissan', 'BMW', 'Audi', 'Mercedes-Benz',
    'Kia', 'Ford', 'Volkswagen', 'Renault', 'Jaguar', 'Porsche', 'Volvo',
  ];

  final Map<String, List<String>> _modelsByManufacturer = {
    'Tesla': ['Model 3', 'Model S', 'Model X', 'Model Y', 'Cybertruck'],
    'MG': ['ZS EV', 'MG4 Electric', 'MG5 EV', 'Comet EV'],
    'Hyundai': ['Kona Electric', 'Ioniq 5', 'Ioniq 6', 'Kona EV'],
    'Nissan': ['Leaf', 'Ariya', 'LEAF e+'],
    'BMW': ['i3', 'i4', 'iX', 'iX3', 'i7'],
    'Audi': ['e-tron', 'Q4 e-tron', 'Q8 e-tron', 'e-tron GT'],
    'Mercedes-Benz': ['EQA', 'EQB', 'EQC', 'EQE', 'EQS', 'EQV'],
    'Kia': ['EV6', 'Niro EV', 'Soul EV', 'EV9'],
    'Ford': ['Mustang Mach-E', 'F-150 Lightning', 'E-Transit'],
    'Volkswagen': ['ID.3', 'ID.4', 'ID.5', 'ID. Buzz', 'e-Golf'],
    'Renault': ['Zoe', 'Megane E-Tech', 'Twizy', 'Kangoo'],
    'Jaguar': ['I-PACE'],
    'Porsche': ['Taycan', 'Macan Electric'],
    'Volvo': ['XC40 Recharge', 'C40 Recharge', 'EX90'],
  };

  List<String> get _availableModels {
    if (_selectedManufacturer != null && _modelsByManufacturer.containsKey(_selectedManufacturer)) {
      return _modelsByManufacturer[_selectedManufacturer]!;
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _registrationController.dispose();
    super.dispose();
  }

  // ---------- Navigation & Scanner ----------

  void _showChargerDetailsBottomSheet(BuildContext context) {
    String selectedChargerModel = 'Delta AC-22';
    String selectedChargerType = 'CCS2';

    final List<String> chargerModels = [
      'Delta AC-22',
      'ABB Terra 54',
      'ABB Terra 124',
      'Tata Power EZ Charge',
      'BP Pulse 60kW',
      'Shell Recharge 150kW',
      'Tesla Wall Connector',
      'ChargePoint CP50',
      'EvBox Elvi',
      'Allegro 50kW'
    ];

    final List<String> chargerTypes = ['CCS2', 'CHAdeMO', 'Type 2', 'GB/T', 'Tesla Supercharger'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.65,
                minChildSize: 0.5,
                maxChildSize: 0.8,
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Appcolor.green.withOpacity(0.1),
                                        Appcolor.green.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    Icons.ev_station,
                                    color: Appcolor.green,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Charger Details",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Select charger information",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),

                                _buildLabel("Charger Model *"),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedChargerModel,
                                      icon: Icon(Icons.arrow_drop_down, color: Appcolor.green),
                                      iconSize: 24,
                                      isExpanded: true,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      items: chargerModels.map((String model) {
                                        return DropdownMenuItem<String>(
                                          value: model,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.ev_station,
                                                  size: 18,
                                                  color: Appcolor.green,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(model),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setStateBottomSheet(() {
                                          selectedChargerModel = newValue!;
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                _buildLabel("Charger Type *"),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedChargerType,
                                      icon: Icon(Icons.arrow_drop_down, color: Appcolor.green),
                                      iconSize: 24,
                                      isExpanded: true,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                      items: chargerTypes.map((String type) {
                                        return DropdownMenuItem<String>(
                                          value: type,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _getChargerIcon(type),
                                                  size: 18,
                                                  color: Appcolor.green,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(type),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setStateBottomSheet(() {
                                          selectedChargerType = newValue!;
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.grey.shade300),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Text(
                                          "Cancel",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (selectedChargerModel.isEmpty) {
                                            _showErrorDialog(context, "Please select charger model");
                                            return;
                                          }
                                          if (selectedChargerType.isEmpty) {
                                            _showErrorDialog(context, "Please select charger type");
                                            return;
                                          }

                                          Map<String, String> chargerDetails = {
                                            'chargerModel': selectedChargerModel,
                                            'chargerType': selectedChargerType,
                                          };

                                          Navigator.pop(context);

                                          Future.delayed(const Duration(milliseconds: 100), () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ScannerPage(
                                                  chargerDetails: chargerDetails,
                                                ),
                                              ),
                                            );
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Appcolor.green,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          "Continue to Scan",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  IconData _getChargerIcon(String type) {
    switch (type) {
      case 'CCS2':
        return Icons.ev_station;
      case 'CHAdeMO':
        return Icons.bolt;
      case 'Type 2':
        return Icons.electrical_services;
      case 'GB/T':
        return Icons.charging_station;
      case 'Tesla Supercharger':
        return Icons.speed;
      default:
        return Icons.ev_station;
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------- Vehicle CRUD ----------
  Future<void> _loadVehicles() async {
    setState(() {
      _isLoadingVehicles = true;
    });

    final response = await _vehicleController.fetchVehicles();

    if (mounted) {
      setState(() {
        _isLoadingVehicles = false;
        if (response.status && response.data != null) {
          vehicles = response.data!;
        } else {
          vehicles = [];
          if (!response.message.contains('Session expired')) {
            _showMessage(response.message, Colors.red);
          }
        }
      });
    }
  }

  Future<void> _addVehicle() async {
    if (_selectedManufacturer == null ||
        _selectedModel == null ||
        _registrationController.text.isEmpty) {
      _showMessage('Please fill all fields', Colors.red);
      return;
    }

    setState(() {
      _isAddingVehicle = true;
    });

    final model = AddVehicleModel(
      manufacturer: _selectedManufacturer!,
      model: _selectedModel!,
      registrationNumber: _registrationController.text.trim(),
    );

    final response = await _vehicleController.addVehicle(model);

    if (mounted) {
      setState(() {
        _isAddingVehicle = false;
      });

      if (response.status) {
        _showMessage(response.message, Appcolor.green);
        await _loadVehicles();
        _resetForm();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        _showMessage(response.message, Colors.red);
      }
    }
  }

  Future<void> _updateVehicle(String vehicleId) async {
    if (_selectedManufacturer == null ||
        _selectedModel == null ||
        _registrationController.text.isEmpty) {
      _showMessage('Please fill all fields', Colors.red);
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    final model = UpdateVehicleModel(
      manufacturer: _selectedManufacturer!,
      model: _selectedModel!,
      registrationNumber: _registrationController.text.trim(),
    );

    // Convert vehicleId to int if needed, or keep as String based on your API
    final response = await _vehicleController.updateVehicle(vehicleId, model);

    if (mounted) {
      setState(() {
        _isUpdating = false;
      });

      if (response.status) {
        _showMessage(response.message, Appcolor.green);
        await _loadVehicles();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        _showMessage(response.message, Colors.red);
      }
    }
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    setState(() {
      _isDeleting = true;
    });

    final response = await _vehicleController.deleteVehicle(vehicleId);

    if (mounted) {
      setState(() {
        _isDeleting = false;
      });

      if (response.status) {
        _showMessage(response.message, Colors.green);
        await _loadVehicles();
      } else {
        _showMessage(response.message, Colors.red);
      }
    }
  }

  void _resetForm() {
    _selectedManufacturer = null;
    _selectedModel = null;
    _registrationController.clear();
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 12)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Vehicle vehicle) {
    showDialog(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade400, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Delete Vehicle",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete ${vehicle.manufacturer} ${vehicle.model} (${vehicle.registrationNumber})?",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: _isDeleting ? null : () async {
              Navigator.pop(context);
              await _deleteVehicle(vehicle.id.toString());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isDeleting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : Text("Delete", style: GoogleFonts.poppins(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showEditVehicleBottomSheet(Vehicle vehicle) {
    _selectedManufacturer = vehicle.manufacturer;
    _selectedModel = vehicle.model;
    _registrationController.text = vehicle.registrationNumber;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !_isUpdating,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBottomSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Edit Vehicle",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModernDropdownField(
                            label: "Manufacturer",
                            icon: Icons.business_outlined,
                            value: _selectedManufacturer,
                            items: _manufacturers,
                            hint: "Select manufacturer",
                            onChanged: (value) {
                              setStateBottomSheet(() {
                                _selectedManufacturer = value;
                                _selectedModel = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernDropdownField(
                            label: "Model",
                            icon: Icons.directions_car_outlined,
                            value: _selectedModel,
                            items: _availableModels,
                            hint: "Select model",
                            enabled: _selectedManufacturer != null,
                            onChanged: (value) {
                              setStateBottomSheet(() {
                                _selectedModel = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _registrationController,
                            label: "Registration Number",
                            icon: Icons.confirmation_number_outlined,
                            hint: "Enter number",
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isUpdating ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text("Cancel", style: GoogleFonts.poppins(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isUpdating ? null : () => _updateVehicle(vehicle.id.toString()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Appcolor.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isUpdating
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                : Text("Update Vehicle", style: GoogleFonts.poppins(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddVehicleBottomSheet() {
    _resetForm();
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBottomSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Appcolor.green, Appcolor.green.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.electric_car, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            "Add New Vehicle",
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModernDropdownField(
                            label: "Manufacturer",
                            icon: Icons.business_outlined,
                            value: _selectedManufacturer,
                            items: _manufacturers,
                            hint: "Select manufacturer",
                            onChanged: (value) {
                              setStateBottomSheet(() {
                                _selectedManufacturer = value;
                                _selectedModel = null;
                                errorMessage = null;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildModernDropdownField(
                            label: "Model",
                            icon: Icons.directions_car_outlined,
                            value: _selectedModel,
                            items: _availableModels,
                            hint: _selectedManufacturer == null ? "Select model" : "Select model",
                            enabled: _selectedManufacturer != null,
                            onChanged: (value) {
                              setStateBottomSheet(() {
                                _selectedModel = value;
                                errorMessage = null;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildModernTextField(
                            controller: _registrationController,
                            label: "Registration Number",
                            icon: Icons.confirmation_number_outlined,
                            hint: "e.g., ABC-1234",
                            onChanged: () {
                              setStateBottomSheet(() {
                                errorMessage = null;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          if (errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isAddingVehicle ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text("Cancel", style: GoogleFonts.poppins(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isAddingVehicle
                                ? null
                                : () async {
                              if (_selectedManufacturer == null ||
                                  _selectedModel == null ||
                                  _registrationController.text.trim().isEmpty) {
                                setStateBottomSheet(() {
                                  errorMessage = "Please fill all details";
                                });
                                return;
                              }
                              await _addVehicle();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Appcolor.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isAddingVehicle
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                : Text("Save Vehicle", style: GoogleFonts.poppins(fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- UI Helpers ----------
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    VoidCallback? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.poppins(fontSize: 13),
            onChanged: (text) => onChanged?.call(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
              prefixIcon: Icon(icon, color: Appcolor.green, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required String hint,
    bool enabled = true,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? Colors.grey.shade200 : Colors.grey.shade300,
            ),
          ),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Appcolor.green, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(
                  hint,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: enabled ? Appcolor.green : Colors.grey.shade400,
                  size: 20,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black,
                ),
                onChanged: enabled ? onChanged : null,
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "My Vehicles",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingVehicles) {
      return const Center(child: CircularProgressIndicator(color: Appcolor.green));
    }

    if (vehicles.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length + 1,
      itemBuilder: (context, index) {
        if (index == vehicles.length) {
          return _buildAddButton();
        }
        return _buildVehicleCard(vehicles[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.electric_car_outlined, size: 60, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              "No Vehicles Added",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "Tap the button below to add your first vehicle",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _buildAddButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton(
      onPressed: _showAddVehicleBottomSheet,
      style: ElevatedButton.styleFrom(
        backgroundColor: Appcolor.green,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(double.infinity, 48),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              "Add New Vehicle",
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Appcolor.green.withOpacity(0.15), Appcolor.green.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.electric_car_rounded, color: Appcolor.green, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${vehicle.manufacturer}\n${vehicle.model}",
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vehicle.registrationNumber,
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showEditVehicleBottomSheet(vehicle),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Appcolor.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.edit_outlined, color: Appcolor.green, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showDeleteConfirmationDialog(vehicle),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}