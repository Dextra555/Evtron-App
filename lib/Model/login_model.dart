

class SendOtpModel {
  final String phone;

  SendOtpModel({
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
    };
  }
}
