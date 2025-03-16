// lib/shared/navigation/navigation.dart
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../config/router.dart';

class AppNavigation {
  static void goToLogin() {
    // Use GoRouter's context-independent navigation
    navigatorKey.currentContext?.let((context) => 
      GoRouter.of(context).go(AppConstants.loginRoute));
  }
  
  static void goToSignup() {
    navigatorKey.currentContext?.let((context) => 
      GoRouter.of(context).go(AppConstants.signupRoute));
  }
  
  static void goToHome() {
    navigatorKey.currentContext?.let((context) => 
      GoRouter.of(context).go(AppConstants.homeRoute));
  }
  
  static void goToOnboarding() {
    navigatorKey.currentContext?.let((context) => 
      GoRouter.of(context).go(AppConstants.onboardingRoute));
  }
  
  static void goBack() {
    navigatorKey.currentContext?.let((context) => 
      GoRouter.of(context).pop());
  }
}

// Helper extension for null safety
extension LetExtension<T> on T? {
  R let<R>(R Function(T) block) {
    if (this != null) {
      return block(this as T);
    }
    throw Exception("Receiver is null");
  }
}