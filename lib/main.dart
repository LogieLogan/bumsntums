import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_dev.dart';
import 'app.dart';
import 'flavors.dart';
import 'shared/services/firebase_service.dart';

FutureOr<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set the flavor
  F.appFlavor = Flavor.prod;
  
  try {
    // Initialize Firebase Core first
    print("Initializing Firebase Core...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase Core initialized successfully");
    
    // Initialize Firebase services using the service class
    print("Initializing Firebase services...");
    final firebaseService = FirebaseService();
    await firebaseService.initialize();
    print("Firebase services initialized successfully");
    
  } catch (e) {
    print("Error during Firebase initialization: $e");
    // Continue without Firebase for development
  }
  
  // Run the app
  runApp(const ProviderScope(child: App()));
}