// lib/shared/repositories/mock_workout_repository.dart
import 'mock_data/index.dart';
import '../../features/workouts/models/workout.dart';

class MockWorkoutRepository {
  // Get all workouts
  List<Workout> getAllWorkouts() {
    return MockWorkoutData.getAllWorkouts();
  }
  
  // Get workouts by category
  List<Workout> getWorkoutsByCategory(WorkoutCategory category) {
    return MockWorkoutData.getWorkoutsByCategory(category);
  }
  
  // Get featured workouts
  List<Workout> getFeaturedWorkouts() {
    return MockWorkoutData.getFeaturedWorkouts();
  }
  
  // Get workout by ID
  Workout? getWorkoutById(String id) {
    return MockWorkoutData.getWorkoutById(id);
  }
}