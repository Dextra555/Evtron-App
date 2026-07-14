class CancelOrderResponse {
  final bool success;
  final String? message;
  final String? orderId;
  final double? walletBalance;
  final bool autoRecovered;

  CancelOrderResponse({
    required this.success,
    this.message,
    this.orderId,
    this.walletBalance,
    this.autoRecovered = false,
  });

  factory CancelOrderResponse.fromJson(Map<String, dynamic> json) {
    // Handle different response formats
    final statusValue = json['status']?.toString().toLowerCase();
    final parsedSuccess = json['success'] ?? (statusValue == 'success');
    final autoRecovered = json['auto_recovered'] == true || json['autoRecovered'] == true;

    return CancelOrderResponse(
      success: parsedSuccess,
      message: json['message']?.toString() ?? json['error']?.toString(),
      orderId: json['order_id']?.toString() ?? json['razorpay_order_id']?.toString(),
      walletBalance: json['wallet_balance'] != null
          ? double.tryParse(json['wallet_balance'].toString())
          : null,
      autoRecovered: autoRecovered,
    );
  }
}