class PaymentHistoryModel {

  final int id;
  final int transactionId;
  final double paidAmount;
  final String paymentDateTime;
  final String paymentMethodName;
  final String rfidTagId;
  final String status;

  PaymentHistoryModel({

    required this.id,
    required this.transactionId,
    required this.paidAmount,
    required this.paymentDateTime,
    required this.paymentMethodName,
    required this.rfidTagId,
    required this.status,
  });

  factory PaymentHistoryModel.fromJson(
      Map<String, dynamic> json) {

    return PaymentHistoryModel(

      id: json['id'] ?? 0,

      transactionId:
      json['transaction_id'] ?? 0,

      paidAmount: double.parse(
        json['paid_amount'].toString(),
      ),

      paymentDateTime:
      json['payment_date_time'] ?? '',

      paymentMethodName:
      json['payment_method_name'] ?? '',

      rfidTagId:
      json['rfid_tag_id'] ?? '',

      status:
      json['status'] ?? '',
    );
  }
}