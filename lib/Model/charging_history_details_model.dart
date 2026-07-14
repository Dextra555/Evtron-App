
class ChargingHistoryDetailsModel {
  final int id;
  final String stationName;
  final String? stationAddress;
  final String chargerId;
  final String chargerModel;
  final String vehicleName;
  final double units;
  final double amount;
  final String status;
  final String startTime;
  final String? endTime;
  final String userName;
  final String userPhone;
  final String costPerKwh;
  final double totalCost;
  final double? durationMinutes;
  final String? stopReason;
  final double meterStart;
  final double meterStop;

  ChargingHistoryDetailsModel({
    required this.id,
    required this.stationName,
    this.stationAddress,
    required this.chargerId,
    required this.chargerModel,
    required this.vehicleName,
    required this.units,
    required this.amount,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.userName,
    required this.userPhone,
    required this.costPerKwh,
    required this.totalCost,
    this.durationMinutes,
    this.stopReason,
    required this.meterStart,
    required this.meterStop,
  });

  factory ChargingHistoryDetailsModel.fromJson(Map<String, dynamic> json) {
    return ChargingHistoryDetailsModel(
      id: json['id'] ?? 0,
      stationName: json['station_name'] ?? '',
      stationAddress: json['station_address'],
      chargerId: json['charger_id'] ?? '',
      chargerModel: json['charger_model'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      units: double.tryParse(json['units'].toString()) ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      status: json['status'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'] ?? '',
      costPerKwh: json['cost_per_kwh'] ?? '',
      totalCost: double.tryParse(json['total_cost'].toString()) ?? 0,
      durationMinutes: json['duration_minutes'] != null
          ? double.tryParse(json['duration_minutes'].toString())
          : null,
      stopReason: json['stop_reason'],
      meterStart: double.tryParse(json['meter_start'].toString()) ?? 0,
      meterStop: double.tryParse(json['meter_stop'].toString()) ?? 0,
    );
  }
}