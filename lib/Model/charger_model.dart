// // charger_model.dart
// class ChargerModel {
//   final int id;
//   final String name;
//   final String manufacturer;
//   final String status;
//   final dynamic powerCapacity;
//   final dynamic powerConsumption;
//   final String serialNumber;
//   final List<ConnectorModel> connectors;
//   final List<TariffModel> tariffs;
//   final String warrantyPeriod;
//
//   ChargerModel({
//     required this.id,
//     required this.name,
//     required this.manufacturer,
//     required this.status,
//     required this.powerCapacity,
//     required this.powerConsumption,
//     required this.serialNumber,
//     required this.connectors,
//     required this.tariffs,
//     required this.warrantyPeriod,
//   });
//
//   factory ChargerModel.fromJson(Map<String, dynamic> json) {
//     return ChargerModel(
//       id: json['id'] ?? 0,
//       name: json['name'] ?? '',
//       manufacturer: json['manufacturer'] ?? '',
//       status: json['status'] ?? '',
//       powerCapacity: json['power_capacity'] ?? 0,
//       powerConsumption: json['power_consumption'] ?? 0,
//       serialNumber: json['serial_number'] ?? '',
//       connectors: (json['connectors'] as List?)
//           ?.map((c) => ConnectorModel.fromJson(c))
//           .toList() ?? [],
//       tariffs: (json['tariffs'] as List?)
//           ?.map((t) => TariffModel.fromJson(t))
//           .toList() ?? [],
//       warrantyPeriod: json['warranty_period'] ?? '',
//     );
//   }
//
//   int get powerCapacityInt {
//     if (powerCapacity is int) return powerCapacity;
//     if (powerCapacity is double) return powerCapacity.toInt();
//     return 0;
//   }
//
//   int get powerConsumptionInt {
//     if (powerConsumption is int) return powerConsumption;
//     if (powerConsumption is double) return powerConsumption.toInt();
//     return 0;
//   }
// }
//
// // Define ConnectorModel in the same file or import it
// class ConnectorModel {
//   final String connectorName;
//   final String currentType;
//   final int maxCurrent;
//   final int maxPower;
//   final String status;
//
//   ConnectorModel({
//     required this.connectorName,
//     required this.currentType,
//     required this.maxCurrent,
//     required this.maxPower,
//     required this.status,
//   });
//
//   factory ConnectorModel.fromJson(Map<String, dynamic> json) {
//     return ConnectorModel(
//       connectorName: json['connector_name'] ?? json['name'] ?? '',
//       currentType: json['current_type'] ?? '',
//       maxCurrent: json['max_current'] ?? 0,
//       maxPower: json['max_power'] ?? 0,
//       status: json['status'] ?? 'Unknown',
//     );
//   }
// }
//
// // Define TariffModel in the same file or import it
// class TariffModel {
//   final String tariffName;
//   final double charge;
//   final double electricityRate;
//
//   TariffModel({
//     required this.tariffName,
//     required this.charge,
//     required this.electricityRate,
//   });
//
//   factory TariffModel.fromJson(Map<String, dynamic> json) {
//     return TariffModel(
//       tariffName: json['tariff_name'] ?? json['name'] ?? '',
//       charge: (json['charge'] ?? 0).toDouble(),
//       electricityRate: (json['electricity_rate'] ?? 0).toDouble(),
//     );
//   }
// }