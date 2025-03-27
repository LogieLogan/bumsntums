// lib/features/workouts/data/sources/exercise_data_source.dart
import '../../models/exercise.dart';

/// Abstract data source for exercise data
abstract class ExerciseDataSource {
  /// Load all exercises from the data source
  Future<List<Exercise>> loadExercises();
  
  /// Save a custom exercise to the data source
  Future<Exercise> saveExercise(Exercise exercise);
}