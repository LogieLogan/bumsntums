// lib/shared/config/router.dart
import 'package:bums_n_tums/features/workout_planning/screens/weekly_planning_screen.dart';
import 'package:bums_n_tums/features/workout_planning/screens/workout_scheduling_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/exercise_detail_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/exercise_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../constants/app_constants.dart';
import '../providers/firebase_providers.dart';
import '../navigation/auth_guard.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final firebaseService = ref.read(firebaseServiceProvider);
  List<NavigatorObserver> observers = [];

  // Only add analytics observer if it's available
  final analyticsObserver = firebaseService.analytics.getAnalyticsObserver();
  if (analyticsObserver != null) {
    observers.add(analyticsObserver);
  }

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppConstants.splashRoute,
    observers: observers,
    redirect: (context, state) => checkAuthRedirect(context, state, ref),
    routes: [
      GoRoute(
        path: AppConstants.splashRoute,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.signupRoute,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppConstants.onboardingRoute,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppConstants.homeRoute,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/exercise-library',
        builder: (context, state) => const ExerciseLibraryScreen(),
      ),
      GoRoute(
        path: '/exercise-detail/:id',
        builder: (context, state) {
          final exerciseId = state.pathParameters['id']!;
          // Log analytics event for exercise detail view
          firebaseService.analytics.logEvent(
            name: 'view_exercise_detail',
            parameters: {'exercise_id': exerciseId},
          );
          return ExerciseDetailScreen(exerciseId: exerciseId);
        },
      ),
      GoRoute(
        path: '/workout-planning',
        builder:
            (context, state) => WeeklyPlanningScreen(
              userId: state.uri.queryParameters['userId'] ?? '',
            ),
      ),
      GoRoute(
        path: '/workout-scheduling',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          final scheduledDate = args?['scheduledDate'] as DateTime?;
          final userId = args?['userId'] as String? ?? '';

          return WorkoutSchedulingScreen(
            userId: userId,
            scheduledDate: scheduledDate ?? DateTime.now(),
          );
        },
      ),
    ],
    errorBuilder:
        (context, state) =>
            Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});
