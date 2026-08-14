import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Model/ev_station_model.dart';
import '../../Theme/colors.dart';
import '../../Controller/wishlist_controller.dart';
import '../../Controller/scan_validation_controller.dart';
import '../Scanner/vehiclelist.dart';
import '../../Model/vehicle_model.dart';
import '../../Model/start_charging_model.dart';
import '../../Controller/vehicle_controller.dart';

class StationDetailsPage extends StatefulWidget {
  final EVStation station;
  final double distance;
  final bool isFavorite;
  final Future<bool> Function(bool isNowFavorite) onFavoriteToggle;
  final VoidCallback onNavigate;
  final Map<String, dynamic>? activeFilters;

  const StationDetailsPage({
    super.key,
    required this.station,
    required this.distance,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onNavigate,
    this.activeFilters,
  });

  @override
  State<StationDetailsPage> createState() => _StationDetailsPageState();
}

class _StationDetailsPageState extends State<StationDetailsPage> {
  late bool _isFavorite;
  late WishlistController _wishlistController;
  bool _isNavigating = false;
  bool _isValidating = false;
  bool _isRefreshing = false;

  final VehicleController _vehicleController = VehicleController();
  List<Vehicle> _vehicles = [];
  bool _isLoadingVehicles = false;

  late EVStation _currentStation;
  late double _currentDistance;
  Map<String, dynamic>? _activeFilters;

  @override
  void initState() {
    super.initState();
    _wishlistController = context.read<WishlistController>();
    _isFavorite = widget.isFavorite;
    _currentStation = widget.station;
    _currentDistance = widget.distance;
    _activeFilters = widget.activeFilters;

    if (_wishlistController.wishlist.isNotEmpty) {
      _checkIfFavorite();
    }

    _loadVehicles();
  }

