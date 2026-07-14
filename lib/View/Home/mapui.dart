import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../Controller/live_charging_controller.dart';
import '../../Controller/wallet_controller.dart';
import '../../Model/ev_station_model.dart';
import '../../Service/AuthService.dart';
import '../../Service/WishlistService.dart';
import '../../Service/charging_session_service.dart';
import '../../Service/location_service.dart';
import '../../Service/station_service.dart';
import '../../session_manager.dart';
import '../Scanner/scanner.dart';
import '../Login/Bottom.dart';
import '../Login/login.dart';
import '../Payment/paymentpage.dart';
import '../Profile/profile.dart';
import '../Scanner/ChargingProgressPage.dart';
import 'CustomMarkerlocation.dart';
import 'homenearby.dart';
import 'map_buttons.dart';
import 'map_search_bar.dart';
import 'station_card.dart';
import 'station_details_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  LatLng _currentPosition = const LatLng(10.8, 78.7);
  List<EVStation> _evStations = [];
  EVStation? _selectedStation;
  double? _selectedStationDistance;
  final Set<int> _favoriteStationIds = {};
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isGettingLocation = true;
  bool _isFirstLoad = true;
  bool _isMapReady = false;
  double _walletBalance = 0.00;
  bool _locationPermissionGranted = false;
  bool _locationServicesEnabled = true;
  bool _hasShownLocationDialog = false;
  static bool _hasShownInCurrentSession = false;
  bool _stationsLoaded = false;
  late final WalletController _walletController;

  MapButtonsController? _mapButtonsController;
  LiveChargingController? _chargingController;
  late final LocationService _locationService;
  late final StationService _stationService;
  late final WishlistService _wishlistService;

  bool _isUpdating = false;
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 2);
  bool _authDialogVisible = false;

  Timer? _controllerUpdateDebounce;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationService = LocationService();
    _stationService = StationService();
    _wishlistService = WishlistService();
    _chargingController = LiveChargingController();
    _chargingController!.addListener(_onChargingControllerUpdate);
    _walletController = WalletController();
    _loadWalletBalance();
    _checkAndRequestPermission();
    _listenToLocationServices();
    _checkForActiveSessionOnInit();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && mounted && !_isLoading) {
        _fetchEVStations();
      }
    });
  }

  void _onChargingControllerUpdate() {
    // ✅ Use debounce to prevent excessive updates
    _controllerUpdateDebounce?.cancel();
    _controllerUpdateDebounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted && _mapButtonsController != null) {
        _mapButtonsController!.refreshSession?.call();
      }
    });
  }

  @override
  void dispose() {
    _controllerUpdateDebounce?.cancel();
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_mapController != null) {
      _mapController!.dispose();
    }
    if (_chargingController != null) {
      _chargingController!.removeListener(_onChargingControllerUpdate);
      _chargingController!.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _refreshMapButtons();
      _loadWalletBalance();
      await _checkForActiveSessionOnInit();

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (serviceEnabled &&
          (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse)) {
        setState(() {
          _locationPermissionGranted = true;
          _locationServicesEnabled = true;
          _stationsLoaded = false;
        });

        await _getCurrentLocation();

        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              _currentPosition,
              14,
            ),
          );
        }
      }
    }
  }

  void _listenToLocationServices() {
    Geolocator.getServiceStatusStream().listen((status) {
      if (mounted) {
        final isEnabled = (status == ServiceStatus.enabled);
        setState(() {
          _locationServicesEnabled = isEnabled;
        });

        if (isEnabled && _locationPermissionGranted && !_stationsLoaded) {
          _refreshStationsWithLocation();
        } else if (!isEnabled && _locationPermissionGranted && !_hasShownLocationDialog && !_hasShownInCurrentSession) {
          _showLocationAccuracyDialog();
        }
      }
    });
  }

  Future<void> _loadWalletBalance() async {
    try {
      final token = await AuthService.getUserToken();
      if (token == null || token.isEmpty) return;

      await _walletController.fetchWallet(token);
      if (_walletController.wallet != null && mounted) {
        setState(() {
          _walletBalance = double.tryParse(
            _walletController.wallet!.walletBalance,
          ) ?? 0.0;
        });
      }
    } catch (e) {
      print("Error loading wallet balance: $e");
    }
  }


  Future<void> _checkForActiveSessionOnInit() async {
    try {
      print('\n🔍 ========== CHECKING SESSION ON MAP INIT ==========');

      // ✅ STEP 1: Get session data from storage (same as before)
      final sessionData = await ChargingSessionService.getActiveSessionData();

      if (sessionData != null && sessionData['sessionId'] != null) {
        final sessionId = sessionData['sessionId'];
        final status = sessionData['status'] ?? 'unknown';

        print('📋 Found active session on init:');
        print('   Session ID: $sessionId');
        print('   Status: $status');

        // ✅ STEP 2: Load vehicle details (same flow as session ID)
        await _loadVehicleDetailsFromStorage(sessionId);

        // ✅ STEP 3: Fetch session data
        await _fetchSessionData(sessionId);
      } else {
        print('ℹ️ No active session found on init');
      }
      print('==========================================\n');
    } catch (e) {
      print('❌ Error checking session on init: $e');
    }
  }

