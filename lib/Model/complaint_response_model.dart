class ComplaintResponse {

  final bool success;
  final String message;
  final ComplaintData? data;

  ComplaintResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ComplaintResponse.fromJson(
      Map<String, dynamic> json,
      ) {
    return ComplaintResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? ComplaintData.fromJson(json['data'])
          : null,
    );
  }
}

class ComplaintData {

  final int id;
  final String subject;
  final String description;
  final int userId;

  ComplaintData({
    required this.id,
    required this.subject,
    required this.description,
    required this.userId,
  });

  factory ComplaintData.fromJson(
      Map<String, dynamic> json,
      ) {
    return ComplaintData(
      id: json['id'] ?? 0,
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      userId: json['user_id'] ?? 0,
    );
  }
}