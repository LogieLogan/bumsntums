// // main.dart
// import 'dart:async';
// import 'package:bums_n_tums/shared/providers/environment_provider.dart';
// import 'package:bums_n_tums/shared/services/environment_service.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
// import 'firebase_options_dev.dart';
// import 'app.dart';
// import 'flavors.dart';
// import 'shared/analytics/crash_reporting_service.dart';
// import 'features/nutrition/services/ml_kit_service.dart';
// import 'shared/utils/exercise_reference_utils.dart';
// import 'dart:io' show Platform; // Import Platform

// FutureOr<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // Set flavor - Ensure this matches the entry point (main_dev.dart)
//   F.appFlavor = Flavor.dev; // Assuming you ran main_dev.dart
//   await _requestPermissions();

//   if (kDebugMode) {
//     print("Initializing Environment Service...");
//   }
//   final environmentService = EnvironmentService();
//   await environmentService.initialize();
//   if (kDebugMode) {
//     print("Environment Service initialized successfully");
//   }

//   if (kDebugMode) {
//     print("Initializing Firebase Core...");
//   }
//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform, // Uses options from file
//     );
//     if (kDebugMode) {
//       print("Firebase Core initialized successfully");
//     }
//   } catch (e) {
//     if (kDebugMode) {
//       print("!!!!!!!! Firebase Core Initialization FAILED: $e !!!!!!!!");
//     }
//     // Optionally, stop the app or show an error UI if core fails
//     return;
//   }

//  // --- App Check Initialization - FORCED DEBUG PROVIDER ---
//   if (kDebugMode) {
//     print("Attempting Firebase App Check activation (FORCING DEBUG)...");
//   }
//   try {
//     // --- ALWAYS use AppleProvider.debug for this test ---
//     if (kDebugMode) {
//       print("[AppCheck] Forcing AppleProvider.debug for testing.");
//     }
//     await FirebaseAppCheck.instance.activate(
//       appleProvider: AppleProvider.debug, // Force debug provider
//     );
//     // --- If this line is reached, activation itself didn't throw ---
//     if (kDebugMode) {
//       print("[AppCheck] activate() method finished.");
//     }

//     // --- Try attaching listener AFTER activate attempt ---
//     if (kDebugMode) {
//       print("[AppCheck] Attaching onTokenChange listener...");
//     }
//     FirebaseAppCheck.instance.onTokenChange.listen((token) {
//       if (kDebugMode) {
//         print("###########################################################");
//       }
//       if (kDebugMode) {
//         print("[AppCheck] onTokenChange emitted token: ${token ?? 'null'}");
//       }
//       if (kDebugMode) {
//         print("###########################################################");
//       }
//     });
//     if (kDebugMode) {
//       print("[AppCheck] Listener attached.");
//     }

//     // --- Try getting token manually AFTER activate attempt ---
//     if (kDebugMode) {
//       print("[AppCheck] Attempting manual getToken()...");
//     }
//     String? currentToken = await FirebaseAppCheck.instance.getToken(true); // Force refresh
//     if (kDebugMode) {
//       print("[AppCheck] Manual getToken() result: ${currentToken ?? 'null'}");
//     }

//   } catch (e, s) { // Catch stack trace too
//     if (kDebugMode) {
//       print("!!!!!!!! Firebase App Check Activation FAILED: $e !!!!!!!!");
//     }
//     if (kDebugMode) {
//       print("!!!!!!!! Stack Trace: $s !!!!!!!!");
//     } // Log stack trace
//     // Log to Crashlytics if initialized
//     try {
//         CrashReportingService().recordError(
//             Exception("AppCheck Activation Failed: $e"), s,
//             reason: "AppCheck Activation Failure");
//     } catch (crashlyticsError) {
//         if (kDebugMode) {
//           print("Error reporting AppCheck failure to Crashlytics: $crashlyticsError");
//         }
//     }
//   }

//   try {
//     if (kDebugMode) {
//       print("Initializing MLKit...");
//     }
//     await MLKitService.initialize();
//     if (kDebugMode) {
//       print("MLKit initialized successfully");
//     }
//     // ... Barcode scanner init ...
//   } catch (e) {
//     if (kDebugMode) {
//       print("Error during post-AppCheck initialization: $e");
//     }
//     CrashReportingService().recordError(e, StackTrace.current);
//   }

//   await initializeExerciseCache();
//   if (kDebugMode) {
//     print("Exercise cache initialized successfully");
//   }

//   runApp(
//     ProviderScope(
//       overrides: [
//         environmentServiceInitProvider.overrideWith((_) async {
//           return environmentService;
//         }),
//       ],
//       child: const App(),
//     ),
//   );
// }

// Future<void> _requestPermissions() async {
//   // Only request permissions if on iOS
//   if (Platform.isIOS) {
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.notification,
//       Permission.camera,
//     ].request();
//     if (kDebugMode) {
//       print("iOS Permission statuses: $statuses");
//     }
//   } else {
//     if (kDebugMode) {
//       print("Skipping iOS permission request on non-iOS platform.");
//     }
//   }
// }