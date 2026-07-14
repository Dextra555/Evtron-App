import 'package:flutter/material.dart';
import '../Model/invoice_model.dart';
import '../Service/invoice_service.dart';

class InvoiceController extends ChangeNotifier {
  final InvoiceService _invoiceService = InvoiceService();

  InvoiceResponse? _invoiceResponse;
  bool _isLoading = false;
  String? _errorMessage;

  InvoiceResponse? get invoiceResponse => _invoiceResponse;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<bool> fetchInvoice(int sessionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _invoiceService.getInvoice(sessionId);
      _invoiceResponse = response;
      _isLoading = false;
      notifyListeners();
      return response.success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearData() {
    _invoiceResponse = null;
    _errorMessage = null;
    notifyListeners();
  }

  void dispose() {
    clearData();
    super.dispose();
  }
}