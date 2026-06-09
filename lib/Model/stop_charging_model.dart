// lib/Model/stop_charging_model.dart

class StopChargingResponse {
  final bool success;
  final String message;
  final StopChargingData? data;

  StopChargingResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory StopChargingResponse.fromJson(Map<String, dynamic> json) {
    return StopChargingResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? StopChargingData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class StopChargingData {
  final int sessionId;
  final String transactionId;
  final String status;
  final DateTime startedAt;
  final DateTime endedAt;
  final double durationMinutes;
  final double energyConsumedKwh;
  final double cost;
  final String walletBalanceAfter;

  StopChargingData({
    required this.sessionId,
    required this.transactionId,
    required this.status,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.energyConsumedKwh,
    required this.cost,
    required this.walletBalanceAfter,
  });

  factory StopChargingData.fromJson(Map<String, dynamic> json) {
    return StopChargingData(
      sessionId: json['session_id'] ?? 0,
      transactionId: json['transaction_id'] ?? '',
      status: json['status'] ?? 'unknown',
      startedAt: DateTime.parse(json['started_at'] ?? DateTime.now().toIso8601String()),
      endedAt: DateTime.parse(json['ended_at'] ?? DateTime.now().toIso8601String()),
      durationMinutes: (json['duration_minutes'] ?? 0).toDouble(),
      energyConsumedKwh: (json['energy_consumed_kwh'] ?? 0).toDouble(),
      cost: (json['cost'] ?? 0).toDouble(),
      walletBalanceAfter: json['wallet_balance_after'] ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'transaction_id': transactionId,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'energy_consumed_kwh': energyConsumedKwh,
      'cost': cost,
      'wallet_balance_after': walletBalanceAfter,
    };
  }

  // Helper methods
  String get formattedDuration {
    int hours = durationMinutes ~/ 60;
    int minutes = (durationMinutes % 60).toInt();
    if (hours > 0) {
      return '$hours hr ${minutes} min';
    }
    return '${minutes} min';
  }

  String get formattedEnergy {
    return '${energyConsumedKwh.toStringAsFixed(2)} kWh';
  }

  String get formattedCost {
    return '₹${cost.toStringAsFixed(2)}';
  }

  String get formattedEndTime {
    // Format: "05:22 PM"
    return '${endedAt.hour.toString().padLeft(2, '0')}:${endedAt.minute.toString().padLeft(2, '0')}';
  }
}