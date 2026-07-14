import 'package:evtron/Controller/wishlist_controller.dart';
import 'package:evtron/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evtron/View/Login/splashscreen.dart';
import 'Controller/complaint_controller.dart';
import 'Controller/payment_history_controller.dart';
import 'View/Home/homepage.dart';
import 'View/Login/splash.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(

      providers: [

        ChangeNotifierProvider(
          create: (_) => WishlistController(),
        ),

        // ChangeNotifierProvider(
        //   create: (_) => ChargingHistoryViewModel(),
        // ),

        ChangeNotifierProvider(
          create: (_) => PaymentHistoryController(),
        ),

        ChangeNotifierProvider(
          create: (_) => ComplaintController(),
        ),

      ],

      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'EVtron App',

      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),

      home: const SplashScreen(),
    );
  }
}


