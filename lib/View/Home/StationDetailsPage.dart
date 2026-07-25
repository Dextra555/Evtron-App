import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/ev_station_model.dart';
import '../../Service/WishlistService.dart';
import '../../Theme/colors.dart';
import '../../Controller/wishlist_controller.dart';
import 'loading_page.dart';

class StationDetailsPage extends StatefulWidget {
  final EVStation station;
  final double distance;
  final bool isFavorite;
  final Future<void> Function() onFavoriteToggle;
  final VoidCallback onNavigate;

  const StationDetailsPage({
    super.key,
    required this.station,
    required this.distance,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onNavigate,
  });

  @override
  State<StationDetailsPage> createState() => _StationDetailsPageState();
}

class _StationDetailsPageState extends State<StationDetailsPage> {
  late bool _isFavorite;
  late WishlistController _wishlistController;
  final WishlistService _wishlistService = WishlistService();

  @override
  void initState() {
    super.initState();
    _wishlistController = context.read<WishlistController>();
    _isFavorite = widget.isFavorite;

    if (_wishlistController.wishlist.isNotEmpty) {
      _checkIfFavorite();
    }
  }

  @override
  void didUpdateWidget(StationDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
  }

  void _checkIfFavorite() {
    setState(() {
      _isFavorite = _wishlistController.isStationInWishlist(widget.station.id);
    });
  }

