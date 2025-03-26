// lib/shared/repositories/mock_data/index.dart
import 'bums_workouts.dart';
import 'tums_workouts.dart';
import 'full_body_workouts.dart';
import 'quick_workouts.dart';
import '../../../features/workouts/models/workout.dart';

class MockWorkoutData {
  // Get all workouts
  static List<Workout> getAllWorkouts() {
    return [
      ...getBumsWorkouts(),
      ...getTumsWorkouts(),
      ...getFullBodyWorkouts(),
      ...getQuickWorkouts(),
    ];
  }
  
  // Get workouts by category
  static List<Workout> getWorkoutsByCategory(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return getBumsWorkouts();
      case WorkoutCategory.tums:
        return getTumsWorkouts();
      case WorkoutCategory.fullBody:
        return getFullBodyWorkouts();
      case WorkoutCategory.quickWorkout:
        return getQuickWorkouts();
      default:
        return [];
    }
  }
  
  // Get featured workouts
  static List<Workout> getFeaturedWorkouts() {
    return getAllWorkouts().where((workout) => workout.featured).toList();
  }
  
  // Get workout by ID
  static Workout? getWorkoutById(String id) {
    try {
      return getAllWorkouts().firstWhere((workout) => workout.id == id);
    } catch (e) {
      return null;
    }
  }
}