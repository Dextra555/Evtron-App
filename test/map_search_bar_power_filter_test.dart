import 'package:evtron/Model/ev_station_model.dart';
import 'package:evtron/View/Home/map_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  testWidgets('power range slider uses fine decimal steps', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapSearchBar(
            currentPosition: const LatLng(12.0, 77.0),
            evStations: const <EVStation>[],
            onStationSelected: (_) {},
            onLocationSelected: (_, __) {},
            onFilterStateChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.pump();

    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    expect(slider.divisions, 3500);
  });
}
