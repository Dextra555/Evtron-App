class EditProfileModel {
  final String name;
  final String email;
  final String phone;

  EditProfileModel({
    required this.name,
    required this.email,
    required this.phone,
  });

  Map<String, String> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  EditProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
  }) {
    return EditProfileModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

class UpdateProfileResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  UpdateProfileResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      success: json['status'] == true,
      message: json['message'] ?? (json['status'] == true ? 'Profile updated successfully' : 'Failed to update profile'),
      data: json['data'],
    );
  }
}