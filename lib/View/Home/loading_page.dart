// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:lottie/lottie.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../Service/api_endpoints.dart';
// import '../../Theme/colors.dart';
// import '../Scanner/vehiclelist.dart';
// import '../../Model/vehicle_model.dart';
// import '../../Model/start_charging_model.dart';
//
// class LoadingPage extends StatefulWidget {
//   final String stationName;
//   final String connectorType;
//   final String chargerId;
//   final String connectorUid;
//
//   const LoadingPage({
//     super.key,
//     required this.stationName,
//     required this.connectorType,
//     required this.chargerId,
//     required this.connectorUid,
//   });
//
//   @override
//   State<LoadingPage> createState() => _LoadingPageState();
// }
//
// class _LoadingPageState extends State<LoadingPage> with TickerProviderStateMixin {
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;
//   bool _isChecking = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//
//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
//       CurvedAnimation(
//         parent: _pulseController,
//         curve: Curves.easeInOut,
//       ),
//     );
//
//     // Start checking for connector availability after 2 seconds
//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) {
//         _checkConnectorAndNavigate();
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _pulseController.dispose();
//     super.dispose();
//   }
//
//   // ✅ Get token from SharedPreferences
//   Future<String?> _getAuthToken() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('auth_token');
//       if (token == null) {
//         token = prefs.getString('token');
//       }
//       if (token == null) {
//         token = prefs.getString('access_token');
//       }
//       return token;
//     } catch (e) {
//       print('❌ Error getting token: $e');
//       return null;
//     }
//   }
//
//   // ✅ Fetch connector info from API
//   Future<Map<String, dynamic>?> _fetchConnectorInfo(String token) async {
//     try {
//       final response = await http.get(
//         Uri.parse('${ApiEndpoints.baseUrl}/connectors/${widget.connectorUid}'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true && data['data'] != null) {
//           return data['data'];
//         }
//       }
//       return null;
//     } catch (e) {
//       print('❌ Error fetching connector info: $e');
//       return null;
//     }
//   }
//
//   // ✅ Check connector status before navigating
//   Future<void> _checkConnectorAndNavigate() async {
//     if (_isChecking) return;
//     setState(() {
//       _isChecking = true;
//     });
//
//     try {
//       final token = await _getAuthToken();
//       if (token == null) {
//         _showErrorDialog('Authentication failed. Please log in again.');
//         return;
//       }
//
//       // Fetch connector info
//       final connectorData = await _fetchConnectorInfo(token);
//       if (connectorData == null) {
//         _showErrorDialog(
//           'Connector not found. Please scan a valid QR code.',
//           title: 'Invalid Connector',
//         );
//         return;
//       }
//
//       final status = connectorData['status'] ?? '';
//
//       if (status.toLowerCase() == 'available') {
//         // ✅ Connector is available - fetch vehicles and navigate
//         if (mounted) {
//           final vehicles = await _fetchUserVehicles(token);
//
//           // Extract connector info
//           final connectorId = connectorData['connector_id'] ?? 0;
//           final connectorType = connectorData['type'] ?? widget.connectorType;
//           final chargerType = connectorData['charger_type'] ?? 'AC';
//           final chargerId = connectorData['charger_id'] ?? widget.chargerId;
//
//           // Create ChargerInfo
//           final chargerInfo = ChargerInfo(
//             id: chargerId,
//             name: 'Charger ${widget.chargerId}',
//             type: chargerType,
//           );
//
//           // Create ConnectorInfo
//           final connectorInfo = ConnectorInfo(
//             connectorUid: widget.connectorUid,
//             connectorType: connectorType,
//           );
//
//           // Create StationInfo
//           final stationInfo = StationInfo(
//             stationName: widget.stationName,
//           );
//
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => VehicleScreen(
//                 connectorUid: widget.connectorUid,
//                 vehicles: vehicles,
//                 chargerModel: chargerId,
//                 chargerType: chargerType,
//                 chargerInfo: chargerInfo,
//                 connectorInfo: connectorInfo,
//                 stationInfo: stationInfo,
//                 connectorId: connectorId,
//                 userBalance: 0.0, // You can fetch this from API if needed
//               ),
//             ),
//           );
//         }
//       } else {
//         // ❌ Connector not available
//         _showErrorDialog(
//           'Connector is not available.\nStatus: $status',
//           title: 'Connector Unavailable',
//         );
//       }
//     } catch (e) {
//       print('❌ Error checking connector: $e');
//       _showErrorDialog(
//         'Error: ${e.toString()}',
//         title: 'Connection Error',
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isChecking = false;
//         });
//       }
//     }
//   }
//
//   // ✅ Fetch user vehicles
//   Future<List<Vehicle>> _fetchUserVehicles(String token) async {
//     try {
//       final response = await http.get(
//         Uri.parse('${ApiEndpoints.baseUrl}/vehicles'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true && data['data'] != null) {
//           final vehiclesList = data['data'] as List;
//           return vehiclesList.map((v) => Vehicle.fromJson(v)).toList();
//         }
//       }
//       return [];
//     } catch (e) {
//       print('❌ Error fetching vehicles: $e');
//       return [];
//     }
//   }
//
//   // ✅ Show error dialog
//   void _showErrorDialog(String message, {String title = 'Error'}) {
//     if (!mounted) return;
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Container(
//             padding: const EdgeInsets.all(24),
//             constraints: const BoxConstraints(maxWidth: 350),
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
//                   title,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   message,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Colors.black87,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                       Navigator.pop(context); // Go back to station details
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Appcolor.green,
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Go Back',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
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
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final bgColor = isDark ? const Color(0xFF0A0A1A) : Colors.white;
//     final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
//     final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
//
//     return Scaffold(
//       backgroundColor: bgColor,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Spacer(flex: 1),
//
//               AnimatedBuilder(
//                 animation: _pulseAnimation,
//                 builder: (context, child) {
//                   return Transform.scale(
//                     scale: _pulseAnimation.value,
//                     child: SizedBox(
//                       width: 550,
//                       height: 300,
//                       child: Lottie.asset(
//                         'assets/Ev_car.json',
//                         fit: BoxFit.contain,
//                         repeat: true,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//
//               const SizedBox(height: 16),
//
//               Text(
//                 _isChecking ? 'Checking connector...' : 'Keep the cable plugged\ninto the vehicle',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.w600,
//                   color: textColor,
//                   height: 1.3,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//
//               const SizedBox(height: 8),
//
//               Text(
//                 _isChecking
//                     ? 'Verifying connector availability...'
//                     : 'Please ensure the charging cable is\nsecurely connected',
//                 style: TextStyle(
//                   fontSize: 15,
//                   color: subtitleColor,
//                   height: 1.5,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//
//               const SizedBox(height: 4),
//
//               if (_isChecking)
//                 const Padding(
//                   padding: EdgeInsets.all(20.0),
//                   child: CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(Appcolor.green),
//                   ),
//                 )
//               else
//                 SizedBox(
//                   width: 300,
//                   height: 200,
//                   child: Lottie.asset(
//                     'assets/loading.json',
//                     fit: BoxFit.contain,
//                     repeat: true,
//                   ),
//                 ),
//
//               const Spacer(flex: 1),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
