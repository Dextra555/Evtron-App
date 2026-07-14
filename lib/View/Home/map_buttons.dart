import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Controller/live_charging_controller.dart';
import '../../Service/charging_session_service.dart';
import '../../Service/active_session_service.dart';
import '../Scanner/ChargingProgressPage.dart';

class MapButtonsController {
  final Function()? refreshSession;

  MapButtonsController({this.refreshSession});
}

class MapButtons extends StatefulWidget {
  final VoidCallback onMyLocation;
  final VoidCallback onList;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final Function(int? sessionId)? onNavigate;
  final Function(MapButtonsController)? onControllerCreated;
  final VoidCallback? onRefreshStations;
  final LiveChargingController? chargingController;

  const MapButtons({
    Key? key,
    required this.onMyLocation,
    required this.onList,
    required this.onZoomOut,
    required this.onZoomIn,
    this.onNavigate,
    this.onControllerCreated,
    this.onRefreshStations,
    this.chargingController,
  }) : super(key: key);

  @override
  State<MapButtons> createState() => MapButtonsState();
}

class MapButtonsState extends State<MapButtons> with SingleTickerProviderStateMixin {
  bool _hasActiveSession = false;
  int? _activeSessionId;
  String? _sessionStatus;
  Timer? _refreshTimer;
  LiveChargingController? _controller;
  bool _isChecking = false;
  DateTime? _lastSessionCheckTime;
  static const Duration _minCheckInterval = Duration(seconds: 5);
  int _consecutiveFailures = 0;
  static const int MAX_FAILURES = 3;
  bool _shouldPoll = true;

  // ✅ Vehicle details
  String _vehicleName = 'Unknown Vehicle';
  String _vehicleRegistration = 'N/A';
  String _vehicleManufacturer = '';
  String _vehicleModel = '';

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  bool _isProcessingUpdate = false;
  bool _isLoadingVehicleData = false;
  String? _cachedVehicleName;

  bool _isUpdating = false;
  bool _isRefreshing = false;
  Timer? _updateDebounceTimer;

  static const List<String> _activeStatuses = [
    'charging',
    'preparing',
    'starting',
    'pending',
    'initializing',
    'requesting',
    'active',
    'suspended',
  ];

  static const List<String> _terminalStatuses = [
    'completed',
    'stopped',
    'finished',
    'done',
    'interrupted',
    'error',
    'failed',
    'timeout',
  ];

  static const List<String> _finishingStatuses = [
    'finishing',
  ];

  // ==================== STATUS CHECKERS ====================
  bool _isSessionActive(String? status) {
    if (status == null) return false;
    final lowerStatus = status.toLowerCase();
    return _activeStatuses.contains(lowerStatus);
  }

  bool _isSessionTerminal(String? status) {
    if (status == null) return false;
    final lowerStatus = status.toLowerCase();
    return _terminalStatuses.contains(lowerStatus);
  }

  bool _isSessionFinishing(String? status) {
    if (status == null) return false;
    final lowerStatus = status.toLowerCase();
    return _finishingStatuses.contains(lowerStatus);
  }

  bool _shouldShowActiveButton(String? status) {
    if (status == null) return false;
    return _isSessionActive(status);
  }


