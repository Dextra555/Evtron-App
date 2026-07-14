// lib/View/Scanner/scanner_page.dart

import 'package:evtron/Controller/scan_validation_controller.dart';
import 'package:evtron/View/Scanner/vehiclelist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../Controller/start_charging_controller.dart';
import '../../Controller/vehicle_controller.dart';
import '../../Model/scan_validation_model.dart';
import '../../Model/vehicle_model.dart';
import '../../Service/scan_validation_service.dart';
import '../../Theme/colors.dart';
import '../Login/Bottom.dart';
import '../Payment/paymentpage.dart';
import '../Profile/profile.dart';
import 'ChargingProgressPage.dart';
import '../Home/mapui.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class ScannerPage extends StatefulWidget {
  final Map<String, String>? chargerDetails;

  const ScannerPage({super.key, this.chargerDetails});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Camera Controllers
  MobileScannerController? cameraController;
  bool isScanning = true;
  String? scannedData;
  bool isFlashOn = false;
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isStartingCamera = false;
  bool _isDisposing = false;

  // Animation Controllers
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  // Text Controllers
  final TextEditingController _connectorIdController = TextEditingController();
  bool _isConnectorIdValid = false;

  // Form Controllers
  final TextEditingController _stationNameController = TextEditingController();
  final TextEditingController _chargerModelController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _powerRatingController = TextEditingController();
  String _selectedChargerType = 'CCS2';
  String _selectedStatus = 'Available';

  // Dropdown Options
  final List<String> chargerTypes = ['CCS2', 'CHAdeMO', 'Type 2', 'GB/T', 'Tesla Supercharger'];
  final List<String> statusOptions = ['Available', 'Occupied', 'Maintenance', 'Offline'];

  // Navigation
  int _currentIndex = 1;

  // Vehicle Controllers
  final VehicleController _vehicleController = VehicleController();
  List<Vehicle> _vehicles = [];
  bool _isLoadingVehicles = false;

  // Scan Validation Controller
  late ScanValidationController _scanValidationController;

  // Store connector data for start charging
  int? _connectorId;
  int? _vehicleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize scan validation controller
    _scanValidationController = ScanValidationController();

    // Load vehicles
    _loadVehicles();

    // Initialize scan animation
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0, end: 200).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );

    // Add listener to connector ID field
    _connectorIdController.addListener(_validateConnectorId);

    // Set initial charger details if provided
    if (widget.chargerDetails != null) {
      _chargerModelController.text = widget.chargerDetails!['chargerModel'] ?? '';
      _selectedChargerType = widget.chargerDetails!['chargerType'] ?? 'CCS2';
    }

    // Initialize camera after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  // ========== VEHICLE LOADING ==========
  Future<void> _loadVehicles() async {
    setState(() {
      _isLoadingVehicles = true;
    });
    try {
      final vehicleResponse = await _vehicleController.fetchVehicles();
      if (mounted) {
        if (vehicleResponse.status && vehicleResponse.data != null) {
          setState(() {
            _vehicles = vehicleResponse.data!;
            _isLoadingVehicles = false;
          });
          print('✅ Loaded ${_vehicles.length} vehicles successfully');
        } else {
          setState(() {
            _vehicles = [];
            _isLoadingVehicles = false;
          });
          print('⚠️ Failed to load vehicles: ${vehicleResponse.message}');
        }
      }
    } catch (e) {
      print('❌ Error loading vehicles: $e');
      if (mounted) {
        setState(() {
          _vehicles = [];
          _isLoadingVehicles = false;
        });
      }
    }
  }

  // ========== CAMERA METHODS ==========
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasPermission && cameraController == null && mounted && !_isDisposing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeCamera();
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (_isDisposing || _isStartingCamera) return;

    final status = await Permission.camera.request();

    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _hasPermission = true;
        });
      }

      await _disposeCameraController();

      if (!mounted) return;

      cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
        autoStart: false,
      );

      if (mounted) {
        setState(() {});
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && cameraController != null && !_isStartingCamera && !_isDisposing) {
            _startCamera();
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasPermission = false;
        });
        _showPermissionDeniedDialog();
      }
    }
  }

  Future<void> _startCamera() async {
    if (_isStartingCamera || _isDisposing || !mounted || cameraController == null) {
      return;
    }

    setState(() {
      _isStartingCamera = true;
    });

    try {
      await cameraController!.start();
      if (mounted && !_isDisposing) {
        setState(() {
          _isInitialized = true;
          _isStartingCamera = false;
        });
      }
    } catch (e) {
      print('Error starting camera: $e');
      if (mounted && !_isDisposing) {
        setState(() {
          _isInitialized = false;
          _isStartingCamera = false;
        });
      }
    }
  }

  Future<void> _stopCamera() async {
    if (cameraController != null && mounted && _isInitialized && !_isDisposing) {
      try {
        await cameraController!.stop();
        if (mounted) {
          setState(() {
            _isInitialized = false;
          });
        }
      } catch (e) {
        print('Error stopping camera: $e');
      }
    }
  }

  Future<void> _disposeCameraController() async {
    if (cameraController != null) {
      try {
        await cameraController!.stop();
        await cameraController!.dispose();
      } catch (e) {
        print('Error disposing camera: $e');
      }
      cameraController = null;
      _isInitialized = false;
      _isStartingCamera = false;
    }
  }

  void _toggleFlash() {
    if (cameraController != null && _isInitialized) {
      setState(() {
        isFlashOn = !isFlashOn;
      });
      cameraController!.toggleTorch();
    }
  }

  void _switchCamera() {
    if (cameraController != null && _isInitialized) {
      cameraController!.switchCamera();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Camera Permission Required"),
        content: const Text("Camera permission is needed to scan QR codes. Please grant permission to continue."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  // ========== SCANNER METHODS ==========
  void _handleScan(BarcodeCapture capture) {
    if (!isScanning || !mounted || !_isInitialized) return;

    final String? code = capture.barcodes.first.rawValue;
    if (code != null) {
      print('✅ QR Code Scanned: $code');
      setState(() {
        isScanning = false;
        scannedData = code;
      });
      _scanAnimationController.stop();
      _stopCamera();

      _connectorIdController.text = code;
      _validateConnectorId();

      _navigateToVehicleScreen(code);
    }
  }

  void _resetScanner() {
    setState(() {
      isScanning = true;
      scannedData = null;
    });
    _scanAnimationController.repeat(reverse: true);

    if (!_isInitialized && cameraController != null && mounted && !_isStartingCamera && !_isDisposing) {
      _startCamera();
    }
  }

  // ========== CONNECTOR ID VALIDATION ==========
  void _validateConnectorId() {
    setState(() {
      _isConnectorIdValid = _connectorIdController.text.trim().isNotEmpty;
    });
  }

  void _startChargingWithManualId() {
    String connectorId = _connectorIdController.text.trim();
    if (connectorId.isNotEmpty) {
      print('Manual connector ID entered: $connectorId');
      _navigateToVehicleScreen(connectorId);
    }
  }

  // ========== HELPER METHOD TO EXTRACT CONNECTOR ID ==========
  int _extractConnectorId(String connectorUid) {
    // Try to extract connector ID from UID (e.g., "CP-001.1" -> 1 or "CP-001" -> 1)
    try {
      final parts = connectorUid.split('.');
      if (parts.length >= 2) {
        final lastPart = parts.last;
        return int.tryParse(lastPart) ?? 0;
      }
      // Try to extract number from the end of the string
      final match = RegExp(r'(\d+)$').firstMatch(connectorUid);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '0') ?? 0;
      }
      return 0;
    } catch (e) {
      print('⚠️ Could not extract connector ID from UID: $connectorUid');
      return 0;
    }
  }

  // ========== NAVIGATION METHODS ==========
// lib/View/Scanner/scanner_page.dart (Updated - Only the relevant part)

// ========== NAVIGATION METHODS ==========
  Future<void> _navigateToVehicleScreen(String scannedData) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
                ),
                const SizedBox(height: 16),
                Text(
                  "Validating QR Code...",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scannedData,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Use the controller to validate
      final bool isValid = await _scanValidationController.validateScan(
        scannedData: scannedData,
        vehicleId: _vehicles.isNotEmpty ? _vehicles.first.id : null,
        // Latitude and longitude will be fetched automatically
      );

      if (!mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog
        }
        return;
      }

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (isValid && _scanValidationController.validationData != null) {
        // ✅ Validation successful
        final validationData = _scanValidationController.validationData!;

        print('\n✅ SCAN VALIDATION SUCCESSFUL!');
        print('🔌 Charger: ${validationData.charger.name}');
        print('💰 Balance: ₹${validationData.userBalance}');

        // Check balance (minimum ₹5)
        if (validationData.userBalance < 5) {
          _showErrorDialog(
            'Insufficient wallet balance (₹${validationData.userBalance.toStringAsFixed(2)}). '
                'Minimum balance required: ₹5. Please recharge your wallet.',
          );
          _resetScanner();
          return;
        }

        // Store the connector ID from validation response
        _connectorId = validationData.connector.connectorId;

        // ✅ FIXED: Navigate to vehicle selection with only primitive data
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleScreen(
              connectorUid: validationData.connector.connectorUid,
              connectorId: validationData.connector.connectorId,
              vehicles: _vehicles,
              chargerModel: validationData.charger.model.isNotEmpty
                  ? validationData.charger.model
                  : widget.chargerDetails?['chargerModel'] ?? 'Standard Charger',
              chargerType: validationData.charger.connectorType.isNotEmpty
                  ? validationData.charger.connectorType
                  : _selectedChargerType,
              // ✅ FIXED: Don't pass the full objects - just pass what's needed
              // or convert to the expected types if needed
            ),
          ),
        );

        if (result != null && result is Map<String, dynamic>) {
          // Get the vehicle ID from the result
          _vehicleId = result['vehicleId'];

          await _startChargingWithVehicle(
            connectorUid: validationData.connector.connectorUid,
            connectorId: validationData.connector.connectorId,
            vehicleData: result,
          );
        } else {
          _resetScanner();
        }
      } else {
        // ❌ Validation failed - Show error dialog with proper configuration
        final config = _scanValidationController.getErrorDialogConfig();
        _showErrorDialog(
          config.message,
          title: config.title,
          icon: config.icon,
          iconColor: config.iconColor,
          failedCheck: config.failedCheck,
          errorCode: config.errorCode,
        );
        _resetScanner();
      }

    } catch (e) {
      print('\n❌ EXCEPTION during validation: $e');
      if (mounted) {
        // Close loading dialog if still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _showErrorDialog('An unexpected error occurred. Please try again.');
        _resetScanner();
      }
    }
  }
  Future<void> _startChargingWithVehicle({
    required String connectorUid,
    required int connectorId,
    required Map<String, dynamic> vehicleData,
  }) async {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║              STARTING CHARGING WITH VEHICLE                   ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('\n📍 Connector UID: $connectorUid');
    print('📍 Connector ID: $connectorId');
    print('🚗 Vehicle: ${vehicleData['vehicleName']}');
    print('🚗 Vehicle ID: ${vehicleData['vehicleId']}');

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
                ),
                const SizedBox(height: 16),
                Text(
                  "Starting Charging Session...",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Connector: $connectorUid",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Vehicle: ${vehicleData['vehicleName']}",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final chargingController = ChargingController();

      // ✅ FIXED: Use connectorId and vehicleId
      final success = await chargingController.startChargingSession(
        connectorId: connectorId,
        vehicleId: vehicleData['vehicleId'],
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (success && mounted && chargingController.currentSession?.data != null) {
        print('\n✅ Charging session started successfully!');

        final sessionData = chargingController.currentSession!.data!;

        Map<String, dynamic> chargingDetails = {
          'sessionId': sessionData.sessionId,
          'transactionId': sessionData.transactionId,
          'startedAt': sessionData.startedAt,
          'vehicleId': vehicleData['vehicleId'],
          'vehicleName': vehicleData['vehicleName'],
          'manufacturer': vehicleData['manufacturer'],
          'model': vehicleData['model'],
          'registrationNumber': vehicleData['registrationNumber'],
          'chargerModel': _chargerModelController.text.isNotEmpty
              ? _chargerModelController.text
              : widget.chargerDetails?['chargerModel'] ?? 'Standard Charger',
          'chargerType': _selectedChargerType,
          'chargerId': sessionData.charger.id,
          'chargerName': sessionData.charger.name,
          'connectorId': sessionData.connector.id,
          'connectorName': sessionData.connector.name,
          'stationId': sessionData.station.id,
          'stationName': sessionData.station.name,
          'pricingType': sessionData.pricing.type,
          'pricingRate': sessionData.pricing.rate,
          'pricingUnit': sessionData.pricing.unit,
          'currency': sessionData.pricing.currency,
          'walletBalanceBefore': sessionData.wallet.balanceBefore,
        };

        if (mounted) {
          await _stopCamera();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChargingProgressPage(
                chargingDetails: chargingDetails,
              ),
            ),
          );
        }
      } else if (mounted) {
        // Show error dialog with proper error handling
        final errorResponse = chargingController.getErrorResponse();
        if (errorResponse != null) {
          _showErrorDialog(
            errorResponse.getUserFriendlyMessage(),
            title: errorResponse.getErrorTitle(),
            icon: errorResponse.getErrorIcon(),
            iconColor: errorResponse.getErrorColor(),
            failedCheck: errorResponse.failedCheck,
            errorCode: errorResponse.errorCode,
          );
        } else {
          _showErrorDialog(
            chargingController.errorMessage ?? "Failed to start charging",
          );
        }
        _resetScanner();
      }
    } catch (e) {
      print('\n❌ EXCEPTION: $e');
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog
        }
        _showErrorDialog(e.toString());
        _resetScanner();
      }
    }
  }

  // ========== ERROR DIALOG ==========
  void _showErrorDialog(
      String errorMessage, {
        String? title,
        IconData? icon,
        Color? iconColor,
        String? failedCheck,
        String? errorCode,
        List<ErrorAction>? actions,
      }) {
    // Use values from controller if not provided
    if (title == null && _scanValidationController.response != null) {
      title = _scanValidationController.response!.getErrorTitle();
      icon = _scanValidationController.response!.getErrorIcon();
      iconColor = _scanValidationController.response!.getErrorColor();
    }

    // Default values
    title ??= 'Charging Failed';
    icon ??= Icons.error_outline;
    iconColor ??= Colors.red;

    print('\n🔴 SHOWING ERROR DIALOG:');
    print('────────────────────────────────────────────────────────────');
    print('📝 Title: $title');
    print('📝 Message: $errorMessage');
    print('🔍 Failed Check: $failedCheck');
    print('🔑 Error Code: $errorCode');
    print('────────────────────────────────────────────────────────────');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor!.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  title!,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Message
                Text(
                  errorMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Buttons with actions support
                if (actions != null && actions.isNotEmpty)
                  ..._buildActionButtons(actions, context)
                else
                  _buildDefaultButtons(context),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildActionButtons(List<ErrorAction> actions, BuildContext context) {
    final List<Widget> buttons = [];

    for (var i = 0; i < actions.length; i++) {
      final action = actions[i];
      final isLast = i == actions.length - 1;

      if (action.isPrimary) {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleErrorAction(action.action);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolor.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                action.label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      } else {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleErrorAction(action.action);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                action.label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
        );
      }

      if (!isLast) {
        buttons.add(const SizedBox(height: 10));
      }
    }

    return buttons;
  }

  Widget _buildDefaultButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetScanner();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Try Again",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetScanner();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolor.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Scan Again",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleErrorAction(String action) {
    switch (action) {
      case 'recharge':
        Navigator.pushNamed(context, '/wallet');
        break;
      case 'connect_gun':
        _showConnectGunDialog();
        break;
      case 'try_another':
        _resetScanner();
        break;
      case 'retry':
        if (scannedData != null) {
          _navigateToVehicleScreen(scannedData!);
        } else {
          _resetScanner();
        }
        break;
      case 'go_back':
      default:
        _resetScanner();
        break;
    }
  }

  void _showConnectGunDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Connect Charging Gun'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Appcolor.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.power_outlined,
                  size: 48,
                  color: Appcolor.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please follow these steps:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildStepText('1', 'Connect the charging gun to your vehicle'),
              const SizedBox(height: 8),
              _buildStepText('2', 'Ensure the connector is properly locked'),
              const SizedBox(height: 8),
              _buildStepText('3', 'Tap "Try Again" to start charging'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetScanner();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (scannedData != null) {
                  _navigateToVehicleScreen(scannedData!);
                } else {
                  _resetScanner();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolor.green,
              ),
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepText(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Appcolor.green.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Appcolor.green,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ========== LIFECYCLE METHODS ==========
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (_hasPermission && mounted && !_isDisposing && cameraController != null && !_isStartingCamera) {
        _startCamera();
      } else if (_hasPermission && mounted && cameraController == null) {
        _initializeCamera();
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);
    _scanValidationController.dispose();
    _disposeCameraController();
    _scanAnimationController.dispose();
    _connectorIdController.dispose();
    _stationNameController.dispose();
    _chargerModelController.dispose();
    _serialNumberController.dispose();
    _powerRatingController.dispose();
    super.dispose();
  }

  // ========== NAVIGATION METHODS ==========
  void _onTabTapped(int index) async {
    if (index == _currentIndex) return;

    await _stopCamera();

    Widget page;
    switch (index) {
      case 0:
        page = const MapScreen();
        break;
      case 1:
        page = const ScannerPage();
        break;
      case 2:
        page = const PaymentScreen();
        break;
      case 3:
        page = ProfileScreen(isDarkMode: false, onToggle: () {});
        break;
      default:
        page = const MapScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _onScanTap() {
    print("Scan button tapped – already on scanner");
  }

  // ========== BUILD ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Scan QR Code",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          // Flash Toggle Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
                size: 18,
              ),
            ),
            onPressed: _toggleFlash,
          ),
          // Switch Camera Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cameraswitch, color: Colors.white, size: 18),
            ),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: !_hasPermission
          ? _buildPermissionDenied()
          : cameraController == null
          ? _buildInitializingCamera()
          : _buildScannerView(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onScanTap: _onScanTap,
      ),
    );
  }

  // ========== UI BUILDERS ==========
  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            "Camera permission required",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeCamera,
            style: ElevatedButton.styleFrom(
              backgroundColor: Appcolor.green,
            ),
            child: const Text("Grant Permission"),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializingCamera() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
          ),
          SizedBox(height: 16),
          Text(
            "Initializing camera...",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: cameraController!,
          onDetect: _handleScan,
        ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
              stops: const [0, 0.2, 0.8, 1],
            ),
          ),
        ),

        // Scan Area
        _buildScanArea(),

        // Scanning Animation
        if (isScanning && _isInitialized)
          _buildScanAnimation(),

        // Camera Starting Indicator
        if (_isStartingCamera && !_isInitialized)
          _buildCameraStarting(),

        // Manual Entry Section
        _buildManualEntry(),
      ],
    );
  }

  Widget _buildScanArea() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.15,
      left: 0,
      right: 0,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Appcolor.green.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            // Scan box
            Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Stack(
                children: [
                  // Top-left corner
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Appcolor.green, width: 3.5),
                          left: BorderSide(color: Appcolor.green, width: 3.5),
                        ),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
                      ),
                    ),
                  ),
                  // Top-right corner
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Appcolor.green, width: 3.5),
                          right: BorderSide(color: Appcolor.green, width: 3.5),
                        ),
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(16)),
                      ),
                    ),
                  ),
                  // Bottom-left corner
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Appcolor.green, width: 3.5),
                          left: BorderSide(color: Appcolor.green, width: 3.5),
                        ),
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                      ),
                    ),
                  ),
                  // Bottom-right corner
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Appcolor.green, width: 3.5),
                          right: BorderSide(color: Appcolor.green, width: 3.5),
                        ),
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanAnimation() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return Positioned(
          top: (MediaQuery.of(context).size.height * 0.15) + 20 + _scanAnimation.value,
          left: (MediaQuery.of(context).size.width / 2) - 115,
          child: Container(
            width: 230,
            height: 2.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Appcolor.green,
                  Appcolor.green.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Appcolor.green.withOpacity(0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraStarting() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
            ),
            SizedBox(height: 16),
            Text(
              "Starting camera...",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntry() {
    return Positioned(
      bottom: 30,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Manual Input Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _connectorIdController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: "Enter Connector ID",
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.ev_station, color: Appcolor.green, size: 20),
                // ✅ FIXED: Replace check icon with arrow icon
                suffixIcon: _isConnectorIdValid
                    ? GestureDetector(
                  onTap: _startChargingWithManualId,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Appcolor.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Start Charging Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isConnectorIdValid ? _startChargingWithManualId : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolor.green,
                disabledBackgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: Text(
                "Start Charging",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== ERROR ACTION CLASS ==========
class ErrorAction {
  final String label;
  final String action;
  final bool isPrimary;

  ErrorAction({
    required this.label,
    required this.action,
    this.isPrimary = false,
  });
}