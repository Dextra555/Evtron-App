
class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String createdAt;
  final String updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? json['mobile'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UpdateProfileModel {
  final String name;
  final String phone;

  UpdateProfileModel({
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}