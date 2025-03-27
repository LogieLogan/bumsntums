// lib/shared/utils/exercise_reference_utils.dart
import '../../features/workouts/models/exercise.dart';
import '../../features/workouts/data/sources/json_exercise_data_source.dart';

/// Cache of exercises for quick lookup
Map<String, Exercise> _exerciseCache = {};
bool _isInitialized = false;

/// Initialize the exercise cache
Future<void> initializeExerciseCache() async {
  // Skip if already initialized
  if (_isInitialized) return;
  
  try {
    // Load exercises directly from the data source
    final dataSource = JsonExerciseDataSource();
    final exercises = await dataSource.loadExercises();
    
    // Log for debugging
    print('Loaded ${exercises.length} exercises from JSON files');
    
    // Populate cache
    _exerciseCache.clear();
    for (final exercise in exercises) {
      _exerciseCache[exercise.id] = exercise;
    }
    
    _isInitialized = true;
  } catch (e) {
    print('Error initializing exercise cache: $e');
    rethrow;
  }
}

/// Get an exercise by ID for use in workout definitions
Exercise getExerciseById(String id) {
  if (!_isInitialized) {
    throw Exception('Exercise cache not initialized. Call initializeExerciseCache() first.');
  }
  
  final exercise = _exerciseCache[id];
  if (exercise == null) {
    throw Exception('Exercise with ID $id not found in the database. '
        'Make sure the ID is correct and the exercise exists in your JSON files.');
  }
  return exercise;
}