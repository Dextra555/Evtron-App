
import 'package:flutter/material.dart';
import '../Model/start_charging_model.dart';
import '../Service/start_charging_service.dart';


class ChargingController extends ChangeNotifier {
  final ChargingService _chargingService = ChargingService();

  bool _isLoading = false;
  String? _errorMessage;
  ChargingSessionResponse? _currentSession;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ChargingSessionResponse? get currentSession => _currentSession;

  Future<bool> startChargingSession({
    required String chargerId,
  }) async {
    print('\n╔══════════════════════════════════════════════════════════════╗');
    print('║              CHARGING CONTROLLER - START SESSION              ║');
    print('╚══════════════════════════════════════════════════════════════╝');
    print('\n📝 Input Parameters:');
    print('   • Charger ID (String): $chargerId');  // Updated log

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _chargingService.startCharging(
        chargerId: chargerId,  // Now passing string
      );

      print('\n📥 Response received in Controller:');
      print('   • Success: ${response.success}');
      print('   • Message: ${response.message}');

      if (response.success && response.data != null) {
        _currentSession = response;
        print('\n✅ SUCCESS: Charging session started successfully!');
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        print('\n❌ ERROR: ${response.message}');
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      print('\n❌ EXCEPTION in Controller: $e');
      print('Stack trace: $stackTrace');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSession() {
    _currentSession = null;
    _errorMessage = null;
    notifyListeners();
  }
}