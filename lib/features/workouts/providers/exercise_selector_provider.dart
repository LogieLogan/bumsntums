// lib/features/workouts/providers/exercise_selector_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../services/exercise_db_service.dart';
import '../../../shared/repositories/mock_workout_repository.dart';

// State class for exercise selector
class ExerciseSelectorState {
  final List<Exercise> exercises;
  final List<Exercise> filteredExercises;
  final bool isLoading;
  final bool hasApiError;
  final String searchTerm;
  final String? targetArea;

  ExerciseSelectorState({
    this.exercises = const [],
    this.filteredExercises = const [],
    this.isLoading = false,
    this.hasApiError = false,
    this.searchTerm = '',
    this.targetArea,
  });

  ExerciseSelectorState copyWith({
    List<Exercise>? exercises,
    List<Exercise>? filteredExercises,
    bool? isLoading,
    bool? hasApiError,
    String? searchTerm,
    String? targetArea,
  }) {
    return ExerciseSelectorState(
      exercises: exercises ?? this.exercises,
      filteredExercises: filteredExercises ?? this.filteredExercises,
      isLoading: isLoading ?? this.isLoading,
      hasApiError: hasApiError ?? this.hasApiError,
      searchTerm: searchTerm ?? this.searchTerm,
      targetArea: targetArea,
    );
  }
}

class ExerciseSelectorNotifier extends StateNotifier<ExerciseSelectorState> {
  final ExerciseDBService _localService;
  final MockWorkoutRepository _mockRepository;

  ExerciseSelectorNotifier(this._localService, this._mockRepository)
    : super(ExerciseSelectorState());

  Future<void> loadExercises() async {
    state = state.copyWith(isLoading: true);

    // Just load local exercises from mock repository
    final allWorkouts = _mockRepository.getAllWorkouts();
    final localExercises = <Exercise>[];

    // Extract unique exercises from all workouts
    for (final workout in allWorkouts) {
      for (final exercise in workout.exercises) {
        // Check if this exercise is already in our list by ID
        if (!localExercises.any((e) => e.id == exercise.id)) {
          localExercises.add(exercise);
        }
      }
    }

    state = state.copyWith(
      exercises: localExercises,
      filteredExercises: localExercises,
      isLoading: false,
    );
  }

  void searchExercises(String searchTerm) {
    state = state.copyWith(
      searchTerm: searchTerm,
      filteredExercises: _filterExercises(
        state.exercises,
        searchTerm,
        state.targetArea,
      ),
    );
  }

  void filterByTargetArea(String? targetArea) {
    state = state.copyWith(
      targetArea: targetArea,
      filteredExercises: _filterExercises(
        state.exercises,
        state.searchTerm,
        targetArea,
      ),
    );
  }

  List<Exercise> _filterExercises(
    List<Exercise> exercises,
    String searchTerm,
    String? targetArea,
  ) {
    return exercises.where((exercise) {
      // Apply search filter
      final matchesSearch =
          searchTerm.isEmpty ||
          exercise.name.toLowerCase().contains(searchTerm.toLowerCase());

      // Apply target area filter
      final matchesTarget =
          targetArea == null ||
          exercise.targetArea.toLowerCase() == targetArea.toLowerCase();

      return matchesSearch && matchesTarget;
    }).toList();
  }
}

// Simplified providers without environment dependency
final exerciseDBServiceProvider = Provider<ExerciseDBService>((ref) {
  return ExerciseDBService();
});

final mockWorkoutRepositoryProvider = Provider<MockWorkoutRepository>((ref) {
  return MockWorkoutRepository();
});

final exerciseSelectorProvider =
    StateNotifierProvider<ExerciseSelectorNotifier, ExerciseSelectorState>((
      ref,
    ) {
      final localService = ref.watch(exerciseDBServiceProvider);
      final mockRepository = ref.watch(mockWorkoutRepositoryProvider);
      return ExerciseSelectorNotifier(localService, mockRepository);
    });
