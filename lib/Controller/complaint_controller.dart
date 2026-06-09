import 'package:flutter/material.dart';

import '../Model/complaint_response_model.dart';
import '../Service/complaint_service.dart';

class ComplaintController extends ChangeNotifier {

  final ComplaintService _service =
  ComplaintService();

  bool isLoading = false;

  Future<ComplaintResponse?> submitComplaint({
    required String subject,
    required String description,
  }) async {

    isLoading = true;

    notifyListeners();

    final response =
    await _service.submitComplaint(
      subject: subject,
      description: description,
    );

    isLoading = false;

    notifyListeners();

    return response;
  }
}