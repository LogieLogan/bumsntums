// lib/features/workouts/providers/exercise_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exercise_repository.dart';
import '../data/local_exercise_repository.dart';
import '../data/sources/exercise_data_source.dart';
import '../data/sources/json_exercise_data_source.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';

// Data source provider
final exerciseDataSourceProvider = Provider<ExerciseDataSource>((ref) {
  return JsonExerciseDataSource();
});

// Repository provider
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final dataSource = ref.watch(exerciseDataSourceProvider);
  return LocalExerciseRepository(dataSource);
});

// Service provider
final exerciseServiceProvider = Provider<ExerciseService>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return ExerciseService(repository);
});

// Various provider for accessing exercise data
final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final service = ref.watch(exerciseServiceProvider);
  await service.initialize();
  return service.getAllExercises();
});

final targetAreasProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(exerciseServiceProvider);
  return service.getAvailableTargetAreas();
});

final equipmentTypesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(exerciseServiceProvider);
  return service.getAvailableEquipment();
});

// Filter parameters class
class FilterParams {
  final String? targetArea;
  final String? equipment;
  final int? difficultyLevel;
  final String? searchQuery;

  const FilterParams({
    this.targetArea,
    this.equipment,
    this.difficultyLevel,
    this.searchQuery,
  });
  
  // For proper object comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterParams &&
      other.targetArea == targetArea &&
      other.equipment == equipment &&
      other.difficultyLevel == difficultyLevel &&
      other.searchQuery == searchQuery;
  }
  
  @override
  int get hashCode {
    return targetArea.hashCode ^
      equipment.hashCode ^
      difficultyLevel.hashCode ^
      searchQuery.hashCode;
  }
}

// Provider for filtered exercises
final filteredExercisesProvider =
    FutureProvider.family<List<Exercise>, FilterParams>((ref, params) async {
  final service = ref.watch(exerciseServiceProvider);
  
  // Make sure the service is initialized
  await service.initialize();
  
  if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
    // If there's a search query, prioritize search results
    return service.searchExercises(params.searchQuery!);
  }
  
  // Otherwise use advanced filtering
  return service.filterExercises(
    targetArea: params.targetArea,
    equipment: params.equipment,
    difficultyLevel: params.difficultyLevel,
  );
});

// Provider for exercise details
final exerciseDetailProvider = FutureProvider.family<Exercise, String>((ref, id) async {
  final service = ref.watch(exerciseServiceProvider);
  final exercise = await service.getExerciseById(id);
  if (exercise == null) {
    throw Exception('Exercise not found: $id');
  }
  return exercise;
});

// Provider for similar exercises
final similarExercisesProvider = FutureProvider.family<List<Exercise>, Exercise>((ref, exercise) async {
  final service = ref.watch(exerciseServiceProvider);
  return service.getSimilarExercises(exercise);
});