  @override
  void didUpdateWidget(StationDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
    if (oldWidget.station != widget.station) {
      _currentStation = widget.station;
    }
    if (oldWidget.distance != widget.distance) {
      _currentDistance = widget.distance;
    }
    if (oldWidget.activeFilters != widget.activeFilters) {
      _activeFilters = widget.activeFilters;
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      print('🔄 Refreshing station details...');

      // ✅ Refresh vehicles
      await _loadVehicles();

      // ✅ Refresh wishlist status
      await _wishlistController.refreshWishlist();
      _checkIfFavorite();

      print('✅ Refresh completed successfully');
    } catch (e) {
      print('❌ Refresh error: $e');
      if (mounted) {
        _showSnackbar('Failed to refresh: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
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

  void _checkIfFavorite() {
    setState(() {
      _isFavorite = _wishlistController.isStationInWishlist(widget.station.id);
    });
  }

  Future<void> _toggleFavorite() async {
    final bool previousState = _isFavorite;
    final bool newState = !previousState;

    setState(() {
      _isFavorite = newState;
    });

    final bool success = await widget.onFavoriteToggle(newState);

    if (!success && mounted) {
      setState(() {
        _isFavorite = previousState;
      });
      _showSnackbar(
        'Failed to ${newState ? 'add to' : 'remove from'} wishlist',
        Colors.orange,
      );
      return;
    }

    if (mounted) {
      _showSnackbar(
        newState ? 'Added to wishlist' : 'Removed from wishlist',
        newState ? Appcolor.green : Colors.red,
      );
    }
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ========== HANDLE START CHARGING WITH VALIDATION ==========
  Future<void> _handleStartCharging(ConnectorPort port) async {
    if (_isValidating || _isNavigating) return;

    setState(() {
      _isValidating = true;
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
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
                  "Validating Charger...",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  port.connectorUid,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final validationController = context.read<ScanValidationController>();

      final isValid = await validationController.validateScan(
        scannedData: port.connectorUid,
        latitude: double.tryParse(widget.station.latitude.toString()),
        longitude: double.tryParse(widget.station.longitude.toString()),
        vehicleId: _vehicles.isNotEmpty ? _vehicles.first.id : null,
      );

      if (mounted) {
        Navigator.pop(context);
      }

      if (isValid && mounted) {
        final validationData = validationController.validationData;

        if (validationData != null) {
          print('\n✅ SCAN VALIDATION SUCCESSFUL!');
          print('🔌 Charger: ${validationData.charger.name}');
          print('💰 Balance: ₹${validationData.userBalance}');

          // Check balance (minimum ₹5)
          if (validationData.userBalance < 5) {
            _showErrorDialog(
              'Insufficient wallet balance (₹${validationData.userBalance.toStringAsFixed(2)}). '
              'Minimum balance required: ₹5. Please recharge your wallet.',
              title: 'Insufficient Balance',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.amber,
              actions: [
                ErrorAction(
                  label: 'Recharge Wallet',
                  action: 'recharge',
                  isPrimary: true,
                ),
                ErrorAction(label: 'Cancel', action: 'go_back'),
              ],
            );
            return;
          }

          // Navigate to VehicleScreen with validation data
          _navigateToVehicleScreen(
            port,
            userBalance: validationData.userBalance,
            connectorId: validationData.connector.connectorId,
          );
        } else {
          _navigateToVehicleScreen(port);
        }
      } else if (mounted) {
        // ❌ Validation failed - show error dialog
        final errorConfig = validationController.getErrorDialogConfig();
        _showErrorDialog(
          errorConfig.message,
          title: errorConfig.title,
          icon: errorConfig.icon,
          iconColor: errorConfig.iconColor,
          failedCheck: errorConfig.failedCheck,
          errorCode: errorConfig.errorCode,
          actions: _getErrorActions(errorConfig.failedCheck),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog(
          'An unexpected error occurred: ${e.toString()}',
          title: 'Error',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
      print('❌ Validation error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  // ========== GET ERROR ACTIONS ==========
  List<ErrorAction> _getErrorActions(String? failedCheck) {
    switch (failedCheck) {
      case 'wallet_balance_insufficient':
        return [
          ErrorAction(
            label: 'Recharge Wallet',
            action: 'recharge',
            isPrimary: true,
          ),
          ErrorAction(label: 'Go Back', action: 'go_back'),
        ];
      case 'connector_not_available':
        return [
          ErrorAction(
            label: 'Try Another Connector',
            action: 'try_another',
            isPrimary: true,
          ),
          ErrorAction(label: 'Go Back', action: 'go_back'),
        ];
      case 'active_session_exists':
        return [
          ErrorAction(
            label: 'View Active Session',
            action: 'view_session',
            isPrimary: true,
          ),
          ErrorAction(label: 'Go Back', action: 'go_back'),
        ];
      case 'user_not_authenticated':
        return [ErrorAction(label: 'Login', action: 'login', isPrimary: true)];
      case 'charger_not_found':
      case 'connector_invalid':
      case 'ocpp_offline':
        return [
          ErrorAction(label: 'Try Again', action: 'retry', isPrimary: true),
          ErrorAction(label: 'Go Back', action: 'go_back'),
        ];
      default:
        return [
          ErrorAction(label: 'Try Again', action: 'retry', isPrimary: true),
          ErrorAction(label: 'Go Back', action: 'go_back'),
        ];
    }
  }

  // ========== NAVIGATE TO VEHICLE SCREEN ==========
  void _navigateToVehicleScreen(
    ConnectorPort port, {
    ChargerInfo? chargerInfo,
    ConnectorInfo? connectorInfo,
    StationInfo? stationInfo,
    double userBalance = 0.0,
    int? connectorId,
  }) {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    try {
      final extractedConnectorId =
          connectorId ?? _extractConnectorId(port.connectorUid);

      print('\n📍 NAVIGATING TO VEHICLE SCREEN:');
      print('   Connector UID: ${port.connectorUid}');
      print('   Connector ID: $extractedConnectorId');
      print('   Vehicles: ${_vehicles.length}');
      print('   Charger Model: ${widget.station.name}');
      print('   Charger Type: ${port.chargerType}');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleScreen(
              connectorUid: port.connectorUid,
              vehicles: _vehicles,
              chargerModel: widget.station.name,
              chargerType: port.chargerType,
              chargerInfo: chargerInfo,
              connectorInfo: connectorInfo,
              stationInfo: stationInfo,
              connectorId: extractedConnectorId,
              userBalance: userBalance,
            ),
          ),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isNavigating = false;
            });
          }
        });
      }
    } catch (e) {
      print('❌ Error navigating to vehicle screen: $e');
      _showSnackbar('Error: ${e.toString()}', Colors.red);
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  int _extractConnectorId(String connectorUid) {
    try {
      final match = RegExp(r'(\d+)$').firstMatch(connectorUid);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '0') ?? 0;
      }
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
                if (title!.trim().isNotEmpty) ...[
                  Text(
                    title,
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

                // Buttons with actions
                if (actions != null && actions.isNotEmpty)
                  ..._buildActionButtons(actions)
                else
                  _buildDefaultButtons(),
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

  Widget _buildDefaultButtons() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "OK",
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
      case 'try_another':
        Navigator.pop(context);
        break;
      case 'view_session':
        Navigator.pushReplacementNamed(context, '/charging-progress');
        break;
      case 'login':
        Navigator.pushReplacementNamed(context, '/login');
        break;
      case 'retry':
        break;
      case 'go_back':
      default:
        Navigator.pop(context);
        break;
    }
  }

  // ========== UI HELPERS ==========
  String _formatDistance() {
    return _currentDistance < 1
        ? "${(_currentDistance * 1000).toInt()} m"
        : "${_currentDistance.toStringAsFixed(1)} km";
  }

  String _getTravelTime() {
    int minutes = (_currentDistance / 40 * 60).round();
    if (minutes < 60) return "$minutes min";
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    return "${hours}h${remainingMinutes > 0 ? ' $remainingMinutes min' : ''}";
  }

  List<ConnectorPort> _getVisibleConnectors() {
    if (_activeFilters == null || _activeFilters!.isEmpty) {
      return List<ConnectorPort>.from(_currentStation.connectorPorts);
    }
    return _currentStation.getFilteredConnectorPorts(_activeFilters);
  }

  bool _hasActiveFilter() {
    if (_activeFilters == null || _activeFilters!.isEmpty) return false;

    final chargerType = _activeFilters!['chargerType']?.toString();
    final connectorType = _activeFilters!['connectorType']?.toString();
    final status = _activeFilters!['status']?.toString();
    final powerRange = _activeFilters!['powerRange'] as RangeValues?;

    return (chargerType != null && chargerType.isNotEmpty) ||
        (connectorType != null && connectorType.isNotEmpty) ||
        (status != null && status.isNotEmpty) ||
        (powerRange != null && !(powerRange.start == 0.0 && powerRange.end == 350.0));
  }

  String _getStationStatus() {
    final visibleConnectors = _getVisibleConnectors();
    if (visibleConnectors.isEmpty) {
      return 'No matching connectors';
    }

    final hasAvailable = visibleConnectors.any(
      (port) => port.status.toLowerCase() == 'available',
    );

    final hasFault = visibleConnectors.any(
      (port) =>
          port.status.toLowerCase() == 'fault' ||
          port.status.toLowerCase() == 'error',
    );

    final hasOffline = visibleConnectors.any(
      (port) => port.status.toLowerCase() == 'offline',
    );

    final hasActive = visibleConnectors.any(
      (port) =>
          port.status.toLowerCase() == 'active' ||
          port.status.toLowerCase() == 'busy' ||
          port.status.toLowerCase() == 'charging',
    );

    if (hasAvailable) {
      final availableCount = visibleConnectors
          .where((port) => port.status.toLowerCase() == 'available')
          .length;
      return 'Available · $availableCount charger${availableCount > 1 ? 's' : ''} free';
    } else if (hasFault || hasOffline) {
      return '⚠️ Offline';
    } else if (hasActive) {
      final activeCount = visibleConnectors
          .where(
            (port) =>
                port.status.toLowerCase() == 'active' ||
                port.status.toLowerCase() == 'busy' ||
                port.status.toLowerCase() == 'charging',
          )
          .length;
      return 'Busy · $activeCount charger${activeCount > 1 ? 's' : ''} in use';
    } else {
      return 'Status unavailable';
    }
  }

  String _getChargerTypeSummary() {
    final visibleConnectors = _getVisibleConnectors();
    if (visibleConnectors.isEmpty) {
      return 'Unknown';
    }

    Set<String> chargerTypes = {};
    for (var port in visibleConnectors) {
      chargerTypes.add(port.chargerType.toLowerCase());
    }

    if (chargerTypes.contains('dc') && chargerTypes.contains('ac')) {
      return 'AC & DC';
    } else if (chargerTypes.contains('dc')) {
      return 'DC';
    } else if (chargerTypes.contains('ac')) {
      return 'AC';
    } else {
      return chargerTypes.first;
    }
  }

  Color _getStatusColor() {
    final visibleConnectors = _getVisibleConnectors();
    if (visibleConnectors.isEmpty) {
      return Colors.grey;
    }

    final hasAvailable = visibleConnectors.any(
      (port) => port.status.toLowerCase() == 'available',
    );

    final hasFault = visibleConnectors.any(
      (port) =>
          port.status.toLowerCase() == 'fault' ||
          port.status.toLowerCase() == 'error',
    );

    final hasOffline = visibleConnectors.any(
      (port) => port.status.toLowerCase() == 'offline',
    );

    if (hasAvailable) {
      return Appcolor.green;
    } else if (hasFault || hasOffline) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  int _getAvailableCount() {
    return _getVisibleConnectors()
        .where((port) => port.status.toLowerCase() == 'available')
        .length;
  }

  int _getTotalCount() {
    return _getVisibleConnectors().length;
  }

  List<ConnectorPort> _getAvailableConnectors() {
    return _getVisibleConnectors()
        .where((port) => port.status.toLowerCase() == 'available')
        .toList();
  }

  List<ConnectorPort> _getUnavailableConnectors() {
    return _getVisibleConnectors()
        .where((port) => port.status.toLowerCase() != 'available')
        .toList();
  }

  String _getConnectorStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'active':
      case 'busy':
      case 'charging':
        return 'In Use';
      case 'fault':
      case 'error':
        return 'Fault';
      case 'offline':
        return 'Offline';
      case 'unavailable':
        return 'Unavailable';
      default:
        return status;
    }
  }

  Color _getConnectorStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Appcolor.green;
      case 'active':
      case 'busy':
      case 'charging':
        return Colors.orange;
      case 'fault':
      case 'error':
      case 'offline':
      case 'unavailable':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getFormattedPrice() {
    if (_currentStation.estimatedChargingPrice > 0) {
      String priceStr = _currentStation.estimatedChargingPrice.toString();
      priceStr = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
      double cleanPrice = double.tryParse(priceStr) ?? 0.0;
      if (cleanPrice > 0) {
        return '₹${cleanPrice.toStringAsFixed(2)}';
      }
    }
    return '₹0.00';
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'restroom':
      case 'toilet':
        return Icons.wc;
      case 'parking':
        return Icons.local_parking;
      case 'waiting_area':
      case 'waiting area':
        return Icons.chair;
      case 'cafe':
      case 'cafeteria':
        return Icons.local_cafe;
      case 'restaurant':
        return Icons.restaurant;
      case 'atm':
        return Icons.atm;
      case 'medical':
        return Icons.local_hospital;
      case 'charging':
        return Icons.bolt;
      case 'security':
        return Icons.security;
      default:
        return Icons.hotel_class;
    }
  }

  String _getFormattedAmenityName(String amenity) {
    return amenity
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  // ========== BUILD CONNECTOR CARD ==========
  Widget _buildConnectorCard(
    ConnectorPort port,
    int index,
    bool isAvailable,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color borderColor,
  ) {
    final statusColor = _getConnectorStatusColor(port.status);
    final statusText = _getConnectorStatusText(port.status);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connector UID Row
              // Row(
              //   children: [
              //     Icon(Icons.qr_code, size: 12, color: textSecondary),
              //     const SizedBox(width: 4),
              //     Expanded(
              //       child: Text(
              //         port.connectorUid.isNotEmpty
              //             ? 'UID: ${port.connectorUid}'
              //             : 'UID: N/A',
              //         style: TextStyle(
              //           fontSize: 10,
              //           fontWeight: FontWeight.w600,
              //           color: textPrimary,
              //         ),
              //         overflow: TextOverflow.ellipsis,
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 4),

              // Charger ID Row
              Row(
                children: [
                  Icon(
                    Icons.electrical_services_outlined,
                    size: 12,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      port.chargerId.isNotEmpty
                          ? 'ID: ${port.chargerId}'
                          : 'ID: N/A',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Charger Type (AC/DC)
              Row(
                children: [
                  Icon(
                    port.chargerType.toLowerCase() == 'dc'
                        ? Icons.bolt
                        : Icons.power_settings_new,
                    size: 11,
                    color: port.chargerType.toLowerCase() == 'dc'
                        ? Colors.orange
                        : Colors.blue,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    port.chargerType,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: port.chargerType.toLowerCase() == 'dc'
                          ? Colors.orange
                          : Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),

              // Connector Type
              Text(
                port.type,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),

              // KW Display
              Row(
                children: [
                  Icon(Icons.power, size: 11, color: Appcolor.green),
                  const SizedBox(width: 3),
                  Text(
                    port.kw != null && port.kw! > 0 ? '${port.kw} kW' : '-- kW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: port.kw != null && port.kw! > 0
                          ? Appcolor.green
                          : textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Button with validation
          Container(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: isAvailable && !_isValidating && !_isNavigating
                  ? () => _handleStartCharging(port)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable
                    ? Appcolor.green
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                elevation: 0,
              ),
              child: _isValidating && isAvailable
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _isNavigating && isAvailable
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isAvailable ? 'Start Charging' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isAvailable
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== BUILD ==========
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark
        ? Colors.grey.shade400
        : const Color(0xFF6B7280);
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    final statusText = _getStationStatus();
    final statusColor = _getStatusColor();
    final availableCount = _getAvailableCount();
    final totalCount = _getTotalCount();
    final visibleConnectors = _getVisibleConnectors();
    final hasActiveFilter = _hasActiveFilter();

    final availableConnectors = _getAvailableConnectors();
    final unavailableConnectors = _getUnavailableConnectors();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Station Details',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Appcolor.green,
        backgroundColor: cardBg,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // ✅ Important for pull-to-refresh
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Appcolor.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.ev_station,
                            color: Appcolor.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.station.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.station.fullAddress,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondary,
                                        height: 1.3,
                                      ),
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                          ),
                          if (totalCount > 0) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$availableCount/$totalCount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Distance',
                      _formatDistance(),
                      Icons.straighten,
                      textPrimary,
                      textSecondary,
                      cardBg,
                      borderColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Travel Time',
                      _getTravelTime(),
                      Icons.access_time,
                      textPrimary,
                      textSecondary,
                      cardBg,
                      borderColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Price/kWh',
                      _getFormattedPrice(),
                      Icons.currency_rupee,
                      textPrimary,
                      textSecondary,
                      cardBg,
                      borderColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 0.5),
                ),
                child: Column(
                  children: [
                    _detailRow(
                      'Connectors',
                      hasActiveFilter
                          ? '${visibleConnectors.length} matching'
                          : '${_currentStation.connectorPorts.length} ports',
                      Icons.flash_on,
                      textPrimary,
                      textSecondary,
                    ),
                    Divider(height: 16, color: dividerColor),
                    _detailRow(
                      'Charger Type',
                      _getChargerTypeSummary(),
                      Icons.electrical_services,
                      textPrimary,
                      textSecondary,
                    ),
                    Divider(height: 16, color: dividerColor),
                    _detailRow(
                      'Operation',
                      _currentStation.is247 ? '24/7' : 'Limited',
                      Icons.access_time,
                      textPrimary,
                      textSecondary,
                    ),
                    Divider(height: 16, color: dividerColor),
                    _detailRow(
                      'Station Type',
                      _currentStation.stationType.toUpperCase(),
                      Icons.ev_station,
                      textPrimary,
                      textSecondary,
                    ),
                    Divider(height: 16, color: dividerColor),
                    _detailRow(
                      'Rating',
                      _currentStation.rating != null
                          ? '${_currentStation.rating!.toStringAsFixed(1)} ★'
                          : 'Not rated',
                      Icons.star,
                      textPrimary,
                      textSecondary,
                      iconColor: _currentStation.rating != null
                          ? Colors.amber
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (visibleConnectors.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      'No matching connectors found.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Available Connectors Section
                if (availableConnectors.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Appcolor.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Available Connectors',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Appcolor.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${availableConnectors.length} available',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Appcolor.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableConnectors.length,
                    itemBuilder: (context, index) {
                      final port = availableConnectors[index];
                      final originalIndex = _currentStation.connectorPorts
                          .indexOf(port);
                      return _buildConnectorCard(
                        port,
                        originalIndex,
                        true,
                        textPrimary,
                        textSecondary,
                        cardBg,
                        borderColor,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

                // Unavailable Connectors Section
                if (unavailableConnectors.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Unavailable Connectors',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${unavailableConnectors.length} unavailable',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: unavailableConnectors.length,
                    itemBuilder: (context, index) {
                      final port = unavailableConnectors[index];
                      final originalIndex = _currentStation.connectorPorts
                          .indexOf(port);
                      return _buildConnectorCard(
                        port,
                        originalIndex,
                        false,
                        textPrimary,
                        textSecondary,
                        cardBg,
                        borderColor,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

                // Amenities Section
                if (_currentStation.amenities.isNotEmpty) ...[
                Text(
                  'Amenities',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _currentStation.amenities.map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getAmenityIcon(amenity),
                            size: 14,
                            color: Appcolor.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getFormattedAmenityName(amenity),
                            style: TextStyle(
                              fontSize: 12,
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onNavigate();
                      },
                      icon: const Icon(Icons.directions_car, size: 18),
                      label: const Text(
                        'Navigate',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolor.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
    ],
    ),
        ),
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color textColor,
    Color subtitleColor,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: Appcolor.green, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: subtitleColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ========== DETAIL ROW ==========
  Widget _detailRow(
    String label,
    String value,
    IconData icon,
    Color textColor,
    Color subtitleColor, {
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? Appcolor.green),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: subtitleColor),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
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
