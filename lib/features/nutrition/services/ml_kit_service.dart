// lib/features/nutrition/services/ml_kit_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MLKitService {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Force MLKit to use a different initialization path
      // This should help with the MLKITx_GIPPseudonymousIDStore errors
      const platform = MethodChannel('com.bumsntums/mlkit');
      await platform.invokeMethod('setMLKitCachingStrategy', {
        'useCustomCaching': true,
      });
      _isInitialized = true;
      debugPrint('MLKit initialization successful');
    } catch (e) {
      debugPrint('Error initializing MLKit: $e');
      // Continue even if this fails - the app may still work
      _isInitialized = true;
    }
  }
}

final mlKitServiceProvider = Provider<MLKitService>((ref) {
  return MLKitService();
});