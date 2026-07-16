// import 'package:flutter_test/flutter_test.dart';
// import 'package:evtron/Model/invoice_model.dart';
//
// void main() {
//   group('InvoiceData parsing', () {
//     test('reads transaction id from nested session payload', () {
//       final invoice = InvoiceData.fromJson({
//         'invoice_id': 229,
//         'invoice_number': 'INV-20260713-00022',
//         'invoice_date': '13-07-2026',
//         'status': 'generated',
//         'user': {'name': 'wahid', 'email': 'wahid@gmail.com', 'phone': '+919710478680'},
//         'station': {'name': 'Evtron Station', 'address': 'Test address', 'gstin': '22AAAAA0000A1Z5'},
//         'charger': 'Ac Charger 2',
//         'connector': 'Gun 1',
//         'session': {
//           'id': 576,
//           'transaction_id': '1400888515',
//           'start_time': '2026-07-13T17:41:05+05:30',
//           'end_time': '2026-07-13T18:07:05+05:30',
//           'duration_minutes': 26,
//         },
//         'energy': {'consumed_kwh': 0, 'rate_per_kwh': 12},
//         'billing': {'subtotal': 0, 'tax_percentage': 18, 'tax': 0, 'total': 0, 'currency': 'INR'},
//         'gst': {
//           'gstin': '22AAAAA0000A1Z5',
//           'hsn_sac': '9986',
//           'cgst_rate': 9,
//           'sgst_rate': 9,
//           'igst_rate': 0,
//           'cgst_amount': 0,
//           'sgst_amount': 0,
//           'igst_amount': 0,
//           'total_gst': 0,
//         },
//         'payment': {'method': 'wallet', 'receipt_number': null, 'wallet_debits': 0},
//         'cost_breakdown': {
//           'energy_cost': 0,
//           'idle_cost': 0,
//           'service_fee': 0,
//           'parking_fee': 0,
//           'subtotal': 0,
//           'gstin': '22AAAAA0000A1Z5',
//           'hsn_sac': '9986',
//           'cgst_rate': 9,
//           'sgst_rate': 9,
//           'cgst_amount': 0,
//           'sgst_amount': 0,
//           'igst_rate': 0,
//           'igst_amount': 0,
//           'tax': 0,
//           'total': 0,
//         },
//       });
//
//       expect(invoice.tid, '1400888515');
//     });
//   });
// }
