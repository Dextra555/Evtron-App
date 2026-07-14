// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import 'package:provider/provider.dart';
// import '../../Controller/live_charging_controller.dart';
// import '../../Theme/colors.dart';
// import 'ChargingProgressPage.dart';
//
// class LottiePreparingScreen extends StatefulWidget {
//   final Map<String, dynamic> chargingDetails;
//
//   const LottiePreparingScreen({
//     Key? key,
//     required this.chargingDetails,
//   }) : super(key: key);
//
//   @override
//   State<LottiePreparingScreen> createState() => _LottiePreparingScreenState();
// }
//
// class _LottiePreparingScreenState extends State<LottiePreparingScreen> {
//   late LiveChargingController _controller;
//   bool _isNavigating = false;
//   Timer? _statusCheckTimer;
//   int _checkAttempts = 0;
//   static const int maxCheckAttempts = 30; // 30 * 3 seconds = 90 seconds max wait
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = LiveChargingController();
//
//     final sessionId = widget.chargingDetails['sessionId'];
//     print('🔄 Starting polling for session: $sessionId');
//
//     _controller.startPolling(
//       sessionId: sessionId,
//       interval: const Duration(seconds: 3),
//     );
//
//     _controller.addListener(_checkStatus);
//
//     // Start a timer to check status periodically even if listener doesn't fire
//     _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
//       _checkAttempts++;
//       if (_checkAttempts >= maxCheckAttempts) {
//         print('⚠️ Max check attempts reached, stopping timer');
//         timer.cancel();
//         _showTimeoutError();
//       }
//       _checkStatus();
//     });
//   }
//
//   void _checkStatus() {
//     if (_isNavigating) return;
//     if (!mounted) return;
//
//     final status = _controller.currentLiveData?.status?.toLowerCase();
//     print('📊 Current Status: $status (Attempt: $_checkAttempts)');
//
//     // If status is "charging" - navigate to ChargingProgressPage
//     if (status == 'charging' && mounted) {
//       _isNavigating = true;
//       print('🚀 Status changed to "charging" - Navigating to ChargingProgressPage');
//       _statusCheckTimer?.cancel();
//
//       final updatedDetails = Map<String, dynamic>.from(widget.chargingDetails);
//       updatedDetails['sessionId'] = _controller.currentSessionId;
//       updatedDetails['transactionId'] = _controller.currentLiveData?.transactionId;
//       updatedDetails['startedAt'] = _controller.currentLiveData?.startedAt;
//       updatedDetails['chargerName'] = _controller.chargerName;
//       updatedDetails['chargerPowerCapacity'] = _controller.chargerPowerCapacity;
//       updatedDetails['connectorType'] = _controller.connectorType;
//       updatedDetails['stationName'] = _controller.stationName;
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ChargingProgressPage(
//             chargingDetails: updatedDetails,
//           ),
//         ),
//       );
//       return;
//     }
//
//     // If status is "error", "failed", or "stopped" - show error
//     if (status == 'error' || status == 'failed' || status == 'stopped') {
//       print('⚠️ Charging failed with status: $status');
//       _statusCheckTimer?.cancel();
//       if (mounted) {
//         _showErrorDialog(_controller.errorMessage ?? 'Failed to start charging');
//       }
//       return;
//     }
//
//     // If data is null (no active session) - this shouldn't happen during preparation
//     if (_controller.currentLiveData == null && _controller.isNoActiveSession) {
//       print('⚠️ No active session detected during preparation');
//       _statusCheckTimer?.cancel();
//       if (mounted) {
//         _showErrorDialog('Charging session not found');
//       }
//       return;
//     }
//   }
//
//   void _showTimeoutError() {
//     if (_isNavigating || !mounted) return;
//     _isNavigating = true;
//     _statusCheckTimer?.cancel();
//     _showErrorDialog('Charging preparation is taking longer than expected. Please try again.');
//   }
//
//   @override
//   void dispose() {
//     _controller.removeListener(_checkStatus);
//     _controller.stopPolling();
//     _controller.dispose();
//     _statusCheckTimer?.cancel();
//     super.dispose();
//   }
//
//   void _showErrorDialog(String errorMessage) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           child: Container(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.red.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.error_outline,
//                     color: Colors.red,
//                     size: 48,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Charging Failed",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   errorMessage,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.black87,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 24),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () {
//                           Navigator.pop(context); // Close dialog
//                           Navigator.pop(context); // Go back to vehicle screen
//                         },
//                         style: OutlinedButton.styleFrom(
//                           side: BorderSide(color: Colors.grey.shade300),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: Text(
//                           "Go Back",
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.grey.shade700,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.pop(context); // Close dialog
//                           Navigator.pop(context); // Go back to vehicle screen
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Appcolor.green,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: Text(
//                           "Retry",
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider.value(
//       value: _controller,
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           title: const Text('Preparing Charging'),
//           backgroundColor: Colors.white,
//           elevation: 0,
//           foregroundColor: Colors.black,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () {
//               _controller.stopPolling();
//               _statusCheckTimer?.cancel();
//               Navigator.pop(context);
//             },
//           ),
//         ),
//         body: Consumer<LiveChargingController>(
//           builder: (context, controller, child) {
//             // Show loading state
//             if (controller.isLoading && controller.currentLiveData == null) {
//               return const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
//                     ),
//                     SizedBox(height: 16),
//                     Text('Initializing charging session...'),
//                   ],
//                 ),
//               );
//             }
//
//             // Show Lottie animation for preparing state
//             return _buildPreparingUI(controller);
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPreparingUI(LiveChargingController controller) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Lottie Animation
//           Lottie.asset(
//             'assets/ev-charging.json',
//             width: 300,
//             height: 300,
//             fit: BoxFit.contain,
//             repeat: true,
//             animate: true,
//           ),
//           const SizedBox(height: 24),
//
//           // Status Text
//           const Text(
//             'Preparing to Charge',
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 8),
//
//           Text(
//             'Please wait while we prepare your charging session...',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade600,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           // const SizedBox(height: 30),
//           //
//           // // Show details if available
//           // if (controller.currentLiveData != null) ...[
//           //   Container(
//           //     margin: const EdgeInsets.symmetric(horizontal: 20),
//           //     padding: const EdgeInsets.all(16),
//           //     decoration: BoxDecoration(
//           //       color: Colors.grey.shade50,
//           //       borderRadius: BorderRadius.circular(12),
//           //       border: Border.all(color: Colors.grey.shade200),
//           //     ),
//           //     child: Column(
//           //       children: [
//           //         _buildInfoRow('Station', widget.chargingDetails['stationName'] ?? controller.stationName),
//           //         const SizedBox(height: 8),
//           //         _buildInfoRow('Charger', widget.chargingDetails['chargerName'] ?? controller.chargerName),
//           //         const SizedBox(height: 8),
//           //         _buildInfoRow('Vehicle', widget.chargingDetails['vehicleName'] ?? ''),
//           //         const SizedBox(height: 8),
//           //         _buildInfoRow('Status', controller.chargingStatus),
//           //       ],
//           //     ),
//           //   ),
//             const SizedBox(height: 20),
//
//             // Loading indicator
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Appcolor.green.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   SizedBox(
//                     width: 16,
//                     height: 16,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     'Initializing...',
//                     style: TextStyle(
//                       color: Appcolor.green,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             color: Colors.grey.shade600,
//             fontSize: 13,
//           ),
//         ),
//         Text(
//           value.isNotEmpty ? value : 'N/A',
//           style: const TextStyle(
//             color: Colors.black87,
//             fontSize: 13,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
// }