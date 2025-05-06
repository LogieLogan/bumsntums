// lib/main_dev.dart

import 'dart:async';
import 'package:bums_n_tums/shared/providers/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'app.dart';
import 'flavors.dart' as flavors;
import 'firebase_options_dev.dart';
import 'shared/config/app_config.dart' as config;
import 'shared/services/environment_service.dart';
import 'shared/providers/environment_provider.dart';

import 'shared/services/firebase_service.dart';
import 'shared/analytics/crash_reporting_service.dart';
import 'shared/utils/exercise_reference_utils.dart';

FutureOr<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  flavors.F.appFlavor = flavors.Flavor.dev;
  if (kDebugMode) {
    print("🚀 RUNNING FLAVOR: ${flavors.F.appFlavor}");
  }

  final appConfig = config.AppConfig(
    flavor: config.Flavor.dev,
    appName: flavors.F.title,
    apiBaseUrl: 'https://dev-api.bumsntums.com',
  );
  if (kDebugMode) {
    print(
      "⚙️ AppConfig Initialized: Flavor=${appConfig.flavor}, Name=${appConfig.appName}, URL=${appConfig.apiBaseUrl}",
    );
  }

  await _requestPermissions();

  if (kDebugMode) print("🔧 Initializing Environment Service...");

  final environmentService = EnvironmentService();
  try {
    await environmentService.initialize();
    if (kDebugMode) print("✅ Environment Service initialized successfully");
  } catch (e) {
    if (kDebugMode) print("🔥 Environment Service Initialization FAILED: $e");
  }

  if (kDebugMode) print("🔥 Initializing Firebase Core (DEV)...");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) print("✅ Firebase Core initialized successfully");
  } catch (e, s) {
    if (kDebugMode) print("🔥 Firebase Core Initialization FAILED: $e");

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
    return;
  }

  if (kDebugMode)
    print("🔒 Initializing Firebase App Check (DEBUG Provider)...");
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    if (kDebugMode) print("✅ Firebase App Check activated (DEBUG mode)");

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
    } catch (_) {}
  }

  if (kDebugMode)
    print("📊 Initializing FirebaseService (Analytics/Crashlytics)...");
  try {
    final firebaseService = FirebaseService();
    await firebaseService.initialize();
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

  if (kDebugMode) print("🚀 Running App (DEV)...");

  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        environmentServiceInitProvider.overrideWith(
          (_) => Future.value(environmentService),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}

Future<void> _requestPermissions() async {
  if (Platform.isIOS || Platform.isAndroid) {
    List<Permission> permissionsToRequest = [];
    if (Platform.isIOS) {
      permissionsToRequest.add(Permission.notification);
    }

    permissionsToRequest.add(Permission.camera);

    if (kDebugMode) print("ℹ️ Requesting Permissions...");
    Map<Permission, PermissionStatus> statuses =
        await permissionsToRequest.request();
    if (kDebugMode) print("ℹ️ Permission statuses: $statuses");
  } else {
    if (kDebugMode)
      print("ℹ️ Skipping permission request on ${Platform.operatingSystem}.");
  }
}
