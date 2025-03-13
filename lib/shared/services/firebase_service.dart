// lib/shared/services/firebase_service.dart
import '../analytics/firebase_analytics_service.dart';
import '../analytics/crash_reporting_service.dart';

class FirebaseService {
  final AnalyticsService _analyticsService = AnalyticsService();
  final CrashReportingService _crashReportingService = CrashReportingService();
  
  AnalyticsService get analytics => _analyticsService;
  CrashReportingService get crashlytics => _crashReportingService;

  Future<void> initialize() async {
    // Firebase is already initialized in main.dart
    _analyticsService.initialize();
    await _crashReportingService.initialize();
  }
}