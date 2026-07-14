import 'dart:ui';

import 'package:flutter/material.dart';

import '../Theme/colors.dart';

class WalletTransactionModel {
  final int id;
  final int userId;
  final String type;
  final double amount;
  final double? balanceBefore;  // Made nullable
  final double? balanceAfter;   // Made nullable
  final String description;
  final String referenceType;
  final int? referenceId;
  final String createdAt;
  final String? receiptNumber;
  final String? sourceType;
  final String? sourceReference;

  WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.balanceBefore,    // Now optional
    this.balanceAfter,     // Now optional
    required this.description,
    required this.referenceType,
    this.referenceId,
    required this.createdAt,
    this.receiptNumber,
    this.sourceType,
    this.sourceReference,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      type: json['type'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      balanceBefore: json['balance_before'] != null
          ? double.tryParse(json['balance_before'].toString())
          : null,
      balanceAfter: json['balance_after'] != null
          ? double.tryParse(json['balance_after'].toString())
          : null,
      description: json['description'] ?? '',
      referenceType: json['reference_type'] ?? '',
      referenceId: json['reference_id'],
      createdAt: json['created_at'] ?? '',
      receiptNumber: json['receipt_number'],
      sourceType: json['source_type'],
      sourceReference: json['source_reference'],
    );
  }

  // Helper method to determine if this is a credit or debit
  bool get isCredit {
    return amount > 0 && type != 'verification_failed' && type != 'processing';
  }

  // Helper method to get display status
  String get displayStatus {
    switch(type) {
      case 'verification_failed':
        return 'Failed';
      case 'processing':
        return 'Processing';
      case 'credit':
        return 'Success';
      case 'debit':
        return 'Paid';
      default:
        return type.toUpperCase();
    }
  }

  // Helper method to get status color
  Color getStatusColor() {
    switch(type) {
      case 'verification_failed':
        return Colors.red;
      case 'processing':
        return Colors.orange;
      case 'credit':
        return Appcolor.green;
      case 'debit':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}