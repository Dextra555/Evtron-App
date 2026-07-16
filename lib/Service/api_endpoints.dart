
class ApiEndpoints {

  static const String baseUrl =
      "https://evtron-dev.dextragroups.com/api/mobile";

  static const String sendOtp =
      "$baseUrl/send-otp";

  static const String verifyOtp =
      "$baseUrl/verify-otp";

  static const String resendOtp =
      "$baseUrl/resend-otp";

  static const String register =
      "$baseUrl/register";

  static const String vehicles =
      "$baseUrl/vehicles";

  static const String addVehicle =
      "$baseUrl/add-vehicle";

  static String updateVehicle(String vehicleId) =>
      "$baseUrl/update-vehicle/$vehicleId";

  static String deleteVehicle(String vehicleId) =>
      "$baseUrl/delete-vehicle/$vehicleId";

  static const String nearbyStations =
      "$baseUrl/nearby-stations";

  static const String stations = "$baseUrl/stations";

  static const String wishlist =
      "$baseUrl/wishlist";

  static String removeWishlist(int id) =>
      "$wishlist/$id";

  static const String profile =
      "$baseUrl/profile";

  // static const String updateProfile =
  //     "$baseUrl/profile/update";

  static const String updateProfile = "$baseUrl/update-profile";

  static const String bookings =
      "$baseUrl/bookings";

  static const String chargingHistory =
      "$baseUrl/charging-history";

  static const String payments =
      "$baseUrl/payments";

  static const String complaints =
      "$baseUrl/complaints";

  static const String validateScan = "$baseUrl/scan/validate";
  static const String startCharging = "$baseUrl/charging/start";
  static const String liveCharging = '$baseUrl/charging/live';
  static const String stopCharging = "$baseUrl/charging/stop";
  static const String chargingStatus = "$baseUrl/charging/status";

  static String chargingHistoryDetails(int id) =>
      "$baseUrl/charging-history/charger/$id";

  static String chargingInvoice(String sessionId) =>
      "$baseUrl/invoices/session/$sessionId";

  static const String manufacturers = '$baseUrl/settings/manufacturers/list';

  static String models(int manufacturerId) =>
      '$baseUrl/settings/models/list?manufacturer_id=$manufacturerId';

  static const String wallet = "$baseUrl/wallet";
  static const String walletRecharge =
      "$baseUrl/wallet/recharge";

  static String walletReceipt(int transactionId) {
    return '$baseUrl/wallet/receipt/$transactionId';
  }

  // Razorpay endpoints
  static const String createRazorpayOrder = '$baseUrl/wallet/recharge/create-order';
  static const String cancelRazorpayOrder = '$baseUrl/api/wallet/recharge/cancel';
  static const String verifyRazorpayPayment = '$baseUrl/wallet/recharge/verify';

  // Add this to your ApiEndpoints class
  static const String walletTransactions = '$baseUrl/wallet/transactions';

  static const String cancelAllPendingOrders = '$baseUrl/wallet/recharge/cancel-all-pending';
}



