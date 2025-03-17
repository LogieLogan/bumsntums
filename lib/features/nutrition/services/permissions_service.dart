// lib/features/nutrition/services/permissions_service.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/providers/analytics_provider.dart';
import 'package:flutter/foundation.dart';

class PermissionsService {
  final AnalyticsService _analyticsService;

  PermissionsService({required AnalyticsService analyticsService})
    : _analyticsService = analyticsService;

  Future<bool> requestCameraPermission() async {
    try {
      // First check current status
      debugPrint('Requesting camera permission...');
      
      // Request permission directly
      final status = await Permission.camera.request();
      debugPrint('Camera permission request result: $status');
      
      _analyticsService.logEvent(
        name: 'camera_permission_request',
        parameters: {'status': status.toString()}
      );

      // Double-check the status after a short delay (helps with inconsistent statuses)
      await Future.delayed(const Duration(milliseconds: 500));
      final verifiedStatus = await Permission.camera.status;
      debugPrint('Verified camera permission status: $verifiedStatus');
      
      return verifiedStatus.isGranted;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  Future<bool> hasCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      debugPrint('Checking camera permission, status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking camera permission: $e');
      return false;
    }
  }
  
  Future<bool> isPermanentlyDenied() async {
    try {
      // Get status without requesting
      final status = await Permission.camera.status;
      debugPrint('Checking if camera permission is permanently denied, status: $status');
      
      // On iOS, if the permission was denied before, we need to treat it as
      // permanently denied since the system won't show the prompt again
      if (status.isDenied) {
        // Try to request to see if the prompt appears
        final requestStatus = await Permission.camera.request();
        debugPrint('Probe request status: $requestStatus');
        
        // If status didn't change after request, it's effectively permanently denied
        return requestStatus.isDenied || requestStatus.isPermanentlyDenied;
      }
      
      return status.isPermanentlyDenied;
    } catch (e) {
      debugPrint('Error checking if camera permission is permanently denied: $e');
      return true; // Assume worst case if we can't determine
    }
  }

  Future<bool> openDeviceSettings() async {
    debugPrint('Opening device settings');
    try {
      // This is the fixed line - using the top-level function instead of a method on Permission
      return await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }
}

// Add this provider definition
final permissionsServiceProvider = Provider<PermissionsService>((ref) {
  return PermissionsService(
    analyticsService: ref.watch(analyticsServiceProvider),
  );
});