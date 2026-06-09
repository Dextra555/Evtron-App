import 'dart:convert';

class Vehicle {
  final int id;
  final int userId;
  final String manufacturer;
  final String model;
  final String registrationNumber;
  final String createdAt;
  final String updatedAt;

  Vehicle({
    required this.id,
    required this.userId,
    required this.manufacturer,
    required this.model,
    required this.registrationNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      manufacturer: json['manufacturer'] ?? '',
      model: json['model'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'manufacturer': manufacturer,
      'model': model,
      'registration_number': registrationNumber,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get displayName => "$manufacturer $model";
}

class AddVehicleModel {
  final String manufacturer;
  final String model;
  final String registrationNumber;

  AddVehicleModel({
    required this.manufacturer,
    required this.model,
    required this.registrationNumber,
  });

  Map<String, String> toJson() {
    return {
      'manufacturer': manufacturer,
      'model': model,
      'registration_number': registrationNumber,
    };
  }
}

class UpdateVehicleModel {
  final String manufacturer;
  final String model;
  final String registrationNumber;

  UpdateVehicleModel({
    required this.manufacturer,
    required this.model,
    required this.registrationNumber,
  });

  Map<String, String> toJson() {
    return {
      'manufacturer': manufacturer,
      'model': model,
      'registration_number': registrationNumber,
    };
  }
}

class VehicleResponse {
  final bool status;
  final String message;
  final List<Vehicle>? data;
  final int totalVehicles;

  VehicleResponse({
    required this.status,
    required this.message,
    this.data,
    this.totalVehicles = 0,
  });

  factory VehicleResponse.fromJson(Map<String, dynamic> json) {
    List<Vehicle>? vehicleList;

    if (json['data'] != null) {
      if (json['data'] is List) {
        vehicleList = (json['data'] as List)
            .map((vehicle) => Vehicle.fromJson(vehicle))
            .toList();
      } else if (json['data'] is Map) {
        vehicleList = [Vehicle.fromJson(json['data'])];
      }
    }

    return VehicleResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: vehicleList,
      totalVehicles: json['total_vehicles'] ?? 0,
    );
  }
}