// ✅ Load vehicle details (same pattern as session ID recovery)
  Future<void> _loadVehicleDetailsFromStorage(int sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Try to get vehicle details for this session
      String vehicleName = prefs.getString('session_${sessionId}_vehicle_name') ?? '';
      String manufacturer = prefs.getString('session_${sessionId}_vehicle_manufacturer') ?? '';
      String model = prefs.getString('session_${sessionId}_vehicle_model') ?? '';
      String registration = prefs.getString('session_${sessionId}_vehicle_registration') ?? '';

      // ✅ Fallback: Get generic vehicle details
      if (vehicleName.isEmpty) {
        vehicleName = prefs.getString('vehicle_name') ?? 'Unknown Vehicle';
        manufacturer = prefs.getString('vehicle_manufacturer') ?? '';
        model = prefs.getString('vehicle_model') ?? '';
        registration = prefs.getString('vehicle_registration') ?? '';
      }

      // ✅ Store in controller or state for later use
      if (_chargingController != null) {
        // Store vehicle details in controller cache
        _chargingController!.setVehicleDetails(
          name: vehicleName,
          manufacturer: manufacturer,
          model: model,
          registration: registration,
        );
      }

      print('✅ Vehicle details loaded from storage:');
      print('   Vehicle: $vehicleName');
      print('   Manufacturer: $manufacturer');
      print('   Model: $model');
      print('   Registration: $registration');

    } catch (e) {
      print('⚠️ Error loading vehicle details: $e');
    }
  }

