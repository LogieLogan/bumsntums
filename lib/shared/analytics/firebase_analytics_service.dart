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

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
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
      await _analytics!.logEvent(
        name: 'food_scanned',
        parameters: {'barcode_value': barcodeValue},
      );
    } catch (e) {
      debugPrint('Error logging food scan: $e');
    }
  }

  void logError({required String error, Map<String, Object>? parameters}) {
    final Map<String, Object> errorParams = {'error_message': error};
    if (parameters != null) {
      errorParams.addAll(parameters);
    }

    _analytics?.logEvent(name: 'app_error', parameters: errorParams);

    // Also log to console for debugging
    print('ERROR: $error');
  }
}
