// lib/main_dev.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform; // For platform-specific checks

import 'app.dart'; // Your root App widget
import 'flavors.dart' as flavors; // Your flavors configuration
import 'firebase_options_dev.dart'; // Dev-specific Firebase options

// Import AppConfig if you use it across the app
import 'shared/config/app_config.dart' as config;

// Import necessary services and providers
import 'shared/services/environment_service.dart';
import 'shared/providers/environment_provider.dart'; // For overriding
import 'features/nutrition/services/ml_kit_service.dart';
import 'shared/services/firebase_service.dart'; // Your service for Analytics/Crashlytics
import 'shared/analytics/crash_reporting_service.dart'; // Still needed for logging init errors
import 'shared/utils/exercise_reference_utils.dart'; // For exercise cache

FutureOr<void> main() async {
  // --- Essential Flutter Setup ---
  WidgetsFlutterBinding.ensureInitialized();

  // --- Flavor Configuration ---
  flavors.F.appFlavor = flavors.Flavor.dev;
  if (kDebugMode) {
    print("🚀 RUNNING FLAVOR: ${flavors.F.appFlavor}");
  }

  // --- Initialize AppConfig (As per your existing main_dev.dart) ---
  // Ensure F.title is available or replace with a string
  final appConfig = config.AppConfig(
    flavor: config.Flavor.dev,
    appName: flavors.F.title, // Make sure flavors.F.title is set
    apiBaseUrl: 'https://dev-api.bumsntums.com', // Your specific DEV URL
  );
  if (kDebugMode) {
    print(
      "⚙️ AppConfig Initialized: Flavor=${appConfig.flavor}, Name=${appConfig.appName}, URL=${appConfig.apiBaseUrl}",
    );
  }

  // --- Permissions ---
  await _requestPermissions();

  // --- Environment Service ---
  if (kDebugMode) print("🔧 Initializing Environment Service...");
  // Create instance once
  final environmentService = EnvironmentService();
  try {
    await environmentService.initialize();
    if (kDebugMode) print("✅ Environment Service initialized successfully");
  } catch (e) {
    if (kDebugMode) print("🔥 Environment Service Initialization FAILED: $e");
    // Decide if this is fatal
  }

  // --- Firebase Core ---
  if (kDebugMode) print("🔥 Initializing Firebase Core (DEV)...");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) print("✅ Firebase Core initialized successfully");
  } catch (e, s) {
    // Capture stack trace
    if (kDebugMode) print("🔥 Firebase Core Initialization FAILED: $e");
    // Use CrashReportingService instance if available, otherwise fallback
    try {
      CrashReportingService().recordError(
        Exception("FATAL: Firebase Core Init Failed: $e"),
        s,
        reason: "Core Init Failure",
        fatal: true,
      );
    } catch (_) {
      /* Ignore if CrashReportingService itself fails */
    }
    return; // Stop execution if Core fails
  }

  // --- Firebase App Check (DEBUG Mode) ---
  if (kDebugMode)
    print("🔒 Initializing Firebase App Check (DEBUG Provider)...");
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    if (kDebugMode) print("✅ Firebase App Check activated (DEBUG mode)");

    // Optional debug listeners/getters
    FirebaseAppCheck.instance.onTokenChange.listen((token) {
      if (kDebugMode)
        print("ℹ️ [AppCheck DEV] Token changed: ${token ?? 'null'}");
    });
    String? initialToken = await FirebaseAppCheck.instance.getToken(true);
    if (kDebugMode)
      print("ℹ️ [AppCheck DEV] Initial token: ${initialToken ?? 'null'}");
  } catch (e, s) {
    if (kDebugMode) {
      print("🔥 Firebase App Check Activation FAILED: $e");
      print("🔥 Stack Trace for App Check Failure: $s");
    }
    try {
      CrashReportingService().recordError(
        Exception("AppCheck Activation Failed (DEV): $e"),
        s,
        reason: "AppCheck Activation Failure",
      );
    } catch (_) {} // Ignore errors logging the error
  }

  // --- Initialize FirebaseService (As per your existing main_dev.dart) ---
  // This service is assumed to handle Analytics/Crashlytics setup internally
  if (kDebugMode)
    print("📊 Initializing FirebaseService (Analytics/Crashlytics)...");
  try {
    final firebaseService = FirebaseService(); // Create instance
    await firebaseService.initialize(); // Call its init method
    if (kDebugMode) print("✅ FirebaseService initialized.");
  } catch (e, s) {
    if (kDebugMode) print("🔥 FirebaseService Initialization FAILED: $e");
    try {
      CrashReportingService().recordError(
        Exception("FirebaseService Init Failed (DEV): $e"),
        s,
        reason: "FirebaseService Init Failure",
      );
    } catch (_) {}
  }

  // --- App-Specific Services ---
  // try {
  //   if (kDebugMode) print("💡 Initializing MLKit Service...");
  //   await MLKitService.initialize();
  //   if (kDebugMode) print("✅ MLKit Service initialized successfully");
  // } catch (e, s) {
  //   if (kDebugMode) print("🔥 MLKit Service Init FAILED: $e");
  //   try {
  //     CrashReportingService().recordError(
  //       Exception("MLKit Init Failed (DEV): $e"),
  //       s,
  //       reason: "MLKit Init Failure",
  //     );
  //   } catch (_) {}
  // }

  try {
    if (kDebugMode) print("🏋️ Initializing Exercise Cache...");
    await initializeExerciseCache();
    if (kDebugMode) print("✅ Exercise Cache initialized successfully");
  } catch (e, s) {
    if (kDebugMode) print("🔥 Exercise Cache Init FAILED: $e");
    try {
      CrashReportingService().recordError(
        Exception("Exercise Cache Init Failed (DEV): $e"),
        s,
        reason: "Exercise Cache Init Failure",
      );
    } catch (_) {}
  }

  // --- Run the App ---
  if (kDebugMode) print("🚀 Running App (DEV)...");
  runApp(
    ProviderScope(
      // Override the environment provider
      overrides: [
        // Correct way to override a FutureProvider with a pre-resolved value
        environmentServiceInitProvider.overrideWith(
          // Provide a Future that immediately completes with the value
          (_) => Future.value(environmentService),
        ),
      ],
      child: const App(), // Your root widget
    ),
  );
}

// --- Helper Functions ---

Future<void> _requestPermissions() async {
  // Only request on iOS/Android where needed
  if (Platform.isIOS || Platform.isAndroid) {
    List<Permission> permissionsToRequest = [];
    if (Platform.isIOS) {
      permissionsToRequest.add(Permission.notification);
    }
    // Add permissions common to both or Android specific ones
    permissionsToRequest.add(Permission.camera);
    // Add other permissions like storage, location if needed

    if (kDebugMode) print("ℹ️ Requesting Permissions...");
    Map<Permission, PermissionStatus> statuses =
        await permissionsToRequest.request();
    if (kDebugMode) print("ℹ️ Permission statuses: $statuses");
  } else {
    if (kDebugMode)
      print("ℹ️ Skipping permission request on ${Platform.operatingSystem}.");
  }
}
