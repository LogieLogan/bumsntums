// lib/shared/analytics/crash_reporting_service.dart - updated code
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  // Change to nullable to avoid late initialization errors
  FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = _crashlytics!.recordFlutterError;
      
      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics!.recordError(error, stack, fatal: true);
        return true;
      };
      
      _isInitialized = true;
      debugPrint('Firebase Crashlytics initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase Crashlytics: $e');
    }
  }

  Future<void> setUserIdentifier(String userId) async {
    if (!_ensureInitialized()) return;
    await _crashlytics!.setUserIdentifier(userId);
  }

  Future<void> log(String message) async {
    if (!_ensureInitialized()) return;
    await _crashlytics!.log(message);
  }

  Future<void> recordError(
    dynamic exception,
    StackTrace stack, {
    dynamic reason,
    Iterable<DiagnosticsNode> information = const [],
    bool fatal = false,
  }) async {
    if (!_ensureInitialized()) {
      // Fall back to debug print if Crashlytics isn't initialized
      debugPrint('ERROR (Crashlytics not initialized): $exception');
      debugPrint('Stack trace: $stack');
      return;
    }
    
    await _crashlytics!.recordError(
      exception,
      stack,
      reason: reason,
      information: information,
      fatal: fatal,
    );
  }
  
  // Helper method to check initialization
  bool _ensureInitialized() {
    if (!_isInitialized || _crashlytics == null) {
      debugPrint('Warning: Trying to use CrashReportingService before initialization');
      return false;
    }
    return true;
  }
}