  Future<void> _toggleFavorite() async {
    final bool previousState = _isFavorite;

    setState(() {
      _isFavorite = !_isFavorite;
    });

    await widget.onFavoriteToggle();

    try {
      if (_isFavorite) {
        final success = await _wishlistService.addToWishlist(
          chargingStationId: widget.station.id,
          isFavorite: true,
          notes: '',
        );

        if (success && mounted) {
          await _wishlistController.refreshWishlist();
          _showSnackbar('Added to wishlist', Appcolor.green);
        } else {
          if (mounted) {
            setState(() {
              _isFavorite = previousState;
            });
            _showSnackbar('Failed to add to wishlist', Colors.orange);
          }
        }
      } else {
        final wishlistId = _wishlistController.getWishlistIdForStation(widget.station.id);

        if (wishlistId != null) {
          final success = await _wishlistController.removeFromWishlist(wishlistId);

          if (success && mounted) {
            await _wishlistController.refreshWishlist();
            _showSnackbar('Removed from wishlist', Colors.red);
          } else {
            if (mounted) {
              setState(() {
                _isFavorite = previousState;
              });
              _showSnackbar('Failed to remove from wishlist', Colors.orange);
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isFavorite = previousState;
            });
            _showSnackbar('Wishlist item not found', Colors.orange);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFavorite = previousState;
        });
        _showSnackbar('Error: ${e.toString()}', Colors.red);
      }
      print('Error toggling favorite: $e');
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

  String _formatDistance() {
    return widget.distance < 1
        ? "${(widget.distance * 1000).toInt()} m"
        : "${widget.distance.toStringAsFixed(1)} km";
  }

  String _getTravelTime() {
    int minutes = (widget.distance / 40 * 60).round();
    if (minutes < 60) return "$minutes min";
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    return "${hours}h${remainingMinutes > 0 ? ' $remainingMinutes min' : ''}";
  }

  String _getStationStatus() {
    if (widget.station.connectorPorts.isEmpty) {
      return 'No connectors available';
    }

    final hasAvailable = widget.station.connectorPorts.any(
            (port) => port.status.toLowerCase() == 'available'
    );

    final hasFault = widget.station.connectorPorts.any(
            (port) => port.status.toLowerCase() == 'fault' ||
            port.status.toLowerCase() == 'error'
    );

    final hasOffline = widget.station.connectorPorts.any(
            (port) => port.status.toLowerCase() == 'offline'
    );

    final hasActive = widget.station.connectorPorts.any(
            (port) => port.status.toLowerCase() == 'active' ||
            port.status.toLowerCase() == 'busy' ||
            port.status.toLowerCase() == 'charging'
    );

    if (hasAvailable) {
      final availableCount = widget.station.connectorPorts
          .where((port) => port.status.toLowerCase() == 'available')
          .length;
      return 'Available · $availableCount charger${availableCount > 1 ? 's' : ''} free';
    } else if (hasFault || hasOffline) {
      return '⚠️ Maintenance required';
    } else if (hasActive) {
      final activeCount = widget.station.connectorPorts
          .where((port) => port.status.toLowerCase() == 'active' ||
          port.status.toLowerCase() == 'busy' ||
          port.status.toLowerCase() == 'charging')
          .length;
      return 'Busy · $activeCount charger${activeCount > 1 ? 's' : ''} in use';
    } else {
      return 'Status unavailable';
    }
  }

  Color _getStatusColor() {
    if (widget.station.connectorPorts.isEmpty) {
      return Colors.grey;
    }

    final hasAvailable = widget.station.connectorPorts.any(
            (port) => port.status.toLowerCase() == 'available'
    );

    final hasFault = widget.station.connectorPorts.any(
            (port) => port.status.toLowerCase() == 'fault' ||
            port.status.toLowerCase() == 'error'
    );

    final hasOffline = widget.station.connectorPorts.any(
            (port) => port.status.toLowerCase() == 'offline'
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
    return widget.station.connectorPorts
        .where((port) => port.status.toLowerCase() == 'available')
        .length;
  }

  int _getTotalCount() {
    return widget.station.connectorPorts.length;
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
    if (widget.station.estimatedChargingPrice > 0) {
      String priceStr = widget.station.estimatedChargingPrice.toString();
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

  void _onStartCharging(int connectorIndex) {
    final port = widget.station.connectorPorts[connectorIndex];

    print('Starting charging for connector ${connectorIndex + 1}');
    print('Station: ${widget.station.name}');
    print('Connector Type: ${port.type}');
    print('Charger ID: ${port.chargerId}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Charging'),
        content: Text(
            'Start charging at ${widget.station.name}\n'
                'Connector: ${widget.station.connectorPorts[connectorIndex].type}\n'
                'Charger ID: ${widget.station.connectorPorts[connectorIndex].chargerId}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoadingPage(
                    stationName: widget.station.name,
                    connectorType: widget.station.connectorPorts[connectorIndex].type,
                    chargerId: widget.station.connectorPorts[connectorIndex].chargerId,
                  ),
                ),
              );

            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Appcolor.green,
            ),
            child: const Text('Start Charging'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? const Color(0xFF2D2D44) : const Color(0xFFF5F7FA);

    final statusText = _getStationStatus();
    final statusColor = _getStatusColor();
    final availableCount = _getAvailableCount();
    final totalCount = _getTotalCount();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Station Details',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        // actions: [
        //   IconButton(
        //     onPressed: _toggleFavorite,
        //     icon: Icon(
        //       _isFavorite ? Icons.favorite : Icons.favorite_border,
        //       color: _isFavorite ? Colors.red : subtitleColor,
        //     ),
        //     tooltip: _isFavorite ? 'Remove from wishlist' : 'Add to wishlist',
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Appcolor.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.ev_station,
                    color: Appcolor.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.station.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: subtitleColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.station.fullAddress,
                              style: TextStyle(
                                fontSize: 13,
                                color: subtitleColor,
                                height: 1.4,
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

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Text(
                    totalCount > 0 ? '$availableCount/$totalCount' : '0/0',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _infoItem(
                    Icons.straighten,
                    _formatDistance(),
                    'Distance',
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoItem(
                    Icons.access_time,
                    _getTravelTime(),
                    'Travel Time',
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoItem(
                    Icons.currency_rupee,
                    _getFormattedPrice(),
                    'Per kWh',
                    isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _detailRow(
                    Icons.flash_on,
                    'Total Connectors',
                    '${widget.station.connectorPorts.length} ports',
                    textColor,
                    subtitleColor,
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    Icons.access_time,
                    'Operation',
                    widget.station.is247 ? '24/7' : 'Limited',
                    textColor,
                    subtitleColor,
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    Icons.ev_station,
                    'Station Type',
                    widget.station.stationType.toUpperCase(),
                    textColor,
                    subtitleColor,
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    Icons.star,
                    'Rating',
                    widget.station.rating != null
                        ? '${widget.station.rating!.toStringAsFixed(1)} / 5'
                        : 'Not rated',
                    textColor,
                    subtitleColor,
                    iconColor: Colors.amber,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (widget.station.connectorPorts.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Connectors',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${widget.station.connectorPorts.length} available',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.station.connectorPorts.length,
                  itemBuilder: (context, index) {
                    final port = widget.station.connectorPorts[index];
                    final statusColor = _getConnectorStatusColor(port.status);
                    final statusText = _getConnectorStatusText(port.status);
                    final isAvailable = port.status.toLowerCase() == 'available';

                    return Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor.withOpacity(0.28),
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.electrical_services_outlined,
                                      size: 14,
                                      color: subtitleColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        port.chargerId.isNotEmpty
                                            ? 'ID: ${port.chargerId}'
                                            : 'ID: N/A',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: statusColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        port.type,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subtitleColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (port.maxPower != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.bolt_outlined,
                                        size: 14,
                                        color: subtitleColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${port.maxPower?.toString() ?? 'N/A'} kW',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtitleColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isAvailable ? () => _onStartCharging(index) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isAvailable ? Appcolor.green : Colors.grey.shade400,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(0, 36),
                                ),
                                child: Text(
                                  isAvailable ? 'Start Charging' : 'Unavailable',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            if (widget.station.amenities.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${widget.station.amenities.length} available',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.station.amenities.map((amenity) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Appcolor.green.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getAmenityIcon(amenity),
                          size: 18,
                          color: Appcolor.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getFormattedAmenityName(amenity),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: subtitleColor,
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
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Appcolor.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String value, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Appcolor.green, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
      IconData icon,
      String label,
      String value,
      Color textColor,
      Color? subtitleColor, {
        Color? iconColor,
      }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor ?? Appcolor.green,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: subtitleColor,
            ),
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


