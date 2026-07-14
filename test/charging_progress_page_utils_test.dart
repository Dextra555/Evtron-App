import 'package:flutter_test/flutter_test.dart';
import 'package:evtron/View/Scanner/charging_progress_page_utils.dart';

void main() {
  group('charging progress helpers', () {
    test('shows DC progress section only for DC chargers', () {
      expect(shouldShowBatteryProgressSection('DC'), isTrue);
      expect(shouldShowBatteryProgressSection('dc'), isTrue);
      expect(shouldShowBatteryProgressSection('AC'), isFalse);
      expect(shouldShowBatteryProgressSection(''), isFalse);
    });

    test('formats empty values as N/A', () {
      expect(formatDisplayValue(''), 'N/A');
      expect(formatDisplayValue('   '), 'N/A');
      expect(formatDisplayValue('Ac Charger 2'), 'Ac Charger 2');
    });
  });
}
