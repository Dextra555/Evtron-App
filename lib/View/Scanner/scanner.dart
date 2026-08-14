import 'dart:async';
import 'package:evtron/Controller/scan_validation_controller.dart';
import 'package:evtron/View/Scanner/vehiclelist.dart';
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
import 'ChargingProgressPage.dart';
import '../Home/mapui.dart';

class ScannerPage extends StatefulWidget {
  final Map<String, String>? chargerDetails;

  const ScannerPage({super.key, this.chargerDetails});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static Future<void> _previousControllerShutdown = Future.value();

  MobileScannerController? cameraController;
  bool isScanning = true;
  String? scannedData;
  bool isFlashOn = false;
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isStartingCamera = false;
  bool _isDisposing = false;
  Future<void> _cameraLifecycleFuture = Future.value();

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

  // final List<String> chargerTypes = [
  //   'CCS2',
  //   'CHAdeMO',
  //   'Type 2',
  //   'GB/T',
  //   'Tesla Supercharger',
  // ];
  // final List<String> statusOptions = [
  //   'Available',
  //   'Occupied',
  //   'Maintenance',
  //   'Offline',
  // ];

  int _currentIndex = 1;

  final VehicleController _vehicleController = VehicleController();
  List<Vehicle> _vehicles = [];
  bool _isLoadingVehicles = false;

  late ScanValidationController _scanValidationController;

  int? _connectorId;
  int? _vehicleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scanValidationController = ScanValidationController();

