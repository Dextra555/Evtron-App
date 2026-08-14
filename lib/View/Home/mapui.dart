import 'dart:async';
import 'dart:convert';
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
import '../../Service/StationCacheService.dart';
import '../../Service/network_service.dart';
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
import 'map_marker_utils.dart';
import 'map_search_bar.dart';
import 'station_card.dart';
import 'StationDetailsPage.dart';

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
  List<EVStation> _displayedStations = [];
  Map<String, dynamic> _activeFilters = {};
  EVStation? _selectedStation;
  double? _selectedStationDistance;
  final Set<int> _favoriteStationIds = {};
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isGettingLocation = true;
  bool _isNavigatingToChargingProgress = false;
  bool _isFirstLoad = true;
  bool _isMapReady = false;
  double _walletBalance = 0.00;
  bool _locationPermissionGranted = false;
  bool _locationServicesEnabled = true;
  bool _hasShownLocationDialog = false;
  static bool _hasShownInCurrentSession = false;
  bool _stationsLoaded = false;
  late final WalletController _walletController;
  bool _isFilterExpanded = false;
  MapButtonsController? _mapButtonsController;
  LiveChargingController? _chargingController;
  late final LocationService _locationService;
  late final StationService _stationService;
  late final WishlistService _wishlistService;
  late final StationCacheService _cacheService;

  bool _isUpdating = false;
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 2);
  bool _authDialogVisible = false;
  bool _sessionRestoreAttempted = false;
  int _searchBarResetSignal = 0;

  static const String _savedSessionKey = 'map_screen_saved_session';
  static const String _savedSessionScreenKey = 'screen';
  static const String _savedSessionStationIdKey = 'station_id';
  static const String _savedSessionFiltersKey = 'filters';

  Timer? _controllerUpdateDebounce;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _locationService = LocationService();
    _stationService = StationService();
    _wishlistService = WishlistService();
    _cacheService = StationCacheService();
    _chargingController = LiveChargingController();
    _chargingController!.addListener(_onChargingControllerUpdate);
    _walletController = WalletController();

    _loadWalletBalance();
    _checkAndRequestPermission();
    _listenToLocationServices();
    _checkForActiveSessionOnInit();

    _preloadCache();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_restorePersistedSession());
      }
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && mounted && !_isLoading) {
        _fetchEVStations();
      }
    });
  }

  Future<void> _preloadCache() async {
    try {
      print('📦 Preloading cache...');
      final cachedStations = await _cacheService.getCachedStations();
      if (cachedStations.isNotEmpty && mounted) {
        print('✅ Preloaded ${cachedStations.length} stations from cache');
        setState(() {
          _evStations = cachedStations;
          _refreshDisplayedStations();
          _stationsLoaded = true;
        });
        await _addMarkersFromStations();
      }
    } catch (e) {
      print('⚠️ Error preloading cache: $e');
    }
  }

  bool _hasActiveFilters() {
    return _hasFilterCriteria(_activeFilters);
  }

  bool _hasFilterCriteria(Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) return false;

    final chargerType = filters['chargerType']?.toString();
    final connectorType = filters['connectorType']?.toString();
    final status = filters['status']?.toString();
    final accessibility = filters['accessibility']?.toString();
    final powerRange = filters['powerRange'] as RangeValues?;

    return (chargerType != null && chargerType.isNotEmpty) ||
        (connectorType != null && connectorType.isNotEmpty) ||
        (status != null && status.isNotEmpty) ||
        (accessibility != null && accessibility.isNotEmpty) ||
        (powerRange != null && !(powerRange.start == 0.0 && powerRange.end == 350.0));
  }

  String _normalizeFilterValue(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  String _normalizeConnectorType(String value) {
    final lower = value.toLowerCase();
    if (lower == 'type2' || lower == 'type 2' || lower == 'type_2') {
      return 'type 2';
    } else if (lower == 'type1' || lower == 'type 1' || lower == 'type_1') {
      return 'type 1';
    } else if (lower == 'ccs2' || lower == 'ccs' || lower == 'ccs_2') {
      return 'ccs2';
    } else if (lower == 'ccs1' || lower == 'ccs_1') {
      return 'ccs1';
    } else if (lower == 'chademo') {
      return 'chademo';
    } else if (lower == 'gbt' || lower == 'gb/t' || lower == 'gb_t') {
      return 'gb/t';
    } else if (lower == 'tesla' || lower == 'nacs') {
      return 'tesla';
    }
    return lower;
  }

  String _getStationChargerType(EVStation station) {
    if (station.connectorPorts.isEmpty) {
      return 'ac';
    }

    final types = <String>{};
    for (final port in station.connectorPorts) {
      final chargerType = (port.chargerType ?? '').trim().toLowerCase();
      final connectorType = (port.type ?? '').trim().toLowerCase();
      final power = port.kw ?? port.maxPower ?? 0.0;

      if (chargerType.contains('dc')) {
        types.add('dc');
      } else if (chargerType.contains('ac')) {
        types.add('ac');
      } else if (connectorType.contains('ccs') ||
          connectorType.contains('chademo') ||
          connectorType.contains('gb/t') ||
          connectorType.contains('tesla')) {
        if (power > 50) {
          types.add('dc');
        } else {
          types.add('ac');
        }
      } else if (connectorType.contains('type 2') || connectorType.contains('type2')) {
        types.add('ac');
      }
    }

    if (types.contains('dc') && types.contains('ac')) {
      return 'both';
    }
    if (types.contains('dc')) {
      return 'dc';
    }
    if (types.contains('ac')) {
      return 'ac';
    }

    final hasHighPower = station.connectorPorts.any((port) =>
        (port.kw ?? 0) > 50 || (port.maxPower ?? 0) > 50);
    return hasHighPower ? 'dc' : 'ac';
  }

  String _getStationConnectorType(EVStation station) {
    if (station.connectorPorts.isEmpty) {
      return '';
    }

    final counts = <String, int>{};
    for (final port in station.connectorPorts) {
      final normalized = _normalizeConnectorType(port.type);
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return '';
    }

    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String _getStationStatus(EVStation station) {
    final overall = station.getOverallStatus().toLowerCase();
    if (overall.contains('available')) return 'available';
    if (overall.contains('busy') || overall.contains('charging') || overall.contains('active') || overall.contains('in-use')) return 'busy';
    if (overall.contains('fault') || overall.contains('error')) return 'fault';
    return 'unavailable';
  }

  String _getStationAccessibility(EVStation station) {
    final type = station.stationType.toLowerCase();
    if (type.contains('public')) return 'public';
    if (type.contains('private')) return 'private';
    if (type.contains('guest') || type.contains('community')) return 'guest';
    return type.isEmpty ? 'public' : type;
  }

  double _getStationMaxPower(EVStation station) {
    if (station.connectorPorts.isEmpty) {
      return 0.0;
    }

    double maxPower = 0.0;
    for (final port in station.connectorPorts) {
      final power = port.kw ?? port.maxPower ?? 0.0;
      if (power > maxPower) {
        maxPower = power;
      }
    }
    return maxPower;
  }

  void _refreshDisplayedStations() {
    if (_evStations.isEmpty) {
      _displayedStations = [];
      return;
    }

    if (_activeFilters.isEmpty) {
      _displayedStations = List<EVStation>.from(_evStations);
      return;
    }

    _displayedStations = _filterStations(_evStations, _activeFilters);
  }

  Future<void> _saveSessionState({
    required String screen,
    int? stationId,
    Map<String, dynamic>? filters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      _savedSessionScreenKey: screen,
      _savedSessionStationIdKey: stationId,
      _savedSessionFiltersKey: _serializeFilters(filters),
    };
    await prefs.setString(_savedSessionKey, json.encode(payload));
  }

  Future<void> _clearSavedSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedSessionKey);
  }

  Map<String, dynamic> _serializeFilters(Map<String, dynamic>? filters) {
    final payload = <String, dynamic>{};
    if (filters == null) return payload;

    final normalizedFilters = Map<String, dynamic>.from(filters);
    final powerRange = normalizedFilters['powerRange'] as RangeValues?;
    if (powerRange != null) {
      normalizedFilters['powerRange'] = RangeValues(
        powerRange.start.toDouble(),
        powerRange.end.toDouble(),
      );
    }

    final chargerType = normalizedFilters['chargerType']?.toString();
    if (chargerType != null && chargerType.isNotEmpty) {
      payload['chargerType'] = chargerType;
    }

    final connectorType = normalizedFilters['connectorType']?.toString();
    if (connectorType != null && connectorType.isNotEmpty) {
      payload['connectorType'] = connectorType;
    }

    final status = normalizedFilters['status']?.toString();
    if (status != null && status.isNotEmpty) {
      payload['status'] = status;
    }

    final accessibility = normalizedFilters['accessibility']?.toString();
    if (accessibility != null && accessibility.isNotEmpty) {
      payload['accessibility'] = accessibility;
    }

    final normalizedPowerRange = normalizedFilters['powerRange'] as RangeValues?;
    if (normalizedPowerRange != null) {
      payload['powerRangeStart'] = normalizedPowerRange.start;
      payload['powerRangeEnd'] = normalizedPowerRange.end;
    }

    return payload;
  }

  Map<String, dynamic> _toStringDynamicMap(Object? value) {
    if (value is Map) {
      return value.map<String, dynamic>((key, entryValue) => MapEntry(key.toString(), entryValue));
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _deserializeFilters(Object? rawFilters) {
    final data = _toStringDynamicMap(rawFilters);
    final restored = <String, dynamic>{};

    final chargerType = data['chargerType']?.toString();
    if (chargerType != null && chargerType.isNotEmpty) {
      restored['chargerType'] = chargerType;
    }

    final connectorType = data['connectorType']?.toString();
    if (connectorType != null && connectorType.isNotEmpty) {
      restored['connectorType'] = connectorType;
    }

    final status = data['status']?.toString();
    if (status != null && status.isNotEmpty) {
      restored['status'] = status;
    }

    final accessibility = data['accessibility']?.toString();
    if (accessibility != null && accessibility.isNotEmpty) {
      restored['accessibility'] = accessibility;
    }

    if (data.containsKey('powerRangeStart') || data.containsKey('powerRangeEnd')) {
      restored['powerRange'] = RangeValues(
        (data['powerRangeStart'] as num?)?.toDouble() ?? 0.0,
        (data['powerRangeEnd'] as num?)?.toDouble() ?? 350.0,
      );
    }

    return restored;
  }

  bool _stationMatchesFilters(EVStation station, Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) return true;
    return _filterStations([station], filters).isNotEmpty;
  }

  Future<void> _restorePersistedSession() async {
    if (_sessionRestoreAttempted || !mounted) return;
    _sessionRestoreAttempted = true;

    final prefs = await SharedPreferences.getInstance();
    final rawSession = prefs.getString(_savedSessionKey);
    if (rawSession == null || rawSession.isEmpty) return;

    try {
      final decoded = json.decode(rawSession);
      if (decoded is! Map) return;

      final decodedSession = _toStringDynamicMap(decoded);
      final savedScreen = decodedSession[_savedSessionScreenKey]?.toString();
      if (savedScreen != 'station_details') return;

      final stationId = decodedSession[_savedSessionStationIdKey] is int
          ? decodedSession[_savedSessionStationIdKey] as int
          : int.tryParse(decodedSession[_savedSessionStationIdKey]?.toString() ?? '');
      final restoredFilters = _deserializeFilters(decodedSession[_savedSessionFiltersKey]);

      if (_evStations.isEmpty && !_isLoading) {
        await _fetchEVStations();
      }

      if (!mounted || _evStations.isEmpty) return;

      final filterState = _hasFilterCriteria(restoredFilters)
          ? Map<String, dynamic>.from(restoredFilters)
          : <String, dynamic>{};

      setState(() {
        _activeFilters = filterState;
        _displayedStations = _hasFilterCriteria(filterState)
            ? _filterStations(_evStations, filterState)
            : List<EVStation>.from(_evStations);
        _markers.clear();
      });

      await _addMarkersFromStations();

      EVStation? targetStation;
      for (final station in _evStations) {
        if (station.id == stationId) {
          targetStation = station;
          break;
        }
      }

      if (targetStation != null && _stationMatchesFilters(targetStation, filterState)) {
        setState(() {
          _selectedStation = targetStation;
          _selectedStationDistance = _locationService.calculateDistance(
            _currentPosition,
            targetStation!.location,
          );
        });

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StationDetailsPage(
                station: targetStation!,
                distance: _selectedStationDistance ??
                    _locationService.calculateDistance(
                      _currentPosition,
                      targetStation!.location,
                    ),
                isFavorite: _favoriteStationIds.contains(targetStation!.id),
                activeFilters: filterState.isNotEmpty ? Map<String, dynamic>.from(filterState) : null,
                onFavoriteToggle: (bool isNowFavorite) async {
                  await _toggleFavorite(targetStation!);
                  if (mounted) setState(() {});
                  return _favoriteStationIds.contains(targetStation.id) == isNowFavorite;
                },
                onNavigate: () {
                  _openNavigation(targetStation!.location, targetStation!.name);
                },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The previous station no longer matches the saved filters. Showing the filtered list.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _selectedStation = null;
        });
        await _saveSessionState(screen: 'station_list', stationId: null, filters: filterState);
      }
    } catch (e) {
      print('⚠️ Failed to restore saved station session: $e');
      await _clearSavedSessionState();
    }
  }

  List<EVStation> _filterStations(List<EVStation> stations, Map<String, dynamic> filters) {
    final chargerType = _normalizeFilterValue(filters['chargerType']?.toString());
    final connectorType = _normalizeFilterValue(filters['connectorType']?.toString());
    final status = _normalizeFilterValue(filters['status']?.toString());
    final accessibility = _normalizeFilterValue(filters['accessibility']?.toString());
    final powerRange = filters['powerRange'] as RangeValues?;

    return stations.where((station) {
      final hasConnectorCriteria = (chargerType.isNotEmpty && chargerType != 'both') ||
          connectorType.isNotEmpty ||
          status.isNotEmpty ||
          (powerRange != null && !(powerRange.start == 0.0 && powerRange.end == 350.0));

      if (hasConnectorCriteria && !station.hasMatchingConnectorPorts(filters)) {
        return false;
      }

      if (powerRange != null && !(powerRange.start == 0.0 && powerRange.end == 350.0) && !station.matchesPowerRange(powerRange)) {
        return false;
      }

      if (accessibility.isNotEmpty) {
        final stationAccessibility = _normalizeFilterValue(_getStationAccessibility(station));
        if (stationAccessibility != accessibility) return false;
      }

      return true;
    }).toList();
  }

  void _handleFilterApplied(List<EVStation> filteredStations, Map<String, dynamic> filters) {
    print('📍 Updating map with ${filteredStations.length} filtered stations');
    print('📊 Filtered station list count: ${filteredStations.length} from ${_evStations.length} stations');

    setState(() {
      _activeFilters = _hasFilterCriteria(filters) ? Map<String, dynamic>.from(filters) : {};
      _displayedStations = _hasFilterCriteria(filters) ? filteredStations : List<EVStation>.from(_evStations);
      _markers.clear();
    });

    _addMarkersFromStations();

    if (_selectedStation != null && !_displayedStations.contains(_selectedStation)) {
      setState(() {
        _selectedStation = null;
      });
    }

    if (_hasFilterCriteria(filters)) {
      unawaited(_saveSessionState(
        screen: _selectedStation != null ? 'station_details' : 'station_list',
        stationId: _selectedStation?.id,
        filters: _activeFilters,
      ));
    } else {
      unawaited(_clearSavedSessionState());
    }
  }

  void _onChargingControllerUpdate() {
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

  void _navigateToStationDetails(EVStation station) {
    final distance = _locationService.calculateDistance(
      _currentPosition,
      station.location,
    );
    final isFavorite = _favoriteStationIds.contains(station.id);

    unawaited(_saveSessionState(
      screen: 'station_details',
      stationId: station.id,
      filters: _activeFilters.isNotEmpty ? Map<String, dynamic>.from(_activeFilters) : {},
    ));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StationDetailsPage(
          station: station,
          distance: distance,
          isFavorite: isFavorite,
          activeFilters: _activeFilters.isNotEmpty ? Map<String, dynamic>.from(_activeFilters) : null,
          onFavoriteToggle: (bool isNowFavorite) async {
            await _toggleFavorite(station);
            if (mounted) setState(() {});
            return _favoriteStationIds.contains(station.id) == isNowFavorite;
          },
          onNavigate: () {
            _openNavigation(station.location, station.name);
          },
        ),
      ),
    ).then((_) {
      if (mounted) {
        unawaited(_clearSavedSessionState());
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

      final sessionData = await ChargingSessionService.getActiveSessionData();

      if (sessionData != null && sessionData['sessionId'] != null) {
        final sessionId = sessionData['sessionId'];
        final status = sessionData['status'] ?? 'unknown';

        print('📋 Found active session on init:');
        print('   Session ID: $sessionId');
        print('   Status: $status');

        await _loadVehicleDetailsFromStorage(sessionId);
        await _fetchSessionData(sessionId);
      } else {
        print('ℹ️ No active session found on init');
      }
      print('==========================================\n');
    } catch (e) {
      print('❌ Error checking session on init: $e');
    }
  }

  Future<void> _loadVehicleDetailsFromStorage(int sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      String vehicleName = prefs.getString('session_${sessionId}_vehicle_name') ?? '';
      String manufacturer = prefs.getString('session_${sessionId}_vehicle_manufacturer') ?? '';
      String model = prefs.getString('session_${sessionId}_vehicle_model') ?? '';
      String registration = prefs.getString('session_${sessionId}_vehicle_registration') ?? '';

      if (vehicleName.isEmpty) {
        vehicleName = prefs.getString('vehicle_name') ?? 'Unknown Vehicle';
        manufacturer = prefs.getString('vehicle_manufacturer') ?? '';
        model = prefs.getString('vehicle_model') ?? '';
        registration = prefs.getString('vehicle_registration') ?? '';
      }

      if (_chargingController != null) {
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

  Future<void> _fetchSessionData(int sessionId) async {
    try {
      if (_chargingController == null) return;

      await _chargingController!.fetchLiveChargingStatus(sessionId: sessionId);

      if (_chargingController!.currentLiveData != null) {
        print('✅ Session data loaded into controller');
        print('   Status: ${_chargingController!.currentLiveData!.status}');
        print('   Phase: ${_chargingController!.currentLiveData!.phase}');

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
      final cachedStations = await _cacheService.getCachedStations();

      if (cachedStations.isNotEmpty && mounted) {
        print("✅ Loaded ${cachedStations.length} stations from cache (immediate display)");

        // ✅ Filter out stations with total = 0
        final filteredStations = cachedStations.where((station) {
          int total = station.connectorPorts.length;
          if (total == 0) total = station.totalChargers;
          return total > 0;
        }).toList();

        print("✅ After filtering: ${filteredStations.length} stations with chargers");

        setState(() {
          _evStations = filteredStations;
          _refreshDisplayedStations();
          _markers.clear();
          _stationsLoaded = true;
        });

        await _addMarkersFromStations();
        await _wishlistService.refreshWishlist(_updateFavoriteIds);
        setState(() {});

        _fetchFreshStationsInBackground();

        setState(() {
          _isLoading = false;
        });
        return;
      }

      print("⏳ No cache available, fetching from API...");

      final stations = await _stationService.fetchStations(
        currentPosition: (_locationPermissionGranted && _locationServicesEnabled)
            ? _currentPosition
            : null,
      );

      print("✅ Received ${stations.length} stations from API");

      if (stations.isNotEmpty) {
        // ✅ Filter out stations with total = 0 before caching
        final filteredStations = stations.where((station) {
          int total = station.connectorPorts.length;
          if (total == 0) total = station.totalChargers;
          return total > 0;
        }).toList();

        print("✅ After filtering: ${filteredStations.length} stations with chargers");

        await _cacheService.saveStations(filteredStations);
        print("✅ Stations cached for future use");
      }

      setState(() {
        _evStations = [];
          _displayedStations = [];
      });

      if (stations.isNotEmpty && mounted) {
        final filteredStations = stations.where((station) {
          int total = station.connectorPorts.length;
          if (total == 0) total = station.totalChargers;
          return total > 0;
        }).toList();

        setState(() {
          _evStations = filteredStations;
          _refreshDisplayedStations();
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
    } on NetworkException catch (e) {
      print("⚠️ Network error fetching stations: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your network and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print("❌ Error fetching stations: $e");

      final fallbackCache = await _cacheService.getCachedStations();
      if (fallbackCache.isNotEmpty && mounted) {
        print("⚠️ API failed, showing cached data as fallback");
        // ✅ Filter fallback cache
        final filteredFallback = fallbackCache.where((station) {
          int total = station.connectorPorts.length;
          if (total == 0) total = station.totalChargers;
          return total > 0;
        }).toList();

        setState(() {
          _evStations = filteredFallback;
          _refreshDisplayedStations();
          _markers.clear();
          _stationsLoaded = true;
        });
        await _addMarkersFromStations();
      } else if (mounted) {
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

  Future<void> _fetchFreshStationsInBackground() async {
    try {
      print("🔄 Background refresh: Fetching fresh stations...");

      final stations = await _stationService.fetchStations(
        currentPosition: (_locationPermissionGranted && _locationServicesEnabled)
            ? _currentPosition
            : null,
      );

      if (stations.isNotEmpty && mounted) {
        // ✅ Filter stations with total > 0
        final filteredStations = stations.where((station) {
          int total = station.connectorPorts.length;
          if (total == 0) total = station.totalChargers;
          return total > 0;
        }).toList();

        // ✅ Cache fresh data
        await _cacheService.saveStations(filteredStations);

        // ✅ Update UI with fresh data if different from cached
        final currentIds = _evStations.map((s) => s.id).toSet();
        final newIds = filteredStations.map((s) => s.id).toSet();

        if (!currentIds.containsAll(newIds) || !newIds.containsAll(currentIds)) {
          print("🔄 Stations changed, updating UI...");
          setState(() {
            _evStations = filteredStations;
            _refreshDisplayedStations();
            _markers.clear();
          });
          await _addMarkersFromStations();
          await _wishlistService.refreshWishlist(_updateFavoriteIds);
          setState(() {});
        } else {
          print("✅ Stations unchanged, no UI update needed");
        }
      }
    } catch (e) {
      print("⚠️ Background refresh failed: $e");
    }
  }

  Future<void> _refreshMap() async {
    print('🔄 Refreshing map and reloading stations...');

    await _clearSavedSessionState();

    if (mounted) {
      setState(() {
        _activeFilters = {};
        _displayedStations = [];
        _selectedStation = null;
        _selectedStationDistance = null;
        _searchBarResetSignal += 1;
      });
    }

    // ✅ Clear cache to force fresh data
    await _cacheService.clearCache();

    setState(() {
      _isLoading = true;
      _evStations.clear();
      _markers.clear();
      _stationsLoaded = false;
    });

    try {
      print('📡 Fetching fresh stations from API...');
      final stations = await _stationService.fetchStations(
        currentPosition: (_locationPermissionGranted && _locationServicesEnabled)
            ? _currentPosition
            : null,
      );

      if (stations.isNotEmpty && mounted) {
        print('✅ Received ${stations.length} fresh stations');

        await _cacheService.saveStations(stations);

        setState(() {
          _evStations = stations;
          _activeFilters = {};
          _refreshDisplayedStations();
          _stationsLoaded = true;
        });
        await _addMarkersFromStations();
        await _wishlistService.refreshWishlist(_updateFavoriteIds);
        setState(() {});
      }

      // Get fresh location and center map
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
      }

    } catch (e) {
      print('❌ Error refreshing map: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
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

    final bool hasFilterState = _hasActiveFilters();
    final stationsToRender = hasFilterState ? _displayedStations : _evStations;
    print("📍 Adding ${stationsToRender.length} stations to map");
    print("📊 Map markers before filtering: ${_evStations.length}, after filtering: ${stationsToRender.length}");

    _markers.clear();

    Set<Marker> newMarkers = {};

    for (var station in stationsToRender.asMap().entries) {
      final index = station.key;
      final stationItem = station.value;

      print('🔍 Station: ${stationItem.name}');
      print('   Available from model: ${stationItem.availableChargers}');
      print('   Total from model: ${stationItem.totalChargers}');
      print('   Connector Ports: ${stationItem.connectorPorts.length}');

      final activeFilters = _hasActiveFilters() ? _activeFilters : null;
      final filteredConnectors = stationItem.getFilteredConnectorPorts(activeFilters);
      int total = filteredConnectors.length;
      int available = filteredConnectors.where(
              (port) => port.status.toLowerCase() == 'available'
      ).length;
      int inUse = filteredConnectors.where((port) {
        final status = port.status.toLowerCase();
        return status == 'busy' || status == 'charging' || status == 'in-use' || status == 'active';
      }).length;
      int fault = filteredConnectors.where((port) {
        final status = port.status.toLowerCase();
        return status == 'fault' || status == 'error';
      }).length;
      int offline = filteredConnectors.where((port) {
        final status = port.status.toLowerCase();
        return status == 'offline' || status == 'unavailable';
      }).length;

      if (total == 0) {
        total = stationItem.totalChargers;
        available = stationItem.availableChargers;
        print('   Using model values as fallback: available=$available, total=$total');
      } else {
        print('   Calculated from filtered ports: available=$available, total=$total');
      }

      if (total == 0) {
        print('   ⚠️ SKIPPING station "${stationItem.name}" - total chargers = 0');
        continue;
      }

      String overallStatus = stationItem.getOverallStatus();
      bool isAvailable = available > 0;

      bool hasFault = stationItem.connectorPorts.any((port) =>
      port.status.toLowerCase() == 'fault' ||
          port.status.toLowerCase() == 'error'
      );
      bool hasOffline = stationItem.connectorPorts.any((port) =>
      port.status.toLowerCase() == 'offline' ||
          port.status.toLowerCase() == 'unavailable'
      );

      print('   Final Values -> Available: $available, Total: $total');
      print('   Overall Status: $overallStatus');
      print('   Is Available: $isAvailable');

      final markerIcon = await LargeChargerMarker.createLargeMarker(
        available: available,
        total: total,
        isAvailable: isAvailable,
        status: overallStatus,
        hasFault: hasFault,
        hasOffline: hasOffline,
        inUse: inUse,
        fault: fault,
        offline: offline,
      );

      final markerPosition = buildMarkerPosition(stationItem.location, index);
      final marker = Marker(
        markerId: MarkerId(buildMarkerId(stationItem.id, index)),
        position: markerPosition,
        infoWindow: InfoWindow.noText,
        icon: markerIcon,
        anchor: const Offset(0.5, 1.0),
        onTap: () {
          print('📍 Marker tapped: ${stationItem.name}');
          _navigateToStationDetails(stationItem);
        },
      );

      newMarkers.add(marker);
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });

    print("✅ ${_markers.length} markers added successfully (${stationsToRender.length - _markers.length} stations skipped due to zero chargers)");
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

    unawaited(_saveSessionState(
      screen: 'station_details',
      stationId: station.id,
      filters: _activeFilters.isNotEmpty ? Map<String, dynamic>.from(_activeFilters) : {},
    ));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StationDetailsPage(
          station: station,
          distance: distance,
          isFavorite: isFavorite,
          activeFilters: _activeFilters.isNotEmpty ? Map<String, dynamic>.from(_activeFilters) : null,
          onFavoriteToggle: (bool isNowFavorite) async {
            await _toggleFavorite(station);
            if (mounted) setState(() {});
            return _favoriteStationIds.contains(station.id) == isNowFavorite;
          },
          onNavigate: () {
            _openNavigation(station.location, station.name);
          },
        ),
      ),
    ).then((_) {
      if (mounted) {
        unawaited(_clearSavedSessionState());
      }
    });
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
    if (_isNavigatingToChargingProgress) {
      print('⏳ Navigation to charging progress is already in progress');
      return;
    }

    _isNavigatingToChargingProgress = true;
    if (mounted) {
      setState(() {});
    }

    print('\n🚗 ========== NAVIGATE TO CHARGING PROGRESS ==========');
    print('📝 Session ID passed: $sessionId');

    try {
      if (sessionId == null || sessionId <= 0) {
        print('🔍 No valid session ID, attempting to recover...');
      }

      print('✅ Valid session ID: $sessionId');

      if (_chargingController == null) {
        _chargingController = LiveChargingController();
      }

      print('📡 Fetching latest session data for ID: $sessionId');
      await _chargingController!.fetchLiveChargingStatus(sessionId: sessionId);

      Map<String, dynamic> chargingDetails = {
        'sessionId': sessionId,
      };

      String manufacturer = 'Unknown';
      String model = 'Vehicle';
      String registrationNumber = 'N/A';
      String vehicleName = 'Unknown Vehicle';

      try {
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

        if (manufacturer == 'Unknown' && vehicleDetails != null) {
          manufacturer = vehicleDetails['manufacturer'] ?? 'Unknown';
          model = vehicleDetails['model'] ?? 'Vehicle';
          registrationNumber = vehicleDetails['registrationNumber'] ?? 'N/A';
          vehicleName = vehicleDetails['vehicleName'] ?? 'Unknown Vehicle';
          print('✅ Using provided vehicle details');
        }

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

      chargingDetails['manufacturer'] = manufacturer;
      chargingDetails['model'] = model;
      chargingDetails['registrationNumber'] = registrationNumber;
      chargingDetails['vehicleName'] = vehicleName;

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
    } finally {
      _isNavigatingToChargingProgress = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
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
                top: 40,
                left: 0,
                right: 0,
                child:
                MapSearchBar(
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
                  onFilterStateChanged: (isExpanded) {
                    setState(() {
                      _isFilterExpanded = isExpanded;
                    });
                  },
                  onFilterApplied: _handleFilterApplied,
                  resetSignal: _searchBarResetSignal,
                )
            ),

            // if (_hasActiveFilters() && _displayedStations.isEmpty && _evStations.isNotEmpty)
            //   Positioned(
            //     top: 115,
            //     left: 16,
            //     right: 16,
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            //       decoration: BoxDecoration(
            //         color: Colors.black.withOpacity(0.78),
            //         borderRadius: BorderRadius.circular(12),
            //         border: Border.all(color: Colors.green.shade300.withOpacity(0.4)),
            //       ),
            //       child: Row(
            //         children: [
            //           const Icon(Icons.info_outline, color: Colors.white70, size: 18),
            //           const SizedBox(width: 8),
            //           Expanded(
            //             child: Text(
            //               'No stations match the selected filters',
            //               style: const TextStyle(color: Colors.white, fontSize: 13),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),

            if (!_isFilterExpanded)
              Positioned(
                top: 115,
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

            if (!_isFilterExpanded)
              Positioned(
                right: 16,
                top: 115,
                child: Column(
                  children: [
                    MapButtons(
                      onControllerCreated: (controller) {
                        _mapButtonsController = controller;
                      },
                      onMyLocation: _centerOnCurrentLocation,
                      onRefresh: _refreshMap, // ✅ Add refresh callback
                      onNavigate: (sessionId) => _navigateToChargingProgress(sessionId, null),
                      onList: _showStationsList,
                      onZoomOut: _zoomOut,
                      onZoomIn: _zoomIn,
                      chargingController: _chargingController,
                    ),
                  ],
                ),
              ),

            if (_selectedStation != null && !_isFilterExpanded)
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
                  activeFilters: _activeFilters.isNotEmpty ? Map<String, dynamic>.from(_activeFilters) : null,
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


