// lib/features/workout_analytics/models/workout_analytics_timeframe.dart
enum AnalyticsTimeframe {
  weekly,
  monthly,
  yearly,
}

extension AnalyticsTimeframeExtension on AnalyticsTimeframe {
  String get label {
    switch (this) {
      case AnalyticsTimeframe.weekly:
        return 'Weekly';
      case AnalyticsTimeframe.monthly:
        return 'Monthly';
      case AnalyticsTimeframe.yearly:
        return 'Yearly';
    }
  }
  
  int get days {
    switch (this) {
      case AnalyticsTimeframe.weekly:
        return 7;
      case AnalyticsTimeframe.monthly:
        return 30;
      case AnalyticsTimeframe.yearly:
        return 365;
    }
  }
}