import 'package:flutter/material.dart';

import '../Model/payment_history_model.dart';
import '../Service/payment_history_service.dart';

class PaymentHistoryController
    extends ChangeNotifier {

  final PaymentHistoryService _service =
  PaymentHistoryService();

  bool isLoading = false;

  List<PaymentHistoryModel>
  paymentHistory = [];

  Future<void> fetchPaymentHistory() async {

    isLoading = true;

    notifyListeners();

    paymentHistory =
    await _service.getPaymentHistory();

    isLoading = false;

    notifyListeners();
  }
}