// lib/features/workouts/data/exercise_repository.dart
import '../models/exercise.dart';

/// Abstract repository interface for accessing exercise data
abstract class ExerciseRepository {
  /// Initialize the repository
  Future<void> initialize();
  
  /// Get all exercises in the database
  Future<List<Exercise>> getAllExercises();
  
  /// Get exercise by its unique ID
  Future<Exercise?> getExerciseById(String id);
  
  /// Get exercises filtered by target area
  Future<List<Exercise>> getExercisesByTargetArea(String targetArea);
  
  /// Get exercises filtered by difficulty level
  Future<List<Exercise>> getExercisesByDifficulty(int difficultyLevel);
  
  /// Get exercises filtered by equipment
  Future<List<Exercise>> getExercisesByEquipment(String equipment);
  
  /// Search exercises by name or description
  Future<List<Exercise>> searchExercises(String query);
  
  /// Get similar exercises based on target area and muscles
  Future<List<Exercise>> getSimilarExercises(Exercise exercise);
  
  /// Get all available target areas
  Future<List<String>> getAvailableTargetAreas();
  
  /// Get all available equipment types
  Future<List<String>> getAvailableEquipment();
  
  /// Get all available target muscles
  Future<List<String>> getAvailableTargetMuscles();
  
  /// Advanced filtering with multiple criteria
  Future<List<Exercise>> filterExercises({
    String? targetArea,
    int? difficultyLevel,
    String? equipment,
    List<String>? targetMuscles,
    bool? hasVideo,
  });
  
  /// Save a custom exercise
  Future<Exercise> saveCustomExercise(Exercise exercise);
}