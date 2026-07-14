import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/invoice_model.dart';
import 'AuthService.dart';

class InvoiceService {
  static const String baseUrl = 'https://evtron-dev.dextragroups.com';

  static bool shouldRetryInvoiceRequest(String errorMessage) {
    final normalized = errorMessage.toLowerCase();
    return normalized.contains('completed sessions') ||
        normalized.contains('not completed yet') ||
        normalized.contains('session is not ready') ||
        normalized.contains('not ready yet');
  }

  Future<InvoiceResponse> getInvoice(int sessionId) async {
    try {
      // Fix: Use getUserToken() instead of getToken()
      final token = await AuthService.getUserToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      print('🔍 Fetching invoice for session ID: $sessionId');
      print('🔍 Token: ${token.substring(0, token.length > 30 ? 30 : token.length)}...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/mobile/invoices/session/$sessionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Invoice API Response Status: ${response.statusCode}');
      print('📦 Invoice API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Invoice data fetched successfully');
        print('🧾 Parsed Invoice Response: $jsonData');
        return InvoiceResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 404) {
        throw Exception('Invoice not found for session ID: $sessionId');
      } else {
        throw Exception('Failed to load invoice: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching invoice: $e');
      throw Exception('Error fetching invoice: $e');
    }
  }
}


