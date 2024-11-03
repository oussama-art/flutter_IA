import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/login.dart';
import 'firebase_options.dart'; // Ensure this file exists and is correctly configured
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase based on platform
  if (kIsWeb) {
    // Code for web platform
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    // Code for Android or other platforms (iOS, etc.)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
