class WalletRechargeModel {
  final String message;
  final String receiptNumber;
  final int transactionId;
  final String walletBalance;
  final double availableBalance;

  WalletRechargeModel({
    required this.message,
    required this.receiptNumber,
    required this.transactionId,
    required this.walletBalance,
    required this.availableBalance,
  });

  factory WalletRechargeModel.fromJson(Map<String, dynamic> json) {
    return WalletRechargeModel(
      message: json['message'] ?? '',
      receiptNumber: json['receipt_number'] ?? '',
      transactionId: json['transaction_id'] ?? 0,
      walletBalance: json['wallet_balance']?.toString() ?? '0',
      availableBalance: double.tryParse(json['available_balance']?.toString() ?? '0') ?? 0.0,
    );
  }
}
