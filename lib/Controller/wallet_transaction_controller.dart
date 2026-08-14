// lib/Controller/wallet_transaction_controller.dart
import 'package:flutter/material.dart';
import 'package:evtron/Service/network_service.dart';
import '../Model/wallet_model.dart';
import '../Service/AuthService.dart';
import '../Service/wallet_service.dart';
import '../Model/wallet_transaction_model.dart';

class WalletTransactionController extends ChangeNotifier {
  final WalletService _service = WalletService();
  List<WalletTransactionModel> transactions = [];
  bool isLoading = false;
  String? errorMessage;
  double totalAmount = 0.0;

  Future<void> fetchTransactions({
    required String token,
    int limit = 20,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getWalletTransactions(
        token: token,
        limit: limit,
      );

      if (response != null && response.isNotEmpty) {
        transactions = response;
        // Calculate total amount (sum of all credits)
        totalAmount = transactions
            .where((t) => t.type == 'credit')
            .fold(0.0, (sum, t) => sum + t.amount);
        errorMessage = null;
      } else {
        transactions = [];
        errorMessage = "No transactions found";
      }
    } on NetworkException catch (e) {
      errorMessage = NetworkService.noInternetMessage;
      transactions = [];
      print('Wallet transaction network error: $e');
    } catch (e, stackTrace) {
      errorMessage = 'Failed to load transactions. Please try again.';
      transactions = [];
      print('Wallet transaction error: $e');
      print(stackTrace);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void setError(String error) {
    errorMessage = error;
    notifyListeners();
  }
}
