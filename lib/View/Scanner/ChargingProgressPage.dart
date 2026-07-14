import 'package:evtron/View/Home/scanner.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../Controller/live_charging_controller.dart';
import '../../Controller/stop_charging_controller.dart';
import '../../Model/stop_charging_model.dart';
import '../../Service/charging_session_service.dart';
import '../../Theme/colors.dart';

class ChargingProgressPage extends StatefulWidget {
  final Map<String, dynamic>? chargingDetails;

  const ChargingProgressPage({super.key, this.chargingDetails});

  @override
  State<ChargingProgressPage> createState() => _ChargingProgressPageState();
}

class _ChargingProgressPageState extends State<ChargingProgressPage> {
  late LiveChargingController _liveChargingController;
  final StopChargingController _stopChargingController = StopChargingController();

  Timer? _durationTimer;
  Duration _currentDuration = Duration.zero;
  DateTime? _sessionStartTime;
  String _vehicleName = "";
  String _registrationNumber = "";
  bool _isSessionCompleted = false;
  bool _isRecovering = false;


  @override
  void initState() {
    super.initState();

    if (widget.chargingDetails != null) {
      _vehicleName = widget.chargingDetails!['vehicleName'] ??
          "${widget.chargingDetails!['manufacturer'] ?? ''} ${widget.chargingDetails!['model'] ?? ''}".trim();
      _registrationNumber = widget.chargingDetails!['registrationNumber'] ?? "N/A";
    }

    _liveChargingController = LiveChargingController();

    int? sessionId = widget.chargingDetails?['sessionId'];

    if (sessionId == null) {
      print('⚠️ No session ID provided, attempting to recover...');
      _recoverAndStartPolling();
    } else {
      // First fetch the full data, then start polling
      _fetchFullDataAndStartPolling(sessionId);
    }

    _liveChargingController.addListener(_onLiveDataUpdate);
    _liveChargingController.addListener(_onControllerUpdate);
    _startDurationTimer();
  }

  Future<void> _fetchFullDataAndStartPolling(int sessionId) async {
    setState(() {
      _isRecovering = true;
    });

    try {
      print('📡 Fetching full session data for ID: $sessionId');

      // Fetch full live data
      final success = await _liveChargingController.fetchLiveChargingStatus(sessionId: sessionId);

      if (success && _liveChargingController.currentLiveData != null) {
        print('✅ Full session data fetched successfully');

        // Update vehicle info from live data
        final liveData = _liveChargingController.currentLiveData!;
        if (liveData.vehicle != null) {
          setState(() {
            _vehicleName = '${liveData.vehicle?.manufacturer ?? ''} ${liveData.vehicle?.model ?? ''}'.trim();
            if (_vehicleName.isEmpty) {
              _vehicleName = widget.chargingDetails?['vehicleName'] ?? 'Unknown Vehicle';
            }
            _registrationNumber = liveData.vehicle?.registrationNumber ??
                widget.chargingDetails?['registrationNumber'] ?? 'N/A';
          });
        }

        // Start polling
        _startPolling(sessionId);
      } else {
        print('❌ Failed to fetch full session data');
        // Try to recover from server
        final recovered = await _liveChargingController.recoverActiveSession();
        if (recovered && _liveChargingController.currentLiveData != null) {
          final newSessionId = _liveChargingController.currentLiveData!.sessionId;
          print('✅ Session recovered from server: $newSessionId');
          _startPolling(newSessionId);
        } else {
          print('❌ Could not recover session');
          _showErrorAndGoBack('No active charging session found');
        }
      }
    } catch (e) {
      print('❌ Error fetching session data: $e');
      _showErrorAndGoBack('Error fetching session data');
    } finally {
      if (mounted) {
        setState(() {
          _isRecovering = false;
        });
      }
    }
  }

