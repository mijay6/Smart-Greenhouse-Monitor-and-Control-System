import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:firebase_core/firebase_core.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_storage/firebase_storage.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:firebase_crashlytics/firebase_crashlytics.dart';
//import 'firebase_options.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';

//void firebaseInit() async {
//  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //firebaseInit();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Greenhouse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        cardColor: const Color(0xFF161B22),
        useMaterial3: true,
        //colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const DashboardScreen(),
    );
  }
}
