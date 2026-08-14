import 'package:flutter_test/flutter_test.dart';
import 'package:evtron/Model/start_charging_model.dart';

void main() {
  group('not_preparing error configuration', () {
    test('uses the exact user-facing message and title', () {
      final response = ChargingSessionResponse(
        success: false,
        message: 'Connector is not preparing',
        failedCheck: 'not_preparing',
        errorCode: 'CONNECTOR_NOT_PREPARING',
      );

      expect(response.getErrorTitle(), 'Connector Not Ready');
      expect(
        response.getUserFriendlyMessage(),
        'Connector is not in preparing state. Please connect the charging gun first.',
      );
    });

    test('button label is Try Again for the not_preparing case', () {
      final actions = ChargingSessionResponse(
        success: false,
        message: 'Connector is not preparing',
        failedCheck: 'not_preparing',
        errorCode: 'CONNECTOR_NOT_PREPARING',
      ).getErrorActions();

      expect(actions.first.label, 'Try Again');
      expect(actions.first.action, 'retry');
    });
  });
}
