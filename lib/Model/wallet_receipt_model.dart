class WalletReceiptModel {
  final String receiptNumber;
  final int transactionId;
  final String type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String description;
  final String status;
  final String date;
  final User user;

  WalletReceiptModel({
    required this.receiptNumber,
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    required this.status,
    required this.date,
    required this.user,
  });

  factory WalletReceiptModel.fromJson(Map<String, dynamic> json) {
    // Handle different response structures
    final data = json['data'] ?? json;

    return WalletReceiptModel(
      receiptNumber: data['receipt_number']?.toString() ?? '',
      transactionId: data['transaction_id'] ?? 0,
      type: data['type'] ?? '',
      amount: double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0,
      balanceBefore: double.tryParse(data['balance_before']?.toString() ?? '0') ?? 0.0,
      balanceAfter: double.tryParse(data['balance_after']?.toString() ?? '0') ?? 0.0,
      description: data['description'] ?? '',
      status: data['status'] ?? '',
      date: data['date'] ?? '',
      user: User.fromJson(data['user'] ?? {}),
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}