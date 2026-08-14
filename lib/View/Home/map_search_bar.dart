import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:evtron/Service/network_service.dart';
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
  final Function(List<EVStation>, Map<String, dynamic>)? onFilterApplied;
  final int resetSignal;

  const MapSearchBar({
    super.key,
    required this.currentPosition,
    required this.evStations,
    required this.onStationSelected,
    required this.onLocationSelected,
    required this.onFilterStateChanged,
    this.onFilterApplied,
    this.resetSignal = 0,
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

  // ✅ Make these non-final so they can be updated
  List<String> _chargerTypes = [];
  List<String> _connectorTypes = [];
  List<String> _statuses = ['Available', 'In-Use', 'Fault', 'Unavailable'];
  List<String> _accessibilities = ['Public', 'Private', 'Guest'];
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
  void didUpdateWidget(covariant MapSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetSignal != widget.resetSignal && widget.resetSignal != 0) {
      _resetFilterState(notifyParent: false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ✅ Get unique statuses from stations
  List<String> _getUniqueStatusesFromStations() {
    Set<String> statuses = {};
    for (var station in widget.evStations) {
      final status = _getStatus(station);
      if (status != null && status.isNotEmpty) {
        statuses.add(status);
      }
    }

    // ✅ Always include all possible statuses
    final allStatuses = {'Available', 'In-Use', 'Fault', 'Unavailable'};
    statuses.addAll(allStatuses);

    return statuses.toList()..sort();
  }

  // ✅ Get unique accessibility from stations
  List<String> _getUniqueAccessibilityFromStations() {
    Set<String> accessibilities = {};
    for (var station in widget.evStations) {
      final accessibility = _getAccessibility(station);
      if (accessibility != null && accessibility.isNotEmpty) {
        accessibilities.add(accessibility);
      }
    }
    return accessibilities.toList()..sort();
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
        // Get charger types from API
        final chargerTypeNames = data.data.chargerTypes.map((e) => e.name).toList();

        // Get connector types from API and normalize
        final connectorTypeNames = data.data.connectorTypes
            .map((e) => e.name.replaceAll('_', ' '))
            .toList();

        // ✅ Get actual statuses from stations (dynamic)
        final statusesFromStations = _getUniqueStatusesFromStations();

        // ✅ Get actual accessibility from stations (dynamic)
        final accessibilityFromStations = _getUniqueAccessibilityFromStations();

        print('✅ API Response - Charger Types: ${chargerTypeNames.join(', ')}');
        print('✅ API Response - Connector Types: ${connectorTypeNames.join(', ')}');
        print('✅ Derived from Stations - Statuses: ${statusesFromStations.join(', ')}');
        print('✅ Derived from Stations - Accessibility: ${accessibilityFromStations.join(', ')}');

        setState(() {
          _filterMasterData = data;
          _chargerTypes = chargerTypeNames;
          _connectorTypes = connectorTypeNames;
          _statuses = statusesFromStations.isNotEmpty
              ? statusesFromStations
              : ['Available', 'In-Use', 'Fault', 'Unavailable'];
          _accessibilities = accessibilityFromStations.isNotEmpty
              ? accessibilityFromStations
              : ['Public', 'Private', 'Community'];
          _isLoadingFilters = false;
        });

        print('✅ Filter data loaded successfully:');
        print('   Charger types: $_chargerTypes');
        print('   Connector types: $_connectorTypes');
        print('   Statuses: $_statuses');
        print('   Accessibilities: $_accessibilities');
        print('========================================\n');
      }
    } catch (e) {
      print('❌ Error loading filter master data: $e');
      if (mounted) {
        // ✅ Fallback: Derive from stations
        final statusesFromStations = _getUniqueStatusesFromStations();
        final accessibilityFromStations = _getUniqueAccessibilityFromStations();

        setState(() {
          _isLoadingFilters = false;
          _chargerTypes = ['AC', 'DC', 'Both'];
          _connectorTypes = ['Type 1', 'Type 2', 'CCS', 'CHAdeMO', 'GB/T', 'Tesla'];
          _statuses = statusesFromStations.isNotEmpty
              ? statusesFromStations
              : ['Available', 'In-Use', 'Fault', 'Unavailable'];
          _accessibilities = accessibilityFromStations.isNotEmpty
              ? accessibilityFromStations
              : ['Public', 'Private', 'Community'];
          _filterError = 'Failed to load filter options. Using defaults.';
        });
        print('⚠️ Using fallback values:');
        print('   Charger types: $_chargerTypes');
        print('   Connector types: $_connectorTypes');
        print('   Statuses: $_statuses');
        print('   Accessibilities: $_accessibilities');
        print('========================================\n');
      }
    }
  }

  String? _getChargerType(EVStation station) {
    try {
      if (station.connectorPorts.isEmpty) {
        return 'AC';
      }

      Set<String> types = {};
      for (var port in station.connectorPorts) {
        final chargerType = (port.chargerType ?? '').trim().toLowerCase();
        final connectorType = (port.type ?? '').trim().toLowerCase();
        final power = port.kw ?? port.maxPower ?? 0.0;

        if (chargerType.contains('dc')) {
          types.add('DC');
        } else if (chargerType.contains('ac')) {
          types.add('AC');
        } else if (connectorType.contains('ccs') ||
            connectorType.contains('chademo') ||
            connectorType.contains('gb/t') ||
            connectorType.contains('tesla')) {
          if (power > 50) {
            types.add('DC');
          } else {
            types.add('AC');
          }
        } else if (connectorType.contains('type 2') || connectorType.contains('type2')) {
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

      bool hasHighPower = station.connectorPorts.any((port) =>
      (port.kw ?? 0) > 50 || (port.maxPower ?? 0) > 50
      );

      return hasHighPower ? 'DC' : 'AC';
    } catch (e) {
      print('⚠️ Error getting charger type: $e');
      return 'AC';
    }
  }

  String? _getConnectorType(EVStation station) {
    try {
      if (station.connectorPorts.isEmpty) {
        return null;
      }

      // Get the most common connector type
      Map<String, int> typeCount = {};
      for (var port in station.connectorPorts) {
        // Normalize the type: replace underscores with spaces
        String normalizedType = port.type
            .replaceAll('_', ' ')
            .trim();

        // Handle common variations
        normalizedType = _normalizeConnectorType(normalizedType);

        typeCount[normalizedType] = (typeCount[normalizedType] ?? 0) + 1;
      }

      String? mostCommonType;
      int maxCount = 0;
      typeCount.forEach((type, count) {
        if (count > maxCount) {
          maxCount = count;
          mostCommonType = type;
        }
      });

      return mostCommonType;
    } catch (e) {
      print('⚠️ Error getting connector type: $e');
      return null;
    }
  }

  String _normalizeConnectorType(String type) {
    final lower = type.toLowerCase();
    if (lower == 'type2' || lower == 'type 2' || lower == 'type_2') {
      return 'Type 2';
    } else if (lower == 'type1' || lower == 'type 1' || lower == 'type_1') {
      return 'Type 1';
    } else if (lower == 'ccs2' || lower == 'ccs' || lower == 'ccs_2') {
      return 'CCS';
    } else if (lower == 'ccs1' || lower == 'ccs_1') {
      return 'CCS1';
    } else if (lower == 'chademo') {
      return 'CHAdeMO';
    } else if (lower == 'gbt' || lower == 'gb/t' || lower == 'gb_t') {
      return 'GB/T';
    } else if (lower == 'tesla' || lower == 'nacs') {
      return 'Tesla';
    }
    return type;
  }

  String? _getStatus(EVStation station) {
    try {
      if (station.connectorPorts.isEmpty) {
        return 'Unavailable';
      }

      // Track all statuses found
      Set<String> foundStatuses = {};

      for (var port in station.connectorPorts) {
        final status = port.status.toLowerCase().trim();
        foundStatuses.add(status);

        // Check for different statuses in priority order
        if (status == 'busy' ||
            status == 'charging' ||
            status == 'active' ||
            status == 'in-use' ||
            status == 'occupied' ||
            status == 'in_use') {
          return 'In-Use';
        }
      }

      // If no in-use, check for available
      for (var port in station.connectorPorts) {
        final status = port.status.toLowerCase().trim();
        if (status == 'available' || status == 'idle') {
          return 'Available';
        }
      }

      // Check for fault/error
      for (var port in station.connectorPorts) {
        final status = port.status.toLowerCase().trim();
        if (status == 'fault' || status == 'error' || status == 'failed') {
          return 'Fault';
        }
      }

      // Check for offline/unavailable
      for (var port in station.connectorPorts) {
        final status = port.status.toLowerCase().trim();
        if (status == 'offline' ||
            status == 'unavailable' ||
            status == 'disconnected' ||
            status == 'maintenance') {
          return 'Unavailable';
        }
      }

      // If all connectors have the same status, use that with proper capitalization
      if (foundStatuses.length == 1) {
        final singleStatus = foundStatuses.first;
        // Map to standardized status names
        if (singleStatus == 'offline' ||
            singleStatus == 'unavailable' ||
            singleStatus == 'disconnected') {
          return 'Unavailable';
        }

        // Return with proper capitalization
        return singleStatus.substring(0, 1).toUpperCase() + singleStatus.substring(1);
      }

      // Default: Check if any port is unavailable
      bool hasAvailable = false;
      bool hasUnavailable = false;

      for (var port in station.connectorPorts) {
        final status = port.status.toLowerCase().trim();
        if (status == 'available' || status == 'idle') {
          hasAvailable = true;
        }
        if (status == 'offline' || status == 'unavailable' || status == 'disconnected') {
          hasUnavailable = true;
        }
      }

      if (hasUnavailable && !hasAvailable) {
        return 'Unavailable';
      }

      return 'Available';
    } catch (e) {
      print('⚠️ Error getting status: $e');
      return 'Available';
    }
  }

  String? _getAccessibility(EVStation station) {
    try {
      // Get the station type
      String type = station.stationType;

      if (type.isEmpty) {
        return 'Public'; // Default
      }

      // Handle various formats and return consistent value
      String normalized = type.replaceAll('_', ' ').toLowerCase().trim();

      // Map to consistent values
      if (normalized.contains('public')) {
        return 'Public';
      } else if (normalized.contains('private')) {
        return 'Private';
      } else if (normalized.contains('guest') || normalized.contains('community')) {
        return 'Guest';
      } else {
        // Return with first letter capitalized
        return type.split(' ')
            .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
      }
    } catch (e) {
      print('⚠️ Error getting accessibility: $e');
      return 'Public';
    }
  }

  double? _getChargerCapacity(EVStation station) {
    try {
      if (station.connectorPorts.isNotEmpty) {
        double maxKW = 0;
        for (var port in station.connectorPorts) {
          if (port.kw != null && port.kw! > maxKW) {
            maxKW = port.kw!;
          }
          if (port.maxPower != null && port.maxPower! > maxKW) {
            maxKW = port.maxPower!;
          }
        }
        if (maxKW > 0) {
          return maxKW;
        }
      }
    } catch (e) {
      print('⚠️ Error getting charger capacity: $e');
    }
    return station.totalChargers > 50 ? 150.0 : station.totalChargers > 20 ? 100.0 : 50.0;
  }

  List<EVStation> _getFilteredStations() {
    List<EVStation> filtered = [];

    print('\n🔍 ========== FILTERING STATIONS ==========');
    print('📊 Filter criteria:');
    print('   Charger Type: ${_selectedChargerType ?? "All"}');
    print('   Connector Type: ${_selectedConnectorType ?? "All"}');
    print('   Status: ${_selectedStatus ?? "All"}');
    print('   Accessibility: ${_selectedAccessibility ?? "All"}');
    print('   Selected min/max power: ${_selectedCapacityRange.start} - ${_selectedCapacityRange.end} kW');
    print('   Total stations before filtering: ${widget.evStations.length}');

    for (var station in widget.evStations) {
      final chargerType = _getChargerType(station);
      final connectorType = _getConnectorType(station);
      final status = _getStatus(station);
      final accessibility = _getAccessibility(station);
      final chargerCapacity = _getChargerCapacity(station);

      print('\n📌 Checking: ${station.name}');
      print('   Charger Type: $chargerType');
      print('   Connector Type: $connectorType');
      print('   Status: $status');
      print('   Accessibility: $accessibility');
      print('   Station power summary: ${chargerCapacity?.toStringAsFixed(1)} kW');
      for (final port in station.connectorPorts) {
        final powerValue = port.kw ?? port.maxPower;
        final parsedPower = powerValue is num
            ? (powerValue as num).toDouble()
            : double.tryParse(powerValue?.toString() ?? '');
        print('   Connector ${port.connectorId}: raw=${powerValue ?? 'null'} parsed=${parsedPower?.toStringAsFixed(2) ?? 'null'}');
      }

      bool passedAllFilters = true;

      final connectorFilters = {
        'chargerType': _selectedChargerType,
        'connectorType': _selectedConnectorType,
        'status': _selectedStatus,
        'powerRange': _selectedCapacityRange,
      };

      final matchingConnectors = station.getFilteredConnectorPorts(connectorFilters);
      final hasConnectorCriteria = (_selectedChargerType != null && _selectedChargerType!.isNotEmpty) ||
          (_selectedConnectorType != null && _selectedConnectorType!.isNotEmpty) ||
          (_selectedStatus != null && _selectedStatus!.isNotEmpty) ||
          (_selectedCapacityRange.start > 0.0 || _selectedCapacityRange.end < _maxCapacity);

      if (hasConnectorCriteria && matchingConnectors.isEmpty) {
        print('   ❌ Skipped - No connectors match the selected connector filters');
        passedAllFilters = false;
      }

      if (passedAllFilters && _selectedStatus != null && _selectedStatus!.isNotEmpty) {
        String normalizedSelected = _selectedStatus!.toLowerCase().trim();
        String normalizedStation = (status ?? '').toLowerCase().trim();

        if (normalizedStation != normalizedSelected) {
          print('   ❌ Skipped - Status mismatch: $status != ${_selectedStatus}');
          passedAllFilters = false;
        }
      }

      if (passedAllFilters && _selectedAccessibility != null && _selectedAccessibility!.isNotEmpty) {
        String normalizedSelected = _selectedAccessibility!.toLowerCase().trim();
        String normalizedStation = (accessibility ?? '').toLowerCase().trim();

        if (normalizedStation != normalizedSelected) {
          print('   ❌ Skipped - Accessibility mismatch: $accessibility != ${_selectedAccessibility}');
          passedAllFilters = false;
        }
      }

      if (passedAllFilters) {
        bool isDefaultRange =
            _selectedCapacityRange.start == 0.0 &&
                _selectedCapacityRange.end == _maxCapacity;

        if (!isDefaultRange) {
          final stationPower = station.connectorPorts.isEmpty
              ? 0.0
              : station.connectorPorts
                  .map((port) => port.kw ?? port.maxPower ?? 0.0)
                  .fold<double>(0.0, (maxValue, current) => current > maxValue ? current : maxValue);

          if (!station.matchesPowerRange(_selectedCapacityRange)) {
            print('   ❌ Skipped - Power out of range');
            passedAllFilters = false;
          }
        }
      }

      if (passedAllFilters) {
        print('   ✅ PASSED ALL FILTERS');
        filtered.add(station);
      }
    }

    print('\n✅ Filtered ${filtered.length} stations from ${widget.evStations.length} total');
    print('========================================\n');
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

  Map<String, dynamic> _getCurrentFilterState() {
    return {
      'chargerType': _selectedChargerType,
      'connectorType': _selectedConnectorType,
      'status': _selectedStatus,
      'accessibility': _selectedAccessibility,
      'powerRange': RangeValues(
        _selectedCapacityRange.start,
        _selectedCapacityRange.end,
      ),
    };
  }

  void _applyFilters() {
    setState(() {
      print('\n🔍 ========== APPLYING FILTERS ==========');
      print('   Charger Type: ${_selectedChargerType ?? "All"}');
      print('   Connector Type: ${_selectedConnectorType ?? "All"}');
      print('   Status: ${_selectedStatus ?? "All"}');
      print('   Accessibility: ${_selectedAccessibility ?? "All"}');
      print('   Power Range: ${_selectedCapacityRange.start} - ${_selectedCapacityRange.end} kW');

      _isFilterApplied =
          (_selectedChargerType != null && _selectedChargerType!.isNotEmpty) ||
              (_selectedConnectorType != null && _selectedConnectorType!.isNotEmpty) ||
              (_selectedStatus != null && _selectedStatus!.isNotEmpty) ||
              (_selectedAccessibility != null && _selectedAccessibility!.isNotEmpty) ||
              _selectedCapacityRange.start > 0.0 ||
              _selectedCapacityRange.end < _maxCapacity;

      final filteredStations = _getFilteredStations();

      print('📊 Applied filters - Found ${filteredStations.length} stations out of ${widget.evStations.length}');

      // Log sample station values for debugging
      if (filteredStations.isNotEmpty) {
        print('📌 Sample filtered station: ${filteredStations.first.name}');
        print('   Accessibility: ${_getAccessibility(filteredStations.first)}');
        print('   Status: ${_getStatus(filteredStations.first)}');
        print('   Charger Type: ${_getChargerType(filteredStations.first)}');
      } else {
        print('⚠️ No stations match the filters!');

        // ✅ SHOW SNACKBAR WHEN NO RESULTS FOUND
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No stations match the selected filters'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Log first few stations' values for debugging
        for (var i = 0; i < widget.evStations.length && i < 3; i++) {
          final station = widget.evStations[i];
          print('   Station ${i+1}: ${station.name}');
          print('      Accessibility: ${_getAccessibility(station)}');
          print('      Status: ${_getStatus(station)}');
          print('      Charger Type: ${_getChargerType(station)}');
        }
      }
      print('==========================================\n');

      if (widget.onFilterApplied != null) {
        widget.onFilterApplied!(filteredStations, _getCurrentFilterState());
      }

      _searchLocation(_controller.text);
      _toggleFilter();
    });
  }

  void _resetFilterState({bool notifyParent = true}) {
    setState(() {
      _selectedChargerType = null;
      _selectedConnectorType = null;
      _selectedStatus = null;
      _selectedAccessibility = null;
      _selectedCapacityRange = const RangeValues(0.0, 350.0);
      _isFilterApplied = false;
    });

    if (notifyParent && widget.onFilterApplied != null) {
      widget.onFilterApplied!(widget.evStations, _getCurrentFilterState());
      print('📊 Cleared filters - Showing all ${widget.evStations.length} stations');
    }

    _searchLocation(_controller.text);
  }

  void _clearFilters() {
    _resetFilterState(notifyParent: true);
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

        if (!station.matchesPowerRange(_selectedCapacityRange)) continue;

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

      final response = await NetworkService.get(Uri.parse(url));
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

      final response = await NetworkService.get(Uri.parse(detailsUrl));
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
    // Sort and remove duplicates from items
    final uniqueItems = items.toSet().toList()..sort();

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
                uniqueItems.isEmpty ? 'No options' : 'Select $label',
                style: TextStyle(
                  color: uniqueItems.isEmpty
                      ? Colors.white.withOpacity(0.4)
                      : Colors.white.withOpacity(0.7),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All', style: TextStyle(color: Colors.white)),
                ),
                ...uniqueItems.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(color: Colors.white)),
                  );
                }),
              ],
              onChanged: uniqueItems.isEmpty ? null : onChanged,
              icon: Icon(
                Icons.arrow_drop_down,
                color: uniqueItems.isEmpty
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
                          'Charger Power: ${_selectedCapacityRange.start.toStringAsFixed(1)} - ${_selectedCapacityRange.end.toStringAsFixed(1)} kW',
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
                          divisions: (_maxCapacity * 10).round(),
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


