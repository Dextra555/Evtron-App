import 'package:flutter_test/flutter_test.dart';
import 'package:evtron/Service/live_charging_service.dart';

void main() {
  group('LiveChargingService status classification', () {
    final service = LiveChargingService();

    test('returns charging state for charging status', () {
      expect(service.classifyChargingStatus('charging'), LiveChargingStatusState.charging);
    });

    test('returns interrupted state for interrupted status', () {
      expect(service.classifyChargingStatus('interrupted'), LiveChargingStatusState.interrupted);
    });

    test('returns completed state for completed status', () {
      expect(service.classifyChargingStatus('completed'), LiveChargingStatusState.completed);
    });

    test('treats timeout as a transient failure that should be retried', () {
      expect(service.shouldRetryAfterFailure('Request timeout'), isTrue);
    });
  });
}