  Future<void> _recoverAndStartPolling() async {
    setState(() {
      _isRecovering = true;
    });

    try {
      // Try to get session from storage
      final sessionData = await ChargingSessionService.getActiveSessionData();

      if (sessionData != null && sessionData['sessionId'] != null) {
        final sessionId = sessionData['sessionId'];
        print('✅ Recovered session ID: $sessionId');

        // Try to fetch live data
        final success = await _liveChargingController.fetchLiveChargingStatus(sessionId: sessionId);

        if (success && _liveChargingController.currentLiveData != null) {
          print('✅ Session data fetched successfully');
          _startPolling(sessionId);
        } else {
          // Try to recover from server
          print('🔄 Trying to recover from server...');
          final recovered = await _liveChargingController.recoverActiveSession();

          if (recovered && _liveChargingController.currentLiveData != null) {
            final newSessionId = _liveChargingController.currentLiveData!.sessionId;
            print('✅ Session recovered from server: $newSessionId');
            _startPolling(newSessionId);
          } else {
            print('❌ Could not recover session');
            _showErrorAndGoBack('No active charging session found');
          }
        }
      } else {
        print('❌ No session data found');
        _showErrorAndGoBack('No active charging session found');
      }
    } catch (e) {
      print('❌ Error recovering session: $e');
      _showErrorAndGoBack('Error recovering session');
    } finally {
      if (mounted) {
        setState(() {
          _isRecovering = false;
        });
      }
    }
  }

  void _startPolling(int sessionId) {
    _liveChargingController.startPolling(
      sessionId: sessionId,
      interval: const Duration(seconds: 5),
    );
  }

  void _showErrorAndGoBack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _onControllerUpdate() {
    // Check if session is completed
    if (_liveChargingController.shouldShowCompletion && mounted && !_isSessionCompleted) {
      print('🔴 Session completed - Showing completion bottom sheet');
      _isSessionCompleted = true;
      _durationTimer?.cancel();
      _liveChargingController.stopPolling();

      // Show completion bottom sheet
      _showCompletionBottomSheetForCompletedSession();
    }

    // Check if session has error
    if (_liveChargingController.hasError && mounted) {
      print('❌ Session error: ${_liveChargingController.errorMessage}');
      _isSessionCompleted = true;
      _durationTimer?.cancel();
      _liveChargingController.stopPolling();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_liveChargingController.errorMessage ?? 'Charging error'),
          backgroundColor: Colors.red,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }

