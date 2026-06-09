import 'package:flutter/material.dart';

import '../Model/charging_history_model.dart';
import '../Service/charging_history_service.dart';

class ChargingHistoryViewModel extends ChangeNotifier {

  final ChargingHistoryService _service =
  ChargingHistoryService();

  bool isLoading = false;

  List<ChargingHistoryModel> chargingHistory = [];

  Future<void> fetchChargingHistory() async {

    isLoading = true;
    notifyListeners();

    chargingHistory =
    await _service.getChargingHistory();

    isLoading = false;
    notifyListeners();
  }
}