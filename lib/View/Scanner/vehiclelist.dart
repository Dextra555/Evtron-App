
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Controller/start_charging_controller.dart';
import '../../Model/start_charging_model.dart';
import '../../Model/vehicle_model.dart';
import '../../Service/charging_session_service.dart';
import '../../Service/start_charging_service.dart';
import '../../Theme/colors.dart';
import 'ChargingProgressPage.dart';

class VehicleScreen extends StatefulWidget {
  final String connectorUid;
  final List<Vehicle> vehicles;
  final String chargerModel;
  final String chargerType;
  final ChargerInfo? chargerInfo;
  final ConnectorInfo? connectorInfo;
  final StationInfo? stationInfo;
  final double? userBalance;
  final int? connectorId;

  const VehicleScreen({
    Key? key,
    required this.connectorUid,
    required this.vehicles,
    required this.chargerModel,
    required this.chargerType,
    this.chargerInfo,
    this.connectorInfo,
    this.stationInfo,
    this.userBalance,
    this.connectorId,
  }) : super(key: key);

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  Vehicle? _selectedVehicle;
  bool _isStartingCharging = false;
  final ChargingController _chargingController = ChargingController();

  // ✅ Save vehicle details to SharedPreferences
  Future<void> _saveVehicleDetailsToStorage({
    required int sessionId,
    required Vehicle vehicle,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final vehicleName = '${vehicle.manufacturer} ${vehicle.model}'.trim();

      // ✅ Save generic vehicle data (fallback)
      await prefs.setString('vehicle_name', vehicleName);
      await prefs.setString('vehicle_manufacturer', vehicle.manufacturer);
      await prefs.setString('vehicle_model', vehicle.model);
      await prefs.setString('vehicle_registration', vehicle.registrationNumber);
      await prefs.setInt('vehicle_id', vehicle.id);

      // ✅ Save session-specific vehicle data (MOST IMPORTANT - tied to session)
      if (sessionId > 0) {
        await prefs.setString('session_${sessionId}_vehicle_name', vehicleName);
        await prefs.setString('session_${sessionId}_vehicle_manufacturer', vehicle.manufacturer);
        await prefs.setString('session_${sessionId}_vehicle_model', vehicle.model);
        await prefs.setString('session_${sessionId}_vehicle_registration', vehicle.registrationNumber);
        await prefs.setInt('session_${sessionId}_vehicle_id', vehicle.id);
      }

      print('✅ VEHICLE DATA SAVED TO STORAGE:');
      print('   Session ID: $sessionId');
      print('   Vehicle: $vehicleName');
      print('   Manufacturer: ${vehicle.manufacturer}');
      print('   Model: ${vehicle.model}');
      print('   Registration: ${vehicle.registrationNumber}');
      print('   Session-specific keys: session_${sessionId}_vehicle_name');

    } catch (e) {
      print('❌ Error saving vehicle details: $e');
    }
  }


// In VehicleScreen (vehiclelist.dart) - Update _startCharging method