    // Check if session is preparing (keep polling)
    if (_liveChargingController.isPreparing && mounted) {
      print('⏳ Session is preparing, continuing polling...');
    }
  }

  void _onLiveDataUpdate() {
    // Check if status is completed or stopped
    final status = _liveChargingController.currentLiveData?.status?.toLowerCase();
    if ((status == 'completed' || status == 'stopped') && mounted && !_isSessionCompleted) {
      print('🔴 Session status: $status - Session completed');
      _isSessionCompleted = true;
      _durationTimer?.cancel();

      // Show completion bottom sheet
      _showCompletionBottomSheetForCompletedSession();
    }

    // Update session start time
    if (_sessionStartTime == null && _liveChargingController.currentLiveData != null) {
      final startedAtRaw = _liveChargingController.currentLiveData?.startedAt;

      if (startedAtRaw != null) {
        _sessionStartTime = _parseDateTime(startedAtRaw);

        if (_sessionStartTime == null) {
          final elapsed = _liveChargingController.currentLiveData?.elapsedTime;
          if (elapsed != null) {
            final elapsedDuration = _extractDurationFromElapsedTime(elapsed);
            if (elapsedDuration != null) {
              _sessionStartTime = DateTime.now().subtract(elapsedDuration);
            }
          }
        }
      }
    }
  }

  Duration? _extractDurationFromElapsedTime(dynamic elapsedTime) {
    if (elapsedTime == null) return null;

    try {
      if (elapsedTime is Map) {
        final seconds = elapsedTime['seconds'];
        if (seconds is int) return Duration(seconds: seconds);
        if (seconds is double) return Duration(seconds: seconds.toInt());
      }

      if (elapsedTime is dynamic) {
        if (elapsedTime.seconds != null) return Duration(seconds: elapsedTime.seconds as int);
        if (elapsedTime.inSeconds != null) return Duration(seconds: elapsedTime.inSeconds as int);
        if (elapsedTime.totalSeconds != null) return Duration(seconds: elapsedTime.totalSeconds as int);

        final elapsedStr = elapsedTime.toString();
        if (elapsedStr.contains('seconds:')) {
          final regex = RegExp(r'seconds:\s*(\d+)');
          final match = regex.firstMatch(elapsedStr);
          if (match != null) {
            final seconds = int.tryParse(match.group(1)!);
            if (seconds != null) return Duration(seconds: seconds);
          }
        }
      }

      if (elapsedTime is int) return Duration(seconds: elapsedTime);
      if (elapsedTime is double) return Duration(seconds: elapsedTime.toInt());
      if (elapsedTime is Duration) return elapsedTime;
    } catch (e) {
      print('Error extracting duration: $e');
    }

    return null;
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

  Duration _parseDuration(dynamic duration) {
    if (duration == null) return Duration.zero;

    final extracted = _extractDurationFromElapsedTime(duration);
    if (extracted != null) return extracted;

    if (duration is Duration) {
      return duration;
    } else if (duration is int) {
      return Duration(seconds: duration);
    } else if (duration is double) {
      return Duration(milliseconds: (duration * 1000).round());
    } else if (duration is String) {
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

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_sessionStartTime != null) {
            _currentDuration = DateTime.now().difference(_sessionStartTime!);
          } else if (_liveChargingController.currentLiveData != null) {
            final elapsed = _liveChargingController.currentLiveData?.elapsedTime;
            _currentDuration = _parseDuration(elapsed);

            final startedAtRaw = _liveChargingController.currentLiveData?.startedAt;
            if (startedAtRaw != null) {
              _sessionStartTime = _parseDateTime(startedAtRaw);
              if (_sessionStartTime == null && elapsed != null) {
                final elapsedDuration = _extractDurationFromElapsedTime(elapsed);
                if (elapsedDuration != null) {
                  _sessionStartTime = DateTime.now().subtract(elapsedDuration);
                }
              }
            }
          } else {
            _currentDuration = Duration.zero;
          }
        });
      }
    });
  }

  String get _formattedRunningDuration {
    if (_currentDuration.inHours > 0) {
      final hours = _currentDuration.inHours;
      final minutes = (_currentDuration.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (_currentDuration.inSeconds % 60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else {
      final minutes = _currentDuration.inMinutes;
      final seconds = (_currentDuration.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
  }

  @override
  void dispose() {
    _liveChargingController.removeListener(_onLiveDataUpdate);
    _liveChargingController.removeListener(_onControllerUpdate);
    _liveChargingController.stopPolling();
    _liveChargingController.dispose();
    _stopChargingController.dispose();
    _durationTimer?.cancel();
    super.dispose();
  }

// Update this method in ChargingProgressPage

  void _showCompletionBottomSheetForCompletedSession() {
    // Build data from current live data
    final data = _liveChargingController.currentLiveData;
    if (data == null) {
      // If no data, just navigate back
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ScannerPage()),
                (route) => false,
          );
        }
      });
      return;
    }

    // Create a Map from the data
    final currency = data.billing.currency;
    final cost = data.billing.currentCost;
    final formattedCost = "$currency${cost.toStringAsFixed(2)}";
    final duration = data.elapsedTime.formatted;
    final energy = "${data.energy.consumedKwh.toStringAsFixed(2)} kWh";

    final sessionData = {
      'formattedDuration': duration,
      'formattedEnergy': energy,
      'formattedCost': formattedCost,
      'status': data.status.toUpperCase(),
      'walletBalanceAfter': data.billing.walletBalance,
    };

    _showCompletionBottomSheet(sessionData);
  }

  void _showCompletionBottomSheet(dynamic data) {
    Map<String, dynamic> sessionData = {};

    if (data == null) {
      // Use current live data if available
      final liveData = _liveChargingController.currentLiveData;
      if (liveData != null) {
        sessionData = {
          'formattedDuration': liveData.elapsedTime.formatted,
          'formattedEnergy': '${liveData.energy.consumedKwh.toStringAsFixed(2)} kWh',
          'formattedCost': '${liveData.billing.currency}${liveData.billing.currentCost.toStringAsFixed(2)}',
          'status': liveData.status.toUpperCase(),
          'walletBalanceAfter': liveData.billing.walletBalance,
        };
      } else {
        // Fallback data
        sessionData = {
          'formattedDuration': 'N/A',
          'formattedEnergy': '0 kWh',
          'formattedCost': '₹0.00',
          'status': 'COMPLETED',
          'walletBalanceAfter': 0.0,
        };
      }
    } else if (data is StopChargingData) {
      // Convert StopChargingData to Map
      sessionData = {
        'formattedDuration': data.formattedDuration,
        'formattedEnergy': data.formattedEnergy,
        'formattedCost': data.formattedCost,
        'status': data.status.toUpperCase(),
        'walletBalanceAfter': double.tryParse(data.walletBalanceAfter) ?? 0.0,
      };
    } else if (data is Map<String, dynamic>) {
      // Already a Map
      sessionData = data;
    } else {
      // Try to convert from JSON
      try {
        sessionData = Map<String, dynamic>.from(data);
      } catch (e) {
        // Fallback
        sessionData = {
          'formattedDuration': 'N/A',
          'formattedEnergy': '0 kWh',
          'formattedCost': '₹0.00',
          'status': 'COMPLETED',
          'walletBalanceAfter': 0.0,
        };
      }
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Appcolor.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Appcolor.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                "Charging Complete! 🎉",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Appcolor.black,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                "Your EV charging session has been completed",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Divider
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: const Divider(color: Appcolor.borderGrey, thickness: 1),
              ),
              const SizedBox(height: 16),

              // Session Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _bottomSheetSummaryRow(
                      "Duration",
                      sessionData['formattedDuration'] ?? "N/A",
                      Icons.timer_outlined,
                    ),
                    const SizedBox(height: 12),
                    _bottomSheetSummaryRow(
                      "Energy Consumed",
                      sessionData['formattedEnergy'] ?? "N/A",
                      Icons.flash_on,
                    ),
                    const SizedBox(height: 12),
                    _bottomSheetSummaryRow(
                      "Status",
                      sessionData['status'] ?? 'COMPLETED',
                      Icons.circle,
                      valueColor: sessionData['status'] == 'COMPLETED'
                          ? Appcolor.green
                          : Colors.orange,
                    ),
                    const SizedBox(height: 12),

                    // Amount with highlighted style
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Appcolor.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Appcolor.green.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.currency_rupee_rounded,
                                color: Appcolor.green,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Total Amount",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            sessionData['formattedCost'] ?? "₹0.00",
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Appcolor.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Wallet Balance
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Wallet Balance",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "₹${sessionData['walletBalanceAfter']?.toStringAsFixed(2) ?? '0.00'}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Appcolor.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pay Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const ScannerPage()),
                            (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Appcolor.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.payment_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Pay Now",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sessionData['formattedCost'] ?? "₹0.00",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Close/Go to Home button
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const ScannerPage()),
                        (route) => false,
                  );
                },
                child: Text(
                  "Go to Home",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomSheetSummaryRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Colors.grey.shade600,
            ),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
                ),
                SizedBox(height: 16),
                Text("Recovering charging session..."),
              ],
            ),
          )
              : Consumer<LiveChargingController>(
            builder: (context, controller, child) {
              // Check for no active session - show loading state while we prepare to navigate back
              if (controller.isNoActiveSession) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
                      ),
                      SizedBox(height: 16),
                      Text("Session completed..."),
                    ],
                  ),
                );
              }

              if (controller.isLoading && controller.currentLiveData == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
                      ),
                      SizedBox(height: 16),
                      Text("Loading charging data..."),
                    ],
                  ),
                );
              }

              // If we have no data after loading, show a message
              if (!controller.isLoading && controller.currentLiveData == null) {
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

              // Main charging progress UI
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  const Divider(color: Appcolor.borderGrey, thickness: 0.5),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Vehicle Info Row - Using stored values from chargingDetails
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _vehicleName.isNotEmpty ? _vehicleName : "Unknown Vehicle",
                                      style: TextStyle(
                                        color: Appcolor.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: Appcolor.fontFamily,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _registrationNumber,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                        fontFamily: Appcolor.fontFamily,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(Icons.access_time, color: Colors.grey.shade600, size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            "Started at ${controller.formattedStartedAt}",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 11,
                                              fontFamily: Appcolor.fontFamily,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: controller.chargingStatus == "Charging" ? Appcolor.green : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            "Refresh in ${(controller.pollIntervalMs / 1000).toInt()}s",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 11,
                                              fontFamily: Appcolor.fontFamily,
                                            ),
                                            overflow: TextOverflow.ellipsis,
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

                          // Car Image
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

                          // Battery Status
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(Icons.flash_on, color: Appcolor.green, size: 20),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${controller.batteryPercentage.toStringAsFixed(0)}%",
                                          style: TextStyle(
                                              color: Appcolor.black,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: Appcolor.fontFamily),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: controller.chargingStatus == "Charging"
                                                ? Appcolor.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            controller.chargingStatus,
                                            style: TextStyle(
                                              color: controller.chargingStatus == "Charging" ? Appcolor.green : Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: Appcolor.fontFamily,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formattedRunningDuration,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: Appcolor.fontFamily,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "Elapsed Time",
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 10,
                                          fontFamily: Appcolor.fontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: controller.batteryPercentage / 100,
                                  minHeight: 8,
                                  backgroundColor: Appcolor.borderGrey,
                                  color: Appcolor.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Info Cards Row 1
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _infoCard("Duration", _formattedRunningDuration),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _infoCard("Amount Used", controller.totalCost),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _infoCard("Current Speed", controller.currentPower),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Info Cards Row 2
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _infoCard("Wallet Balance", controller.walletBalance),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _infoCard("Station", controller.stationCity),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _infoCard("Charger Type", controller.chargerType),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Bottom Cards
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _bigCard("Expected Completion", controller.getEstimatedTimeToFull()),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _bigCard("Charger Capacity", controller.chargerPowerCapacity),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Technical Details - Complete API Response
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Appcolor.lightGrey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Session Details",
                                      style: TextStyle(
                                        color: Appcolor.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Icon(Icons.ev_station,
                                        color: Appcolor.green, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: Appcolor.borderGrey, thickness: 1),

                                // Session Information
                                _sectionHeader("📋 Session Information"),
                                _techRow("Session ID", controller.currentLiveData?.sessionId.toString() ?? 'N/A'),
                                _techRow("Transaction ID", controller.currentLiveData?.transactionId ?? 'N/A'),
                                _techRow("Started At", controller.formattedStartedAt),
                                _techRow("Status", controller.chargingStatus),

                                // Time Information
                                _sectionHeader("⏱️ Time Information"),
                                _techRow("Elapsed Seconds", "${_parseDuration(controller.currentLiveData?.elapsedTime).inSeconds} sec"),
                                _techRow("Elapsed Minutes", "${_parseDuration(controller.currentLiveData?.elapsedTime).inMinutes} min"),
                                _techRow("Formatted Time", _formattedRunningDuration),

                                // Energy Information
                                _sectionHeader("⚡ Energy Information"),
                                _techRow("Consumed Energy", controller.energyConsumed),
                                _techRow("Current Power", controller.currentPower),
                                _techRow("SOC Percentage", controller.currentLiveData?.energy.socPercent != null
                                    ? "${controller.currentLiveData!.energy.socPercent!.toStringAsFixed(1)}%"
                                    : "N/A"),
                                _techRow("Meter Readings", controller.totalMeterReadings.toString()),

                                // Billing Information
                                _sectionHeader("💰 Billing Information"),
                                _techRow("Current Cost", controller.totalCost),
                                _techRow("Currency", controller.currentLiveData?.billing.currency ?? 'INR'),
                                _techRow("Wallet Balance", controller.walletBalance),

                                // Vehicle Information - Using stored values
                                _sectionHeader("🚗 Vehicle Information"),
                                _techRow("Vehicle Name", _vehicleName),
                                _techRow("Registration Number", _registrationNumber),

                                // Charger Information
                                _sectionHeader("🔌 Charger Information"),
                                _techRow("Charger ID", controller.chargerId),
                                _techRow("Charger Name", controller.chargerName),
                                _techRow("Charger Type", controller.chargerType),
                                _techRow("Power Capacity", controller.chargerPowerCapacity),
                                _techRow("Charger Status", controller.chargerStatus),

                                // Connector Information
                                _sectionHeader("⚡ Connector Information"),
                                _techRow("Connector ID", "${controller.currentLiveData?.connector.id ?? 'N/A'}"),
                                _techRow("Connector UID", controller.currentLiveData?.connector.uid ?? 'N/A'),
                                _techRow("Connector Name", controller.connectorName),
                                _techRow("Connector Type", controller.connectorType),
                                _techRow("Connector Status", controller.connectorStatus),

                                // Station Information
                                _sectionHeader("📍 Station Information"),
                                _techRow("Station ID", "${controller.stationId}"),
                                _techRow("Station Name", controller.stationName),
                                _techRow("City", controller.stationCity),

                                // OCPP Information
                                _sectionHeader("🔄 OCPP Information"),
                                _techRow("OCPP Connected", controller.ocppConnected ? "Yes" : "No"),
                                _techRow("OCPP Transaction ID", controller.ocppTransactionId.toString()),
                                _techRow("Meter Readings", controller.totalMeterReadings.toString()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // End Session Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _stopCharging,
                              child: Text(
                                "Stop Charging",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: Appcolor.fontFamily,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Appcolor.green,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: Appcolor.fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Appcolor.lightGrey,
        borderRadius: BorderRadius.circular(10),
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

  Widget _bigCard(String title, String value) {
    return Container(
      height: 105,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Appcolor.lightGrey,
        borderRadius: BorderRadius.circular(12),
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

  Widget _techRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontFamily: Appcolor.fontFamily,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Appcolor.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: Appcolor.fontFamily,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _stopCharging() async {
    int? sessionId = widget.chargingDetails?['sessionId'] ?? _liveChargingController.currentSessionId;

    print('🔍 Stop Charging - Session ID: $sessionId');

    if (sessionId == null) {
      print('❌ Session ID is null');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session ID not found"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Stop"),
            ),
          ],
        );
      },
    );

    if (shouldStop != true) return;

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
      final success = await _stopChargingController.stopChargingSession(
        sessionId: sessionId,
      );

      if (mounted) {
        Navigator.pop(context);
      }

      if (success && mounted) {
        _liveChargingController.stopPolling();
        _durationTimer?.cancel();

        // Get the stop response data
        final stopData = _stopChargingController.stopResponse?.data;

        // If we have stop data, use it, otherwise use live data
        if (stopData != null) {
          // Create a Map from StopChargingData
          final sessionData = {
            'formattedDuration': stopData.formattedDuration,
            'formattedEnergy': stopData.formattedEnergy,
            'formattedCost': stopData.formattedCost,
            'status': stopData.status.toUpperCase(),
            'walletBalanceAfter': double.tryParse(stopData.walletBalanceAfter) ?? 0.0,
          };
          _showCompletionBottomSheet(sessionData);
        } else {
          // Fallback to live data
          _showCompletionBottomSheetForCompletedSession();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_stopChargingController.errorMessage ?? "Failed to stop charging"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error in _stopCharging: $e');
      if (mounted) {
        Navigator.pop(context);
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