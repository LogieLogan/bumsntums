// lib/shared/constants/app_constants.dart
class AppConstants {
  // API endpoints
  static const String openFoodFactsBaseUrl =
      'https://world.openfoodfacts.org/api/v0';

  // Local storage keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String foodScanHistoryKey = 'food_scan_history';
  static const String dailyScanCountKey = 'daily_scan_count';
  static const String lastScanDateKey = 'last_scan_date';

  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String onboardingRoute = '/onboarding';
  static const String homeRoute = '/home';
  static const String scannerRoute = '/scanner';
  static const String workoutsRoute = '/workouts';
  static const String workoutDetailRoute = '/workout-detail';
  static const String customWorkoutsRoute = '/custom-workouts';
  static const String workoutCalendarRoute = '/workout-calendar';
  static const String workoutAnalyticsRoute = '/workout-analytics';
  static const String profileRoute = '/profile';

  // Food scanner routes
  static const String foodScannerRoute = '/food-scanner';
  static const String foodDetailsRoute = '/food-details';
  static const String foodHistoryRoute = '/food-history';

  // Timeouts
  static const int apiTimeoutSeconds = 30;

  // Misc
  static const int minPasswordLength = 8;

  // Food scanner constants
  static const int freeTierDailyScanLimit = 5;
  static const int scanHistoryCacheLimit = 50;
  static const String scannerInstructionsText =
      'Align barcode within the frame';
}