  Future<void> _loadVehicleDetails(int sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Try session-specific vehicle details first (most reliable)
      String vehicleName = prefs.getString('session_${sessionId}_vehicle_name') ?? '';
      String registration = prefs.getString('session_${sessionId}_vehicle_registration') ?? '';
      String manufacturer = prefs.getString('session_${sessionId}_vehicle_manufacturer') ?? '';
      String model = prefs.getString('session_${sessionId}_vehicle_model') ?? '';

      // ✅ Fallback to generic vehicle details
      if (vehicleName.isEmpty) {
        vehicleName = prefs.getString('vehicle_name') ?? 'Unknown Vehicle';
        registration = prefs.getString('vehicle_registration') ?? 'N/A';
        manufacturer = prefs.getString('vehicle_manufacturer') ?? '';
        model = prefs.getString('vehicle_model') ?? '';
      }

      setState(() {
        _vehicleName = vehicleName;
        _vehicleRegistration = registration.isNotEmpty ? registration : 'N/A';
        _vehicleManufacturer = manufacturer;
        _vehicleModel = model;
      });

      if (_controller != null) {
        _controller!.setVehicleDetails(
          name: _vehicleName,
          manufacturer: _vehicleManufacturer,
          model: _vehicleModel,
          registration: _vehicleRegistration,
        );
      }

      // ✅ Only log if vehicle changed (not on every load to reduce spam)
      if (_cachedVehicleName != vehicleName) {
        print('✅ Vehicle loaded: $_vehicleName (Session: $sessionId)');
        _cachedVehicleName = vehicleName;
      }

    } catch (e) {
      print('⚠️ Error loading vehicle details: $e');
    }
  }

  /// ✅ Update session state and load vehicle details
  Future<void> _updateSessionWithVehicleDetails(int sessionId, String status) async {
    setState(() {
      _hasActiveSession = _shouldShowActiveButton(status);
      _activeSessionId = sessionId;
      _sessionStatus = status;
    });

    // ✅ Load vehicle details for this session
    await _loadVehicleDetails(sessionId);

    // ✅ Update controller with vehicle details
    if (_controller != null) {
      _controller!.setVehicleDetails(
        name: _vehicleName,
        manufacturer: _vehicleManufacturer,
        model: _vehicleModel,
        registration: _vehicleRegistration,
      );
    }
  }

  // ==================== INIT STATE ====================
  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController!,
        curve: Curves.easeInOut,
      ),
    );

    _controller = widget.chargingController ?? LiveChargingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveSessionOnStartup();
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted && _shouldPoll) {
        final currentRoute = ModalRoute.of(context);
        final isOnChargingPage = currentRoute?.settings.name == '/charging-progress' ||
            currentRoute?.settings.name?.contains('ChargingProgress') == true;

        if (!isOnChargingPage) {
          _checkActiveSession();
        }
      }
    });

    if (widget.onControllerCreated != null) {
      widget.onControllerCreated!(MapButtonsController(
        refreshSession: _checkActiveSession,
      ));
    }

    if (widget.chargingController != null) {
      widget.chargingController!.addListener(_onControllerUpdate);
    }
  }

  // ==================== UPDATE SESSION STATE FROM CONTROLLER ====================
