import 'package:flutter/material.dart';
import '../Model/wallet_model.dart';
import '../Model/wallet_recharge_model.dart';
import '../Model/wallet_receipt_model.dart';
import '../Model/razorpay_response_model.dart';
import '../Service/wallet_service.dart';

class WalletController extends ChangeNotifier {
  final WalletService _service = WalletService();

  WalletModel? wallet;
  bool isLoading = false;
  WalletRechargeModel? rechargeResponse;
  WalletReceiptModel? receiptResponse;

  RazorpayOrderResponse? razorpayOrderResponse;

  Future<void> fetchWallet(String token) async {
    isLoading = true;
    notifyListeners();

    wallet = await _service.getWalletDetails(token);

    if (wallet != null) {
      print('Wallet Balance: ${wallet!.walletBalance}');
      print('Credit Limit: ${wallet!.creditLimit}');
      print('Available Balance: ${wallet!.availableBalance}');
      print('Wallet Status: ${wallet!.walletStatus}');
      print('Last Recharged At: ${wallet!.lastRechargedAt}');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> rechargeWallet({
    required String token,
    required double amount,
  }) async {
    rechargeResponse = await _service.rechargeWallet(
      token: token,
      amount: amount,
    );

    return rechargeResponse != null;
  }

  // New method to fetch receipt
  Future<bool> fetchWalletReceipt({
    required String token,
    required int transactionId,
  }) async {
    receiptResponse = await _service.getWalletReceipt(
      token: token,
      transactionId: transactionId,
    );

    return receiptResponse != null;
  }

  // NEW: Create Razorpay Order with forceNew parameter
  Future<RazorpayOrderResponse?> createRazorpayOrder({
    required String token,
    required double amount,
    bool forceNew = false,
  }) async {
    try {
      razorpayOrderResponse = await _service.createRazorpayOrder(
        token: token,
        amount: amount,
        forceNew: forceNew,
      );
      return razorpayOrderResponse;
    } catch (e) {
      print('Error creating Razorpay order: $e');
      return null;
    }
  }

  // NEW: Verify Razorpay Payment
  Future<VerifyPaymentResponse?> verifyRazorpayPayment({
    required String token,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final response = await _service.verifyRazorpayPayment(
        token: token,
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      return response;
    } catch (e) {
      print('Error verifying payment: $e');
      return VerifyPaymentResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  // NEW: Verify order status
  Future<OrderStatusResponse?> verifyOrderStatus({
    required String token,
    required String orderId,
  }) async {
    try {
      return await _service.verifyOrderStatus(
        token: token,
        orderId: orderId,
      );
    } catch (e) {
      print('Error verifying order status: $e');
      return null;
    }
  }

  // NEW: Cancel order
  Future<CancelOrderResponse?> cancelOrder({
    required String token,
    required String orderId,
  }) async {
    try {
      return await _service.cancelOrder(
        token: token,
        orderId: orderId,
      );
    } catch (e) {
      print('Error cancelling order: $e');
      return null;
    }
  }

  // Helper method to get current wallet balance as double
  Future<double?> getCurrentWalletBalance(String token) async {
    try {
      final walletData = await _service.getWalletDetails(token);
      if (walletData != null) {
        wallet = walletData;
        // Convert walletBalance from String to double
        return double.tryParse(walletData.walletBalance) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      print('Error getting wallet balance: $e');
      return 0.0;
    }
  }

  // Helper method to get current wallet balance as String
  Future<String?> getCurrentWalletBalanceAsString(String token) async {
    try {
      final walletData = await _service.getWalletDetails(token);
      if (walletData != null) {
        wallet = walletData;
        return walletData.walletBalance;
      }
      return '0.00';
    } catch (e) {
      print('Error getting wallet balance: $e');
      return '0.00';
    }
  }
}

