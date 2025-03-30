// lib/shared/navigation/navigation.dart
import 'package:bums_n_tums/features/workouts/screens/workout_analytics_screen.dart';
import 'package:bums_n_tums/features/workout_planning/screens/workout_calendar_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/workouts/screens/workout_detail_screen.dart';
import '../../features/workouts/screens/workout_execution_screen.dart';
import '../../features/workouts/screens/workout_editor_screen.dart';
import '../../features/workouts/models/workout.dart';
import '../../features/nutrition/screens/food_details_screen.dart';
import '../../features/nutrition/models/food_item.dart';
import '../../features/ai/screens/ai_chat_screen.dart';
import '../../features/ai/screens/ai_workout_screen.dart';
import '../constants/app_constants.dart';
import '../config/router.dart';

/// Helper class for navigation within the app
class AppNavigation {
  // Context-independent GoRouter navigation
  static void goToLogin() {
    navigatorKey.currentContext?.let(
      (context) => GoRouter.of(context).go(AppConstants.loginRoute),
    );
  }

  static void goToSignup() {
    navigatorKey.currentContext?.let(
      (context) => GoRouter.of(context).go(AppConstants.signupRoute),
    );
  }

  static void goToHome() {
    navigatorKey.currentContext?.let(
      (context) => GoRouter.of(context).go(AppConstants.homeRoute),
    );
  }

  static void goToOnboarding() {
    navigatorKey.currentContext?.let(
      (context) => GoRouter.of(context).go(AppConstants.onboardingRoute),
    );
  }

  static void goBack() {
    navigatorKey.currentContext?.let((context) => GoRouter.of(context).pop());
  }

  // Context-based navigation for feature screens
  /// Navigate to workout details
  static void navigateToWorkoutDetails(BuildContext context, String workoutId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workoutId: workoutId),
      ),
    );
  }

  /// Navigate to workout execution
  /// Note: This method requires a Workout object, not just a workoutId
  static void navigateToWorkoutExecution(
    BuildContext context,
    Workout workout,
  ) {
    // For now, we'll just navigate to the execution screen.
    // In a real implementation, you might need to prepare workout state first
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WorkoutExecutionScreen()),
    );
  }

  /// Navigate to workout editor
  static void navigateToWorkoutEditor(
    BuildContext context, {
    Workout? originalWorkout,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => WorkoutEditorScreen(originalWorkout: originalWorkout),
      ),
    );
  }

  /// Navigate to AI chat
  static void navigateToAIChat(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AIChatScreen()));
  }

  /// Navigate to AI workout creator
  static void navigateToAIWorkout(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AIWorkoutScreen()));
  }

  /// Navigate to food details
  static void navigateToFoodDetails(BuildContext context, FoodItem foodItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FoodDetailsScreen(foodItem: foodItem),
      ),
    );
  }

  static void navigateToWorkoutCalendar(BuildContext context, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutCalendarScreen(userId: userId),
      ),
    );
  }

  /// Navigate to workout analytics
  static void navigateToWorkoutAnalytics(BuildContext context, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkoutAnalyticsScreen(userId: userId),
      ),
    );
  }

  static void navigateToWorkoutHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WorkoutHistoryScreen()),
    );
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