// In MapButtonsState - Update _updateSessionStateFromController

  void _updateSessionStateFromController() {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      if (_controller == null) {
        _isUpdating = false;
        return;
      }

      final liveData = _controller!.currentLiveData;

      if (liveData == null) {
        _checkStorageForSession();
        _isUpdating = false;
        return;
      }

      final status = liveData.status?.toLowerCase() ?? '';
      final sessionId = _validateSessionId(liveData.sessionId);

      // ✅ Only log once per status change (no verbose logging on every update)
      if (_sessionStatus != liveData.status) {
        print('📡 Status changed: $status (Session: $sessionId)');
      }

      if (sessionId != null && sessionId > 0) {
        _saveSessionToStorage(sessionId, liveData.status);

        // ✅ Load vehicle details for this session
        _loadVehicleDetails(sessionId);
      }

      if (_shouldShowActiveButton(status) && sessionId != null && sessionId > 0) {
        setState(() {
          _hasActiveSession = true;
          _activeSessionId = sessionId;
          _sessionStatus = liveData.status;
        });

        if (_controller != null && !_controller!.isPollingActive) {
          _controller!.startPolling(sessionId: sessionId);
        }
      } else {
        setState(() {
          _hasActiveSession = false;
          _activeSessionId = sessionId;
          _sessionStatus = liveData.status;
        });

        if (_isSessionTerminal(status)) {
          _controller?.stopPolling();
        }
      }
    } catch (e) {
      print('❌ Error updating session state: $e');
    } finally {
      _isUpdating = false;
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    if (_isProcessingUpdate) return;
    _isProcessingUpdate = true;

    _updateDebounceTimer?.cancel();
    _updateDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _updateSessionStateFromController();
        _isProcessingUpdate = false;
      }
    });
  }

  Future<void> _checkActiveSessionOnStartup() async {
    if (_isChecking) return;
    _isChecking = true;

    print('🔍 ========== CHECKING ACTIVE SESSION ON STARTUP ==========');

    try {
      final prefs = await SharedPreferences.getInstance();

      int? sessionId = prefs.getInt('active_session_id');
      if (sessionId == null) {
        sessionId = prefs.getInt('session_id');
      }

      String? status = prefs.getString('session_status');
      if (status == null) {
        status = prefs.getString('session_status_active');
      }

      print('📋 Storage Check:');
      print('   Session ID: $sessionId');
      print('   Status: $status');

      if (sessionId != null && sessionId > 0) {
        if (_shouldShowActiveButton(status)) {
          print('✅ Found ACTIVE session in storage: $sessionId');
          print('   Status: $status');

          // ✅ Load vehicle details
          await _loadVehicleDetails(sessionId);

          setState(() {
            _hasActiveSession = true;
            _activeSessionId = sessionId;
            _sessionStatus = status;
          });

          if (_controller != null) {
            try {
              print('🔄 Verifying with server...');
              final success = await _controller!.fetchLiveChargingStatus(
                sessionId: sessionId,
              );

              if (success && _controller!.currentLiveData != null) {
                final liveData = _controller!.currentLiveData!;
                final liveStatus = liveData.status?.toLowerCase() ?? '';

                if (_shouldShowActiveButton(liveStatus)) {
                  print('✅ Server confirms active session: $sessionId');
                  // ✅ Reload vehicle details from server response
                  await _loadVehicleDetails(sessionId);

                  setState(() {
                    _hasActiveSession = true;
                    _activeSessionId = sessionId;
                    _sessionStatus = liveData.status;
                  });

                  if (!_controller!.isPollingActive) {
                    _controller!.startPolling(sessionId: sessionId);
                  }
                } else if (_isSessionFinishing(liveStatus)) {
                  print('⏳ Server says finishing - keep in storage but hide button');
                  setState(() {
                    _hasActiveSession = false;
                    _activeSessionId = sessionId;
                    _sessionStatus = liveData.status;
                  });
                } else if (_isSessionTerminal(liveStatus)) {
                  print('⏹️ Server says terminal - clearing storage');
                  await _clearSessionData();
                } else {
                  print('⚠️ Unknown status from server: $liveStatus - hiding but keeping storage');
                  setState(() {
                    _hasActiveSession = false;
                    _activeSessionId = sessionId;
                    _sessionStatus = liveStatus;
                  });
                }
              } else {
                print('⚠️ Could not verify with server, keeping storage state');
              }
            } catch (e) {
              print('⚠️ Error verifying with server: $e');
            }
          }
          _isChecking = false;
          return;
        } else if (_isSessionFinishing(status)) {
          print('⏳ Session is finishing - hiding button but keeping storage');
          setState(() {
            _hasActiveSession = false;
            _activeSessionId = sessionId;
            _sessionStatus = status;
          });
          _isChecking = false;
          return;
        } else {
          if (_isSessionTerminal(status)) {
            print('⏹️ Terminal status in storage: $status - clearing');
            await _clearSessionData();
          } else {
            print('⚠️ Unknown status in storage: $status - keeping but hiding');
            setState(() {
              _hasActiveSession = false;
              _activeSessionId = sessionId;
              _sessionStatus = status;
            });
          }
        }
      }

      if (_controller != null && sessionId == null) {
        try {
          print('🔄 No session in storage, checking API directly...');
          final success = await _controller!.fetchLiveChargingStatus().timeout(
            const Duration(seconds: 5),
          );

          if (success && _controller!.currentLiveData != null) {
            final liveData = _controller!.currentLiveData!;
            final status = liveData.status?.toLowerCase() ?? '';

            if (_shouldShowActiveButton(status)) {
              final sessionId = liveData.sessionId;
              if (sessionId != null && sessionId > 0) {
                print('✅ Found active session from API: $sessionId');
                print('   Status: ${liveData.status}');

                // ✅ Load vehicle details
                await _loadVehicleDetails(sessionId);

                setState(() {
                  _hasActiveSession = true;
                  _activeSessionId = sessionId;
                  _sessionStatus = liveData.status;
                });

                await _saveSessionToStorage(sessionId, liveData.status);

                if (!_controller!.isPollingActive) {
                  _controller!.startPolling(sessionId: sessionId);
                }
              }
            } else if (_isSessionFinishing(status)) {
              print('⏳ Session is finishing - hiding button');
              setState(() {
                _hasActiveSession = false;
                _activeSessionId = liveData.sessionId;
                _sessionStatus = liveData.status;
              });
              if (liveData.sessionId != null && liveData.sessionId > 0) {
                await _saveSessionToStorage(liveData.sessionId, liveData.status);
              }
            } else {
              print('⚠️ No active session from API');
              await _clearSessionData();
            }
          }
        } catch (e) {
          print('⚠️ API check failed: $e');
        }
      }

      print('✅ ========== STARTUP CHECK COMPLETE ==========');
    } catch (e) {
      print('❌ Error checking session on startup: $e');
    } finally {
      _isChecking = false;
    }
  }

  // ==================== CLEAR SESSION DATA ====================
  Future<void> _clearSessionData() async {
    print('🗑️ Clearing active session data from storage...');
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('active_session_id');
      await prefs.remove('session_status_active');
      await prefs.remove('session_status');

      if (mounted) {
        setState(() {
          _hasActiveSession = false;
          _activeSessionId = null;
          _sessionStatus = null;
          _vehicleName = 'Unknown Vehicle';
          _vehicleRegistration = 'N/A';
          _vehicleManufacturer = '';
          _vehicleModel = '';
        });
      }
    } catch (e) {
      print('❌ Error clearing session data: $e');
    }
  }

  // ==================== SAVE SESSION TO STORAGE ====================
  Future<void> _saveSessionToStorage(int sessionId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('session_id', sessionId);

      if (_isSessionActive(status)) {
        await prefs.setInt('active_session_id', sessionId);
        await prefs.setString('session_status_active', status);
      }

      await prefs.setString('session_status', status);
      // ✅ Session saved (silent log - reduce spam)
    } catch (e) {
      print('Error saving session to storage: $e');
    }
  }

  // ==================== CHECK STORAGE FOR SESSION ====================
  Future<void> _checkStorageForSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? sessionId = prefs.getInt('active_session_id');
      if (sessionId == null) {
        sessionId = prefs.getInt('session_id');
      }
      String? status = prefs.getString('session_status');

      if (mounted) {
        setState(() {
          if (sessionId != null && sessionId > 0) {
            _hasActiveSession = _shouldShowActiveButton(status);
            _activeSessionId = sessionId;
            _sessionStatus = status;
          } else {
            _hasActiveSession = false;
            _activeSessionId = null;
            _sessionStatus = null;
          }
        });
      }
    } catch (e) {
      print('Error checking storage for session: $e');
    }
  }

  // ==================== VALIDATE SESSION ID ====================
  int? _validateSessionId(dynamic id) {
    if (id == null) return null;
    try {
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
      if (id is double) {
        if (id.isNaN || id.isInfinite) return null;
        return id.toInt();
      }
      if (id is num) return id.toInt();
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== CHECK ACTIVE SESSION ====================
  Future<void> _checkActiveSession() async {
    final now = DateTime.now();
    if (_lastSessionCheckTime != null) {
      final elapsed = now.difference(_lastSessionCheckTime!);
      if (elapsed < _minCheckInterval) {
        print('⏳ Skipping check, last check was ${elapsed.inSeconds}s ago');
        return;
      }
    }
    _lastSessionCheckTime = now;

    if (_isChecking) return;
    _isChecking = true;

    try {
      if (_hasActiveSession && _controller != null && _controller!.currentLiveData != null) {
        final liveData = _controller!.currentLiveData!;
        final status = liveData.status?.toLowerCase() ?? '';

        if (!_shouldShowActiveButton(status)) {
          print('⚠️ Session no longer active (status: $status) - hiding button');
          if (mounted) {
            setState(() {
              _hasActiveSession = false;
              _activeSessionId = liveData.sessionId;
              _sessionStatus = liveData.status;
            });
          }
          if (_isSessionTerminal(status) || _isSessionFinishing(status)) {
            _controller?.stopPolling();
          }
          _isChecking = false;
          return;
        }
        _isChecking = false;
        return;
      }

      if (_controller != null) {
        try {
          final success = await _controller!.fetchLiveChargingStatus().timeout(
            const Duration(seconds: 3),
          );
          if (success) {
            _updateSessionStateFromController();
          }
        } catch (e) {
          print('⚠️ API check failed: $e');
          _consecutiveFailures++;
          if (_consecutiveFailures >= MAX_FAILURES) {
            _shouldPoll = false;
          }
        }
      }
    } catch (e) {
      print('❌ Error checking session: $e');
    } finally {
      _isChecking = false;
    }
  }


  void _handleActiveSessionTap() {
    int? sessionId = _activeSessionId;

    // ✅ Show vehicle info when tapping with vehicle details
    if (_vehicleName.isNotEmpty && _vehicleName != 'Unknown Vehicle') {
      // Show a nice snackbar with vehicle info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_vehicleName • $_vehicleRegistration',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    if (sessionId == null && _controller != null) {
      final rawId = _controller!.currentSessionId;
      if (rawId != null && rawId > 0) {
        sessionId = rawId is int ? rawId : int.tryParse(rawId.toString());
      }
    }

    if (sessionId == null) {
      _getSessionIdFromStorage().then((storedId) {
        if (storedId != null && mounted) {
          _navigateToChargingProgress(storedId);
        } else {
          _showNoSessionError();
        }
      });
      return;
    }

    if (sessionId <= 0) {
      _showNoSessionError();
      return;
    }

    _navigateToChargingProgress(sessionId);
  }

  Future<int?> _getSessionIdFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? sessionId = prefs.getInt('active_session_id');
      if (sessionId == null) {
        sessionId = prefs.getInt('session_id');
      }
      return sessionId;
    } catch (e) {
      print('Error getting session ID from storage: $e');
      return null;
    }
  }

  // ==================== SHOW NO SESSION ERROR ====================
  void _showNoSessionError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No active charging session found"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

