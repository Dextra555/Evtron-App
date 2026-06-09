class VerifyOtpModel {
  final String phone;
  final String otp;

  VerifyOtpModel({
    required this.phone,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'otp': otp,
    };
  }
}

class ResendOtpModel {
  final String phone;

  ResendOtpModel({
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
    };
  }
}