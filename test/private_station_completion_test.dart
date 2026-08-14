import 'package:evtron/Model/live_charging_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveChargingData station parsing', () {
    test('stores station_type from the API for private stations', () {
      final station = StationInfo.fromJson({
        'id': 12,
        'name': 'Siva Private Station',
        'city': 'Chennai',
        'station_type': 'private',
      });

      expect(station.stationType, 'private');
    });
  });
}
