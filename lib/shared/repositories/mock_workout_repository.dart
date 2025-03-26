// lib/shared/repositories/mock_workout_repository.dart
import 'package:uuid/uuid.dart';
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
  
  // Get quick workouts (under 20 minutes)
  List<Workout> getQuickWorkouts() {
    return getAllWorkouts()
        .where((w) => w.durationMinutes <= 20)
        .toList();
  }
  
  // Get workouts that use specific equipment
  List<Workout> getWorkoutsByEquipment(String equipment) {
    return getAllWorkouts()
        .where((w) => w.equipment.contains(equipment.toLowerCase()))
        .toList();
  }
  
  // Get workouts with accessibility options
  List<Workout> getAccessibleWorkouts() {
    return getAllWorkouts()
        .where((w) => w.hasAccessibilityOptions)
        .toList();
  }
}