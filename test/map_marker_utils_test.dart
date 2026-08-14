import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:evtron/View/Home/map_marker_utils.dart';

void main() {
  group('map marker helpers', () {
    test('offsets duplicate positions so markers remain visible', () {
      final base = const LatLng(12.34, 56.78);

      final first = buildMarkerPosition(base, 0);
      final second = buildMarkerPosition(base, 1);

      expect(first.latitude, base.latitude);
      expect(first.longitude, base.longitude);
      expect(second.latitude, greaterThan(base.latitude));
      expect(second.longitude, greaterThan(base.longitude));
    });

    test('creates stable marker ids for each station', () {
      expect(buildMarkerId(101, 0), 'station_101');
      expect(buildMarkerId(101, 1), 'station_101_1');
    });
  });
}
