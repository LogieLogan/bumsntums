import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options_dev.dart';
import 'app.dart';
import 'flavors.dart';
import 'shared/services/firebase_service.dart';
import 'shared/analytics/crash_reporting_service.dart';
import 'features/nutrition/services/ml_kit_service.dart'; // Add this import

FutureOr<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set the flavor
  F.appFlavor = Flavor.prod;

  // Request necessary permissions for iOS
  await _requestPermissions();

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

    // Initialize MLKit after Firebase
    print("Initializing MLKit...");
    await MLKitService.initialize();
    print("MLKit initialized successfully");
  } catch (e) {
    print("Error during initialization: $e");
    // Log the error to a crash reporting service if available
    CrashReportingService().recordError(e, StackTrace.current);
  }

  // Run the app
  runApp(const ProviderScope(child: App()));
}

// Function to request permissions
Future<void> _requestPermissions() async {
  // For iOS, we need to request permission for notifications and camera
  Map<Permission, PermissionStatus> statuses =
      await [
        Permission.notification,
        Permission.camera, // Add camera permission request here
      ].request();

  print("Permission statuses: $statuses");
}
