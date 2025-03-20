// lib/shared/navigation/auth_guard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/user_provider.dart';
import '../constants/app_constants.dart';
import '../analytics/firebase_analytics_service.dart';

// Function to handle redirect logic
String? checkAuthRedirect(BuildContext context, GoRouterState state, Ref ref) {
  final analytics = AnalyticsService();
  final user = ref.read(authStateProvider).value;
  final currentPath = state.uri.path;

  // Skip redirect for splash screen
  if (currentPath == AppConstants.splashRoute) {
    return null;
  }

  // If not logged in and not on login/signup screen, redirect to login
  if (user == null &&
      currentPath != AppConstants.loginRoute &&
      currentPath != AppConstants.signupRoute) {
    analytics.logEvent(
      name: 'redirect_to_login',
      parameters: {'from': currentPath},
    );
    return AppConstants.loginRoute;
  }

  // If logged in but on login/signup screen, redirect to home or onboarding
  if (user != null &&
      (currentPath == AppConstants.loginRoute ||
          currentPath == AppConstants.signupRoute)) {
    final userProfileAsync = ref.read(userProfileProvider);

    // Wait for profile data before deciding
    if (userProfileAsync is AsyncLoading) {
      return null;
    }

    final profile = userProfileAsync.value;
    if (profile == null || !profile.onboardingCompleted) {
      print("User needs onboarding, redirecting from $currentPath");
      analytics.logEvent(
        name: 'redirect_to_onboarding',
        parameters: {'from': currentPath},
      );
      return AppConstants.onboardingRoute;
    } else {
      print(
        "User onboarding complete, redirecting to home from $currentPath",
      );
      analytics.logEvent(
        name: 'redirect_to_home',
        parameters: {'from': currentPath},
      );
      return AppConstants.homeRoute;
    }
  }

  // If logged in, check if onboarding needed (except if already on onboarding)
  if (user != null && currentPath != AppConstants.onboardingRoute) {
    final userProfileAsync = ref.read(userProfileProvider);

    // Don't redirect during loading
    if (userProfileAsync is AsyncLoading) {
      return null;
    }

    final profile = userProfileAsync.value;
    if (profile == null || !profile.onboardingCompleted) {
      print("Onboarding needed, redirecting from $currentPath");
      analytics.logEvent(
        name: 'redirect_to_onboarding',
        parameters: {'from': currentPath},
      );
      return AppConstants.onboardingRoute;
    } else if (currentPath == AppConstants.onboardingRoute &&
        profile.onboardingCompleted) {
      // If we're on onboarding but already completed it, go to home
      print("Onboarding already complete, redirecting to home");
      analytics.logEvent(
        name: 'redirect_to_home',
        parameters: {'from': currentPath},
      );
      return AppConstants.homeRoute;
    }
  }

  return null;
}