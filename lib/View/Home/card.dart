// import 'package:evtron/View/Home/startcharge.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../../Theme/colors.dart';
// import 'ChargingProgressPage.dart';
//
// class SwipeableVehicleCards extends StatelessWidget {
//   const SwipeableVehicleCards({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // You can change this to whichever vehicle you want to display
//     final Map<String, dynamic> vehicle = {
//       "name": "Tesla Model 3",
//       "kwh": "75 kWh",
//       "duration": "2h 15m",
//       "type": "car",
//       "status": "Active",
//     };
//
//     return SizedBox(
//       height: 230,
//       child: _buildVehicleCard(context, vehicle),
//     );
//   }
//
//   Widget _buildVehicleCard(BuildContext context, Map<String, dynamic> vehicle) {
//     Color getStatusColor(String status) {
//       switch(status) {
//         case "Active":
//           return Colors.white.withOpacity(0.9);
//         case "Charging":
//           return Colors.white.withOpacity(0.9);
//         case "Low Battery":
//           return Colors.white.withOpacity(0.7);
//         default:
//           return Colors.white.withOpacity(0.8);
//       }
//     }
//
//     Color getStatusBgColor(String status) {
//       switch(status) {
//         case "Active":
//           return Colors.white.withOpacity(0.15);
//         case "Charging":
//           return Colors.white.withOpacity(0.15);
//         case "Low Battery":
//           return Colors.white.withOpacity(0.1);
//         default:
//           return Colors.white.withOpacity(0.12);
//       }
//     }
//
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [
//             Appcolor.green,
//             Color(0xFF1B5E20),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Appcolor.green.withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 44,
//                 height: 44,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   vehicle["type"] == "car"
//                       ? Icons.electric_car
//                       : Icons.two_wheeler,
//                   color: Appcolor.green,
//                   size: 28,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       vehicle["name"],
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       vehicle["type"] == "car" ? "Electric Car" : "Electric Scooter",
//                       style: GoogleFonts.poppins(
//                         color: Colors.white70,
//                         fontSize: 11,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                 decoration: BoxDecoration(
//                   color: getStatusBgColor(vehicle["status"]),
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: Colors.white.withOpacity(0.2),
//                   ),
//                 ),
//                 child: Text(
//                   vehicle["status"],
//                   style: GoogleFonts.poppins(
//                     color: getStatusColor(vehicle["status"]),
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   children: [
//                     Text(
//                       vehicle["kwh"],
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       "Battery Capacity",
//                       style: GoogleFonts.poppins(
//                         color: Colors.white70,
//                         fontSize: 11,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 height: 35,
//                 width: 1,
//                 color: Colors.white.withOpacity(0.2),
//               ),
//               Expanded(
//                 child: Column(
//                   children: [
//                     Text(
//                       vehicle["duration"],
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       "Est. Charging Time",
//                       style: GoogleFonts.poppins(
//                         color: Colors.white70,
//                         fontSize: 11,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const ChargingProgressPage(),
//                 ),
//               );
//             },
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(
//                     Icons.bolt,
//                     color: Appcolor.green,
//                     size: 16,
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     "Start Charging",
//                     style: GoogleFonts.poppins(
//                       fontSize: 13,
//                       fontWeight: FontWeight.bold,
//                       color: Appcolor.green,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }