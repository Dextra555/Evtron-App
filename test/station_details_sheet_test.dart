import 'package:evtron/Model/ev_station_model.dart';
import 'package:evtron/View/Home/station_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows charger id with connector type and status', (tester) async {
    final station = EVStation(
      id: 1,
      name: 'Test Station',
      fullAddress: 'Test Address',
      latitude: 12.0,
      longitude: 77.0,
      status: 'active',
      stationType: 'public',
      is247: true,
      estimatedChargingPrice: 10.0,
      totalChargers: 1,
      availableChargers: 1,
      connectorPorts: [
        ConnectorPort(
          chargerId: 'CH-101',
          connectorId: 1,
          type: 'CCS',
          status: 'available',
          maxPower: 50,
        ),
      ],
      amenities: const [],
      realTimeAvailability: true,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StationDetailsSheet(
            station: station,
            distance: 1.2,
            isFavorite: false,
            onFavoriteToggle: () {},
            onNavigate: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('CH-101'), findsOneWidget);
    expect(find.textContaining('CCS'), findsOneWidget);
    expect(find.textContaining('Charger ID: CH-101'), findsOneWidget);
  });
}
