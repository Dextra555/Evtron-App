import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../Model/wallet_model.dart';
import '../Model/wallet_recharge_model.dart';
import '../Model/wallet_receipt_model.dart';
import '../Model/wallet_transaction_model.dart';
import '../Model/razorpay_response_model.dart';
import 'api_endpoints.dart';

class WalletService {

  Future<WalletModel?> getWalletDetails(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.wallet),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('========== WALLET API ==========');
      print('URL: ${ApiEndpoints.wallet}');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('================================');

      if (response.statusCode == 200) {
        // Parse the response correctly - it's a direct object, not nested in 'data'
        final jsonData = jsonDecode(response.body);
        return WalletModel.fromJson(jsonData);
      }

      return null;
    } catch (e) {
      print('Wallet API Error: $e');
      return null;
    }
  }

  Future<WalletRechargeModel?> rechargeWallet({
    required String token,
    required double amount,
  }) async
  {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.walletRecharge),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "amount": amount,
          "description": "Wallet Recharge"
        }),
      );
      print("========== WALLET RECHARGE ==========");
      print("URL: ${ApiEndpoints.walletRecharge}");
      print("Request: ${jsonEncode({
        "amount": amount,
        "description": "Wallet Recharge"
      })}");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("=====================================");

      if (response.statusCode == 200) {
        return WalletRechargeModel.fromJson(
          jsonDecode(response.body),
        );
      }

      return null;
    } catch (e) {
      print("Wallet Recharge Error: $e");
      return null;
    }
  }

  // Updated method to get wallet receipt with better error handling
  Future<WalletReceiptModel?> getWalletReceipt({
    required String token,
    required int transactionId,
  }) async
  {
    try {
      final url = ApiEndpoints.walletReceipt(transactionId);
      print("========== WALLET RECEIPT ==========");
      print("URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("=====================================");

      if (response.statusCode == 200) {
        return WalletReceiptModel.fromJson(
          jsonDecode(response.body),
        );
      } else if (response.statusCode == 404) {
        print("Receipt not found for transaction ID: $transactionId");
        return null;
      }

      return null;
    } catch (e) {
      print("Wallet Receipt Error: $e");
      return null;
    }
  }

  // In WalletService class - UPDATED with better error handling
  Future<CancelOrderResponse?> cancelOrder({
    required String token,
    required String orderId,
  }) async {
    // Try both possible payload formats
    final payloads = [
      {'order_id': orderId},
      {'razorpay_order_id': orderId},
    ];

    for (final payload in payloads) {
      try {
        debugPrint('Trying to cancel order with payload: $payload');

        final response = await http.post(
          Uri.parse(ApiEndpoints.cancelRazorpayOrder),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        );

        debugPrint('Cancel order response status: ${response.statusCode}');
        debugPrint('Cancel order response body: ${response.body}');

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            return CancelOrderResponse.fromJson(data);
          } catch (e) {
            debugPrint('Cancel order parse error: $e');
            // If parsing fails but status is 200, consider it a success
            return CancelOrderResponse(
              success: true,
              message: 'Order cancelled successfully',
            );
          }
        } else if (response.statusCode == 404) {
          // Order not found - treat as success (already cancelled)
          debugPrint('Order not found, treating as already cancelled');
          return CancelOrderResponse(
            success: true,
            message: 'Order already cancelled or not found',
          );
        }
      } catch (e) {
        debugPrint('Cancel order attempt failed: $e');
        // Continue to next payload format
      }
    }

    // If all attempts fail, return a failure response
    return CancelOrderResponse(
      success: false,
      message: 'Failed to cancel order. Please try again.',
    );
  }

  Future<RazorpayOrderResponse?> createRazorpayOrder({
    required String token,
    required double amount,
    bool forceNew = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.createRazorpayOrder),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'force_new': forceNew,
        }),
      );

      print("========== CREATE RAZORPAY ORDER ==========");
      print("URL: ${ApiEndpoints.createRazorpayOrder}");
      print("Request: ${jsonEncode({
        'amount': amount,
        'force_new': forceNew,
      })}");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("===========================================");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RazorpayOrderResponse.fromJson(data);
      }

      return null;
    } catch (e) {
      print("Create Razorpay Order Error: $e");
      return null;
    }
  }