// ✅ Update fetch session data to use vehicle details
  Future<void> _fetchSessionData(int sessionId) async {
    try {
      if (_chargingController == null) return;

      await _chargingController!.fetchLiveChargingStatus(sessionId: sessionId);

      if (_chargingController!.currentLiveData != null) {
        print('✅ Session data loaded into controller');
        print('   Status: ${_chargingController!.currentLiveData!.status}');
        print('   Phase: ${_chargingController!.currentLiveData!.phase}');

        // ✅ Vehicle details are already loaded from storage
        // The controller will use them via its getters

        _refreshMapButtons();
      }
    } catch (e) {
      print('❌ Error fetching session data: $e');
    }
  }

  Future<void> _refreshStationsWithLocation() async {
    print("🔄 Refreshing stations with location...");
    setState(() {
      _isLoading = true;
      _stationsLoaded = false;
    });

    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
      });

      if (_mapController != null && _isMapReady) {
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 14),
        );
      }

      await _fetchEVStations();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLocationAccuracyDialog() {
    if (_hasShownLocationDialog) return;

    _hasShownInCurrentSession = true;
    _hasShownLocationDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.orange[700], size: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "For a better experience, your device will need to use Location Accuracy",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "The following settings should be on:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  const Text("• Device location"),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "• Location Accuracy, which provides more accurate location for apps and services.",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Geolocator.openLocationSettings();
                },
                child: const Text(
                  "Manage settings or learn more",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeMapWithoutLocation();
            },
            child: const Text(
              "No, thanks",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
              await Future.delayed(const Duration(milliseconds: 1500));

              bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
              print("📍 After settings return, location enabled: $serviceEnabled");

              if (serviceEnabled && mounted) {
                LocationPermission permission = await Geolocator.checkPermission();
                print("📍 Permission after settings: $permission");

                if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
                  setState(() {
                    _locationPermissionGranted = true;
                    _locationServicesEnabled = true;
                    _stationsLoaded = false;
                  });
                  await _forceRefreshStations();
                } else if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                  if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
                    setState(() {
                      _locationPermissionGranted = true;
                      _locationServicesEnabled = true;
                      _stationsLoaded = false;
                    });
                    await _forceRefreshStations();
                  }
                }
              } else if (mounted) {
                _initializeMapWithoutLocation();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Turn on",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ).then((_) {
      _hasShownLocationDialog = false;
    });
  }

  Future<void> _forceRefreshStations() async {
    print("🔄 Force refreshing stations...");

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _evStations.clear();
      _markers.clear();
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null && mounted) {
        print("📍 Got location: ${position.latitude}, ${position.longitude}");
        setState(() {
          _currentPosition = position;
        });

        if (_mapController != null && _isMapReady) {
          await _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(position, 14),
          );
        }

        await _fetchEVStations();
      } else {
        print("⚠️ Could not get location after enabling");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error in force refresh: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _locationServicesEnabled = serviceEnabled;
    });

    if (!serviceEnabled) {
      if (!_hasShownInCurrentSession) {
        _showLocationAccuracyDialog();
      } else {
        _initializeMapWithoutLocation();
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        _initializeMapWithoutLocation();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!_hasShownInCurrentSession) {
        _showSettingsDialog();
      } else {
        _initializeMapWithoutLocation();
      }
      return;
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      setState(() {
        _locationPermissionGranted = true;
      });
      await _initializeMap();
      _setupLocationListener();
    }
  }

  void _showSettingsDialog() {
    _hasShownInCurrentSession = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Location Permission Required"),
        content: const Text("Location permission is permanently denied. You can still browse stations but won't see your current location."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeMapWithoutLocation();
            },
            child: const Text("Continue Without"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) {
                await _checkAndRequestPermission();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _initializeMapWithoutLocation() async {
    setState(() {
      _locationPermissionGranted = false;
      _isGettingLocation = false;
    });
    await _loadFavoritesFromStorage();
    await _fetchEVStations();
  }

  void _setupLocationListener() {
    _locationService.getLocationStream().listen((position) {
      if (position != null && mounted && _isMapReady && _locationPermissionGranted && _locationServicesEnabled && !_stationsLoaded) {
        print("📍 Location stream received: ${position.latitude}, ${position.longitude}");
        setState(() {
          _currentPosition = position;
        });
        _updateSearchRadius();
        if (!_stationsLoaded) {
          _fetchEVStations();
        }
      }
    });
  }

  Future<void> _initializeMap() async {
    await _loadFavoritesFromStorage();
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isGettingLocation = true;
      if (_isFirstLoad) _isLoading = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null && mounted) {
        print("📍 Got current location: ${position.latitude}, ${position.longitude}");
        setState(() {
          _currentPosition = position;
          _isGettingLocation = false;
        });

        if (_mapController != null && _isMapReady) {
          await _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(position, 14),
          );
          _isFirstLoad = false;
        }

        await _fetchEVStations();
      } else {
        print("⚠️ Could not get current location");
        setState(() {
          _isGettingLocation = false;
        });
        await _fetchEVStations();
      }
    } catch (e) {
      print("❌ Error getting location: $e");
      setState(() {
        _isGettingLocation = false;
      });
      await _fetchEVStations();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchEVStations() async {
    if (!mounted) return;

    print("📍 Fetching EV Stations with current position: ${_currentPosition.latitude}, ${_currentPosition.longitude}");

    setState(() {
      _isLoading = true;
    });

    try {
      final stations = await _stationService.fetchStations(
        currentPosition: (_locationPermissionGranted && _locationServicesEnabled)
            ? _currentPosition
            : null,
      );

      print("✅ Received ${stations.length} stations");

      setState(() {
        _evStations = [];
        _markers.clear();
        _stationsLoaded = true;
      });

      if (stations.isNotEmpty && mounted) {
        for (var station in stations) {
          print('📊 Station: ${station.name}');
          print('   Available: ${station.availableChargers}');
          print('   Total: ${station.totalChargers}');
        }

        setState(() {
          _evStations = stations;
        });

        await _addMarkersFromStations();
        await _wishlistService.refreshWishlist(_updateFavoriteIds);
        setState(() {});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No EV stations found in your area'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } on AuthSessionExpiredException catch (e) {
      if (mounted && !_authDialogVisible) {
        await _showSessionExpiredDialog(e.message);
      }
    } catch (e) {
      print("❌ Error fetching stations: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showSessionExpiredDialog(String message) async {
    if (!mounted || _authDialogVisible) return;

    setState(() {
      _authDialogVisible = true;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Session expired'),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await SessionManager.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (mounted) {
      setState(() {
        _authDialogVisible = false;
      });
    }
  }

  void _updateFavoriteIds(Set<int> ids) {
    if (mounted) {
      setState(() {
        _favoriteStationIds.clear();
        _favoriteStationIds.addAll(ids);
      });
      _saveFavoritesToStorage();
    }
  }

  Future<void> _addMarkersFromStations() async {
    if (!_isMapReady || !mounted) {
      print("⚠️ Map not ready, will add markers later");
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _isMapReady && _evStations.isNotEmpty) {
          _addMarkersFromStations();
        }
      });
      return;
    }

    print("📍 Adding ${_evStations.length} markers to map");

    _markers.clear();

    Set<Marker> newMarkers = {};

    for (var station in _evStations) {
      print('🔍 Station: ${station.name}');
      print('   Available: ${station.availableChargers}');
      print('   Total: ${station.totalChargers}');
      print('   Connector Ports: ${station.connectorPorts.length}');

      String overallStatus = station.getOverallStatus();
      bool isAvailable = station.availableChargers > 0;

      if (!isAvailable && station.totalChargers > 0) {
        isAvailable = station.connectorPorts.any(
          (port) => port.status.toLowerCase() == 'available',
        );
      }

      if (station.totalChargers <= 0) {
        isAvailable = false;
      }

      bool hasFault = station.connectorPorts.any((port) =>
      port.status == 'fault' || port.status == 'error'
      );
      bool hasOffline = station.connectorPorts.any((port) =>
      port.status == 'offline' || port.status == 'unavailable'
      );

      print('   Overall Status: $overallStatus');
      print('   Is Available: $isAvailable');
      print('   Has Fault: $hasFault');
      print('   Has Offline: $hasOffline');

      final markerIcon = await LargeChargerMarker.createLargeMarker(
        available: station.availableChargers,
        total: station.totalChargers,
        isAvailable: isAvailable,
        status: overallStatus,
        hasFault: hasFault,
        hasOffline: hasOffline,
      );

      final marker = Marker(
        markerId: MarkerId('station_${station.id}_${DateTime.now().millisecondsSinceEpoch}'),
        position: station.location,
        infoWindow: InfoWindow.noText,
        icon: markerIcon,
        anchor: const Offset(0.5, 1.0),
        onTap: () {
          print('📍 Marker tapped: ${station.name}');

          setState(() {
            _selectedStation = station;
            _selectedStationDistance = _locationService.calculateDistance(
              _currentPosition,
              station.location,
            );
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(
                station.location.latitude - 0.0015,
                station.location.longitude,
              ),
            ),
          );
        },
      );

      newMarkers.add(marker);
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });

    print("✅ ${_markers.length} markers added successfully");
  }

  Future<BitmapDescriptor> _createLabelMarker(int count) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final Paint paint = Paint()..color = Colors.white;
    final Radius radius = Radius.circular(12);
    final Rect rect = Rect.fromLTWH(0, 0, 30, 30);
    final RRect rrect = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(rrect, paint);

    final Paint borderPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: TextStyle(
          color: count > 0 ? Colors.red : Colors.green,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (30 - textPainter.width) / 2,
        (30 - textPainter.height) / 2,
      ),
    );

    final ui.Image image = await recorder.endRecording().toImage(30, 30);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData != null) {
      return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
    }

    return BitmapDescriptor.defaultMarker;
  }

  void _updateSearchRadius() {
    _circles.clear();
    if (_locationPermissionGranted && _locationServicesEnabled) {
      _circles.add(
        Circle(
          circleId: const CircleId('search_radius'),
          center: _currentPosition,
          radius: 5000,
          fillColor: Colors.green.withOpacity(0.1),
          strokeColor: Colors.green.withOpacity(0.5),
          strokeWidth: 2,
        ),
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite(EVStation station) async {
    final wasFavorite = _favoriteStationIds.contains(station.id);

    setState(() {
      if (wasFavorite) {
        _favoriteStationIds.remove(station.id);
      } else {
        _favoriteStationIds.add(station.id);
      }
    });

    final success = await _wishlistService.toggleFavorite(
      station,
      !wasFavorite,
    );

    if (!success && mounted) {
      setState(() {
        if (wasFavorite) {
          _favoriteStationIds.add(station.id);
        } else {
          _favoriteStationIds.remove(station.id);
        }
      });
    } else {
      await _wishlistService.refreshWishlist(_updateFavoriteIds);
    }
  }

  void _showStationDetails(EVStation station) {
    final distance = _locationService.calculateDistance(
      _currentPosition,
      station.location,
    );
    final isFavorite = _favoriteStationIds.contains(station.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StationDetailsSheet(
          station: station,
          distance: distance,
          isFavorite: isFavorite,
          onFavoriteToggle: () async {
            await _toggleFavorite(station);
            if (mounted) setState(() {});
          },
          onNavigate: () {
            _openNavigation(station.location, station.name);
          },
        );
      },
    );
  }

  Future<void> _openNavigation(LatLng destination, String name) async {
    try {
      final origin = await _locationService.getCurrentLocation();

      if (origin == null) {
        return;
      }

      await _locationService.openNavigation(
        origin,
        destination,
        name,
      );
    } catch (e) {
      print("Failed to open navigation: $e");
    }
  }

  void _showStationsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: NearbyStationsSection(
                        userLatitude: _currentPosition.latitude,
                        userLongitude: _currentPosition.longitude,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _centerOnCurrentLocation() async {
    if (!_locationPermissionGranted) {
      _checkAndRequestPermission();
      return;
    }

    if (!_locationServicesEnabled) {
      _showLocationAccuracyDialog();
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    final position = await _locationService.getCurrentLocation();

    setState(() {
      _isGettingLocation = false;
    });

    if (position != null) {
      setState(() {
        _currentPosition = position;
        _stationsLoaded = false;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 14),
      );

      await _fetchEVStations();
    }
  }

  Future<void> _loadFavoritesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorite_stations');
      if (favorites != null) {
        setState(() {
          _favoriteStationIds.addAll(favorites.map(int.parse));
        });
      }
      await _wishlistService.refreshWishlist(_updateFavoriteIds);
    } catch (e) {
      print("Error loading favorites: $e");
    }
  }

  Future<void> _saveFavoritesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'favorite_stations',
        _favoriteStationIds.map((id) => id.toString()).toList(),
      );
    } catch (e) {
      print("Error saving favorites: $e");
    }
  }

  void _navigateToPaymentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentScreen()),
    ).then((_) {
      _loadWalletBalance();
      _refreshMapButtons();
    });
  }

  Widget _getDestinationPage(int index) {
    switch (index) {
      case 1:
        return const ScannerPage();
      case 2:
        return const PaymentScreen();
      case 3:
        return ProfileScreen(
          isDarkMode: false,
          onToggle: () {},
        );
      default:
        return const SizedBox();
    }
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      setState(() {
        _currentIndex = index;
      });
      _refreshMapButtons();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _getDestinationPage(index),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _currentIndex = 0;
          });
          _refreshMapButtons();
          _loadWalletBalance();
        }
      });
    }
  }

  Future<void> _refreshMapButtons() async {
    print('🔄 Refreshing MapButtons...');
    if (_mapButtonsController != null && _mapButtonsController!.refreshSession != null) {
      await _mapButtonsController!.refreshSession!();
      print('✅ MapButtons refreshed successfully');
    }
  }

  void _handleChargingError(String errorMessage) {
    if (errorMessage.contains('already have an active charging session')) {
      print('! Active session detected - recovering session data...');
      _recoverActiveSession();
    }
  }

  Future<void> _recoverActiveSession() async {
    try {
      final sessionData = await ChargingSessionService.getActiveSessionData();

      if (sessionData != null) {
        final sessionId = sessionData['sessionId'];

        print('📋 Recovered session data:');
        print('   Session ID: $sessionId');
        print('   Status: ${sessionData['status']}');

        if (_chargingController == null) {
          _chargingController = LiveChargingController();
        }

        await _chargingController!.fetchLiveChargingStatus(sessionId: sessionId);

        if (_chargingController!.currentLiveData != null) {
          final status = _chargingController!.currentLiveData!.status;
          final isActive = status == 'charging' ||
              status == 'preparing' ||
              status == 'starting';

          if (isActive) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Active charging session found'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error recovering session: $e');
    }
  }

  Future<void> _navigateToChargingProgress(int? sessionId, Map<String, dynamic>? vehicleDetails) async {
    print('\n🚗 ========== NAVIGATE TO CHARGING PROGRESS ==========');
    print('📝 Session ID passed: $sessionId');

    try {
      // ✅ Step 1: Validate session ID
      if (sessionId == null || sessionId <= 0) {
        print('🔍 No valid session ID, attempting to recover...');
        // ... recovery logic (keep existing code) ...
      }

      print('✅ Valid session ID: $sessionId');

      // ✅ Step 2: Fetch live data
      if (_chargingController == null) {
        _chargingController = LiveChargingController();
      }

      print('📡 Fetching latest session data for ID: $sessionId');
      await _chargingController!.fetchLiveChargingStatus(sessionId: sessionId);

      // ✅ Step 3: Build charging details
      Map<String, dynamic> chargingDetails = {
        'sessionId': sessionId,
      };

      // ✅ Step 4: Get vehicle data - FIRST from AuthService
      String manufacturer = 'Unknown';
      String model = 'Vehicle';
      String registrationNumber = 'N/A';
      String vehicleName = 'Unknown Vehicle';

      try {
        // ✅ Try AuthService first (persists across app reinstalls)
        final vehicleData = await AuthService.getVehicleData();

        if (vehicleData['manufacturer'] != null && vehicleData['manufacturer']!.isNotEmpty) {
          manufacturer = vehicleData['manufacturer']!;
          model = vehicleData['model'] ?? 'Vehicle';
          registrationNumber = vehicleData['registrationNumber']?.isNotEmpty == true
              ? vehicleData['registrationNumber']!
              : 'N/A';
          vehicleName = vehicleData['vehicleName'] ?? '$manufacturer $model'.trim();
          if (vehicleName.isEmpty) vehicleName = 'Unknown Vehicle';

          print('✅ Vehicle data from AuthService:');
          print('   Manufacturer: $manufacturer');
          print('   Model: $model');
          print('   Registration: $registrationNumber');
          print('   Name: $vehicleName');
        } else if (_chargingController != null) {
          // ✅ Second try: Get from controller
          final controllerManufacturer = _chargingController!.vehicleManufacturer;
          final controllerModel = _chargingController!.vehicleModel;
          final controllerRegistration = _chargingController!.vehicleRegistrationNumber;
          final controllerVehicleName = _chargingController!.vehicleName;

          if (controllerManufacturer != 'N/A' && controllerManufacturer.isNotEmpty) {
            manufacturer = controllerManufacturer;
            model = controllerModel != 'N/A' ? controllerModel : '';
            registrationNumber = controllerRegistration != 'N/A' ? controllerRegistration : 'N/A';
            vehicleName = controllerVehicleName != 'Unknown Vehicle' ? controllerVehicleName : '$manufacturer $model'.trim();
            print('✅ Vehicle data from controller:');
            print('   Manufacturer: $manufacturer');
            print('   Model: $model');
            print('   Registration: $registrationNumber');
            print('   Name: $vehicleName');
          }
        }

        // ✅ Third try: Use provided vehicleDetails
        if (manufacturer == 'Unknown' && vehicleDetails != null) {
          manufacturer = vehicleDetails['manufacturer'] ?? 'Unknown';
          model = vehicleDetails['model'] ?? 'Vehicle';
          registrationNumber = vehicleDetails['registrationNumber'] ?? 'N/A';
          vehicleName = vehicleDetails['vehicleName'] ?? 'Unknown Vehicle';
          print('✅ Using provided vehicle details');
        }

        // ✅ Final fallback
        if (manufacturer == 'Unknown' || manufacturer.isEmpty) {
          manufacturer = 'Unknown';
          model = 'Vehicle';
          registrationNumber = 'N/A';
          vehicleName = 'Unknown Vehicle';
          print('⚠️ Using fallback vehicle data');
        }

      } catch (e) {
        print('⚠️ Error getting vehicle data: $e');
      }

      // ✅ Set vehicle data in charging details
      chargingDetails['manufacturer'] = manufacturer;
      chargingDetails['model'] = model;
      chargingDetails['registrationNumber'] = registrationNumber;
      chargingDetails['vehicleName'] = vehicleName;

      // ✅ Add session details from live data
      if (_chargingController != null && _chargingController!.currentLiveData != null) {
        final liveData = _chargingController!.currentLiveData!;
        chargingDetails['transactionId'] = liveData.transactionId;
        chargingDetails['startedAt'] = liveData.startedAt.toIso8601String();
        chargingDetails['status'] = liveData.status;
        chargingDetails['phase'] = liveData.phase;

        if (liveData.station != null) {
          chargingDetails['stationName'] = liveData.station!.name;
          chargingDetails['stationCity'] = liveData.station!.city ?? '';
        }

        chargingDetails['chargerName'] = liveData.charger.name;
        chargingDetails['chargerPowerCapacity'] = liveData.charger.powerCapacity;
        chargingDetails['connectorType'] = liveData.connector.type;
      }

      print('📋 Final charging details:');
      print('   Session ID: ${chargingDetails['sessionId']}');
      print('   Vehicle: ${chargingDetails['vehicleName']}');
      print('   Manufacturer: ${chargingDetails['manufacturer']}');
      print('   Model: ${chargingDetails['model']}');
      print('   Registration: ${chargingDetails['registrationNumber']}');
      print('   Status: ${chargingDetails['status'] ?? 'unknown'}');
      print('   Phase: ${chargingDetails['phase'] ?? 'unknown'}');

      // ✅ Step 5: Navigate
      print('🚀 Navigating to ChargingProgressPage...');
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChargingProgressPage(
            chargingDetails: chargingDetails,
          ),
        ),
      );

      print('↩️ Returned from ChargingProgressPage');
      _refreshMapButtons();
      _loadWalletBalance();
      print('==========================================\n');

    } catch (e, stackTrace) {
      print('❌ Error in _navigateToChargingProgress: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NEW METHOD: Exit app immediately without any dialog
  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default pop behavior
      onPopInvoked: (bool didPop) async {
        if (didPop) return; // If already popped, do nothing

        // ✅ Exit app immediately without any confirmation
        _exitApp();
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: (_locationPermissionGranted && _locationServicesEnabled) ? 14 : 7.2,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _isMapReady = true;
                print("🗺️ Map created successfully");

                if (_evStations.isNotEmpty) {
                  _addMarkersFromStations();
                }

                if (_locationPermissionGranted && _locationServicesEnabled && !_stationsLoaded) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition, 14),
                  );
                  if (_evStations.isEmpty) {
                    _fetchEVStations();
                  }
                }
              },
              markers: _markers,
              circles: _circles,
              myLocationEnabled: _locationPermissionGranted && _locationServicesEnabled,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              onTap: (_) {
                setState(() {
                  _selectedStation = null;
                });
              },
            ),
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: MapSearchBar(
                currentPosition: _currentPosition,
                evStations: _evStations,
                onStationSelected: (station) {
                  setState(() {
                    _selectedStation = station;
                    _selectedStationDistance = _locationService.calculateDistance(
                      _currentPosition,
                      station.location,
                    );
                  });
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(station.location, 16),
                  );
                },
                onLocationSelected: (location, name) async {
                  await _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(location, 15),
                  );
                },
              ),
            ),
            Positioned(
              top: 135,
              left: 16,
              child: GestureDetector(
                onTap: _navigateToPaymentScreen,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.green.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "₹${_walletBalance.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 140,
              child: Column(
                children: [
                  MapButtons(
                    onControllerCreated: (controller) {
                      _mapButtonsController = controller;
                    },
                    onMyLocation: _centerOnCurrentLocation,
                    onNavigate: (sessionId) => _navigateToChargingProgress(sessionId, null),
                    onList: _showStationsList,
                    onZoomOut: _zoomOut,
                    onZoomIn: _zoomIn,
                    chargingController: _chargingController,
                  ),
                ],
              ),
            ),

            if (_selectedStation != null)
              Positioned(
                bottom: 90,
                left: 16,
                right: 16,
                child: StationCard(
                  station: _selectedStation!,
                  distance: _selectedStationDistance ??
                      _locationService.calculateDistance(
                        _currentPosition,
                        _selectedStation!.location,
                      ),
                  isFavorite: _favoriteStationIds.contains(_selectedStation!.id),
                  onFavoriteToggle: () {
                    _toggleFavorite(_selectedStation!);
                  },
                  onDetails: () {
                    _showStationDetails(_selectedStation!);
                  },
                  onNavigate: () {
                    _openNavigation(
                      _selectedStation!.location,
                      _selectedStation!.name,
                    );
                  },
                  onClose: () {
                    setState(() {
                      _selectedStation = null;
                    });
                  },
                ),
              ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          onScanTap: () {
            _onTabTapped(1);
          },
        ),
      ),
    );
  }
}



