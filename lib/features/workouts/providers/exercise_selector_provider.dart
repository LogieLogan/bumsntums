// lib/features/workouts/providers/exercise_selector_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../services/exercise_db_service.dart';

// State class for the exercise selector
class ExerciseSelectorState {
  final List<Exercise> allExercises;
  final List<Exercise> exercises;
  final String searchQuery;
  final String? filterTargetArea;
  final bool isLoading;
  final String? errorMessage;

  ExerciseSelectorState({
    this.allExercises = const [],
    this.exercises = const [],
    this.searchQuery = '',
    this.filterTargetArea,
    this.isLoading = false,
    this.errorMessage,
  });

  ExerciseSelectorState copyWith({
    List<Exercise>? allExercises,
    List<Exercise>? exercises,
    String? searchQuery,
    String? filterTargetArea,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ExerciseSelectorState(
      allExercises: allExercises ?? this.allExercises,
      exercises: exercises ?? this.exercises,
      searchQuery: searchQuery ?? this.searchQuery,
      filterTargetArea: filterTargetArea,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Provider for the exercise selector
class ExerciseSelectorNotifier extends StateNotifier<ExerciseSelectorState> {
  final ExerciseDBService _exerciseService;

  ExerciseSelectorNotifier(this._exerciseService)
      : super(ExerciseSelectorState());

  // Load all exercises
  Future<void> loadExercises() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final exercises = await _exerciseService.getAllExercises();
      state = state.copyWith(
        allExercises: exercises,
        exercises: exercises,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load exercises: ${e.toString()}',
      );
    }
  }

  // Search exercises by name or description
  void searchExercises(String query) {
    if (state.allExercises.isEmpty) return;

    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  // Filter exercises by target area
  void filterByTargetArea(String? targetArea) {
    state = state.copyWith(filterTargetArea: targetArea);
    _applyFilters();
  }

  // Filter exercises by difficulty level
  void filterByDifficultyLevel(int? difficultyLevel) {
    if (state.allExercises.isEmpty) return;

    if (difficultyLevel == null) {
      _applyFilters();
      return;
    }

    final filtered = state.allExercises.where((exercise) {
      return exercise.difficultyLevel == difficultyLevel;
    }).toList();

    state = state.copyWith(exercises: filtered);
  }

  // Filter exercises by equipment
  void filterByEquipment(String? equipment) {
    if (state.allExercises.isEmpty) return;

    if (equipment == null) {
      _applyFilters();
      return;
    }

    final filtered = state.allExercises.where((exercise) {
      return exercise.equipmentOptions.contains(equipment.toLowerCase());
    }).toList();

    state = state.copyWith(exercises: filtered);
  }

  // Apply all filters (search query and target area)
  void _applyFilters() {
    if (state.allExercises.isEmpty) return;

    var filtered = List<Exercise>.from(state.allExercises);

    // Apply search filter if any
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((exercise) {
        return exercise.name.toLowerCase().contains(query) ||
            exercise.description.toLowerCase().contains(query) ||
            exercise.targetMuscles.any((muscle) => muscle.toLowerCase().contains(query));
      }).toList();
    }

    // Apply target area filter if any
    if (state.filterTargetArea != null && state.filterTargetArea!.isNotEmpty) {
      filtered = filtered.where((exercise) {
        return exercise.targetArea.toLowerCase() == state.filterTargetArea!.toLowerCase();
      }).toList();
    }

    state = state.copyWith(exercises: filtered);
  }
}

// Providers
final exerciseDBServiceProvider = Provider<ExerciseDBService>((ref) {
  return ExerciseDBService();
});

final exerciseSelectorProvider =
    StateNotifierProvider<ExerciseSelectorNotifier, ExerciseSelectorState>((ref) {
  final exerciseService = ref.watch(exerciseDBServiceProvider);
  return ExerciseSelectorNotifier(exerciseService);
});