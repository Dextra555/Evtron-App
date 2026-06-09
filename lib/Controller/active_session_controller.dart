// // lib/Controller/active_session_controller.dart
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class ActiveSessionController extends ChangeNotifier {
//   bool _hasActiveSession = false;
//   bool _isLoading = false;
//   Map<String, dynamic>? _activeSessionData;
//
//   // Key for storing active session in SharedPreferences
//   static const String ACTIVE_SESSION_KEY = 'active_charging_session';
//   static const String SESSION_TIMESTAMP_KEY = 'session_start_timestamp';
//
//   bool get hasActiveSession => _hasActiveSession;
//   bool get isLoading => _isLoading;
//   Map<String, dynamic>? get activeSessionData => _activeSessionData;
//
//   Future<void> checkActiveSession() async {
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final sessionJson = prefs.getString(ACTIVE_SESSION_KEY);
//
//       if (sessionJson != null) {
//         final sessionData = json.decode(sessionJson);
//         final startTimestamp = prefs.getInt(SESSION_TIMESTAMP_KEY);
//
//         // Optional: Check if session is expired (e.g., after 24 hours)
//         if (startTimestamp != null) {
//           final currentTime = DateTime.now().millisecondsSinceEpoch;
//           final hoursElapsed = (currentTime - startTimestamp) / (1000 * 60 * 60);
//
//           // Clear session if it's older than 24 hours (adjust as needed)
//           if (hoursElapsed > 24) {
//             await clearActiveSession();
//             _hasActiveSession = false;
//             _activeSessionData = null;
//           } else {
//             _hasActiveSession = true;
//             _activeSessionData = Map<String, dynamic>.from(sessionData);
//           }
//         } else {
//           _hasActiveSession = true;
//           _activeSessionData = Map<String, dynamic>.from(sessionData);
//         }
//       } else {
//         _hasActiveSession = false;
//         _activeSessionData = null;
//       }
//     } catch (e) {
//       print('Error checking active session: $e');
//       _hasActiveSession = false;
//       _activeSessionData = null;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Save active session when starting a new charging session
//   Future<void> saveActiveSession(Map<String, dynamic> sessionData) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(ACTIVE_SESSION_KEY, json.encode(sessionData));
//       await prefs.setInt(SESSION_TIMESTAMP_KEY, DateTime.now().millisecondsSinceEpoch);
//
//       _hasActiveSession = true;
//       _activeSessionData = sessionData;
//       notifyListeners();
//     } catch (e) {
//       print('Error saving active session: $e');
//     }
//   }
//
//   // Clear active session when charging stops
//   Future<void> clearActiveSession() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove(ACTIVE_SESSION_KEY);
//       await prefs.remove(SESSION_TIMESTAMP_KEY);
//
//       _hasActiveSession = false;
//       _activeSessionData = null;
//       notifyListeners();
//     } catch (e) {
//       print('Error clearing active session: $e');
//     }
//   }
//
//   // Update existing session data (e.g., when progress updates)
//   Future<void> updateActiveSession(Map<String, dynamic> updatedData) async {
//     if (_activeSessionData != null) {
//       _activeSessionData!.addAll(updatedData);
//       await saveActiveSession(_activeSessionData!);
//     }
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
// }