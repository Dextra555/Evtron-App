import 'package:evtron/View/Scanner/scanner.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../Controller/invoice_controller.dart';
import '../../Controller/live_charging_controller.dart';
import '../../Controller/stop_charging_controller.dart';
import '../../Model/live_charging_model.dart';
import '../../Model/stop_charging_model.dart';
import '../../Service/charging_session_service.dart';
import '../../Service/active_session_service.dart';
import '../../Service/invoice_pdf_service.dart';
import '../../Service/invoice_service.dart';
import '../../Theme/colors.dart';
import 'invoice_bottom_sheet.dart';
import 'charging_progress_page_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Home/mapui.dart';

class ChargingProgressPage extends StatefulWidget {
  final Map<String, dynamic>? chargingDetails;

  const ChargingProgressPage({super.key, this.chargingDetails});

  @override
  State<ChargingProgressPage> createState() => _ChargingProgressPageState();
}

class _ChargingProgressPageState extends State<ChargingProgressPage>
    with WidgetsBindingObserver {
  late LiveChargingController _liveChargingController;
  final StopChargingController _stopChargingController =
      StopChargingController();
  final InvoiceController _invoiceController = InvoiceController();

  Timer? _durationTimer;
  Timer? _pollingTimer;
  Timer? _refreshTimer;
  Duration _currentDuration = Duration.zero;
  DateTime? _sessionStartTime;
  Duration _elapsedBaseDuration = Duration.zero;
  DateTime? _lastElapsedUpdateTime;
  String _vehicleName = "";
  String _registrationNumber = "";
  bool _isSessionCompleted = false;
  bool _isRecovering = false;
  bool _isLoadingDialogShowing = false;
  bool _isInvoiceSheetShowing = false;
  bool _invoiceFetchCompleted = false;
  bool _isHandlingNetworkInterruption = false;
  bool _retryLoopActive = false;
  StreamSubscription? _connectivitySubscription;

  int? _currentSessionId;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  bool _isMounted = false;
  Timer? _uiDebounceTimer;

  int _safeToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) {
      if (value.isNaN || value.isInfinite) {
        return defaultValue;
      }
      return value.toInt();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        if (parsed.isNaN || parsed.isInfinite) {
          return defaultValue;
        }
        return parsed.toInt();
      }
      return defaultValue;
    }
    return defaultValue;
  }

  double _safeToDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) {
      if (value.isNaN || value.isInfinite) {
        return defaultValue;
      }
      return value;
    }
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        if (parsed.isNaN || parsed.isInfinite) {
          return defaultValue;
        }
        return parsed;
      }
      return defaultValue;
    }
    return defaultValue;
  }

  bool _isValidDuration(Duration duration) {
    try {
      final seconds = duration.inSeconds;
      if (seconds.isNaN || seconds.isInfinite) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  String getDisplayStatus() {
    if (_liveChargingController.currentLiveData == null) return "Charging";
    final data = _liveChargingController.currentLiveData!;
    if (data.isSuspended) return "SUSPENDED ⏸️";
    if (data.isFinishing) return "FINISHING ⏳";
    if (data.isCharging) return "CHARGING ⚡";
    if (data.isCompleted) return "COMPLETED ✅";
    if (data.hasError) return "INTERRUPTED ❌";
    if (data.isPreparing) return "PREPARING 🔄";
    return data.phase.toUpperCase();
  }

  Color getStatusColor() {
    if (_liveChargingController.currentLiveData == null) return Colors.grey;
    final data = _liveChargingController.currentLiveData!;
    if (data.isSuspended) return Colors.orange;
    if (data.isFinishing) return Colors.blue;
    if (data.isCharging) return Appcolor.green;
    if (data.isCompleted) return Appcolor.green;
    if (data.hasError) return Colors.red;
    if (data.isPreparing) return Colors.amber;
    return Colors.grey;
  }

  // ==================== VEHICLE DATA LOADING ====================

  /// ✅ Load vehicle details from storage (same pattern as session ID)
  Future<void> _loadVehicleDetailsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get session ID
      int? sessionId =
          widget.chargingDetails?['sessionId'] ??
          prefs.getInt('active_session_id') ??
          prefs.getInt('session_id');

      String vehicleName = '';
      String registration = '';

      // ✅ 1. Try session-specific vehicle details first (most reliable)
      if (sessionId != null && sessionId > 0) {
        vehicleName =
            prefs.getString('session_${sessionId}_vehicle_name') ?? '';
        registration =
            prefs.getString('session_${sessionId}_vehicle_registration') ?? '';
      }

      // ✅ 2. Fallback to generic vehicle details
      if (vehicleName.isEmpty) {
        vehicleName = prefs.getString('vehicle_name') ?? 'Unknown Vehicle';
        registration = prefs.getString('vehicle_registration') ?? 'N/A';
      }

      // ✅ 3. Fallback to widget details
      if (vehicleName == 'Unknown Vehicle' && widget.chargingDetails != null) {
        final widgetName =
            widget.chargingDetails!['vehicleName']?.toString() ?? '';
        final widgetRegistration =
            widget.chargingDetails!['registrationNumber']?.toString() ?? '';
        if (widgetName.isNotEmpty) {
          vehicleName = widgetName;
          registration = widgetRegistration.isNotEmpty
              ? widgetRegistration
              : 'N/A';
        }
      }

      setState(() {
        _vehicleName = vehicleName;
        _registrationNumber = registration;
      });

      print('✅ Vehicle details loaded from storage:');
      print('   Vehicle: $vehicleName');
      print('   Registration: $registration');
      print('   Session ID: ${sessionId ?? 'null'}');
    } catch (e) {
      print('⚠️ Error loading vehicle details from storage: $e');
    }
  }

  /// ✅ Save vehicle details to storage (for persistence)
  Future<void> _saveVehicleDetailsToStorage({
    required int sessionId,
    required String vehicleName,
    required String registrationNumber,
    required String manufacturer,
    required String model,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save generic vehicle details
      await prefs.setString('vehicle_name', vehicleName);
      await prefs.setString('vehicle_registration', registrationNumber);
      await prefs.setString('vehicle_manufacturer', manufacturer);
      await prefs.setString('vehicle_model', model);

      // ✅ Save session-specific vehicle details (keyed by session ID)
      await prefs.setString('session_${sessionId}_vehicle_name', vehicleName);
      await prefs.setString(
        'session_${sessionId}_vehicle_registration',
        registrationNumber,
      );
      await prefs.setString(
        'session_${sessionId}_vehicle_manufacturer',
        manufacturer,
      );
      await prefs.setString('session_${sessionId}_vehicle_model', model);

      print('✅ Vehicle details saved to storage:');
      print('   Session ID: $sessionId');
      print('   Vehicle: $vehicleName');
      print('   Registration: $registrationNumber');
    } catch (e) {
      print('❌ Error saving vehicle details: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);

    print('\n🔍 ========== CHARGING PROGRESS PAGE INIT ==========');
    print('📋 Charging Details:');
    print('   Session ID: ${widget.chargingDetails?['sessionId']}');
    print('   Vehicle Name: ${widget.chargingDetails?['vehicleName']}');
    print('   Status: ${widget.chargingDetails?['status']}');
    print('   Phase: ${widget.chargingDetails?['phase']}');
    print('==========================================\n');

    if (widget.chargingDetails != null) {
      print('📋 Full charging details:');
      widget.chargingDetails!.forEach((key, value) {
        print('   $key: $value');
      });
    }

    // ✅ Load vehicle details from storage FIRST
    _loadVehicleDetailsFromStorage();

    // ✅ If widget has vehicle details, save them to storage
    if (widget.chargingDetails != null) {
      final sessionId = widget.chargingDetails!['sessionId'];
      final vehicleName =
          widget.chargingDetails!['vehicleName']?.toString() ?? '';
      final registration =
          widget.chargingDetails!['registrationNumber']?.toString() ?? '';
      final manufacturer =
          widget.chargingDetails!['manufacturer']?.toString() ?? '';
      final model = widget.chargingDetails!['model']?.toString() ?? '';

      if (sessionId != null && sessionId > 0 && vehicleName.isNotEmpty) {
        _saveVehicleDetailsToStorage(
          sessionId: sessionId,
          vehicleName: vehicleName,
          registrationNumber: registration,
          manufacturer: manufacturer,
          model: model,
        );
      }

      // Set initial values from widget if storage didn't have them
      if (vehicleName.isNotEmpty && _vehicleName.isEmpty) {
        _vehicleName = vehicleName;
        _registrationNumber = registration.isNotEmpty ? registration : 'N/A';
      }
    }

    _liveChargingController = LiveChargingController();

    int? sessionId = widget.chargingDetails?['sessionId'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted) return;
      _showLoadingDialog();
      _initializeSession(sessionId);
    });

    _liveChargingController.addListener(_onControllerUpdate);
    _startDurationTimer();
    _startAutoRefreshTimer();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      print('📡 Connectivity changed: hasConnection=$hasConnection');
      if (hasConnection && _isMounted && mounted && !_isSessionCompleted) {
        _liveChargingController.resetNetworkFailures();

        if (_retryLoopActive) {
          print(
            '📡 Internet returned during retry loop - dismissing dialog and checking session',
          );
          _retryLoopActive = false;
          _hideLoadingDialog();
          _isHandlingNetworkInterruption = false;
          _checkSessionAndRecoverWithRetries();
          return;
        }

        if (_currentSessionId != null) {
          print('📡 Re-fetching after connectivity change');
          _liveChargingController.startPolling(sessionId: _currentSessionId);
        }
      }
    });
  }

  void _initializeSession(int? sessionId) {
    if (sessionId != null && sessionId > 0) {
      print('✅ Valid session ID found: $sessionId');
      _fetchFullDataAndStartPolling(sessionId);
    } else {
      print('⚠️ No valid session ID. Will poll for active session...');
      _recoverAndStartPolling();
    }
  }

  // ==================== LIFECYCLE MANAGEMENT ====================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_isMounted) return;
    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App resumed - refreshing charging status');
        if (_currentSessionId != null && !_isSessionCompleted) {
          if (_liveChargingController.pollingStoppedByNetwork) {
            print('📱 App resumed with stopped polling - restarting');
            _liveChargingController.resetNetworkFailures();
            _liveChargingController.startPolling(sessionId: _currentSessionId);
          } else {
            _liveChargingController.fetchLiveChargingStatus(
              sessionId: _currentSessionId,
            );
          }
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        print('📱 App paused - reducing activity');
        _liveChargingController.onAppPaused();
        break;
      case AppLifecycleState.detached:
        print('📱 App detached - cleaning up');
        _liveChargingController.onAppPaused();
        break;
    }
  }

  void _showLoadingDialog() {
    if (_isLoadingDialogShowing) return;
    if (!_isMounted) return;
    if (!mounted) return;

    _isLoadingDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
                ),
                const SizedBox(height: 20),
                Text(
                  "Loading Please wait...",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Appcolor.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please wait while we connect to the charger...",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "This may take a few moments",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Please ensure the connector is properly plugged in",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    _hideLoadingDialog();
                    if (_isMounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (!_isLoadingDialogShowing) return;
    _isLoadingDialogShowing = false;
    if (_isMounted) {
      try {
        Navigator.pop(context);
      } catch (e) {
        // Dialog might already be dismissed
      }
    }
  }

  void _updateLoadingDialogMessage(String message) {
    print('📱 Loading message: $message');
  }

  void _showInvoiceBottomSheet() {
    if (_isInvoiceSheetShowing) return;
    _invoiceFetchCompleted = false;
    _isInvoiceSheetShowing = true;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
                ),
                SizedBox(height: 16),
                Text(
                  'Generating invoice...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Please wait while we prepare your invoice',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isInvoiceSheetShowing = false;
    });

    // Fetch invoice data with retry
    _fetchInvoiceData(maxRetries: 15, retryDelaySeconds: 2).then((_) {
      _invoiceFetchCompleted = true;
      // Close the loading bottom sheet
      try {
        if (_isMounted) {
          Navigator.pop(context);
          // Small delay to let Navigator settle before pushing new route
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_isMounted) {
              _isInvoiceSheetShowing = false;
              _showInvoiceSheet();
            }
          });
          return;
        }
      } catch (e) {
        print('⚠️ Could not close loading sheet: $e');
      }

      // If pop failed or widget unmounted, still try to show invoice
      _isInvoiceSheetShowing = false;
      _showInvoiceSheet();
    }).catchError((error) {
      _invoiceFetchCompleted = true;
      print('❌ Invoice fetch error: $error');
      _isInvoiceSheetShowing = false;
      try { if (_isMounted) Navigator.pop(context); } catch (_) {}
      _showInvoiceSheet();
    });

    // Safety timeout: if invoice fetch takes >30s, force close loading sheet
    Future.delayed(const Duration(seconds: 30), () {
      if (!_isMounted || _invoiceFetchCompleted) return;
      print('⏰ Invoice fetch timeout - force showing invoice sheet');
      _isInvoiceSheetShowing = false;
      try { if (_isMounted) Navigator.pop(context); } catch (_) {}
      _showInvoiceSheet();
    });
  }

  void _showInvoiceSheet() {
    if (!_isMounted) return;
    if (_isInvoiceSheetShowing) return;

    _isInvoiceSheetShowing = true;
    print('📋 Showing invoice bottom sheet');

    try {
      showModalBottomSheet(
        context: context,
        isDismissible: true,
        enableDrag: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return InvoiceBottomSheet(
            invoiceController: _invoiceController,
            onClosed: () {
              _isInvoiceSheetShowing = false;
              _navigateToScanner();
            },
          );
        },
      ).then((_) {
        _isInvoiceSheetShowing = false;
        if (_isMounted) {
          _navigateToScanner();
        }
      });
    } catch (e) {
      print('❌ Error showing invoice sheet: $e');
      _isInvoiceSheetShowing = false;
    }
  }

  void _showNetworkInterruptedDialog() {
    if (_isLoadingDialogShowing || !_isMounted || !mounted) return;

    _isLoadingDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
                  'Network Interrupted',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Appcolor.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Waiting for connection to recover...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We will recheck the charging session once the internet is back.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleNetworkInterruptionAndRetry() async {
    if (!_isMounted || !mounted || _isHandlingNetworkInterruption) return;
    _isHandlingNetworkInterruption = true;
    _retryLoopActive = true;

    _refreshTimer?.cancel();
    _refreshTimer = null;
    _durationTimer?.cancel();
    _liveChargingController.stopPolling();
    stopPolling();
    _hideLoadingDialog();
    _showNetworkInterruptedDialog();

    final deadline = DateTime.now().add(const Duration(seconds: 30));
    int attempt = 0;

    while (DateTime.now().isBefore(deadline) &&
        !_isSessionCompleted &&
        _retryLoopActive &&
        _isMounted &&
        mounted) {
      attempt++;

      // Check connectivity every attempt (fast, ~50ms)
      try {
        final results = await Connectivity().checkConnectivity();
        final hasConnection = results.any((r) => r != ConnectivityResult.none);

        if (hasConnection) {
          print('📡 Retry attempt $attempt: network is back! Recovering...');
          _retryLoopActive = false;
          _hideLoadingDialog();
          _isHandlingNetworkInterruption = false;
          await _checkSessionAndRecoverWithRetries();
          return;
        }
      } catch (e) {
        print('⚠️ Connectivity check error on attempt $attempt: $e');
      }

      await Future.delayed(const Duration(seconds: 3));
    }

    if (!_isMounted || !mounted) {
      _retryLoopActive = false;
      _isHandlingNetworkInterruption = false;
      return;
    }

    _retryLoopActive = false;
    _hideLoadingDialog();

    if (_isMounted && mounted) {
      print('📡 Retry loop expired - navigating to map');
      _navigateToMapScreen();
    }
    _isHandlingNetworkInterruption = false;
  }


  Future<void> _fetchInvoiceData({
    int maxRetries = 10,
    int retryDelaySeconds = 2,
  }) async {
    try {
      // Get session ID from multiple sources
      int? sessionId = _currentSessionId;

      if (sessionId == null || sessionId <= 0) {
        sessionId = widget.chargingDetails?['sessionId'];
      }

      if (sessionId == null || sessionId <= 0) {
        sessionId = _stopChargingController.stopResponse?.data?.sessionId;
      }

      if (sessionId == null || sessionId <= 0) {
        final prefs = await SharedPreferences.getInstance();
        sessionId = prefs.getInt('session_id');
      }

      if (sessionId == null || sessionId <= 0) {
        print('⚠️ No session ID available for invoice');
        if (_isMounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No session ID found for invoice'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      print('📋 Fetching invoice for session: $sessionId');

      int retryCount = 0;
      bool success = false;

      while (retryCount < maxRetries && !success) {
        try {
          success = await _invoiceController.fetchInvoice(sessionId);

          if (success && _invoiceController.invoiceResponse != null) {
            print('✅ Invoice fetched successfully');
            print(
              '   Invoice #: ${_invoiceController.invoiceResponse?.data.invoiceNumber}',
            );
            print(
              '   Total: ${_invoiceController.invoiceResponse?.data.billing.total}',
            );
            break;
          }

          final errorMsg = _invoiceController.errorMessage ?? '';
          if (InvoiceService.shouldRetryInvoiceRequest(errorMsg)) {
            retryCount++;
            print(
              '⏳ Session not completed yet, retrying in ${retryDelaySeconds}s... (Attempt $retryCount/$maxRetries)',
            );

            if (_isMounted && retryCount <= maxRetries) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Waiting for session to complete... ($retryCount/$maxRetries)',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: retryDelaySeconds),
                ),
              );
            }

            await Future.delayed(Duration(seconds: retryDelaySeconds));
          } else {
            print(
              '⚠️ Failed to fetch invoice: ${_invoiceController.errorMessage}',
            );
            break;
          }
        } catch (e) {
          print('❌ Error fetching invoice (attempt $retryCount): $e');
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: retryDelaySeconds));
          }
        }
      }

      if (!success && _isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice not ready yet. Please try again later.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error fetching invoice: $e');
    }
  }

  void _startPolling(int sessionId) {
    _currentSessionId = sessionId;
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;

    _pollingTimer?.cancel();
    _refreshTimer?.cancel();

    _liveChargingController.startPolling(
      sessionId: sessionId,
      interval: const Duration(seconds: 10),
    );
    _startAutoRefreshTimer();
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _liveChargingController.stopPolling();
  }

  Future<void> _fetchFullDataAndStartPolling(int sessionId) async {
    if (!_isMounted) return;

    setState(() {
      _isRecovering = true;
    });

    try {
      print('📡 Fetching full session data for ID: $sessionId');
      await ChargingSessionService.saveSessionIdOnly(sessionId);
      print('💾 Session ID saved to SharedPreferences: $sessionId');

      final success = await _liveChargingController.fetchLiveChargingStatus(
        sessionId: sessionId,
      );

      if (!_isMounted) return;

      if (success && _liveChargingController.currentLiveData != null) {
        print('✅ Full session data fetched successfully');
        final liveData = _liveChargingController.currentLiveData!;

        if (liveData.sessionId != sessionId) {
          print(
            '⚠️ Session mismatch: expected $sessionId, got ${liveData.sessionId}',
          );
          _recoverAndStartPolling();
          return;
        }

        _saveSessionDataInBackground(liveData);

        // ✅ Update vehicle details from live data if available
        if (liveData.vehicle != null) {
          final manufacturer = liveData.vehicle?.manufacturer ?? '';
          final model = liveData.vehicle?.model ?? '';
          final registration = liveData.vehicle?.registrationNumber ?? '';
          final vehicleName = '$manufacturer $model'.trim();

          if (vehicleName.isNotEmpty) {
            setState(() {
              _vehicleName = vehicleName;
              _registrationNumber = registration.isNotEmpty
                  ? registration
                  : 'N/A';
            });

            // ✅ Save to storage for persistence
            await _saveVehicleDetailsToStorage(
              sessionId: sessionId,
              vehicleName: vehicleName,
              registrationNumber: registration,
              manufacturer: manufacturer,
              model: model,
            );
          }
        }

        if (liveData.isCompleted) {
          print('⚠️ Session is already completed');
          _isSessionCompleted = true;
          _liveChargingController.stopPolling();
          _hideLoadingDialog();
          _showInvoiceBottomSheet();
          return;
        }

        _hideLoadingDialog();
        _startPolling(sessionId);
      } else {
        print('❌ Failed to fetch full session data');
        _recoverAndStartPolling();
      }
    } catch (e) {
      print('❌ Error fetching session data: $e');
      _hideLoadingDialog();
      _showErrorAndGoBack('Error fetching session data');
    } finally {
      if (_isMounted) {
        setState(() {
          _isRecovering = false;
        });
      }
    }
  }

  void _saveSessionDataInBackground(LiveChargingData data) {
    unawaited(_saveSessionDataAsync(data));
  }

  Future<void> _saveSessionDataAsync(LiveChargingData data) async {
    try {
      await ChargingSessionService.saveActiveSession(
        sessionId: data.sessionId,
        startedAt: data.startedAt,
        status: data.status,
        phase: data.phase,
        transactionId: data.transactionId,
      );
      print('💾 Active session saved with status: ${data.status}');
    } catch (e) {
      print('⚠️ Error saving session data: $e');
    }
  }

// In _recoverAndStartPolling method in ChargingProgressPage

  Future<void> _recoverAndStartPolling() async {
    if (!_isMounted) return;

    setState(() {
      _isRecovering = true;
    });

    try {
      print('🔄 Attempting to recover active session...');

      final sessionData = await ChargingSessionService.getActiveSessionData();

      if (sessionData != null && sessionData['sessionId'] != null) {
        final sessionId = sessionData['sessionId'];
        if (sessionId is int && sessionId > 0) {
          print('✅ Recovered session ID from storage: $sessionId');
          final success = await _liveChargingController.fetchLiveChargingStatus(
            sessionId: sessionId,
          );

          if (!_isMounted) return;

          if (success && _liveChargingController.currentLiveData != null) {
            final liveData = _liveChargingController.currentLiveData!;
            // ✅ Don't treat preparing or timeout as failure
            if (!liveData.isCompleted && !liveData.hasError) {
              print('✅ Active session found: $sessionId');
              _hideLoadingDialog();
              _startPolling(sessionId);
              setState(() {
                _isRecovering = false;
              });
              return;
            } else {
              print('⚠️ Session is completed or has error');
            }
          }
        }
      }

      print('🔄 Polling live API for active session...');
      _updateLoadingDialogMessage('Connecting to charger...');

      int retryCount = 0;
      const maxRetries = 30; // Increase to 30 (90 seconds total)
      bool foundActiveSession = false;

      while (retryCount < maxRetries && !foundActiveSession && _isMounted) {
        await Future.delayed(const Duration(seconds: 3));

        if (retryCount % 3 == 0) {
          _updateLoadingDialogMessage(
            'Waiting for charger to start... (${(retryCount + 1) * 3}s)',
          );
        }

        try {
          final success = await _liveChargingController.fetchLiveChargingStatus();

          if (!_isMounted) break;

          if (success && _liveChargingController.currentLiveData != null) {
            final liveData = _liveChargingController.currentLiveData!;
            // ✅ Accept preparing state as valid
            if (!liveData.isCompleted && !liveData.hasError) {
              final sessionId = liveData.sessionId;
              print('✅ Found active session after polling: $sessionId');
              print('   Status: ${liveData.status}');
              print('   Phase: ${liveData.phase}');

              await ChargingSessionService.saveSessionIdOnly(sessionId);
              await ChargingSessionService.saveActiveSession(
                sessionId: sessionId,
                startedAt: liveData.startedAt,
                status: liveData.status,
                phase: liveData.phase,
                transactionId: liveData.transactionId,
              );

              _hideLoadingDialog();
              _startPolling(sessionId);
              foundActiveSession = true;
              setState(() {
                _isRecovering = false;
              });
              return;
            } else {
              print('⏳ Session in state: ${liveData.status}, retrying...');
            }
          }
        } catch (e) {
          print('⚠️ Polling attempt $retryCount failed: $e');
          // ✅ Don't break on timeout, keep retrying
        }

        retryCount++;
      }

      if (!foundActiveSession && _isMounted) {
        print('❌ No active session found after polling - navigating to map');
        _hideLoadingDialog();
        _navigateToMapScreen();
      }
    } catch (e) {
      print('❌ Error recovering session: $e');
      _hideLoadingDialog();
      _showErrorAndGoBack('Error recovering session');
    } finally {
      if (_isMounted) {
        setState(() {
          _isRecovering = false;
        });
      }
    }
  }

  void _showErrorAndGoBack(String message) {
    if (!_isMounted) return;
    _hideLoadingDialog();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    _scheduleNavigationToScanner();
  }

  void _scheduleNavigationToScanner() {
    Future.delayed(const Duration(seconds: 2), () {
      if (_isMounted) {
        _navigateToScanner();
      }
    });
  }

  void _navigateToScanner() {
    if (!_isMounted) return;
    _clearSessionData();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ScannerPage()),
      (route) => false,
    );
  }

  void _navigateToMapScreen() {
    if (!_isMounted) return;
    _clearSessionData();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
      (route) => false,
    );
  }

  Future<void> _checkSessionAndRecoverWithRetries() async {
    if (!_isMounted || !mounted) return;

    int? sessionId =
        _currentSessionId ??
        widget.chargingDetails?['sessionId'] ??
        _liveChargingController.currentSessionId;

    if (sessionId == null || sessionId <= 0) {
      try {
        final prefs = await SharedPreferences.getInstance();
        sessionId =
            prefs.getInt('active_session_id') ?? prefs.getInt('session_id');
      } catch (_) {}
    }

    if (sessionId != null && sessionId > 0) {
      for (int i = 0; i < 5; i++) {
        if (!_isMounted || !mounted) return;

        print('📡 Session recovery attempt ${i + 1}/5 for session $sessionId');
        final success = await _liveChargingController.fetchLiveChargingStatus(
          sessionId: sessionId,
        );

        if (!_isMounted || !mounted) return;

        if (success && _liveChargingController.currentLiveData != null) {
          final liveData = _liveChargingController.currentLiveData!;
          if (liveData.isCompleted || liveData.hasError) {
            print('🔴 Session completed/errored after network recovery');
            _isSessionCompleted = true;
            _showInvoiceBottomSheet();
          } else {
            print('✅ Active session recovered: $sessionId');
            _startPolling(sessionId);
          }
          return;
        }

        if (i < 4) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    if (_isMounted && mounted) {
      print('📡 No active session found after recovery - navigating to map');
      _navigateToMapScreen();
    }
  }

  void _startAutoRefreshTimer() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!_isMounted || !mounted || _isSessionCompleted) {
        _refreshTimer?.cancel();
        _refreshTimer = null;
        return;
      }

      if (_retryLoopActive || _isHandlingNetworkInterruption) {
        _refreshTimer?.cancel();
        _refreshTimer = null;
        return;
      }

      final liveData = _liveChargingController.currentLiveData;
      final shouldRefresh =
          liveData == null ||
          liveData.isCharging ||
          liveData.isPreparing ||
          liveData.isSuspended ||
          liveData.isFinishing;

      if (!shouldRefresh) {
        _refreshTimer?.cancel();
        _refreshTimer = null;
        return;
      }

      final sessionId =
          _currentSessionId ??
          widget.chargingDetails?['sessionId'] ??
          _liveChargingController.currentSessionId;

      if (sessionId == null || sessionId <= 0) {
        return;
      }

      print('🔄 Auto-refreshing charging data every 10 seconds');
      final success = await _liveChargingController.fetchLiveChargingStatus(
        sessionId: sessionId,
      );

      if (!success && _isMounted && mounted && !_isHandlingNetworkInterruption && !_retryLoopActive) {
        final errorMsg = (_liveChargingController.errorMessage ?? '').toLowerCase();
        final isNetworkIssue =
            errorMsg.contains('network') ||
            errorMsg.contains('socket') ||
            errorMsg.contains('connection') ||
            errorMsg.contains('timeout') ||
            errorMsg.contains('internet') ||
            errorMsg.isEmpty;

        if (isNetworkIssue) {
          print('📡 Auto-refresh detected network failure - triggering recovery');
          _refreshTimer?.cancel();
          _refreshTimer = null;
          unawaited(_handleNetworkInterruptionAndRetry());
          return;
        }
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onControllerUpdate() {
    _uiDebounceTimer?.cancel();
    _uiDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_isMounted) return;
      _processControllerUpdate();
    });
  }

  void _processControllerUpdate() {
    print('🔄 ChargingProgressPage: Controller updated');

    if (_liveChargingController.isNoActiveSession && _isMounted) {
      print('⚠️ No active session detected - waiting before rechecking');
      unawaited(_handleNetworkInterruptionAndRetry());
      return;
    }

    if (_liveChargingController.pollingStoppedByNetwork &&
        _isMounted &&
        !_isSessionCompleted &&
        !_isHandlingNetworkInterruption) {
      print('📡 Polling stopped by network failures - triggering recovery');
      _refreshTimer?.cancel();
      _refreshTimer = null;
      unawaited(_handleNetworkInterruptionAndRetry());
      return;
    }

    if (_liveChargingController.currentLiveData != null) {
      final data = _liveChargingController.currentLiveData!;

      if (data.isCompleted && _isMounted && !_isSessionCompleted) {
        print('🔴 Session completed');
        print('   Status: ${data.status}');
        print('   Phase: ${data.phase}');

        _isSessionCompleted = true;
        _durationTimer?.cancel();
        _liveChargingController.stopPolling();
        stopPolling();
        _hideLoadingDialog();
        _showInvoiceBottomSheet();
        return;
      }
    }

    if (_liveChargingController.hasError && _isMounted) {
      if (_liveChargingController.isNoActiveSession) {
        return;
      }

      final errorMessage = (_liveChargingController.errorMessage ?? '')
          .toLowerCase();
      final isConnectionIssue =
          errorMessage.contains('network') ||
          errorMessage.contains('socket') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('internet');

      print('❌ Session error: ${_liveChargingController.errorMessage}');

      if (isConnectionIssue) {
        unawaited(_handleNetworkInterruptionAndRetry());
        return;
      }

      _isSessionCompleted = true;
      _durationTimer?.cancel();
      _liveChargingController.stopPolling();
      stopPolling();
      _hideLoadingDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _liveChargingController.errorMessage ?? 'Charging error',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );

      _scheduleNavigationToScanner();
      return;
    }
  }

  void _saveFinalSessionStatus(LiveChargingData data) async {
    try {
      await ChargingSessionService.saveActiveSession(
        sessionId: data.sessionId,
        startedAt: data.startedAt,
        status: data.status,
      );
      print('💾 Final session status saved: ${data.status}');
    } catch (e) {
      print('❌ Error saving final status: $e');
    }
  }

  Duration? _extractDurationFromElapsedTime(dynamic elapsedTime) {
    if (elapsedTime == null) return null;

    try {
      if (elapsedTime is Map) {
        final seconds = elapsedTime['seconds'];
        if (seconds != null) {
          final safeSeconds = _safeToInt(seconds);
          return Duration(seconds: safeSeconds);
        }
      }

      if (elapsedTime is int) {
        return Duration(seconds: elapsedTime);
      }

      if (elapsedTime is double) {
        final safeSeconds = _safeToInt(elapsedTime);
        return Duration(seconds: safeSeconds);
      }

      if (elapsedTime is Duration) {
        if (_isValidDuration(elapsedTime)) {
          return elapsedTime;
        }
        return Duration.zero;
      }

      if (elapsedTime.toString().contains('seconds:')) {
        final regex = RegExp(r'seconds:\s*(\d+)');
        final match = regex.firstMatch(elapsedTime.toString());
        if (match != null) {
          final seconds = int.tryParse(match.group(1)!);
          if (seconds != null) return Duration(seconds: seconds);
        }
      }

      try {
        final seconds = (elapsedTime as dynamic).seconds;
        if (seconds != null) {
          final safeSeconds = _safeToInt(seconds);
          return Duration(seconds: safeSeconds);
        }
      } catch (_) {}

      try {
        final inSeconds = (elapsedTime as dynamic).inSeconds;
        if (inSeconds != null) {
          final safeSeconds = _safeToInt(inSeconds);
          return Duration(seconds: safeSeconds);
        }
      } catch (_) {}
    } catch (e) {
      print('Error extracting duration: $e');
    }

    return null;
  }

  Duration _parseDuration(dynamic duration) {
    if (duration == null) return Duration.zero;

    final extracted = _extractDurationFromElapsedTime(duration);
    if (extracted != null && _isValidDuration(extracted)) {
      return extracted;
    }

    if (duration is Duration) {
      if (_isValidDuration(duration)) {
        return duration;
      }
      return Duration.zero;
    }

    if (duration is int) {
      return Duration(seconds: duration);
    }

    if (duration is double) {
      final safeSeconds = _safeToInt(duration);
      return Duration(seconds: safeSeconds);
    }

    if (duration is String) {
      final parts = duration.split(':');
      if (parts.length == 3) {
        return Duration(
          hours: int.tryParse(parts[0]) ?? 0,
          minutes: int.tryParse(parts[1]) ?? 0,
          seconds: int.tryParse(parts[2]) ?? 0,
        );
      }
    }

    return Duration.zero;
  }

  DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    if (dateTime is DateTime) {
      return dateTime;
    } else if (dateTime is String) {
      return DateTime.tryParse(dateTime);
    } else if (dateTime is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateTime);
    }
    return null;
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isMounted) {
        timer.cancel();
        return;
      }

      setState(() {
        try {
          final liveData = _liveChargingController.currentLiveData;
          final elapsed = liveData?.elapsedTime;

          if (elapsed != null) {
            final parsedDuration = _parseDuration(elapsed);
            if (_isValidDuration(parsedDuration)) {
              if (_lastElapsedUpdateTime == null ||
                  _elapsedBaseDuration != parsedDuration) {
                _elapsedBaseDuration = parsedDuration;
                _lastElapsedUpdateTime = DateTime.now();
              }

              _currentDuration = calculateElapsedDuration(
                baseDuration: _elapsedBaseDuration,
                lastUpdateTime: _lastElapsedUpdateTime,
                now: DateTime.now(),
              );
              _sessionStartTime = null;
              return;
            }
          }

          if (_sessionStartTime != null) {
            _currentDuration = DateTime.now().difference(_sessionStartTime!);
            if (!_isValidDuration(_currentDuration)) {
              _currentDuration = Duration.zero;
            }
          } else if (liveData?.startedAt != null) {
            _sessionStartTime = _parseDateTime(liveData!.startedAt);
            if (_sessionStartTime == null) {
              _sessionStartTime = DateTime.now();
            }
            _currentDuration = Duration.zero;
          } else {
            _currentDuration = Duration.zero;
          }
        } catch (e) {
          print('Error updating duration: $e');
          _currentDuration = Duration.zero;
        }
      });
    });
  }

  String get _formattedRunningDuration {
    try {
      final duration = _currentDuration;
      if (!_isValidDuration(duration)) {
        return '0:00';
      }
      if (duration.inHours > 0) {
        final hours = duration.inHours;
        final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
        return '$hours:$minutes:$seconds';
      } else {
        final minutes = duration.inMinutes;
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
        return '$minutes:$seconds';
      }
    } catch (e) {
      print('Error formatting duration: $e');
      return '0:00';
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _uiDebounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _liveChargingController.removeListener(_onControllerUpdate);
    _liveChargingController.stopPolling();
    _liveChargingController.dispose();
    _stopChargingController.dispose();
    _durationTimer?.cancel();
    _refreshTimer?.cancel();
    _refreshTimer = null;
    stopPolling();
    _hideLoadingDialog();
    super.dispose();
  }

  void _clearSessionData() {
    try {
      ActiveSessionService.clearSessionFromStorage();
      print(
        '🗑️ Session cleared using ActiveSessionService.clearSessionFromStorage()',
      );
      return;
    } catch (e) {
      print('⚠️ Error using ActiveSessionService.clearSessionFromStorage: $e');
    }

    _manualClearSession();
  }

  void _manualClearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_session_id');
      await prefs.remove('session_id');
      await prefs.remove('session_status');
      await prefs.remove('session_status_phase');
      await prefs.remove('session_transaction_id');
      await prefs.remove('session_started_at');
      await prefs.remove('session_data');
      await prefs.remove('session_id_only');

      final sessionId = _currentSessionId;
      if (sessionId != null) {
        await prefs.remove('session_${sessionId}_vehicle_name');
        await prefs.remove('session_${sessionId}_vehicle_manufacturer');
        await prefs.remove('session_${sessionId}_vehicle_model');
        await prefs.remove('session_${sessionId}_vehicle_registration');
        await prefs.remove('session_${sessionId}_vehicle_id');
      }

      print('🗑️ Session manually cleared from SharedPreferences');
    } catch (e) {
      print('❌ Error manually clearing session: $e');
    }
  }

  Widget _bottomSheetSummaryRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Appcolor.black,
          ),
        ),
      ],
    );
  }

  Future<void> _stopCharging() async {
    // Try multiple sources to get the session ID
    int? sessionId = widget.chargingDetails?['sessionId'];

    print('🔍 Stop Charging - Widget Session ID: $sessionId');

    if (sessionId == null || sessionId <= 0) {
      sessionId = _liveChargingController.currentSessionId;
      print('🔍 Stop Charging - Controller Session ID: $sessionId');
    }

    if (sessionId == null || sessionId <= 0) {
      sessionId = _currentSessionId;
      print('🔍 Stop Charging - _currentSessionId: $sessionId');
    }

    // If still null, try getting from SharedPreferences
    if (sessionId == null || sessionId <= 0) {
      try {
        final prefs = await SharedPreferences.getInstance();
        sessionId =
            prefs.getInt('active_session_id') ??
            prefs.getInt('session_id') ??
            prefs.getInt('current_session_id');
        print('🔍 Stop Charging - SharedPreferences Session ID: $sessionId');
      } catch (e) {
        print('⚠️ Error reading session ID from preferences: $e');
      }
    }

    // If still no session ID, try to get it from the live data
    if (sessionId == null || sessionId <= 0) {
      final liveData = _liveChargingController.currentLiveData;
      if (liveData != null && liveData.sessionId > 0) {
        sessionId = liveData.sessionId;
        print('🔍 Stop Charging - Live Data Session ID: $sessionId');
      }
    }

    print('🔍 Final Session ID for stop: $sessionId');

    if (sessionId == null || sessionId <= 0) {
      print('❌ Session ID is null or invalid');
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session ID not found. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Stop Charging"),
          content: const Text("Are you sure you want to stop charging?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Stop"),
            ),
          ],
        );
      },
    );

    if (shouldStop != true) return;

    // Show loading dialog
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
                  "Stopping Charging Session...",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please wait",
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
      print('📤 Calling stop charging API with session ID: $sessionId');
      final success = await _stopChargingController.stopChargingSession(
        sessionId: sessionId,
      );

      if (_isMounted) {
        Navigator.pop(context);
      }

      if (success && _isMounted) {
        _liveChargingController.stopPolling();
        stopPolling();
        _durationTimer?.cancel();
        _isSessionCompleted = true;
        _showInvoiceBottomSheet();
      } else if (_isMounted) {
        // If stop failed, try to clear session anyway if it's already completed
        final errorMsg =
            _stopChargingController.errorMessage?.toLowerCase() ?? '';

        if (errorMsg.contains('not found') ||
            errorMsg.contains('already') ||
            errorMsg.contains('completed')) {
          // Session is already stopped or invalid - show invoice
          print(
            '⚠️ Session already completed or not found - proceeding to invoice',
          );
          _liveChargingController.stopPolling();
          stopPolling();
          _durationTimer?.cancel();
          _isSessionCompleted = true;
          _showInvoiceBottomSheet();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _stopChargingController.errorMessage ??
                    "Failed to stop charging",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in _stopCharging: $e');
      if (_isMounted) {
        Navigator.pop(context);

        if (e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Network error. Please check your connection."),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _infoCard(String title, String value) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Appcolor.borderGrey, width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontFamily: Appcolor.fontFamily,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Appcolor.black,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: Appcolor.fontFamily,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _infoCardWithBorder(String title, String value) {
    return Container(
      height: 85,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Appcolor.borderGrey, width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                title == "Vehicle Name"
                    ? Icons.directions_car
                    : title == "Registration Number"
                    ? Icons.confirmation_number
                    : Icons.flash_on,
                size: 14,
                color: Appcolor.green.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontFamily: Appcolor.fontFamily,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: Appcolor.black,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: Appcolor.fontFamily,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Appcolor.green.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontFamily: Appcolor.fontFamily,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Appcolor.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: Appcolor.fontFamily,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _liveChargingController),
        ChangeNotifierProvider.value(value: _stopChargingController),
      ],
      child: Scaffold(
        backgroundColor: Appcolor.white,
        body: SafeArea(
          child: _isRecovering
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Appcolor.green,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text("Recovering charging session..."),
                    ],
                  ),
                )
              : Consumer<LiveChargingController>(
                  builder: (context, controller, child) {
                    if (controller.isNoActiveSession) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Appcolor.green,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text("Session completed..."),
                          ],
                        ),
                      );
                    }

                    if (controller.isLoading &&
                        controller.currentLiveData == null) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Appcolor.green,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text("Loading charging data..."),
                          ],
                        ),
                      );
                    }

                    if (!controller.isLoading &&
                        controller.currentLiveData == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.ev_station,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No active charging session",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Please start a new charging session",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Appcolor.green,
                              ),
                              child: const Text("Go Back"),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  "Charging In Progress",
                                  style: TextStyle(
                                    color: Appcolor.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: Appcolor.fontFamily,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          color: Appcolor.borderGrey,
                          thickness: 0.5,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                color: Colors.grey.shade600,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  "Started at ${controller.formattedStartedAt}",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 11,
                                                    fontFamily:
                                                        Appcolor.fontFamily,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  height: 160,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Appcolor.lightGrey,
                                    image: const DecorationImage(
                                      image: AssetImage('assets/tataev.jpg'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Column(
                                  children: [
                                    if (shouldShowBatteryProgressSection(
                                      controller.chargerType,
                                    ))
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.flash_on,
                                                  color: Appcolor.green,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  "${controller.batteryPercentage.toStringAsFixed(0)}%",
                                                  style: TextStyle(
                                                    color: Appcolor.black,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily:
                                                        Appcolor.fontFamily,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        controller
                                                                .chargingStatus ==
                                                            "Charging"
                                                        ? Appcolor.green
                                                              .withOpacity(0.1)
                                                        : Colors.red
                                                              .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    controller.chargingStatus,
                                                    style: TextStyle(
                                                      color:
                                                          controller
                                                                  .chargingStatus ==
                                                              "Charging"
                                                          ? Appcolor.green
                                                          : Colors.red,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily:
                                                          Appcolor.fontFamily,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _formattedRunningDuration,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily:
                                                      Appcolor.fontFamily,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                "Elapsed Time",
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 10,
                                                  fontFamily:
                                                      Appcolor.fontFamily,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Charging Session",
                                                  style: TextStyle(
                                                    color: Appcolor.black,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily:
                                                        Appcolor.fontFamily,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                // Text(
                                                //   "Waiting for DC charging metrics",
                                                //   style: TextStyle(
                                                //     color: Colors.grey.shade600,
                                                //     fontSize: 12,
                                                //     fontFamily: Appcolor.fontFamily,
                                                //   ),
                                                // ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _formattedRunningDuration,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily:
                                                      Appcolor.fontFamily,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                "Elapsed Time",
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 10,
                                                  fontFamily:
                                                      Appcolor.fontFamily,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    if (shouldShowBatteryProgressSection(
                                      controller.chargerType,
                                    ))
                                      const SizedBox(height: 10),
                                    if (shouldShowBatteryProgressSection(
                                      controller.chargerType,
                                    ))
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: LinearProgressIndicator(
                                          value:
                                              controller.batteryPercentage /
                                              100,
                                          minHeight: 8,
                                          backgroundColor: Appcolor.borderGrey,
                                          color: Appcolor.green,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _infoCard(
                                        "Amount Used",
                                        controller.totalCost,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _infoCard(
                                        "Current Speed",
                                        controller.currentPower,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 12),
                                      _infoCardWithBorder(
                                        "Energy Consumed",
                                        controller.energyConsumed,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Appcolor.borderGrey,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow(
                                        icon: Icons.ev_station,
                                        label: 'Charger',
                                        value: formatDisplayValue(
                                          controller.chargerName,
                                        ),
                                      ),
                                      const Divider(
                                        color: Appcolor.borderGrey,
                                        thickness: 0.5,
                                        height: 16,
                                      ),
                                      _buildDetailRow(
                                        icon: Icons.confirmation_number,
                                        label: 'Charger ID',
                                        value: formatDisplayValue(
                                          controller.chargerId,
                                        ),
                                      ),
                                      const Divider(
                                        color: Appcolor.borderGrey,
                                        thickness: 0.5,
                                        height: 16,
                                      ),
                                      _buildDetailRow(
                                        icon: Icons.power,
                                        label: 'Connector',
                                        value: formatDisplayValue(
                                          controller.connectorName,
                                        ),
                                      ),
                                      const Divider(
                                        color: Appcolor.borderGrey,
                                        thickness: 0.5,
                                        height: 16,
                                      ),
                                      _buildDetailRow(
                                        icon: Icons.fiber_pin,
                                        label: 'Connector UID',
                                        value: formatDisplayValue(
                                          controller
                                              .currentLiveData
                                              ?.connector
                                              .uid,
                                        ),
                                      ),
                                      const Divider(
                                        color: Appcolor.borderGrey,
                                        thickness: 0.5,
                                        height: 16,
                                      ),
                                      _buildDetailRow(
                                        icon: Icons.directions_car,
                                        label: 'Vehicle Name',
                                        value: _vehicleName.isNotEmpty
                                            ? _vehicleName
                                            : 'Unknown Vehicle',
                                      ),
                                      const Divider(
                                        color: Appcolor.borderGrey,
                                        thickness: 0.5,
                                        height: 16,
                                      ),
                                      _buildDetailRow(
                                        icon: Icons.confirmation_number,
                                        label: 'Registration Number',
                                        value: _registrationNumber.isNotEmpty
                                            ? _registrationNumber
                                            : 'N/A',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed:
                                          _stopChargingController.isLoading
                                          ? null
                                          : _stopCharging,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: _stopChargingController.isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(
                                                  Icons.stop_circle,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  "Stop Charging",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}



