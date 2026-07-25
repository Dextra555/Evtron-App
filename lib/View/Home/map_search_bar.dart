import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../Model/ev_station_model.dart';
import '../../Model/filter_master_model.dart';
import '../../Service/filter_service.dart';

class MapSearchBar extends StatefulWidget {
  final LatLng currentPosition;
  final List<EVStation> evStations;
  final Function(EVStation) onStationSelected;
  final Function(LatLng, String) onLocationSelected;
  final Function(bool) onFilterStateChanged;
  final Function(List<EVStation>)? onFilterApplied;

  const MapSearchBar({
    super.key,
    required this.currentPosition,
    required this.evStations,
    required this.onStationSelected,
    required this.onLocationSelected,
    required this.onFilterStateChanged,
    this.onFilterApplied,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  String? _error;
  bool _isFocused = false;
  static const String _apiKey = "AIzaSyBKgPe-P7029JQIk9KYDT7Os4U96g5Mmbs";

  // Filter state
  String? _selectedChargerType;
  String? _selectedConnectorType;
  String? _selectedStatus;
  String? _selectedAccessibility;
  RangeValues _selectedCapacityRange = const RangeValues(0.0, 350.0);
  bool _isFilterApplied = false;
  bool _isFilterExpanded = false;

  // Filter master data
  FilterMasterResponse? _filterMasterData;
  bool _isLoadingFilters = false;
  String? _filterError;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  List<String> _chargerTypes = [];
  List<String> _connectorTypes = [];

  final List<String> _statuses = ['Available', 'In-Use','Fault'];
  final List<String> _accessibilities = ['Public', 'Private', 'Guest'];
  final double _maxCapacity = 350.0;

  final FilterService _filterService = FilterService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadFilterMasterData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFilterMasterData() async {
    print('\n🔍 ========== LOADING FILTER DATA ==========');
    setState(() {
      _isLoadingFilters = true;
      _filterError = null;
    });

    try {
      final data = await _filterService.getFilterMasterData();

      if (mounted) {
        final chargerTypeNames = data.data.chargerTypes.map((e) => e.name).toList();
        final connectorTypeNames = data.data.connectorTypes.map((e) => e.name).toList();

        print('✅ API Response - Charger Types: ${chargerTypeNames.join(', ')}');
        print('✅ API Response - Connector Types: ${connectorTypeNames.join(', ')}');

        setState(() {
          _filterMasterData = data;
          _chargerTypes = chargerTypeNames;
          _connectorTypes = connectorTypeNames;
          _isLoadingFilters = false;
        });

        print('✅ Filter data loaded successfully:');
        print('   Charger types: $_chargerTypes');
        print('   Connector types: $_connectorTypes');
        print('========================================\n');
      }
    } catch (e) {
      print('❌ Error loading filter master data: $e');
      if (mounted) {
        setState(() {
          _isLoadingFilters = false;
          // Default values based on your actual model
          _chargerTypes = ['AC', 'DC', 'Both'];
          _connectorTypes = ['Type 1', 'Type 2', 'CCS', 'CHAdeMO', 'GB/T', 'Tesla'];
          _filterError = 'Failed to load filter options. Using defaults.';
        });
        print('⚠️ Using fallback values:');
        print('   Charger types: $_chargerTypes');
        print('   Connector types: $_connectorTypes');
        print('========================================\n');
      }
    }
  }

  // ✅ Updated: Get charger type from connector ports
  String? _getChargerType(EVStation station) {
    try {
      // Check if all connectors are of same type
      if (station.connectorPorts.isNotEmpty) {
        Set<String> types = {};
        for (var port in station.connectorPorts) {
          final type = port.type.toLowerCase();
          if (type.contains('dc') || type.contains('ccs') || type.contains('chademo')) {
            types.add('DC');
          } else if (type.contains('ac') || type.contains('type')) {
            types.add('AC');
          }
        }

        if (types.contains('DC') && types.contains('AC')) {
          return 'Both';
        } else if (types.contains('DC')) {
          return 'DC';
        } else if (types.contains('AC')) {
          return 'AC';
        }
      }
    } catch (e) {}

    // Fallback based on station data
    return station.totalChargers > 20 ? 'DC' : 'AC';
  }

  // ✅ Updated: Get connector type from connector ports
  String? _getConnectorType(EVStation station) {
    try {
      if (station.connectorPorts.isNotEmpty) {
        // Get the most common connector type
        Map<String, int> typeCount = {};
        for (var port in station.connectorPorts) {
          final type = port.type;
          typeCount[type] = (typeCount[type] ?? 0) + 1;
        }

        // Return the most frequent type
        String? mostCommonType;
        int maxCount = 0;
        typeCount.forEach((type, count) {
          if (count > maxCount) {
            maxCount = count;
            mostCommonType = type;
          }
        });

        if (mostCommonType != null) {
          return mostCommonType;
        }
      }
    } catch (e) {}

    return null;
  }

  // ✅ Updated: Get status from station
  String? _getStatus(EVStation station) {
    try {
      return station.status;
    } catch (e) {}

    return 'active';
  }

  // ✅ Updated: Get accessibility from station type
  String? _getAccessibility(EVStation station) {
    try {
      return station.stationType;
    } catch (e) {}

    return 'public';
  }

  // ✅ Updated: Get charger capacity from connector ports
  double? _getChargerCapacity(EVStation station) {
    try {
      if (station.connectorPorts.isNotEmpty) {
        // Get max power from connectors
        double maxPower = 0;
        for (var port in station.connectorPorts) {
          if (port.maxPower != null && port.maxPower! > maxPower) {
            maxPower = port.maxPower!;
          }
        }
        if (maxPower > 0) {
          return maxPower;
        }
      }
    } catch (e) {}

    // Fallback based on charger count
    if (station.totalChargers > 50) return 150.0;
    if (station.totalChargers > 20) return 100.0;
    return 50.0;
  }

  // ✅ Updated: Get all unique connector types from stations
  List<String> _getUniqueConnectorTypes() {
    Set<String> types = {};
    for (var station in widget.evStations) {
      for (var port in station.connectorPorts) {
        types.add(port.type);
      }
    }
    return types.toList()..sort();
  }

  List<EVStation> _getFilteredStations() {
    List<EVStation> filtered = [];

    for (var station in widget.evStations) {
      // Check charger type
      if (_selectedChargerType != null) {
        final chargerType = _getChargerType(station);
        if (chargerType != _selectedChargerType) {
          print('⏭️ Skipping ${station.name} - Charger type mismatch: $chargerType != ${_selectedChargerType}');
          continue;
        }
      }

      // Check connector type
      if (_selectedConnectorType != null) {
        final connectorType = _getConnectorType(station);
        if (connectorType != _selectedConnectorType) {
          print('⏭️ Skipping ${station.name} - Connector type mismatch: $connectorType != ${_selectedConnectorType}');
          continue;
        }
      }

      // Check status
      if (_selectedStatus != null) {
        final status = _getStatus(station);
        if (status != _selectedStatus) {
          print('⏭️ Skipping ${station.name} - Status mismatch: $status != ${_selectedStatus}');
          continue;
        }
      }

      // Check accessibility
      if (_selectedAccessibility != null) {
        final accessibility = _getAccessibility(station);
        if (accessibility != _selectedAccessibility) {
          print('⏭️ Skipping ${station.name} - Accessibility mismatch: $accessibility != ${_selectedAccessibility}');
          continue;
        }
      }

      // Check capacity range
      final chargerCapacity = _getChargerCapacity(station);
      if (chargerCapacity != null) {
        if (chargerCapacity < _selectedCapacityRange.start ||
            chargerCapacity > _selectedCapacityRange.end) {
          print('⏭️ Skipping ${station.name} - Capacity mismatch: $chargerCapacity kW not in range ${_selectedCapacityRange.start}-${_selectedCapacityRange.end}');
          continue;
        }
      }

      filtered.add(station);
    }

    print('✅ Filtered ${filtered.length} stations from ${widget.evStations.length} total');
    return filtered;
  }

  void _toggleFilter() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
      if (_isFilterExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    widget.onFilterStateChanged(_isFilterExpanded);
  }

  void _applyFilters() {
    setState(() {
      _isFilterApplied = _selectedChargerType != null ||
          _selectedConnectorType != null ||
          _selectedStatus != null ||
          _selectedAccessibility != null ||
          _selectedCapacityRange.start > 0.0 ||
          _selectedCapacityRange.end < _maxCapacity;

      // Get filtered stations
      final filteredStations = _getFilteredStations();

      print('📊 Applied filters - Found ${filteredStations.length} stations out of ${widget.evStations.length}');
      print('   Charger Type: ${_selectedChargerType ?? "All"}');
      print('   Connector Type: ${_selectedConnectorType ?? "All"}');
      print('   Status: ${_selectedStatus ?? "All"}');
      print('   Accessibility: ${_selectedAccessibility ?? "All"}');
      print('   Capacity Range: ${_selectedCapacityRange.start} - ${_selectedCapacityRange.end} kW');

      // Notify parent widget to update map markers
      if (widget.onFilterApplied != null) {
        widget.onFilterApplied!(filteredStations);
      }

      // Update search results
      _searchLocation(_controller.text);
      _toggleFilter();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedChargerType = null;
      _selectedConnectorType = null;
      _selectedStatus = null;
      _selectedAccessibility = null;
      _selectedCapacityRange = RangeValues(0.0, _maxCapacity);
      _isFilterApplied = false;

      // Reset to show all stations
      if (widget.onFilterApplied != null) {
        widget.onFilterApplied!(widget.evStations);
        print('📊 Cleared filters - Showing all ${widget.evStations.length} stations');
      }

      _searchLocation(_controller.text);
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results.clear();
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = <Map<String, dynamic>>[];

      // Use filtered stations for search
      List<EVStation> searchStations = _isFilterApplied ? _getFilteredStations() : widget.evStations;

      for (var station in searchStations) {
        bool matchesSearch = station.name.toLowerCase().contains(query.toLowerCase()) ||
            station.fullAddress.toLowerCase().contains(query.toLowerCase());

        if (!matchesSearch) continue;

        final chargerType = _getChargerType(station);
        final connectorType = _getConnectorType(station);
        final status = _getStatus(station);
        final accessibility = _getAccessibility(station);
        final chargerCapacity = _getChargerCapacity(station);

        if (_selectedChargerType != null && chargerType != _selectedChargerType) continue;
        if (_selectedConnectorType != null && connectorType != _selectedConnectorType) continue;
        if (_selectedStatus != null && status != _selectedStatus) continue;
        if (_selectedAccessibility != null && accessibility != _selectedAccessibility) continue;

        double stationCapacity = chargerCapacity ?? 0;
        if (stationCapacity < _selectedCapacityRange.start ||
            stationCapacity > _selectedCapacityRange.end) continue;

        results.add({
          'type': 'EV Station',
          'name': station.name,
          'address': station.fullAddress,
          'station': station,
        });
      }

      final url = "https://maps.googleapis.com/maps/api/place/autocomplete/json"
          "?input=$query"
          "&location=${widget.currentPosition.latitude},${widget.currentPosition.longitude}"
          "&radius=50000&types=establishment|geocode&key=$_apiKey";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['predictions'] != null) {
          for (var prediction in data['predictions']) {
            results.add({
              'type': 'Location',
              'name': prediction['description'],
              'placeId': prediction['place_id'],
              'address': prediction['description'],
            });
          }
        }
      }

      setState(() {
        _results.clear();
        _results.addAll(results);
        _isSearching = false;
        _error = results.isEmpty ? "No results found for '$query'" : null;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _error = "Error searching: $e";
      });
    }
  }

  Future<void> _selectResult(Map<String, dynamic> result) async {
    setState(() => _isSearching = true);

    if (result['type'] == 'EV Station' && result['station'] != null) {
      widget.onStationSelected(result['station']);
    } else if (result['placeId'] != null) {
      final detailsUrl = "https://maps.googleapis.com/maps/api/place/details/json"
          "?place_id=${result['placeId']}&fields=geometry,formatted_address&key=$_apiKey";

      final response = await http.get(Uri.parse(detailsUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final lat = data['result']['geometry']['location']['lat'];
          final lng = data['result']['geometry']['location']['lng'];
          widget.onLocationSelected(LatLng(lat, lng), result['name']);
        }
      }
    }

    _controller.clear();
    setState(() {
      _results.clear();
      _isSearching = false;
      _isFocused = false;
    });
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: isLoading
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
                : DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.grey[900],
              hint: Text(
                items.isEmpty ? 'Loading...' : 'Select $label',
                style: TextStyle(
                  color: items.isEmpty
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white.withOpacity(0.7),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All', style: TextStyle(color: Colors.white)),
                ),
                ...items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(color: Colors.white)),
                  );
                }),
              ],
              onChanged: items.isEmpty ? null : onChanged,
              icon: Icon(
                Icons.arrow_drop_down,
                color: items.isEmpty
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused ? Colors.green : Colors.black,
                width: 0.5,
              ),
              boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      setState(() {
                        _isFocused = hasFocus;
                      });
                    },
                    child: TextField(
                      controller: _controller,
                      onChanged: _searchLocation,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Search location or EV station...',
                        hintStyle: const TextStyle(color: Colors.black),
                        prefixIcon: const Icon(Icons.search, color: Colors.black),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _results.clear();
                              _error = null;
                            });
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: AnimatedRotation(
                          turns: _isFilterExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.tune,
                            color: _isFilterApplied ? Colors.green : Colors.black,
                          ),
                        ),
                        onPressed: _toggleFilter,
                      ),
                      if (_isFilterApplied && !_isFilterExpanded)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizeTransition(
            sizeFactor: _slideAnimation,
            axisAlignment: -1.0,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.filter_alt,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Filter EV Stations',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _toggleFilter,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildFilterDropdown(
                      label: 'Charger Type',
                      value: _selectedChargerType,
                      items: _chargerTypes,
                      onChanged: (value) {
                        setState(() {
                          _selectedChargerType = value;
                        });
                      },
                      isLoading: _isLoadingFilters,
                    ),
                    const SizedBox(height: 12),

                    _buildFilterDropdown(
                      label: 'Connector Type',
                      value: _selectedConnectorType,
                      items: _connectorTypes,
                      onChanged: (value) {
                        setState(() {
                          _selectedConnectorType = value;
                        });
                      },
                      isLoading: _isLoadingFilters,
                    ),
                    const SizedBox(height: 12),

                    _buildFilterDropdown(
                      label: 'Status',
                      value: _selectedStatus,
                      items: _statuses,
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildFilterDropdown(
                      label: 'Accessibility',
                      value: _selectedAccessibility,
                      items: _accessibilities,
                      onChanged: (value) {
                        setState(() {
                          _selectedAccessibility = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Charger Capacity: ${_selectedCapacityRange.start.toStringAsFixed(1)} - ${_selectedCapacityRange.end.toStringAsFixed(1)} kW',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RangeSlider(
                          values: _selectedCapacityRange,
                          min: 0.0,
                          max: _maxCapacity,
                          divisions: 350,
                          labels: RangeLabels(
                            '${_selectedCapacityRange.start.toStringAsFixed(1)} kW',
                            '${_selectedCapacityRange.end.toStringAsFixed(1)} kW',
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                              _selectedCapacityRange = values;
                            });
                          },
                          activeColor: Colors.green,
                          inactiveColor: Colors.grey.shade600,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0.0 kW',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            Text(
                              '${_maxCapacity.toStringAsFixed(1)} kW',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_filterError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _filterError!,
                                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _clearFilters,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Clear All'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_results.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length > 5 ? 5 : _results.length,
                itemBuilder: (context, index) => Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        _results[index]['type'] == 'EV Station' ? Icons.ev_station : Icons.location_on,
                        color: Colors.green,
                      ),
                      title: Text(_results[index]['name'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        _results[index]['address'] ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                      ),
                      onTap: () => _selectResult(_results[index]),
                    ),
                    if (index < (_results.length > 5 ? 5 : _results.length) - 1)
                      Divider(color: Colors.white.withOpacity(0.1)),
                  ],
                ),
              ),
            ),

          if (_error != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white))),
                ],
              ),
            ),

          if (_isSearching)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)),
                  SizedBox(width: 10),
                  Text('Searching...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

