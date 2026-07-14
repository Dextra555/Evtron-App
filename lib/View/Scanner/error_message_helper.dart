//
// class ErrorMessageHelper {
//   static String getErrorMessage(String errorMessage) {
//     // Map specific error messages to user-friendly ones
//     if (errorMessage.toLowerCase().contains('charger not found')) {
//       return 'Charger not found. Please scan a valid QR code.';
//     } else if (errorMessage.toLowerCase().contains('connector invalid')) {
//       return 'Invalid connector type. Please try another charger.';
//     } else if (errorMessage.toLowerCase().contains('ocpp offline')) {
//       return 'Charger is currently offline. Please try another charger.';
//     } else if (errorMessage.toLowerCase().contains('charger not available')) {
//       return 'This charger is currently occupied or unavailable.';
//     } else if (errorMessage.toLowerCase().contains('wallet balance insufficient')) {
//       return 'Insufficient wallet balance. Please recharge your wallet.';
//     } else if (errorMessage.toLowerCase().contains('active session exists')) {
//       return 'You already have an active charging session.';
//     } else if (errorMessage.toLowerCase().contains('connector incompatible')) {
//       return 'Your vehicle connector type is not compatible with this charger.';
//     } else if (errorMessage.toLowerCase().contains('location mismatch')) {
//       return 'You are too far from this charging station.';
//     } else if (errorMessage.toLowerCase().contains('operating hours invalid')) {
//       return 'This station is currently closed.';
//     } else if (errorMessage.toLowerCase().contains('user not authenticated')) {
//       return 'Please login again to continue.';
//     }
//     return errorMessage;
//   }
// }