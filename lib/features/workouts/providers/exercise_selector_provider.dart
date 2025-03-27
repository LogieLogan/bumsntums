// lib/features/workouts/providers/exercise_selector_provider.dart
import 'package:bums_n_tums/features/workouts/services/exercise_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../providers/exercise_providers.dart';

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
      filterTargetArea: filterTargetArea ?? this.filterTargetArea,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Provider for the exercise selector
class ExerciseSelectorNotifier extends StateNotifier<ExerciseSelectorState> {
  final ExerciseService _exerciseService;

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
  void filterByDifficultyLevel(int? difficultyLevel) async {
    if (state.allExercises.isEmpty) return;

    if (difficultyLevel == null) {
      _applyFilters();
      return;
    }

    state = state.copyWith(isLoading: true);
    
    try {
      final filtered = await _exerciseService.getExercisesByDifficulty(difficultyLevel);
      state = state.copyWith(exercises: filtered, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to filter by difficulty: ${e.toString()}',
      );
    }
  }

  // Filter exercises by equipment
  void filterByEquipment(String? equipment) async {
    if (state.allExercises.isEmpty) return;

    if (equipment == null) {
      _applyFilters();
      return;
    }

    state = state.copyWith(isLoading: true);
    
    try {
      final filtered = await _exerciseService.getExercisesByEquipment(equipment);
      state = state.copyWith(exercises: filtered, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to filter by equipment: ${e.toString()}',
      );
    }
  }

  // Apply all filters (search query and target area)
  void _applyFilters() async {
    if (state.allExercises.isEmpty) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      List<Exercise> filtered;
      
      if (state.searchQuery.isNotEmpty) {
        // If there's a search query, use that
        filtered = await _exerciseService.searchExercises(state.searchQuery);
      } else if (state.filterTargetArea != null && state.filterTargetArea!.isNotEmpty) {
        // Otherwise, filter by target area if specified
        filtered = await _exerciseService.getExercisesByTargetArea(state.filterTargetArea!);
      } else {
        // If no filters, use all exercises
        filtered = List<Exercise>.from(state.allExercises);
      }
      
      state = state.copyWith(exercises: filtered, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to apply filters: ${e.toString()}',
      );
    }
  }
}

// Provider that uses our new exercise service
final exerciseSelectorProvider =
    StateNotifierProvider<ExerciseSelectorNotifier, ExerciseSelectorState>((ref) {
  final exerciseService = ref.watch(exerciseServiceProvider);
  return ExerciseSelectorNotifier(exerciseService);
});