// In MapButtonsState - Update _navigateToChargingProgress

  void _navigateToChargingProgress(int sessionId) {
    print('🔄 Navigating to ChargingProgress with sessionId: $sessionId');
    print('   Vehicle: $_vehicleName');
    print('   Registration: $_vehicleRegistration');
    print('   Manufacturer: $_vehicleManufacturer');
    print('   Model: $_vehicleModel');

    if (widget.onNavigate != null) {
      // Pass vehicle details along with session ID
      widget.onNavigate!(sessionId);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChargingProgressPage(
            chargingDetails: {
              'sessionId': sessionId,
              'vehicleName': _vehicleName,
              'manufacturer': _vehicleManufacturer,
              'model': _vehicleModel,
              'registrationNumber': _vehicleRegistration,
            },
          ),
        ),
      );
    }
  }
  // ==================== ON MY LOCATION PRESSED ====================
  void _onMyLocationPressed() {
    widget.onMyLocation();
    if (widget.onRefreshStations != null) {
      widget.onRefreshStations!();
    }
  }

  // ==================== STOP POLLING ====================
  void stopPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _shouldPoll = false;
    _updateDebounceTimer?.cancel();
  }

  // ==================== DISPOSE ====================
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _updateDebounceTimer?.cancel();
    _pulseController?.dispose();
    if (widget.chargingController == null) {
      _controller?.dispose();
    } else {
      widget.chargingController!.removeListener(_onControllerUpdate);
    }
    super.dispose();
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final buttonBackgroundColor = Colors.black.withOpacity(0.6);
    final buttonSplashColor = Colors.white.withOpacity(0.2);
    final buttonHighlightColor = Colors.white.withOpacity(0.1);

    return Column(
      children: [
        _circleButton(
          icon: Icons.my_location,
          onPressed: _onMyLocationPressed,
          color: Colors.white,
          backgroundColor: buttonBackgroundColor,
          splashColor: buttonSplashColor,
          highlightColor: buttonHighlightColor,
        ),
        const SizedBox(height: 10),
        _circleButton(
          icon: Icons.list,
          onPressed: widget.onList,
          color: Colors.white,
          backgroundColor: buttonBackgroundColor,
          splashColor: buttonSplashColor,
          highlightColor: buttonHighlightColor,
        ),
        const SizedBox(height: 10),
        _circleButton(
          icon: Icons.add,
          onPressed: widget.onZoomIn,
          color: Colors.white,
          backgroundColor: buttonBackgroundColor,
          splashColor: buttonSplashColor,
          highlightColor: buttonHighlightColor,
        ),
        const SizedBox(height: 10),
        _circleButton(
          icon: Icons.remove,
          onPressed: widget.onZoomOut,
          color: Colors.white,
          backgroundColor: buttonBackgroundColor,
          splashColor: buttonSplashColor,
          highlightColor: buttonHighlightColor,
        ),
        const SizedBox(height: 10),
        // Show active session button ONLY if genuinely active
        if (_hasActiveSession && _shouldShowActiveButton(_sessionStatus)) ...[
          _buildActiveSessionButton(),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // ==================== BUILD ACTIVE SESSION BUTTON ====================
  Widget _buildActiveSessionButton() {
    final isSuspended = _sessionStatus?.toLowerCase() == 'suspended';
    final buttonColor = isSuspended ? Colors.orange : Colors.green;
    final pulseColor = isSuspended ? Colors.orange : Colors.green;

    // ✅ Show vehicle name as tooltip
    final tooltip = _vehicleName.isNotEmpty && _vehicleName != 'Unknown Vehicle'
        ? '$_vehicleName • $_vehicleRegistration'
        : 'Active Charging Session';

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: _handleActiveSessionTap,
        child: AnimatedBuilder(
          animation: _pulseController!,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation!.value,
              child: Container(
                decoration: BoxDecoration(
                  color: buttonColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: pulseColor.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: pulseColor.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleActiveSessionTap,
                    customBorder: const CircleBorder(),
                    splashColor: Colors.white.withOpacity(0.3),
                    highlightColor: Colors.white.withOpacity(0.2),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: isSuspended
                          ? const Icon(
                        Icons.pause_circle_outline,
                        color: Colors.white,
                        size: 28,
                      )
                          : const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== CIRCLE BUTTON ====================
  Widget _circleButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
    required Color backgroundColor,
    required Color splashColor,
    required Color highlightColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          splashColor: splashColor,
          highlightColor: highlightColor,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}