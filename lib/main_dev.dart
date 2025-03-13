// lib/main_dev.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'shared/config/app_config.dart' as config;
import 'shared/services/firebase_service.dart';
import 'firebase_options_dev.dart';
import 'flavors.dart' as flavors;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set the flavor for the app
  flavors.F.appFlavor = flavors.Flavor.dev;
  
  // Initialize app config
  config.AppConfig(
    flavor: config.Flavor.dev,
    appName: flavors.F.title,
    apiBaseUrl: 'https://dev-api.bumsntums.com',
  );
  
  // First initialize Firebase directly
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Then initialize the Firebase service which sets up analytics and crashlytics
  final firebaseService = FirebaseService();
  await firebaseService.initialize();
  
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}