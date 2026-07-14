// lib/Controller/scan_validation_controller.dart

import 'package:flutter/material.dart';
import 'package:evtron/Model/scan_validation_model.dart';
import 'package:evtron/Service/scan_validation_service.dart';

class ScanValidationController extends ChangeNotifier {
  final ScanValidationService _service = ScanValidationService();

  bool _isLoading = false;
  String? _errorMessage;
  ScanValidationResponse? _response;
  ScanValidationData? _validationData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ScanValidationResponse? get response => _response;
  ScanValidationData? get validationData => _validationData;

  /// Validate scanned QR code
  Future<bool> validateScan({
    required String scannedData,
    double? latitude,
    double? longitude,
    int? vehicleId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _response = await _service.validateScan(
        scannedData: scannedData,
        latitude: latitude,
        longitude: longitude,
        vehicleId: vehicleId,
      );

      if (_response!.success && _response!.data != null) {
        _validationData = _response!.data;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = _response!.getUserFriendlyMessage();
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset state
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _response = null;
    _validationData = null;
    notifyListeners();
  }

  /// Get error dialog configuration
  ErrorDialogConfig getErrorDialogConfig() {
    if (_response == null) {
      return ErrorDialogConfig(
        title: 'Error',
        message: _errorMessage ?? 'An unexpected error occurred',
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    }

    return ErrorDialogConfig(
      title: _response!.getErrorTitle(),
      message: _response!.getUserFriendlyMessage(),
      icon: _response!.getErrorIcon(),
      iconColor: _response!.getErrorColor(),
      failedCheck: _response!.failedCheck,
      errorCode: _response!.errorCode,
    );
  }
}

/// Configuration for error dialog
class ErrorDialogConfig {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final String? failedCheck;
  final String? errorCode;

  ErrorDialogConfig({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    this.failedCheck,
    this.errorCode,
  });
}