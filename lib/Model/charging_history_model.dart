class ChargingHistoryModel {
  final int id;
  final String stationName;
  final String? stationAddress;
  final String chargerId;
  final String chargerModel;
  final String? connectorId;
  final String vehicleName;
  final String? regNumber;
  final double units;
  final double amount;
  final String status;
  final String startTime;
  final String? endTime;

  ChargingHistoryModel({
    required this.id,
    required this.stationName,
    this.stationAddress,
    required this.chargerId,
    required this.chargerModel,
    this.connectorId,
    required this.vehicleName,
    this.regNumber,
    required this.units,
    required this.amount,
    required this.status,
    required this.startTime,
    this.endTime,
  });

  factory ChargingHistoryModel.fromJson(Map<String, dynamic> json) {
    return ChargingHistoryModel(
      id: json['id'] ?? 0,
      stationName: json['station_name'] ?? '',
      stationAddress: json['station_address'],
      chargerId: json['charger_id'] ?? '',
      chargerModel: json['charger_model'] ?? '',
      connectorId: json['connector_id'],
      vehicleName: json['vehicle_name'] ?? '',
      regNumber: json['reg_number'],
      units: double.tryParse(json['units'].toString()) ?? 0.0,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      status: json['status'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
    );
  }
}