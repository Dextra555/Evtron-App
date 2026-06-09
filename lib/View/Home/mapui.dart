// lib/View/Map/map_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../Model/ev_station_model.dart';
import '../../Service/WishlistService.dart';
import '../../Service/location_service.dart';
import '../../Service/station_service.dart';
import '../Home/scanner.dart';
import '../Login/Bottom.dart';
import '../Payment/paymentpage.dart';
import '../Profile/profile.dart';
import 'ChargingProgressPage.dart';
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
  bool _showStationCard = true;

  MapButtonsController? _mapButtonsController;

  late final LocationService _locationService;
  late final StationService _stationService;
  late final WishlistService _wishlistService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationService = LocationService();
    _stationService = StationService();
    _wishlistService = WishlistService();
    _checkAndRequestPermission();
    _loadWalletBalance();
    _listenToLocationServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app comes back to foreground
      _refreshMapButtons();
      _loadWalletBalance();
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

  Future<void> _loadWalletBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final balance = prefs.getDouble('wallet_balance') ?? 0.00;
      setState(() {
        _walletBalance = balance;
      });
    } catch (e) {
      print("Error loading wallet balance: $e");
    }
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
    print("📍 Permission granted: $_locationPermissionGranted, Services enabled: $_locationServicesEnabled");

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

      if (stations.isNotEmpty && mounted) {
        setState(() {
          _evStations = stations;
          _stationsLoaded = true;
        });

        await _addMarkersFromStations();
        await _wishlistService.refreshWishlist(_updateFavoriteIds);
      } else if (stations.isEmpty && mounted) {
        print("⚠️ No stations found");
        setState(() {
          _stationsLoaded = true;
        });
      }
    } catch (e) {
      print("❌ Error fetching stations: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    for (var station in _evStations) {
      final markerIcon = await _stationService.getMarkerIcon(station);

      final marker = Marker(
        markerId: MarkerId('station_${station.id}'),
        position: station.location,
        infoWindow: InfoWindow(
          title: station.name,
          snippet: '⭐ ${station.rating.toStringAsFixed(1)} | '
              '${station.availableChargers}/${station.totalChargers} chargers',
          onTap: () {
            setState(() {
              _selectedStation = station;
              _showStationCard = true; // ← Add this line
              _selectedStationDistance = _locationService.calculateDistance(
                _currentPosition,
                station.location,
              );
            });
          },
        ),
        icon: markerIcon,
      );

      _markers.add(marker);
    }

    _updateSearchRadius();

    if (mounted) {
      setState(() {});
      print("✅ Markers added successfully");
    }
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
          onFavoriteToggle: () {
            _toggleFavorite(station);
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
      final origin = await _locationService.getCurrentPosition();

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

    final position = await _locationService.getCurrentPosition();

    setState(() {
      _isGettingLocation = false;
    });

    if (position != null) {
      setState(() {
        _currentPosition = position;
      });
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 14),
      );

      if (!_stationsLoaded) {
        await _fetchEVStations();
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                _showStationCard = true;
              });
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      "Loading EV stations...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
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
                  onNavigate: (int? sessionId) async {
                    if (sessionId != null) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChargingProgressPage(
                            chargingDetails: {'sessionId': sessionId},
                          ),
                        ),
                      );
                      _refreshMapButtons();
                      _loadWalletBalance();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("No active charging session found"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  onList: _showStationsList,
                  onZoomOut: _zoomOut,
                  onZoomIn: _zoomIn,
                ),
              ],
            ),
          ),
          if (_showStationCard && _selectedStation != null)
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
                    _showStationCard = false;
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
    );
  }
}