    _loadVehicles();

    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0, end: 200).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _connectorIdController.addListener(_validateConnectorId);

    if (widget.chargerDetails != null) {
      _chargerModelController.text =
          widget.chargerDetails!['chargerModel'] ?? '';
      _selectedChargerType = widget.chargerDetails!['chargerType'] ?? 'CCS2';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }


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


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasPermission &&
        cameraController == null &&
        mounted &&
        !_isDisposing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeCamera();
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (_isDisposing) return;

    await _runCameraLifecycle(() async {
      final status = await Permission.camera.request();

      if (!mounted || _isDisposing) return;

      if (status.isGranted) {
        setState(() {
          _hasPermission = true;
        });

        await _previousControllerShutdown;

        if (cameraController != null) {
          if (cameraController!.value.isRunning) {
            setState(() {
              _isInitialized = true;
              _isStartingCamera = false;
            });
            return;
          }
          await _stopCameraInternal();
          await _disposeCameraControllerInternal();
        }

        if (!mounted || _isDisposing) return;

        cameraController = MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back,
          torchEnabled: false,
          autoStart: false,
        );

        if (mounted) {
          setState(() {});
        }

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && cameraController != null && !_isDisposing) {
          await _startCameraInternal();
        }
      } else {
        setState(() {
          _hasPermission = false;
        });
        _showPermissionDeniedDialog();
      }
    });
  }

  Future<void> _startCamera() async {
    await _runCameraLifecycle(() => _startCameraInternal());
  }

  Future<void> _startCameraInternal() async {
    if (_isDisposing || !mounted || cameraController == null) {
      return;
    }

    if (cameraController!.value.isRunning || cameraController!.value.isStarting) {
      if (mounted && !_isDisposing) {
        setState(() {
          _isInitialized = cameraController!.value.isInitialized;
          _isStartingCamera = false;
        });
      }
      return;
    }

    if (mounted && !_isDisposing) {
      setState(() {
        _isStartingCamera = true;
      });
    }

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
    await _runCameraLifecycle(() async {
      await _stopCameraInternal();
    });
  }

  Future<void> _stopCameraInternal() async {
    if (cameraController == null) {
      if (mounted && !_isDisposing) {
        setState(() {
          _isInitialized = false;
        });
      }
      return;
    }

    if (!cameraController!.value.isRunning && !cameraController!.value.isInitialized && !cameraController!.value.isStarting) {
      if (mounted && !_isDisposing) {
        setState(() {
          _isInitialized = false;
        });
      }
      return;
    }

    try {
      await cameraController!.stop();
    } catch (e) {
      print('Error stopping camera: $e');
    } finally {
      if (mounted && !_isDisposing) {
        setState(() {
          _isInitialized = false;
          _isStartingCamera = false;
        });
      }
    }
  }

  Future<void> _disposeCameraController() async {
    await _runCameraLifecycle(() async {
      await _disposeCameraControllerInternal();
    });
  }

  Future<void> _disposeCameraControllerInternal() async {
    final controller = cameraController;
    cameraController = null;
    _isInitialized = false;
    _isStartingCamera = false;

    if (controller == null) {
      return;
    }

    try {
      await controller.stop();
      await controller.dispose();
    } catch (e) {
      print('Error disposing camera: $e');
    }
  }

  Future<void> _runCameraLifecycle(Future<void> Function() operation) {
    final current = _cameraLifecycleFuture;
    final next = current.then((_) => operation(), onError: (_, __) => operation());
    _cameraLifecycleFuture = next.catchError((_) {});
    return next;
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
        content: const Text(
          "Camera permission is needed to scan QR codes. Please grant permission to continue.",
        ),
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

  void _handleScan(BarcodeCapture capture) {
    if (!isScanning || !mounted || !_isInitialized || cameraController == null || !cameraController!.value.isRunning) return;

    final String? code = capture.barcodes.first.rawValue;
    if (code != null) {
      final String upperCode = code.toUpperCase();
      print('✅ QR Code Scanned: $upperCode');
      setState(() {
        isScanning = false;
        scannedData = upperCode;
      });
      _scanAnimationController.stop();
    unawaited(_stopCamera());
      _connectorIdController.text = upperCode;
      _validateConnectorId();

      _navigateToVehicleScreen(upperCode);
    }
  }

  void _pauseScannerForError() {
    if (!mounted || _isDisposing) return;

    setState(() {
      isScanning = false;
      scannedData = null;
    });
    _scanAnimationController.stop();
    unawaited(_stopCamera());
  }

  Future<void> _resumeScanner() async {
    if (!mounted || _isDisposing) return;

    setState(() {
      isScanning = true;
      scannedData = null;
    });
    _scanAnimationController.repeat(reverse: true);

    if (_hasPermission &&
        cameraController != null &&
        mounted &&
        !_isStartingCamera &&
        !_isDisposing) {
      await _startCamera();
    }
  }

  void _resetScanner() {
    setState(() {
      isScanning = true;
      scannedData = null;
    });
    _scanAnimationController.repeat(reverse: true);

    if (_hasPermission &&
        cameraController != null &&
        mounted &&
        !_isStartingCamera &&
        !_isDisposing) {
      unawaited(_startCamera());
    }
  }

  void _validateConnectorId() {
    setState(() {
      _isConnectorIdValid = _connectorIdController.text.trim().isNotEmpty;
    });
  }

  void _startChargingWithManualId() {
    String connectorId = _connectorIdController.text.trim().toUpperCase();
    if (connectorId.isNotEmpty) {
      print('Manual connector ID entered: $connectorId');
      _navigateToVehicleScreen(connectorId);
    }
  }

  int _extractConnectorId(String connectorUid) {
    try {
      final parts = connectorUid.split('.');
      if (parts.length >= 2) {
        final lastPart = parts.last;
        return int.tryParse(lastPart) ?? 0;
      }
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

  Future<void> _navigateToVehicleScreen(String scannedData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
          _pauseScannerForError();
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
                  : widget.chargerDetails?['chargerModel'] ??
                        'Standard Charger',
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
        _pauseScannerForError();
      }
    } catch (e) {
      print('\n❌ EXCEPTION during validation: $e');
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _showErrorDialog('An unexpected error occurred. Please try again.');
        _pauseScannerForError();
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
        Navigator.pop(context);
      }

      if (success &&
          mounted &&
          chargingController.currentSession?.data != null) {
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
              builder: (context) =>
                  ChargingProgressPage(chargingDetails: chargingDetails),
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
    title ??= '';
    icon ??= Icons.error_outline;
    iconColor ??= Colors.red;

    print('\n🔴 SHOWING ERROR DIALOG:');
    print('────────────────────────────────────────────────────────────');
    print('📝 Title: $title');
    print('📝 Message: $errorMessage');
    print('🔍 Failed Check: $failedCheck');
    print('🔑 Error Code: $errorCode');
    print('────────────────────────────────────────────────────────────');

    _pauseScannerForError();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                  child: Icon(icon, color: iconColor, size: 48),
                ),
                const SizedBox(height: 20),

                // Title
                if (title != null && title!.trim().isNotEmpty) ...[
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
                ],

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

  List<Widget> _buildActionButtons(
    List<ErrorAction> actions,
    BuildContext context,
  ) {
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          _resumeScanner();
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
        _resumeScanner();
        break;
      case 'retry':
        if (scannedData != null) {
          _navigateToVehicleScreen(scannedData!);
        } else {
          _resumeScanner();
        }
        break;
      case 'go_back':
      default:
        Navigator.maybePop(context);
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
              style: ElevatedButton.styleFrom(backgroundColor: Appcolor.green),
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
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13))),
      ],
    );
  }

  // ========== LIFECYCLE METHODS ==========
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_stopCamera());
    } else if (state == AppLifecycleState.resumed) {
      if (_hasPermission && mounted && !_isDisposing) {
        if (cameraController != null && !cameraController!.value.isRunning && !cameraController!.value.isStarting) {
          unawaited(_startCamera());
        } else if (cameraController == null) {
          unawaited(_initializeCamera());
        }
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);
    _scanValidationController.dispose();
    _previousControllerShutdown = _previousControllerShutdown.whenComplete(_disposeCameraController);
    unawaited(_previousControllerShutdown);
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
              child: const Icon(
                Icons.cameraswitch,
                color: Colors.white,
                size: 18,
              ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Appcolor.green),
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
          Text("Initializing camera...", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(controller: cameraController!, onDetect: _handleScan),

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
        if (isScanning && _isInitialized) _buildScanAnimation(),

        // Camera Starting Indicator
        if (_isStartingCamera && !_isInitialized) _buildCameraStarting(),

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
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                        ),
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
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                        ),
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
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                        ),
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
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(16),
                        ),
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
          top:
              (MediaQuery.of(context).size.height * 0.15) +
              20 +
              _scanAnimation.value,
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
            Text("Starting camera...", style: TextStyle(color: Colors.white)),
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
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              onChanged: (value) {
                if (value != value.toUpperCase()) {
                  _connectorIdController.value = TextEditingValue(
                    text: value.toUpperCase(),
                    selection: TextSelection.collapsed(
                      offset: value.toUpperCase().length,
                    ),
                  );
                  _validateConnectorId();
                }
              },
              decoration: InputDecoration(
                hintText: "Enter Connector ID",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  Icons.ev_station,
                  color: Appcolor.green,
                  size: 20,
                ),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isConnectorIdValid
                  ? _startChargingWithManualId
                  : null,
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


