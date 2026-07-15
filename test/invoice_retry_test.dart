// import 'package:evtron/Model/invoice_model.dart';
// import 'package:evtron/Service/invoice_service.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// void main() {
//   group('InvoiceService retry handling', () {
//     test('retries when the backend reports the session is not ready yet', () {
//       expect(
//         InvoiceService.shouldRetryInvoiceRequest(
//           'Invoice can only be generated for completed sessions.',
//         ),
//         isTrue,
//       );
//     });
//
//     test('does not retry for auth or missing-invoice errors', () {
//       expect(
//         InvoiceService.shouldRetryInvoiceRequest('Unauthorized: Invalid or expired token'),
//         isFalse,
//       );
//       expect(
//         InvoiceService.shouldRetryInvoiceRequest('Invoice not found for session ID: 282'),
//         isFalse,
//       );
//     });
//
//     test('supports invoice fields used by the PDF service', () {
//       final invoice = InvoiceData.fromJson({
//         'invoice_number': 'INV-1001',
//         'invoice_date': '2026-07-11',
//         'status': 'paid',
//         'user': {
//           'name': 'John Doe',
//           'email': 'john@example.com',
//           'phone': '9876543210',
//           'business_name': 'Acme Pvt Ltd',
//           'address': '1 Main Street',
//           'gstin': '33AAAAA0000A1Z5',
//         },
//         // 'company': {
//         //   'name': 'Evtron Electric Private Limited',
//         //   'address': 'Kugalur, 22/7 Vaikal Puthur Street',
//         //   'city': 'Erode',
//         //   'state': 'Tamil Nadu',
//         //   'pincode': '638313',
//         //   'footer': 'Thank You For Your Business',
//         //   'jurisdiction': 'Exclusive jurisdiction in Erode Courts',
//         // },
//         'station': {
//           'name': 'Charge Station',
//           'address': '2nd Cross',
//           'gstin': '33BBBBB1111B2Z6',
//         },
//         'charger': 'DC Fast',
//         'connector': 'CCS2',
//         'session': {
//           'id': 12,
//           'start_time': '2026-07-11T09:00:00Z',
//           'end_time': '2026-07-11T10:30:00Z',
//           'duration_minutes': 90,
//         },
//         'energy': {
//           'consumed_kwh': 15.5,
//           'rate_per_kwh': 7.2,
//         },
//         'billing': {
//           'subtotal': 111.6,
//           'tax_percentage': 18,
//           'tax': 20.1,
//           'total': 131.7,
//           'currency': 'INR',
//         },
//         'gst': {
//           'gstin': '33AAAAA0000A1Z5',
//           'hsn_sac': 'B2',
//           'cgst_rate': 9,
//           'sgst_rate': 9,
//           'igst_rate': 0,
//           'cgst_amount': 10.05,
//           'sgst_amount': 10.05,
//           'igst_amount': 0,
//           'total_gst': 20.1,
//         },
//         'payment': {
//           'method': 'razorpay',
//           'receipt_number': 'RCPT-001',
//           'wallet_debits': 0,
//         },
//         'cost_breakdown': {
//           'energy_cost': 111.6,
//           'idle_cost': 0,
//           'service_fee': 5,
//           'parking_fee': 0,
//           'subtotal': 116.6,
//           'tax': 20.1,
//           'total': 136.7,
//         },
//       });
//
//       expect(invoice.user.name, 'John Doe');
//       expect(invoice.user.businessName, 'Acme Pvt Ltd');
//       expect(invoice.user.gstin, '33AAAAA0000A1Z5');
//       expect(invoice.company?.name, 'Evtron Electric Private Limited');
//       expect(invoice.company?.footer, 'Thank You For Your Business');
//       expect(invoice.tid, isNull);
//     });
//   });
// }
