// lib/shared/constants/app_constants.dart
class AppConstants {
  // API endpoints
  static const String openFoodFactsBaseUrl = 'https://world.openfoodfacts.org/api/v0';
  
  // Local storage keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String onboardingCompletedKey = 'onboarding_completed';
  
  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String onboardingRoute = '/onboarding';
  static const String homeRoute = '/home';
  static const String scannerRoute = '/scanner';
  static const String workoutsRoute = '/workouts';
  static const String workoutDetailRoute = '/workout-detail';
  static const String profileRoute = '/profile';
  
  // Timeouts
  static const int apiTimeoutSeconds = 30;
  
  // Misc
  static const int minPasswordLength = 8;
}