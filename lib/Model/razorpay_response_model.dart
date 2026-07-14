class RazorpayOrderResponse {
  final bool success;
  final bool existingOrder;
  final String? message;
  final RazorpayOrderData data;

  RazorpayOrderResponse({
    required this.success,
    required this.existingOrder,
    required this.message,
    required this.data,
  });

  factory RazorpayOrderResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return RazorpayOrderResponse(
      success: json['success'] ?? false,
      existingOrder: json['existing_order'] ?? false,
      message: json['message']?.toString(),
      data: RazorpayOrderData.fromJson(dataJson, fallbackRoot: json),
    );
  }
}

class RazorpayOrderData {
  final String orderId;
  final int amount;
  final String currency;
  final String key;

  RazorpayOrderData({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.key,
  });

  factory RazorpayOrderData.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? fallbackRoot,
  }) {
    fallbackRoot ??= json;
    return RazorpayOrderData(
      orderId: json['order_id']?.toString() ?? fallbackRoot['order_id']?.toString() ?? '',
      amount: int.tryParse(json['amount']?.toString() ?? fallbackRoot['amount']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString() ?? fallbackRoot['currency']?.toString() ?? 'INR',
      key: json['key']?.toString() ?? fallbackRoot['key']?.toString() ?? '',
    );
  }
}

class VerifyPaymentResponse {
  final bool success;
  final String? status;
  final String? error;
  final String? errorKey;
  final double? walletBalance;
  final double? availableBalance;
  final String? message;
  final String? transactionId;

  VerifyPaymentResponse({
    required this.success,
    this.status,
    this.error,
    this.errorKey,
    this.walletBalance,
    this.availableBalance,
    this.message,
    this.transactionId,
  });

  factory VerifyPaymentResponse.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status']?.toString().toLowerCase();
    final parsedSuccess = json['success'] ?? (statusValue == 'success');

    return VerifyPaymentResponse(
      success: parsedSuccess,
      status: statusValue,
      error: json['error']?.toString(),
      errorKey: json['error_key']?.toString(),
      walletBalance: double.tryParse(json['wallet_balance']?.toString() ?? '0'),
      availableBalance: double.tryParse(json['available_balance']?.toString() ?? '0'),
      message: json['message']?.toString(),
      transactionId: json['transaction_id']?.toString(),
    );
  }

  String get userFriendlyMessage {
    final normalizedStatus = status?.toLowerCase();
    final normalizedErrorKey = errorKey?.toLowerCase();

    if (normalizedStatus == 'success' || success) {
      return message ?? 'Wallet recharge completed successfully.';
    }

    switch (normalizedErrorKey) {
      case 'order_not_found':
        return 'The payment order could not be found. Please try again.';
      case 'duplicate_request':
        return 'This payment was already processed. Please check your wallet balance.';
      case 'order_is_cancelled':
        return 'The payment order was cancelled or expired. Please try again.';
      case 'signature_verification_failed':
        return 'Payment verification failed because the signature was invalid. Please contact support if the amount was deducted.';
      case 'verification_failed':
        return 'Payment verification failed due to a mismatch. Please contact support if the amount was deducted.';
      case 'internal_error':
        return 'Payment verification hit a server issue. Please try again shortly.';
      case 'order_cannot_cancel':
        return 'This order cannot be cancelled because it already has a paid or pending payment.';
      default:
        return error ?? message ?? 'Payment verification failed.';
    }
  }
}

class PaymentData {
  final String? transactionId;
  final double? walletBalance;

  PaymentData({
    this.transactionId,
    this.walletBalance,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      transactionId: json['transaction_id']?.toString(),
      walletBalance: double.tryParse(json['wallet_balance']?.toString() ?? '0'),
    );
  }
}
