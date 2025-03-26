// lib/features/workouts/providers/workout_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/workout_repository.dart';
import '../services/exercise_db_service.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final exerciseService = ExerciseDBService();
  
  return WorkoutRepository(
    exerciseService: exerciseService,
  );
});