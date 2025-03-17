// lib/shared/services/shake_detector_service.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetectorService {
  // Singleton pattern
  static final ShakeDetectorService _instance =
      ShakeDetectorService._internal();
  factory ShakeDetectorService() => _instance;
  ShakeDetectorService._internal();

  // Shake detection parameters
  static const double _accelerationThreshold = 50.0; // sensitivity
  static const int _minTimeBetweenShakes = 1000; // milliseconds
  static const int _shakeSlopTimeMs = 500; // milliseconds for shake to complete

  // Subscription to accelerometer events
  StreamSubscription<AccelerometerEvent>? _subscription;

  // Shake detection state
  DateTime? _lastShakeTime;
  DateTime? _shakeStartTime;

  // Callback for when shake is detected
  VoidCallback? _onShake;

  bool get isListening => _subscription != null;

  void startListening({required VoidCallback onShake}) {
    if (_subscription != null) return;

    _onShake = onShake;
    _lastShakeTime = null;
    _shakeStartTime = null;

    _subscription = accelerometerEvents.listen(_onAccelerometerEvent);
    debugPrint('Shake detector started');
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _onShake = null;
    debugPrint('Shake detector stopped');
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    final double acceleration = _computeAcceleration(event);
    final DateTime now = DateTime.now();

    // Debug log acceleration values occasionally
    if (DateTime.now().millisecondsSinceEpoch % 3000 < 10) {
      // Log roughly every second
      debugPrint(
        'Acceleration: $acceleration (threshold: $_accelerationThreshold)',
      );
    }

    // Check if acceleration exceeds threshold
    if (acceleration > _accelerationThreshold) {
      debugPrint('Threshold exceeded! Acceleration: $acceleration');
      final bool notTooFrequent =
          _lastShakeTime == null ||
          now.difference(_lastShakeTime!).inMilliseconds >
              _minTimeBetweenShakes;

      if (notTooFrequent) {
        _shakeStartTime = now;
        debugPrint('Shake start registered at ${now.toString()}');
      }
    }

    // Check if shake completed in the right time window
    if (_shakeStartTime != null) {
      final timeSinceShakeStarted =
          now.difference(_shakeStartTime!).inMilliseconds;

      if (timeSinceShakeStarted > _shakeSlopTimeMs) {
        // Reset shake start time
        _shakeStartTime = null;

        // If we haven't had a shake recently, report it
        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!).inMilliseconds >
                _minTimeBetweenShakes) {
          _lastShakeTime = now;
          debugPrint('SHAKE DETECTED! Calling callback.');
          _onShake?.call();
        }
      }
    }
  }

double _computeAcceleration(AccelerometerEvent event) {
  // Calculate change in acceleration, accounting for gravity (9.8 m/s²)
  const double gravity = 9.8;
  final double x = event.x;
  final double y = event.y;
  final double z = event.z - gravity; // Remove gravity from z-axis
  
  // Use magnitude of acceleration vector
  return sqrt(x * x + y * y + z * z);
}

}
