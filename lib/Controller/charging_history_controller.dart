import 'package:flutter/material.dart';
import 'package:evtron/Service/network_service.dart';
import '../model/charging_history_model.dart';
import '../service/charging_history_service.dart';

class ChargingHistoryController extends ChangeNotifier {
  final ChargingHistoryService _service = ChargingHistoryService();

  List<ChargingHistoryModel> chargingHistory = [];
  bool isLoading = false;
  String? errorMessage;

  // Statistics
  int get totalSessions => chargingHistory.length;
  double get totalEnergy => chargingHistory.fold(0, (sum, item) => sum + item.units);
  double get totalAmount => chargingHistory.fold(0, (sum, item) => sum + item.amount);

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    errorMessage = error;
    notifyListeners();
  }

  Future<void> fetchChargingHistory(String token) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      print('🔄 Fetching charging history...');
      print('🔑 Token length: ${token.length}');

      chargingHistory = await _service.getChargingHistory(token);
      print('✅ Successfully loaded ${chargingHistory.length} records');

      if (chargingHistory.isEmpty) {
        errorMessage = "No charging history found";
      }

    } on NetworkException catch (e) {
      errorMessage = NetworkService.noInternetMessage;
      print('❌ Network error in charging history controller: $e');
    } catch (e, stackTrace) {
      errorMessage = 'Failed to load charging history. Please try again.';
      print('❌ Error in controller: $e');
      print(stackTrace);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    chargingHistory.clear();
    errorMessage = null;
    notifyListeners();
  }
}