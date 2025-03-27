// lib/features/workouts/data/local_exercise_repository.dart
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import 'exercise_repository.dart';
import 'sources/exercise_data_source.dart';
import '../../../shared/services/exercise_media_service.dart';

class LocalExerciseRepository implements ExerciseRepository {
  final ExerciseDataSource _dataSource;
  
  List<Exercise> _exercises = [];
  Map<String, List<Exercise>> _exercisesByCategory = {};
  Map<String, List<Exercise>> _exercisesByEquipment = {};
  Map<int, List<Exercise>> _exercisesByDifficulty = {};
  Set<String> _targetAreas = {};
  Set<String> _equipmentTypes = {};
  Set<String> _targetMuscles = {};
  
  bool _isInitialized = false;
  
  LocalExerciseRepository(this._dataSource);
  
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadExercises();
    _categorizeExercises();
    _isInitialized = true;
  }
  
  Future<void> _loadExercises() async {
    _exercises = await _dataSource.loadExercises();
    
    // Check for video paths for each exercise
    for (int i = 0; i < _exercises.length; i++) {
      final exercise = _exercises[i];
      if (exercise.videoPath == null) {
        final videoPath = await ExerciseMediaService.findVideoForExercise(exercise.name);
        if (videoPath != null) {
          _exercises[i] = exercise.copyWith(videoPath: videoPath);
        }
      }
    }
  }
  
  void _categorizeExercises() {
    // Clear existing maps
    _exercisesByCategory = {};
    _exercisesByEquipment = {};
    _exercisesByDifficulty = {};
    _targetAreas = {};
    _equipmentTypes = {};
    _targetMuscles = {};
    
    // Categorize each exercise
    for (final exercise in _exercises) {
      // By target area
      final category = exercise.targetArea.toLowerCase();
      if (!_exercisesByCategory.containsKey(category)) {
        _exercisesByCategory[category] = [];
      }
      _exercisesByCategory[category]!.add(exercise);
      _targetAreas.add(exercise.targetArea);
      
      // By equipment
      for (final equipment in exercise.equipmentOptions) {
        final equipmentKey = equipment.toLowerCase();
        if (!_exercisesByEquipment.containsKey(equipmentKey)) {
          _exercisesByEquipment[equipmentKey] = [];
        }
        _exercisesByEquipment[equipmentKey]!.add(exercise);
        _equipmentTypes.add(equipment);
      }
      
      // By difficulty level
      final difficultyKey = exercise.difficultyLevel;
      if (!_exercisesByDifficulty.containsKey(difficultyKey)) {
        _exercisesByDifficulty[difficultyKey] = [];
      }
      _exercisesByDifficulty[difficultyKey]!.add(exercise);
      
      // Collect all target muscles
      for (final muscle in exercise.targetMuscles) {
        _targetMuscles.add(muscle);
      }
    }
  }
  
  @override
  Future<List<Exercise>> getAllExercises() async {
    if (!_isInitialized) await initialize();
    return _exercises;
  }
  
  @override
  Future<Exercise?> getExerciseById(String id) async {
    if (!_isInitialized) await initialize();
    
    try {
      return _exercises.firstWhere((exercise) => exercise.id == id);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<Exercise>> getExercisesByTargetArea(String targetArea) async {
    if (!_isInitialized) await initialize();
    
    final key = targetArea.toLowerCase();
    return _exercisesByCategory[key] ?? [];
  }
  
  @override
  Future<List<Exercise>> getExercisesByDifficulty(int difficultyLevel) async {
    if (!_isInitialized) await initialize();
    
    return _exercisesByDifficulty[difficultyLevel] ?? [];
  }
  
  @override
  Future<List<Exercise>> getExercisesByEquipment(String equipment) async {
    if (!_isInitialized) await initialize();
    
    final key = equipment.toLowerCase();
    return _exercisesByEquipment[key] ?? [];
  }
  
  @override
  Future<List<Exercise>> filterExercises({
    String? targetArea,
    int? difficultyLevel,
    String? equipment,
    List<String>? targetMuscles,
    bool? hasVideo,
  }) async {
    if (!_isInitialized) await initialize();
    
    return _exercises.where((exercise) {
      // Filter by target area if specified
      if (targetArea != null && 
          exercise.targetArea.toLowerCase() != targetArea.toLowerCase()) {
        return false;
      }
      
      // Filter by difficulty level if specified
      if (difficultyLevel != null && 
          exercise.difficultyLevel != difficultyLevel) {
        return false;
      }
      
      // Filter by equipment if specified
      if (equipment != null && 
          !exercise.equipmentOptions.any(
            (e) => e.toLowerCase() == equipment.toLowerCase()
          )) {
        return false;
      }
      
      // Filter by target muscles if specified
      if (targetMuscles != null && targetMuscles.isNotEmpty) {
        final hasTargetMuscle = exercise.targetMuscles.any(
          (muscle) => targetMuscles.any(
            (filter) => muscle.toLowerCase().contains(filter.toLowerCase())
          )
        );
        if (!hasTargetMuscle) {
          return false;
        }
      }
      
      // Filter by video availability if specified
      if (hasVideo == true && exercise.videoPath == null) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  @override
  Future<List<Exercise>> searchExercises(String query) async {
    if (!_isInitialized) await initialize();
    
    if (query.isEmpty) {
      return _exercises;
    }
    
    final lowerQuery = query.toLowerCase();
    return _exercises.where((exercise) {
      return exercise.name.toLowerCase().contains(lowerQuery) ||
             exercise.description.toLowerCase().contains(lowerQuery) ||
             exercise.targetMuscles.any(
               (muscle) => muscle.toLowerCase().contains(lowerQuery)
             ) ||
             exercise.targetArea.toLowerCase().contains(lowerQuery);
    }).toList();
  }
  
  @override
  Future<List<Exercise>> getSimilarExercises(Exercise exercise) async {
    if (!_isInitialized) await initialize();
    
    // First attempt: find exercises with same target area AND common muscles
    final primaryMatches = _exercises.where((e) {
      // Skip the original exercise
      if (e.id == exercise.id) return false;
      
      // Check for same target area (case-insensitive)
      if (e.targetArea.toLowerCase() != exercise.targetArea.toLowerCase()) 
        return false;
      
      // Check for at least one common target muscle
      final hasCommonMuscle = e.targetMuscles.any(
        (muscle) => exercise.targetMuscles.any(
          (m) => m.toLowerCase() == muscle.toLowerCase()
        )
      );
      
      return hasCommonMuscle;
    }).toList();
    
    // If we found enough exercises with strict criteria, return them
    if (primaryMatches.length >= 3) {
      return primaryMatches;
    }
    
    // Fallback: find exercises with same target area only
    final fallbackMatches = _exercises.where((e) {
      // Skip the original exercise and already matched exercises
      if (e.id == exercise.id || primaryMatches.any((m) => m.id == e.id)) 
        return false;
      
      // Match by target area only (case-insensitive)
      return e.targetArea.toLowerCase() == exercise.targetArea.toLowerCase();
    }).toList();
    
    // Combine both match types, with primary matches first
    return [...primaryMatches, ...fallbackMatches];
  }
  
  @override
  Future<List<String>> getAvailableTargetAreas() async {
    if (!_isInitialized) await initialize();
    return _targetAreas.toList()..sort();
  }
  
  @override
  Future<List<String>> getAvailableEquipment() async {
    if (!_isInitialized) await initialize();
    return _equipmentTypes.toList()..sort();
  }
  
  @override
  Future<List<String>> getAvailableTargetMuscles() async {
    if (!_isInitialized) await initialize();
    return _targetMuscles.toList()..sort();
  }
  
  @override
  Future<Exercise> saveCustomExercise(Exercise exercise) async {
    if (!_isInitialized) await initialize();
    
    // Generate an ID if needed
    final newExercise = exercise.copyWith(
      id: exercise.id.isNotEmpty ? exercise.id : 'custom-${const Uuid().v4()}',
    );
    
    // Add to our local list if it's a new exercise
    if (!_exercises.any((e) => e.id == newExercise.id)) {
      _exercises.add(newExercise);
    } else {
      // Replace existing exercise
      final index = _exercises.indexWhere((e) => e.id == newExercise.id);
      _exercises[index] = newExercise;
    }
    
    // Recategorize exercises
    _categorizeExercises();
    
    return newExercise;
  }
}