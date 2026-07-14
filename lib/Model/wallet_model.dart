
class WalletModel {
  final String walletBalance;
  final String creditLimit;
  final double availableBalance;
  final String walletStatus;
  final String lastRechargedAt;

  WalletModel({
    required this.walletBalance,
    required this.creditLimit,
    required this.availableBalance,
    required this.walletStatus,
    required this.lastRechargedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      walletBalance: json['wallet_balance']?.toString() ?? '0.00',
      creditLimit: json['credit_limit']?.toString() ?? '0.00',
      availableBalance: double.tryParse(json['available_balance']?.toString() ?? '0') ?? 0.0,
      walletStatus: json['wallet_status'] ?? '',
      lastRechargedAt: json['last_recharged_at'] ?? '',
    );
  }
}



