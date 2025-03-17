// lib/shared/analytics/firebase_analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  // Singleton instance
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _isInitialized = false;
  FirebaseAnalytics? _analytics;
  
  // Maximum allowed length for Firebase Analytics parameter values
  static const int _maxParamValueLength = 100;

  void initialize() {
    if (_isInitialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _isInitialized = true;
      debugPrint('Firebase Analytics initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase Analytics: $e');
    }
  }

  FirebaseAnalyticsObserver? getAnalyticsObserver() {
    if (_analytics == null) {
      if (!_isInitialized) initialize();
      if (_analytics == null) return null;
    }

    try {
      return FirebaseAnalyticsObserver(analytics: _analytics!);
    } catch (e) {
      debugPrint('Error creating analytics observer: $e');
      return null;
    }
  }

  // Helper method to truncate parameter values
  Map<String, Object>? _sanitizeParameters(Map<String, Object>? parameters) {
    if (parameters == null) return null;
    
    final sanitizedParams = <String, Object>{};
    
    for (final entry in parameters.entries) {
      if (entry.value is String && (entry.value as String).length > _maxParamValueLength) {
        sanitizedParams[entry.key] = 
            '${(entry.value as String).substring(0, _maxParamValueLength - 3)}...';
      } else {
        sanitizedParams[entry.key] = entry.value;
      }
    }
    
    return sanitizedParams;
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (_analytics == null) return;
    try {
      final sanitizedParams = _sanitizeParameters(parameters);
      await _analytics!.logEvent(name: name, parameters: sanitizedParams);
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  Future<void> logSignUp({required String method}) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logSignUp(signUpMethod: method);
    } catch (e) {
      debugPrint('Error logging sign up: $e');
    }
  }

  Future<void> logLogin({required String method}) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Error logging login: $e');
    }
  }

  Future<void> logWorkoutStarted({
    required String workoutId,
    required String workoutName,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: 'workout_started',
        parameters: {'workout_id': workoutId, 'workout_name': workoutName},
      );
    } catch (e) {
      debugPrint('Error logging workout start: $e');
    }
  }

  Future<void> logWorkoutCompleted({
    required String workoutId,
    required String workoutName,
    required int durationSeconds,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: 'workout_completed',
        parameters: {
          'workout_id': workoutId,
          'workout_name': workoutName,
          'duration_seconds': durationSeconds,
        },
      );
    } catch (e) {
      debugPrint('Error logging workout completion: $e');
    }
  }

  Future<void> logFoodScanned({required String barcodeValue}) async {
    if (_analytics == null) return;
    try {
      // Truncate the barcode value if it's too long
      String truncatedBarcode = barcodeValue;
      if (truncatedBarcode.length > _maxParamValueLength) {
        truncatedBarcode = 
            '${truncatedBarcode.substring(0, _maxParamValueLength - 3)}...';
      }
      
      await _analytics!.logEvent(
        name: 'food_scanned',
        parameters: {'barcode_value': truncatedBarcode},
      );
    } catch (e) {
      debugPrint('Error logging food scan: $e');
    }
  }

  void logError({required String error, Map<String, Object>? parameters}) {
    if (_analytics == null) return;
    
    try {
      // Truncate the error message if it's too long
      String truncatedError = error;
      if (truncatedError.length > _maxParamValueLength) {
        truncatedError = 
            '${truncatedError.substring(0, _maxParamValueLength - 3)}...';
      }
      
      final Map<String, Object> errorParams = {'error_message': truncatedError};
      if (parameters != null) {
        errorParams.addAll(_sanitizeParameters(parameters) ?? {});
      }

      _analytics?.logEvent(name: 'app_error', parameters: errorParams);
    } catch (e) {
      debugPrint('Error logging error event: $e');
    }

    // Also log to console for debugging
    print('ERROR: $error');
  }
}