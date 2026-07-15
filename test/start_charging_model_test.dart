// import 'package:flutter_test/flutter_test.dart';
// import 'package:evtron/Model/start_charging_model.dart';
// import 'package:evtron/Service/start_charging_service.dart';
//
// void main() {
//   group('ChargingSessionData.fromJson', () {
//     test('uses session_id when provided', () {
//       final data = ChargingSessionData.fromJson({
//         'session_id': 123,
//       });
//
//       expect(data.sessionId, 123);
//     });
//
//     test('falls back to sessionId when backend returns camelCase field', () {
//       final data = ChargingSessionData.fromJson({
//         'sessionId': 456,
//       });
//
//       expect(data.sessionId, 456);
//     });
//
//     test('falls back to id when backend returns a plain id field', () {
//       final data = ChargingSessionData.fromJson({
//         'id': 789,
//       });
//
//       expect(data.sessionId, 789);
//     });
//   });
//
//   group('ChargingService.extractSessionIdFromResponse', () {
//     test('extracts session_id from the root payload', () {
//       expect(
//         ChargingService.extractSessionIdFromResponse({'session_id': 123}),
//         123,
//       );
//     });
//
//     test('resolves a fallback session id when backend omits one', () {
//       final response = ChargingSessionResponse(
//         success: true,
//         message: 'Charging started',
//         data: ChargingSessionData(
//           sessionId: 0,
//           transactionId: '',
//           ocppSent: false,
//           startedAt: DateTime.now().toIso8601String(),
//           charger: ChargerInfo(id: '', name: '', type: '', powerCapacity: 0, model: '', manufacturer: ''),
//           connector: ConnectorInfo(id: 0, uid: '', name: '', type: '', currentType: '', maxPower: 0),
//           station: StationInfo(id: 0, name: '', address: '', latitude: '', longitude: ''),
//           pricing: PricingInfo(type: '', rate: 0, unit: '', currency: ''),
//           wallet: WalletInfo(balanceBefore: 0, currency: ''),
//         ),
//       );
//
//       expect(
//         ChargingService.resolveSessionId(response: response, fallbackSessionId: 456),
//         456,
//       );
//     });
//
//     test('extracts sessionId from nested data payload', () {
//       expect(
//         ChargingService.extractSessionIdFromResponse({
//           'data': {'sessionId': 456},
//         }),
//         456,
//       );
//     });
//
//     test('extracts id from nested response object', () {
//       expect(
//         ChargingService.extractSessionIdFromResponse({
//           'result': {'id': 789},
//         }),
//         789,
//       );
//     });
//   });
// }
