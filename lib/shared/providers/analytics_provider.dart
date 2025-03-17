// lib/shared/providers/analytics_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../analytics/firebase_analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final analytics = AnalyticsService();
  analytics.initialize();
  return analytics;
});