// lib/features/workouts/services/exercise_service.dart
import '../data/exercise_repository.dart';
import '../models/exercise.dart';

class ExerciseService {
  final ExerciseRepository _repository;
  
  ExerciseService(this._repository);
  
  Future<void> initialize() async {
    await _repository.initialize();
  }
  
  Future<List<Exercise>> getAllExercises() async {
    return _repository.getAllExercises();
  }
  
  Future<Exercise?> getExerciseById(String id) async {
    return _repository.getExerciseById(id);
  }
  
  Future<List<Exercise>> getExercisesByTargetArea(String targetArea) async {
    return _repository.getExercisesByTargetArea(targetArea);
  }
  
  Future<List<Exercise>> getExercisesByDifficulty(int difficultyLevel) async {
    return _repository.getExercisesByDifficulty(difficultyLevel);
  }
  
  Future<List<Exercise>> getExercisesByEquipment(String equipment) async {
    return _repository.getExercisesByEquipment(equipment);
  }
  
  Future<List<Exercise>> filterExercises({
    String? targetArea,
    int? difficultyLevel,
    String? equipment,
    List<String>? targetMuscles,
    bool? hasVideo,
  }) async {
    return _repository.filterExercises(
      targetArea: targetArea,
      difficultyLevel: difficultyLevel,
      equipment: equipment,
      targetMuscles: targetMuscles,
      hasVideo: hasVideo,
    );
  }
  
  Future<List<Exercise>> searchExercises(String query) async {
    return _repository.searchExercises(query);
  }
  
  Future<List<Exercise>> getSimilarExercises(Exercise exercise) async {
    return _repository.getSimilarExercises(exercise);
  }
  
  Future<List<String>> getAvailableTargetAreas() async {
    return _repository.getAvailableTargetAreas();
  }
  
  Future<List<String>> getAvailableEquipment() async {
    return _repository.getAvailableEquipment();
  }
  
  Future<List<String>> getAvailableTargetMuscles() async {
    return _repository.getAvailableTargetMuscles();
  }
  
  Future<Exercise> saveCustomExercise(Exercise exercise) async {
    return _repository.saveCustomExercise(exercise);
  }
}