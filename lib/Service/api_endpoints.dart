
class ApiEndpoints {

  static const String baseUrl =
      "http://evtron-dev.dextragroups.com/api/mobile";

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

  static const String updateProfile =
      "$baseUrl/profile/update";

  static const String bookings =
      "$baseUrl/bookings";

  static const String chargingHistory =
      "$baseUrl/charging-history";

  static const String payments =
      "$baseUrl/payments";

  static const String complaints =
      "$baseUrl/complaints";

  static const String startCharging = "$baseUrl/charging/start";
  static const String liveCharging = '$baseUrl/charging/live';
  static const String stopCharging = "$baseUrl/charging/stop";
  static const String chargingStatus = "$baseUrl/charging/status";

}



