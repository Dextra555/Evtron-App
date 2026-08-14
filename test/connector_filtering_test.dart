import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evtron/Model/ev_station_model.dart';

void main() {
  group('EVStation connector filtering', () {
    test('returns only connectors matching the charger type filter', () {
      final station = EVStation(
        id: 1,
        name: 'Test Station',
        fullAddress: 'Test Address',
        latitude: 12.0,
        longitude: 77.0,
        status: 'active',
        stationType: 'public',
        is247: true,
        estimatedChargingPrice: 0.0,
        totalChargers: 2,
        availableChargers: 2,
        connectorPorts: [
          ConnectorPort(
            chargerId: 'a1',
            connectorId: 1,
            type: 'Type 2',
            status: 'available',
            chargerType: 'AC',
            connectorUid: 'uid-ac',
          ),
          ConnectorPort(
            chargerId: 'd1',
            connectorId: 2,
            type: 'CCS',
            status: 'available',
            chargerType: 'DC',
            connectorUid: 'uid-dc',
          ),
        ],
        realTimeAvailability: true,
        createdAt: DateTime.now(),
      );

      final filtered = station.getFilteredConnectorPorts({'chargerType': 'DC'});

      expect(filtered.length, 1);
      expect(filtered.single.chargerType.toLowerCase(), 'dc');
    });

    test('returns an empty list when no connectors match the selected filters', () {
      final station = EVStation(
        id: 1,
        name: 'Test Station',
        fullAddress: 'Test Address',
        latitude: 12.0,
        longitude: 77.0,
        status: 'active',
        stationType: 'public',
        is247: true,
        estimatedChargingPrice: 0.0,
        totalChargers: 2,
        availableChargers: 1,
        connectorPorts: [
          ConnectorPort(
            chargerId: 'a1',
            connectorId: 1,
            type: 'Type 2',
            status: 'available',
            chargerType: 'AC',
            connectorUid: 'uid-ac',
          ),
        ],
        realTimeAvailability: true,
        createdAt: DateTime.now(),
      );

      final filtered = station.getFilteredConnectorPorts({'chargerType': 'DC'});

      expect(filtered, isEmpty);
    });

    test('includes decimal charger power values within a floating-point range', () {
      final station = EVStation(
        id: 1,
        name: 'Test Station',
        fullAddress: 'Test Address',
        latitude: 12.0,
        longitude: 77.0,
        status: 'active',
        stationType: 'public',
        is247: true,
        estimatedChargingPrice: 0.0,
        totalChargers: 2,
        availableChargers: 2,
        connectorPorts: [
          ConnectorPort(
            chargerId: 'a1',
            connectorId: 1,
            type: 'Type 2',
            status: 'available',
            chargerType: 'AC',
            connectorUid: 'uid-ac',
            kw: 7.4,
          ),
          ConnectorPort(
            chargerId: 'd1',
            connectorId: 2,
            type: 'CCS',
            status: 'available',
            chargerType: 'DC',
            connectorUid: 'uid-dc',
            kw: 22.5,
          ),
        ],
        realTimeAvailability: true,
        createdAt: DateTime.now(),
      );

      final filtered = station.getFilteredConnectorPorts({'powerRange': const RangeValues(0.0, 10.0)});

      expect(filtered, hasLength(1));
      expect(filtered.single.kw, 7.4);
    });

    test('matches a station by its effective power for decimal ranges', () {
      final station = EVStation(
        id: 1,
        name: 'Test Station',
        fullAddress: 'Test Address',
        latitude: 12.0,
        longitude: 77.0,
        status: 'active',
        stationType: 'public',
        is247: true,
        estimatedChargingPrice: 0.0,
        totalChargers: 1,
        availableChargers: 1,
        connectorPorts: [
          ConnectorPort(
            chargerId: 'a1',
            connectorId: 1,
            type: 'Type 2',
            status: 'available',
            chargerType: 'AC',
            connectorUid: 'uid-ac',
            kw: 7.4,
          ),
        ],
        realTimeAvailability: true,
        createdAt: DateTime.now(),
      );

      expect(station.matchesPowerRange(const RangeValues(0.0, 8.0)), isTrue);
      expect(station.matchesPowerRange(const RangeValues(8.0, 20.0)), isFalse);
    });
  });
}
