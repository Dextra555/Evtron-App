class Manufacturer {
  final int id;
  final String name;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  Manufacturer({
    required this.id,
    required this.name,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Manufacturer.fromJson(Map<String, dynamic> json) {
    return Manufacturer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class ManufacturerResponse {
  final bool success;
  final List<Manufacturer> data;

  ManufacturerResponse({
    required this.success,
    required this.data,
  });

  factory ManufacturerResponse.fromJson(Map<String, dynamic> json) {
    List<Manufacturer> manufacturerList = [];
    if (json['data'] != null && json['data'] is List) {
      manufacturerList = (json['data'] as List)
          .map((item) => Manufacturer.fromJson(item))
          .toList();
    }
    return ManufacturerResponse(
      success: json['success'] ?? false,
      data: manufacturerList,
    );
  }
}

class VehicleModel {
  final int id;
  final int manufacturerId;
  final String name;
  final Manufacturer? manufacturer;

  VehicleModel({
    required this.id,
    required this.manufacturerId,
    required this.name,
    this.manufacturer,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? 0,
      manufacturerId: json['manufacturer_id'] ?? 0,
      name: json['name'] ?? '',
      manufacturer: json['manufacturer'] != null
          ? Manufacturer.fromJson(json['manufacturer'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manufacturer_id': manufacturerId,
      'name': name,
      'manufacturer': manufacturer?.toJson(),
    };
  }
}

class VehicleModelResponse {
  final bool success;
  final List<VehicleModel> data;

  VehicleModelResponse({
    required this.success,
    required this.data,
  });

  factory VehicleModelResponse.fromJson(Map<String, dynamic> json) {
    List<VehicleModel> modelList = [];
    if (json['data'] != null && json['data'] is List) {
      modelList = (json['data'] as List)
          .map((item) => VehicleModel.fromJson(item))
          .toList();
    }
    return VehicleModelResponse(
      success: json['success'] ?? false,
      data: modelList,
    );
  }
}