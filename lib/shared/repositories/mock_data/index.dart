import 'bums_workouts.dart';
import 'tums_workouts.dart';
import 'full_body_workouts.dart';
import 'quick_workouts.dart';
import 'cardio_workouts.dart';

import '../../../features/workouts/models/workout.dart';

class MockWorkoutData {
  static List<Workout> getAllWorkouts() {
    return [
      ...getBumsWorkouts(),
      ...getTumsWorkouts(),
      ...getFullBodyWorkouts(),
      ...getQuickWorkouts(),
      ...getCardioWorkouts(),
    ];
  }

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
      case WorkoutCategory.cardio:
        return getCardioWorkouts();

      case WorkoutCategory.arms:
        print(
          "MockWorkoutData: No specific mock data for Arms category yet. Returning empty list.",
        );
        return [];
    }
  }

  static List<Workout> getFeaturedWorkouts() {
    return getAllWorkouts().where((workout) => workout.featured).toList();
  }

  static Workout? getWorkoutById(String id) {
    try {
      return getAllWorkouts().firstWhere((workout) => workout.id == id);
    } catch (e) {
      return null;
    }
  }
}