// NEW: Verify order status
  Future<OrderStatusResponse?> verifyOrderStatus({
    required String token,
    required String orderId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.createRazorpayOrder}/status/$orderId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("========== VERIFY ORDER STATUS ==========");
      print("URL: ${ApiEndpoints.createRazorpayOrder}/status/$orderId");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("=========================================");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OrderStatusResponse.fromJson(data);
      }

      return null;
    } catch (e) {
      print("Verify Order Status Error: $e");
      return null;
    }
  }


  // NEW: Get order details
  Future<OrderDetailsResponse?> getOrderDetails({
    required String token,
    required String orderId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.createRazorpayOrder}/$orderId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("========== GET ORDER DETAILS ==========");
      print("URL: ${ApiEndpoints.createRazorpayOrder}/$orderId");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("=======================================");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OrderDetailsResponse.fromJson(data);
      }

      return null;
    } catch (e) {
      print("Get Order Details Error: $e");
      return null;
    }
  }

  // NEW: Retry payment for existing order
  Future<RazorpayOrderResponse?> retryPayment({
    required String token,
    required String orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.createRazorpayOrder}/retry'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId,
        }),
      );

      print("========== RETRY PAYMENT ==========");
      print("URL: ${ApiEndpoints.createRazorpayOrder}/retry");
      print("Request: ${jsonEncode({'order_id': orderId})}");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("===================================");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RazorpayOrderResponse.fromJson(data);
      }

      return null;
    } catch (e) {
      print("Retry Payment Error: $e");
      return null;
    }
  }

  // Add this to your WalletService class
  Future<List<WalletTransactionModel>> getWalletTransactions({
    required String token,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.wallet}/transactions?limit=$limit'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('========== WALLET TRANSACTIONS ==========');
      print('URL: ${ApiEndpoints.wallet}/transactions?limit=$limit');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================================');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => WalletTransactionModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Wallet Transactions Error: $e');
      return [];
    }
  }

  Future<VerifyPaymentResponse?> verifyRazorpayPayment({
    required String token,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.verifyRazorpayPayment),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        }),
      );

      print("========== VERIFY RAZORPAY PAYMENT ==========");
      print("URL: ${ApiEndpoints.verifyRazorpayPayment}");
      print("Request: ${jsonEncode({
        'order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      })}");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.body}");
      print("=============================================");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VerifyPaymentResponse.fromJson(data);
      } else {
        final data = jsonDecode(response.body);
        return VerifyPaymentResponse(
          success: false,
          status: data['status']?.toString(),
          error: data['error']?.toString() ?? 'Verification failed',
          errorKey: data['error_key']?.toString(),
          message: data['message']?.toString(),
        );
      }
    } catch (e) {
      print("Verify Razorpay Payment Error: $e");
      return VerifyPaymentResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

}

// NEW: Order Status Response Model
class OrderStatusResponse {
  final bool success;
  final bool isValid;
  final String? status;
  final String? message;
  final String? orderId;
  final int? amount;
  final String? currency;

  OrderStatusResponse({
    required this.success,
    required this.isValid,
    this.status,
    this.message,
    this.orderId,
    this.amount,
    this.currency,
  });

  factory OrderStatusResponse.fromJson(Map<String, dynamic> json) {
    return OrderStatusResponse(
      success: json['success'] ?? false,
      isValid: json['valid'] ?? false,
      status: json['status'],
      message: json['message'],
      orderId: json['order_id'],
      amount: json['amount'],
      currency: json['currency'],
    );
  }
}

// NEW: Cancel Order Response Model
class CancelOrderResponse {
  final bool success;
  final String? message;
  final String? orderId;
  final double? walletBalance;
  final bool autoRecovered;

  CancelOrderResponse({
    required this.success,
    this.message,
    this.orderId,
    this.walletBalance,
    this.autoRecovered = false,
  });

  factory CancelOrderResponse.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status']?.toString().toLowerCase();
    final parsedSuccess = json['success'] ?? (statusValue == 'success');

    return CancelOrderResponse(
      success: parsedSuccess,
      message: json['message']?.toString() ?? json['error']?.toString(),
      orderId: json['order_id']?.toString() ?? json['razorpay_order_id']?.toString(),
      walletBalance: json['wallet_balance'] != null
          ? double.tryParse(json['wallet_balance'].toString())
          : null,
      autoRecovered: json['auto_recovered'] == true,
    );
  }
}

// NEW: Order Details Response Model
class OrderDetailsResponse {
  final bool success;
  final String? orderId;
  final int? amount;
  final String? currency;
  final String? status;
  final String? message;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderDetailsResponse({
    required this.success,
    this.orderId,
    this.amount,
    this.currency,
    this.status,
    this.message,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderDetailsResponse.fromJson(Map<String, dynamic> json) {
    return OrderDetailsResponse(
      success: json['success'] ?? false,
      orderId: json['order_id'],
      amount: json['amount'],
      currency: json['currency'],
      status: json['status'],
      message: json['message'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
}