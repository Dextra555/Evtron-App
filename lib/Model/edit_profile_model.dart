class EditProfileModel {
  final String name;
  final String email;
  final String phone;
  final String? businessName;
  final String? address;
  final String? gstNumber;
  final bool companyProfile;

  EditProfileModel({
    required this.name,
    required this.email,
    required this.phone,
    this.businessName,
    this.address,
    this.gstNumber,
    this.companyProfile = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      if (businessName != null && businessName!.isNotEmpty) 'business_name': businessName,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (gstNumber != null && gstNumber!.isNotEmpty) 'gst_number': gstNumber,
      'company_profile': companyProfile,
    };
  }

  EditProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? businessName,
    String? address,
    String? gstNumber,
    bool? companyProfile,
  }) {
    return EditProfileModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      companyProfile: companyProfile ?? this.companyProfile,
    );
  }
}