import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../Controller/start_charging_controller.dart';
import '../../Controller/vehicle_controller.dart';
import '../../Model/vehicle_model.dart';
import '../../Theme/colors.dart';
import '../Login/Bottom.dart';
import '../Payment/paymentpage.dart';
import '../Profile/profile.dart';
import '../myev/myevs.dart';
import 'ChargingProgressPage.dart';
import 'mapui.dart';

class ScannerPage extends StatefulWidget {
  final Map<String, String>? chargerDetails;

  const ScannerPage({super.key, this.chargerDetails});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  MobileScannerController? cameraController;
  bool isScanning = true;
  String? scannedData;
  bool isFlashOn = false;
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isStartingCamera = false;
  bool _isDisposing = false;
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
  final TextEditingController _connectorIdController = TextEditingController();
  bool _isConnectorIdValid = false;

  final TextEditingController _stationNameController = TextEditingController();
  final TextEditingController _chargerModelController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _powerRatingController = TextEditingController();
  String _selectedChargerType = 'CCS2';
  String _selectedStatus = 'Available';

  final List<String> chargerTypes = ['CCS2', 'CHAdeMO', 'Type 2', 'GB/T', 'Tesla Supercharger'];
  final List<String> statusOptions = ['Available', 'Occupied', 'Maintenance', 'Offline'];

  int _currentIndex = 1;

