import 'package:evtron/View/Home/scanner.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../Controller/live_charging_controller.dart';
import '../../Controller/stop_charging_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _liveChargingController = LiveChargingController();

    int? sessionId = widget.chargingDetails?['sessionId'];

    _liveChargingController.startPolling(
      sessionId: sessionId,
      interval: const Duration(seconds: 5),
    );

    // Add a listener to update session start time when data loads
    _liveChargingController.addListener(_onLiveDataUpdate);

    // Start the duration timer that updates every second
    _startDurationTimer();
  }

  void _onLiveDataUpdate() {
    // When live data updates, capture the session start time
    if (_sessionStartTime == null && _liveChargingController.currentLiveData != null) {
      final startedAtRaw = _liveChargingController.currentLiveData?.startedAt;

      if (startedAtRaw != null) {
        _sessionStartTime = _parseDateTime(startedAtRaw);

        // If still null, use current time minus elapsed time as fallback
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

  // Helper method to extract Duration from ElapsedTime object
  Duration? _extractDurationFromElapsedTime(dynamic elapsedTime) {
    if (elapsedTime == null) return null;

    // Try to get seconds from ElapsedTime object
    try {
      // If it has a 'seconds' property
      if (elapsedTime is Map) {
        final seconds = elapsedTime['seconds'];
        if (seconds is int) return Duration(seconds: seconds);
        if (seconds is double) return Duration(seconds: seconds.toInt());
      }

      // If it has a 'inSeconds' method or property
      if (elapsedTime is dynamic) {
        // Try common property names
        if (elapsedTime.seconds != null) return Duration(seconds: elapsedTime.seconds as int);
        if (elapsedTime.inSeconds != null) return Duration(seconds: elapsedTime.inSeconds as int);
        if (elapsedTime.totalSeconds != null) return Duration(seconds: elapsedTime.totalSeconds as int);

        // Try to convert to string and parse
        final elapsedStr = elapsedTime.toString();
        if (elapsedStr.contains('seconds:')) {
          // Parse format like "ElapsedTime(seconds: 120)"
          final regex = RegExp(r'seconds:\s*(\d+)');
          final match = regex.firstMatch(elapsedStr);
          if (match != null) {
            final seconds = int.tryParse(match.group(1)!);
            if (seconds != null) return Duration(seconds: seconds);
          }
        }
      }

      // If it's a number directly
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

    // Try to extract from ElapsedTime object
    final extracted = _extractDurationFromElapsedTime(duration);
    if (extracted != null) return extracted;

    if (duration is Duration) {
      return duration;
    } else if (duration is int) {
      return Duration(seconds: duration);
    } else if (duration is double) {
      return Duration(milliseconds: (duration * 1000).round());
    } else if (duration is String) {
      // Try to parse string format
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
            // Calculate duration based on session start time
            _currentDuration = DateTime.now().difference(_sessionStartTime!);
          } else if (_liveChargingController.currentLiveData != null) {
            // Fallback to elapsed time from API
            final elapsed = _liveChargingController.currentLiveData?.elapsedTime;
            _currentDuration = _parseDuration(elapsed);

            // Try to set start time again
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
    _liveChargingController.stopPolling();
    _liveChargingController.dispose();
    _stopChargingController.dispose();
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _stopCharging() async {
    int? sessionId = widget.chargingDetails?['sessionId'];

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

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            final data = _stopChargingController.stopResponse?.data;
            return AlertDialog(
              title: const Text("Charging Session Complete"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Session Summary",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Appcolor.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _summaryRow("Duration", data?.formattedDuration ?? "N/A"),
                  _summaryRow("Energy Consumed", data?.formattedEnergy ?? "N/A"),
                  _summaryRow("Total Cost", data?.formattedCost ?? "N/A"),
                  _summaryRow("Wallet Balance", "₹${data?.walletBalanceAfter ?? '0.00'}"),
                  const SizedBox(height: 8),
                  Text(
                    "Status: ${data?.status?.toUpperCase() ?? 'COMPLETED'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const ScannerPage()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Appcolor.green,
                  ),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
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

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
          child: Column(
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
                child: Consumer<LiveChargingController>(
                  builder: (context, controller, child) {
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

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.chargingDetails?['vehicleName'] ?? "Tata Nexon EV",
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
                                      widget.chargingDetails?['registrationNumber'] ?? "TN21BX1585",
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
                                        Icon(Icons.circle,
                                            color: controller.chargingStatus == "Charging" ? Appcolor.green : Colors.red,
                                            size: 8),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            "Updating in 5s",
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
                                _techRow("Meter Values Count", "${controller.meterValuesCount}"),
                                _techRow("Meter Readings", controller.totalMeterReadings.toString()),

                                // Cost Information
                                _sectionHeader("💰 Cost Information"),
                                _techRow("Total Cost", controller.totalCost),
                                _techRow("Currency", controller.currentLiveData?.cost.currency ?? 'INR'),

                                // Charger Information
                                _sectionHeader("🔌 Charger Information"),
                                _techRow("Charger ID", controller.chargerId),
                                _techRow("Charger Name", controller.chargerName),
                                _techRow("Power Capacity", controller.chargerPowerCapacity),
                                _techRow("Charger Status", controller.chargerStatus),

                                // Connector Information
                                _sectionHeader("⚡ Connector Information"),
                                _techRow("Connector ID", "${controller.currentLiveData?.connector.id ?? 'N/A'}"),
                                _techRow("Connector Name", controller.connectorName),
                                _techRow("Connector Type", controller.connectorType),
                                _techRow("Connector Status", controller.connectorStatus),

                                // Station Information
                                _sectionHeader("📍 Station Information"),
                                _techRow("Station ID", "${controller.stationId}"),
                                _techRow("Station Name", controller.stationName),
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
                    );
                  },
                ),
              ),
            ],
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
          Text(title,
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
          Text(value,
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
          Text(title,
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
          Text(value,
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
            child: Text(title,
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
            child: Text(value,
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
}