  Future<void> _startCharging() async {
    if (_selectedVehicle == null) return;

    setState(() {
      _isStartingCharging = true;
    });

    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║              STARTING CHARGING WITH VEHICLE                   ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('\n📍 Connector UID: ${widget.connectorUid}');
    print('🚗 Vehicle: ${_selectedVehicle!.manufacturer} ${_selectedVehicle!.model}');
    print('📝 Registration: ${_selectedVehicle!.registrationNumber}');

    // ✅ STEP 1: Save vehicle data IMMEDIATELY (before API call)
    await _saveVehicleDetailsToStorage(
      sessionId: 0, // Session ID not known yet, but we'll update later
      vehicle: _selectedVehicle!,
    );
    print('✅ Vehicle data saved BEFORE starting charging');

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
                  "Vehicle: ${_selectedVehicle!.manufacturer} ${_selectedVehicle!.model}",
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
      int connectorId = widget.connectorId ?? _extractConnectorId(widget.connectorUid);

      if (connectorId <= 0) {
        throw Exception('Invalid connector ID. Please scan a valid QR code.');
      }

      final success = await _chargingController.startChargingSession(
        connectorId: connectorId,
        vehicleId: _selectedVehicle!.id,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (success && mounted) {
        print('\n✅ Charging session started successfully!');

        final sessionData = _chargingController.currentSession?.data;
        final prefs = await SharedPreferences.getInstance();
        final fallbackSessionId = prefs.getInt('active_session_id') ?? 0;
        final resolvedSessionId = ChargingService.resolveSessionId(
          response: _chargingController.currentSession,
          fallbackSessionId: fallbackSessionId,
        );

        if (resolvedSessionId > 0) {
          print('✅ Resolved session ID: $resolvedSessionId');
        } else {
          print('⚠️ No session ID returned by backend. Proceeding without it and letting live status recover it.');
        }

        await _saveVehicleDetailsToStorage(
          sessionId: resolvedSessionId,
          vehicle: _selectedVehicle!,
        );

        if (resolvedSessionId > 0 && sessionData != null) {
          await ChargingSessionService.saveActiveSession(
            sessionId: resolvedSessionId,
            startedAt: DateTime.parse(sessionData.startedAt),
            status: 'charging',
            phase: 'starting',
            transactionId: sessionData.transactionId,
            vehicleData: {
              'vehicleName': '${_selectedVehicle!.manufacturer} ${_selectedVehicle!.model}'.trim(),
              'manufacturer': _selectedVehicle!.manufacturer,
              'model': _selectedVehicle!.model,
              'registrationNumber': _selectedVehicle!.registrationNumber,
              'vehicleId': _selectedVehicle!.id,
            },
          );
        }

        final sessionVehicleName = resolvedSessionId > 0
            ? prefs.getString('session_${resolvedSessionId}_vehicle_name') ?? 'NOT FOUND'
            : prefs.getString('vehicle_name') ?? 'NOT FOUND';
        final storedSessionId = prefs.getInt('active_session_id') ?? 0;

        print('📋 VERIFYING DATA IN STORAGE:');
        print('   Session-specific name: $sessionVehicleName');
        print('   Session ID in storage: $storedSessionId');
        print('   Resolved session ID: $resolvedSessionId');

        Map<String, dynamic> chargingDetails = {
          'sessionId': resolvedSessionId > 0 ? resolvedSessionId : null,
          'vehicleId': _selectedVehicle!.id,
          'vehicleName': '${_selectedVehicle!.manufacturer} ${_selectedVehicle!.model}'.trim(),
          'manufacturer': _selectedVehicle!.manufacturer,
          'model': _selectedVehicle!.model,
          'registrationNumber': _selectedVehicle!.registrationNumber,
          'connectorUid': widget.connectorUid,
          'connectorId': connectorId,
        };

        print('📋 CHARGING DETAILS BEING PASSED:');
        print('   Session ID: ${chargingDetails['sessionId']}');
        print('   Vehicle: ${chargingDetails['vehicleName']}');

        if (mounted) {
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
        // Show error dialog
        final errorResponse = _chargingController.getErrorResponse();
        if (errorResponse != null) {
          _showErrorDialog(
            errorResponse.getUserFriendlyMessage(),
            title: errorResponse.getErrorTitle(),
            icon: errorResponse.getErrorIcon(),
            iconColor: errorResponse.getErrorColor(),
            failedCheck: errorResponse.failedCheck,
            errorCode: errorResponse.errorCode,
            actions: errorResponse.getErrorActions(),
          );
        } else {
          _showErrorDialog(
            _chargingController.errorMessage ?? "Failed to start charging",
          );
        }
      }

    } catch (e) {
      print('\n❌ EXCEPTION: $e');
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStartingCharging = false;
        });
      }
    }
  }

  int _extractConnectorId(String connectorUid) {
    try {
      final parts = connectorUid.split('.');
      if (parts.length >= 2) {
        final lastPart = parts.last;
        return int.tryParse(lastPart) ?? 0;
      }
      return 0;
    } catch (e) {
      print('⚠️ Could not extract connector ID from UID: $connectorUid');
      return 0;
    }
  }

  void _showErrorDialog(
      String errorMessage, {
        String? title,
        IconData? icon,
        Color? iconColor,
        String? failedCheck,
        String? errorCode,
        List<ErrorAction>? actions,
      }) {
    title ??= 'Charging Failed';
    icon ??= Icons.error_outline;
    iconColor ??= Colors.red;

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
                Text(
                  errorMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (failedCheck != null || errorCode != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (failedCheck != null)
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Error: $failedCheck',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (errorCode != null)
                          Row(
                            children: [
                              Icon(Icons.code, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Code: $errorCode',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (actions != null && actions.isNotEmpty)
                  ..._buildActionButtons(actions),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildActionButtons(List<ErrorAction> actions) {
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
                _handleAction(action.action);
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
                _handleAction(action.action);
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

  void _handleAction(String action) {
    switch (action) {
      case 'recharge':
        Navigator.pushReplacementNamed(context, '/wallet');
        break;
      case 'try_another':
        Navigator.pop(context);
        Navigator.pop(context);
        break;
      case 'retry':
        _startCharging();
        break;
      case 'go_back':
      default:
        Navigator.pop(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).pop();
          },
          tooltip: 'Back',
        ),
        title: Text(
          'Select Vehicle',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: widget.vehicles.isEmpty
          ? Center(
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
              "No vehicles found",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Please add a vehicle in My EVs section",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolor.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Go Back",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Charger Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Appcolor.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Appcolor.green.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Appcolor.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.ev_station,
                    color: Appcolor.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Connector ID",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        widget.connectorUid,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Appcolor.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.chargerType,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Appcolor.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vehicle Selection Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  "Select Your Vehicle",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Vehicle List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = widget.vehicles[index];
                final isSelected = _selectedVehicle?.id == vehicle.id;
                return GestureDetector(
                  onTap: _isStartingCharging
                      ? null
                      : () {
                    setState(() {
                      _selectedVehicle = vehicle;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Appcolor.green : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected ? Appcolor.green.withOpacity(0.05) : Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Appcolor.green : Colors.grey.shade400,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.directions_car,
                              size: 32,
                              color: isSelected ? Appcolor.green : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${vehicle.manufacturer} ${vehicle.model}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vehicle.registrationNumber,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Appcolor.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedVehicle != null && !_isStartingCharging)
                    ? _startCharging
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolor.green,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isStartingCharging
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  "Confirm & Continue",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