  final VehicleController _vehicleController = VehicleController();
  List<Vehicle> _vehicles = [];
  bool _isLoadingVehicles = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0, end: 200).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );

    _connectorIdController.addListener(_validateConnectorId);

    if (widget.chargerDetails != null) {
      _chargerModelController.text = widget.chargerDetails!['chargerModel'] ?? '';
      _selectedChargerType = widget.chargerDetails!['chargerType'] ?? 'CCS2';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only reinitialize if coming back and controller is disposed
    if (_hasPermission && cameraController == null && mounted && !_isDisposing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeCamera();
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (_isDisposing || _isStartingCamera) return;

    // Request camera permission
    final status = await Permission.camera.request();

    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _hasPermission = true;
        });
      }

      // Dispose existing controller if any
      await _disposeCameraController();

      if (!mounted) return;

      // Create new controller with autoStart false to control manually
      cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
        autoStart: false, // Important: Don't auto start
      );

      if (mounted) {
        setState(() {});
        // Start camera after a short delay
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
    // Prevent multiple start attempts
    if (_isStartingCamera || _isDisposing || !mounted || cameraController == null) {
      print('⚠️ Cannot start camera: _isStartingCamera=$_isStartingCamera, _isDisposing=$_isDisposing, mounted=$mounted');
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
        print('✅ Camera started successfully');
      }
    } catch (e) {
      print('Error starting camera: $e');
      if (mounted && !_isDisposing) {
        setState(() {
          _isInitialized = false;
          _isStartingCamera = false;
        });
        // Don't retry automatically to avoid loops
      }
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

  void _validateConnectorId() {
    setState(() {
      _isConnectorIdValid = _connectorIdController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeCameraController();
    _scanAnimationController.dispose();
    _connectorIdController.dispose();
    _stationNameController.dispose();
    _chargerModelController.dispose();
    _serialNumberController.dispose();
    _powerRatingController.dispose();
    super.dispose();
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

  // Implement WidgetsBindingObserver method
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

  void _resetScanner() {
    setState(() {
      isScanning = true;
      scannedData = null;
    });
    _scanAnimationController.repeat(reverse: true);

    // Restart camera if needed
    if (!_isInitialized && cameraController != null && mounted && !_isStartingCamera && !_isDisposing) {
      _startCamera();
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

  void _handleScan(BarcodeCapture capture) {
    if (!isScanning || !mounted || !_isInitialized) return;

    final String? code = capture.barcodes.first.rawValue;
    if (code != null) {
      setState(() {
        isScanning = false;
        scannedData = code;
      });
      _scanAnimationController.stop();
      _stopCamera(); // Stop camera when scanning is done

      // Auto-fill the connector ID
      _connectorIdController.text = code;
      _validateConnectorId(); // Trigger validation

      // Directly start charging without showing dialog
      _startChargingDirectly(code);
    }
  }

  void _showScannedDialog(String qrData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(26)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Appcolor.green, Appcolor.green.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  "Station Found!",
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Appcolor.green.withOpacity(0.1), Appcolor.green.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Appcolor.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Connector ID",
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600, letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        qrData,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Appcolor.green),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          "Scan Again",
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Auto-fill the connector ID and start charging
                          _connectorIdController.text = qrData;
                          _validateConnectorId(); // Trigger validation
                          _startChargingDirectly(qrData);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Appcolor.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          "Start Charging",
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted && isScanning && !_isStartingCamera && !_isDisposing) {
        _initializeCamera();
      }
    });
  }

  void _startChargingDirectly(String stationId) async {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║              DIRECT CHARGING START - USING QR DATA            ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('\n📍 Scanned QR Data: $stationId');
    print('🔌 Charger ID from input: ${_connectorIdController.text.trim()}');

    String chargerId = _connectorIdController.text.trim();  // Keep as String, don't parse to int

    if (chargerId.isEmpty) {
      print('⚠️ No charger ID entered');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter charger ID first"),
            backgroundColor: Colors.red,
          ),
        );
        _resetScanner();
      }
      return;
    }

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
                  "Charger ID: $chargerId",  // Show the charger ID
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
      // IMPORTANT: Pass the charger ID as String, don't convert to int
      final chargingController = ChargingController();
      final success = await chargingController.startChargingSession(
        chargerId: chargerId,  // Pass directly as String
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (success && mounted) {
        // Print the response data that will be passed to next page
        print('\n📤 DATA PASSING TO CHARGING PROGRESS PAGE:');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('Session ID: ${chargingController.currentSession?.data?.sessionId}');
        print('Transaction ID: ${chargingController.currentSession?.data?.transactionId}');
        print('Started At: ${chargingController.currentSession?.data?.startedAt}');
        print('Charger: ${chargingController.currentSession?.data?.charger.name}');
        print('Charger ID: ${chargingController.currentSession?.data?.charger.id}');  // This will show "Evt-0D76C0"
        print('Connector: ${chargingController.currentSession?.data?.connector.name} (${chargingController.currentSession?.data?.connector.type})');
        print('Station: ${chargingController.currentSession?.data?.station.name}');
        print('Location: ${chargingController.currentSession?.data?.station.location.city}');
        print('Cost: ${chargingController.currentSession?.data?.pricing.estimatedCostPerKwh} ${chargingController.currentSession?.data?.pricing.currency}/kWh');
        print('User: ${chargingController.currentSession?.data?.user.name}');
        print('Wallet Balance: ${chargingController.currentSession?.data?.user.walletBalance}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

        Map<String, dynamic> chargingDetails = {
          'stationId': chargerId,  // Now this is the actual charger ID string
          'vehicleId': 'direct_charging',
          'vehicleName': 'EV Vehicle',
          'manufacturer': 'Electric Vehicle',
          'model': 'EV Model',
          'registrationNumber': 'EV-001',
          'chargerModel': _chargerModelController.text.isNotEmpty
              ? _chargerModelController.text
              : widget.chargerDetails?['chargerModel'] ?? 'Standard Charger',
          'chargerType': _selectedChargerType,
          'sessionId': chargingController.currentSession?.data?.sessionId,
          'transactionId': chargingController.currentSession?.data?.transactionId,
          'startedAt': chargingController.currentSession?.data?.startedAt,
          'chargerInfo': chargingController.currentSession?.data?.charger,
          'connectorInfo': chargingController.currentSession?.data?.connector,
          'stationInfo': chargingController.currentSession?.data?.station,
          'pricingInfo': chargingController.currentSession?.data?.pricing,
        };

        if (mounted) {
          // Stop camera before navigating
          await _stopCamera();

          // Navigate to charging progress page
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
        // Show error dialog with the actual error message
        String errorTitle = "Charging Failed";
        IconData errorIcon = Icons.error_outline;
        Color errorColor = Colors.red;

        // Get detailed error message from controller
        String errorMessage = chargingController.errorMessage ?? "Unknown error occurred";

        // Parse specific error messages
        if (errorMessage.contains("charger id is invalid") ||
            errorMessage.contains("The selected charger id is invalid")) {
          errorTitle = "Invalid Charger ID";
          errorIcon = Icons.qr_code_scanner;
          errorColor = Colors.orange;
          errorMessage = "The charger ID '$chargerId' is invalid. Please check and try again.";
        } else if (errorMessage.contains("already in use")) {
          errorTitle = "Charger Unavailable";
          errorIcon = Icons.ev_station;
          errorColor = Colors.orange;
          errorMessage = "This charger is currently in use. Please try another charger.";
        } else if (errorMessage.contains("401") || errorMessage.contains("unauthorized")) {
          errorTitle = "Session Expired";
          errorIcon = Icons.lock_outline;
          errorColor = Colors.red;
          errorMessage = "Your session has expired. Please login again.";
        }

        // Show error dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        errorIcon,
                        color: errorColor,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      errorTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: errorColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        errorMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _connectorIdController.clear();
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
                              "Scan Again",
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
                              "Try Again",
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
                ),
              ),
            );
          },
        ).then((_) {
          if (mounted) {
            _resetScanner();
          }
        });
      }
    } catch (e) {
      print('\n❌ EXCEPTION: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if open
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Error",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Failed to start charging: ${e.toString()}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _resetScanner();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolor.green,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Try Again",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ).then((_) {
          if (mounted) {
            _resetScanner();
          }
        });
      }
    }
  }

  void _startChargingWithManualId() {
    String chargerId = _connectorIdController.text.trim();
    if (chargerId.isNotEmpty) {
      print('🔌 Manual charger ID entered: $chargerId');
      _startChargingDirectly(chargerId);  // Pass directly as String
    }
  }

  void _onTabTapped(int index) async {
    if (index == _currentIndex) return;

    // Stop camera before navigating
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
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 18),
            ),
            onPressed: _toggleFlash,
          ),
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
          ? Center(
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
      )
          : cameraController == null
          ? const Center(
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
      )
          : Stack(
        children: [
          MobileScanner(
            controller: cameraController!,
            onDetect: _handleScan,
          ),

          // Gradient overlay
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

          // Scanner frame
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: Appcolor.green.withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                  ),
                  Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Stack(
                      children: [
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
          ),

          // Scanning animation line
          if (isScanning && _isInitialized)
            AnimatedBuilder(
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
                        colors: [Colors.transparent, Appcolor.green, Appcolor.green.withOpacity(0.7), Colors.transparent],
                      ),
                      boxShadow: [BoxShadow(color: Appcolor.green.withOpacity(0.8), blurRadius: 8)],
                    ),
                  ),
                );
              },
            ),

          // Instruction chip
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15 + 260,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Appcolor.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Align QR code within frame",
                      style: GoogleFonts.poppins(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay when camera is starting
          if (_isStartingCamera && !_isInitialized)
            Container(
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
            ),

          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Enter Charger ID",
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.ev_station, color: Appcolor.green, size: 20),
                      suffixIcon: _isConnectorIdValid
                          ? Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Appcolor.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
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
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onScanTap: _onScanTap,
      ),
    );
  }
}


