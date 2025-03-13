// lib/shared/navigation/navigation.dart
import '../constants/app_constants.dart';
import '../../shared/config/router.dart';

class AppNavigation {
  static void goToLogin() {
    navigatorKey.currentState?.pushReplacementNamed(AppConstants.loginRoute);
  }
  
  static void goToSignup() {
    navigatorKey.currentState?.pushNamed(AppConstants.signupRoute);
  }
  
  static void goToHome() {
    navigatorKey.currentState?.pushReplacementNamed(AppConstants.homeRoute);
  }
  
  static void goToOnboarding() {
    navigatorKey.currentState?.pushReplacementNamed(AppConstants.onboardingRoute);
  }
  
  static void goBack() {
    navigatorKey.currentState?.pop();
  }
}