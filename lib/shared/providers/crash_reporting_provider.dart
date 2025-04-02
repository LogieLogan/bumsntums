import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../analytics/crash_reporting_service.dart';

final crashReportingProvider = Provider<CrashReportingService>((ref) {
  final service = CrashReportingService();
  service.initialize();
  return service;
});