// lib/features/workouts/providers/workout_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../services/workout_service.dart';
import '../../../shared/providers/analytics_provider.dart';

// Core providers
final workoutServiceProvider = Provider<WorkoutService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return WorkoutService(analytics);
});

// Workout data providers
final allWorkoutsProvider = FutureProvider<List<Workout>>((ref) async {
  final workoutService = ref.watch(workoutServiceProvider);
  return workoutService.getAllWorkouts();
});

final featuredWorkoutsProvider = FutureProvider<List<Workout>>((ref) async {
  final workoutService = ref.watch(workoutServiceProvider);
  return workoutService.getFeaturedWorkouts();
});

final workoutsByCategoryProvider = FutureProvider.family<List<Workout>, WorkoutCategory>((ref, category) async {
  final workoutService = ref.watch(workoutServiceProvider);
  return workoutService.getWorkoutsByCategory(category);
});

final workoutsByDifficultyProvider = FutureProvider.family<List<Workout>, WorkoutDifficulty>((ref, difficulty) async {
  final workoutService = ref.watch(workoutServiceProvider);
  return workoutService.getWorkoutsByDifficulty(difficulty);
});

final workoutsByDurationProvider = FutureProvider.family<List<Workout>, ({int min, int max})>((ref, range) async {
  final workoutService = ref.watch(workoutServiceProvider);
  return workoutService.getWorkoutsByDuration(range.min, range.max);
});

final workoutDetailsProvider = FutureProvider.family<Workout?, String>((ref, workoutId) async {
  final workoutService = ref.watch(workoutServiceProvider);
  return workoutService.getWorkoutById(workoutId);
});

final userWorkoutHistoryProvider = FutureProvider.family<List<WorkoutLog>, String>((ref, userId) async {
  final workoutService = ref.watch(workoutServiceProvider);
  return workoutService.getUserWorkoutHistory(userId);
});

final userFavoriteWorkoutsProvider = FutureProvider.family<List<Workout>, String>((ref, userId) async {
  final workoutService = ref.watch(workoutServiceProvider);
  return workoutService.getUserFavoriteWorkouts(userId);
});

final isWorkoutFavoritedProvider = FutureProvider.family<bool, ({String userId, String workoutId})>((ref, params) async {
  final workoutService = ref.watch(workoutServiceProvider);
  return workoutService.isWorkoutFavorited(params.userId, params.workoutId);
});