

class ChargingHistoryModel {
  final String stationName;
  final int chargerId;
  final String modelName;
  final String vehicleName;
  final double units;
  final double amount;
  final String status;
  final String startTime;
  final String endTime;

  ChargingHistoryModel({
    required this.stationName,
    required this.chargerId,
    required this.modelName,
    required this.vehicleName,
    required this.units,
    required this.amount,
    required this.status,
    required this.startTime,
    required this.endTime,
  });

  factory ChargingHistoryModel.fromJson(Map<String, dynamic> json) {
    return ChargingHistoryModel(
      stationName: json['station_name'] ?? '',
      chargerId: json['charger_id'] ?? 0,
      modelName: json['model_name'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      units: double.parse(json['units'].toString()),
      amount: double.parse(json['amount'].toString()),
      status: json['status'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
    );
  }
}