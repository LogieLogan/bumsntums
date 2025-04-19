// lib/features/ai_workout_creation/provider/workout_generation_provider.dart
import 'package:flutter/foundation.dart'; // Use foundation for debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bums_n_tums/features/workouts/models/workout.dart';
// Import the abstract AIService and its provider
import 'package:bums_n_tums/features/ai/services/ai_service.dart';
import 'package:bums_n_tums/features/ai/providers/ai_service_provider.dart';
// Import shared providers
import 'package:bums_n_tums/shared/providers/analytics_provider.dart';
import 'package:bums_n_tums/shared/analytics/firebase_analytics_service.dart'; // Keep if AnalyticsService is defined here

// State class remains the same
class WorkoutGenerationState {
  final bool isLoading;
  final Map<String, dynamic>? workoutData;
  final String? error;
  final Map<String, dynamic> parameters;
  final List<Map<String, dynamic>> refinementHistory;
  final String? changesSummary;
  final String? originalRequest;

  WorkoutGenerationState({
    this.isLoading = false,
    this.workoutData,
    this.error,
    this.parameters = const {},
    this.refinementHistory = const [],
    this.changesSummary,
    this.originalRequest,
  });

  // Add clear flags for convenience
  WorkoutGenerationState copyWith({
    bool? isLoading,
    Map<String, dynamic>? workoutData,
    String? error,
    Map<String, dynamic>? parameters,
    List<Map<String, dynamic>>? refinementHistory,
    String? changesSummary,
    String? originalRequest,
    bool clearError = false,
    bool clearChangesSummary = false,
    bool clearWorkoutData = false,
  }) {
    return WorkoutGenerationState(
      isLoading: isLoading ?? this.isLoading,
      workoutData: clearWorkoutData ? null : workoutData ?? this.workoutData,
      error: clearError ? null : error ?? this.error,
      parameters: parameters ?? this.parameters,
      refinementHistory: refinementHistory ?? this.refinementHistory,
      changesSummary:
          clearChangesSummary ? null : changesSummary ?? this.changesSummary,
      originalRequest: originalRequest ?? this.originalRequest,
    );
  }

  WorkoutGenerationState updateParameters(Map<String, dynamic> newParams) {
    final updatedParams = Map<String, dynamic>.from(parameters)
      ..addAll(newParams);
    return copyWith(parameters: updatedParams);
  }
}

// Update Notifier to depend on AIService
class WorkoutGenerationNotifier extends StateNotifier<WorkoutGenerationState> {
  // Use the abstract AIService interface
  final AIService _aiService;
  final AnalyticsService _analytics;

  // Update constructor signature
  WorkoutGenerationNotifier(this._aiService, this._analytics)
    : super(WorkoutGenerationState());

  // --- setParameters method remains the same ---
  void setParameters({
    required String workoutCategory,
    required int durationMinutes,
    required List<String> focusAreas,
    String? specialRequest,
    List<String>? equipment,
    Map<String, dynamic>? consultationResponses,
  }) {
    // Reset state except parameters when setting new ones
    state = WorkoutGenerationState().updateParameters({
      'workoutCategory': workoutCategory,
      'durationMinutes': durationMinutes,
      'focusAreas': focusAreas,
      if (specialRequest != null && specialRequest.isNotEmpty)
        'specialRequest': specialRequest,
      if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
      if (consultationResponses != null && consultationResponses.isNotEmpty)
        'consultationResponses': consultationResponses,
    });
    _analytics.logEvent(
      name: 'workout_gen_params_set',
      parameters: {
        'category': workoutCategory,
        'duration': durationMinutes,
        'focus_areas_count': focusAreas.length,
        'equipment_count': equipment?.length ?? 0,
        'has_consultation':
            (consultationResponses != null && consultationResponses.isNotEmpty)
                .toString(),
      },
    );
  }

  // --- updateParameter method remains the same ---
  void updateParameter(String key, dynamic value) {
    state = state.updateParameters({key: value});
    _analytics.logEvent(
      name: 'workout_gen_param_updated',
      parameters: {'key': key},
    );
  }

  // --- generateWorkout method updated to use _aiService ---
  Future<void> generateWorkout({
    required String userId,
    Map<String, dynamic>? userProfileData,
  }) async {
    debugPrint("WorkoutGenerationNotifier: generateWorkout method entered.");
    // Reset state before generation, keep parameters
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearChangesSummary: true,
      clearWorkoutData: true,
      refinementHistory: [], // Clear history on new generation
    );

    final params = state.parameters;

    try {
      // Extract profile data safely
      final String? userFitnessLevel =
          userProfileData?['fitnessLevel'] as String?;
      final int? userAge = userProfileData?['age'] as int?;
      final List<String>? userGoals =
          (userProfileData?['goals'] as List?)?.whereType<String>().toList();
      final String? userPreferredLocation =
          userProfileData?['preferredLocation'] as String?;
      final List<String>? userHealthConditions =
          (userProfileData?['healthConditions'] as List?)
              ?.whereType<String>()
              .toList();

      // Extract workout parameters safely
      final workoutCategoryStr =
          params['workoutCategory'] as String? ?? 'fullBody';
      final durationMinutes = params['durationMinutes'] as int? ?? 30;
      final focusAreas =
          (params['focusAreas'] as List?)?.whereType<String>().toList() ??
          ['Overall Fitness'];
      final specialRequest = params['specialRequest'] as String?;
      final equipment =
          (params['equipment'] as List?)?.whereType<String>().toList() ?? [];
      final consultationResponses =
          params['consultationResponses'] as Map<String, dynamic>?;

      final WorkoutCategory category = WorkoutCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == workoutCategoryStr.toLowerCase(),
        orElse: () => WorkoutCategory.fullBody,
      );

      final requestDesc =
          "Create a ${category.name} workout for $durationMinutes min. Focus: ${focusAreas.join(', ')}. Equip: ${equipment.isEmpty ? 'bodyweight' : equipment.join(', ')}. ${specialRequest != null ? 'Req: $specialRequest' : ''}";

      _analytics.logEvent(
        name: 'workout_generation_started',
        parameters: {
          'user_id': userId,
          'category': category.name,
          'duration': durationMinutes,
          'ai_service': _aiService.runtimeType.toString(),
        },
      );

      debugPrint(
        "WorkoutGenerationNotifier: Calling _aiService.generateWorkoutRecommendation...",
      );
      // --- Use the abstract _aiService ---
      final workoutData = await _aiService.generateWorkoutRecommendation(
        userId: userId,
        category: category,
        maxMinutes: durationMinutes,
        equipment: equipment,
        focusAreas: focusAreas,
        specificRequest: specialRequest,
        fitnessLevel: userFitnessLevel,
        age: userAge,
        goals: userGoals,
        preferredLocation: userPreferredLocation,
        healthConditions: userHealthConditions,
        consultationResponses: consultationResponses,
      );
      // --- End Use the abstract _aiService ---

      state = state.copyWith(
        isLoading: false,
        workoutData: workoutData,
        originalRequest: requestDesc,
      );

      _analytics.logEvent(
        name: 'workout_generation_success',
        parameters: {
          'user_id': userId,
          'category': category.name,
          'duration': workoutData['durationMinutes'] ?? durationMinutes,
          'exercise_count': _countExercises(workoutData),
          'ai_service': _aiService.runtimeType.toString(),
        },
      );
    } catch (e, stackTrace) {
      final errorMessage = 'Workout generation failed: ${e.toString()}';
      state = state.copyWith(isLoading: false, error: errorMessage);
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'generateWorkout',
          'userId': userId,
          'params_keys': params.keys.join(
            ',',
          ), // Log keys instead of full params
          'ai_service': _aiService.runtimeType.toString(),
        },
      );
    }
  }

  // --- refineWorkout method updated to use _aiService ---
  Future<void> refineWorkout({
    required String userId,
    required String refinementRequest,
  }) async {
    if (state.workoutData == null) {
      state = state.copyWith(
        error: 'Cannot refine: No workout has been generated yet.',
      );
      return;
    }
    if (refinementRequest.trim().isEmpty) {
      state = state.copyWith(
        error: 'Cannot refine: Please provide specific feedback.',
      );
      return;
    }

    final currentWorkout = Map<String, dynamic>.from(state.workoutData!);
    final updatedHistory = List<Map<String, dynamic>>.from(
      state.refinementHistory,
    )..add(currentWorkout);

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearChangesSummary: true,
      refinementHistory: updatedHistory,
    );

    try {
      _analytics.logEvent(
        name: 'workout_refinement_started',
        parameters: {
          'user_id': userId,
          'refinement_count': state.refinementHistory.length,
          'ai_service': _aiService.runtimeType.toString(),
        },
      );

      // --- Use the abstract _aiService ---
      final refinedWorkout = await _aiService.refineWorkout(
        userId: userId,
        originalWorkout: currentWorkout,
        refinementRequest: refinementRequest,
        originalRequest: state.originalRequest,
      );
      // --- End Use the abstract _aiService ---

      String? changesSummary = refinedWorkout['changesSummary'] as String?;

      state = state.copyWith(
        isLoading: false,
        workoutData: refinedWorkout,
        changesSummary: changesSummary ?? 'Workout refined (summary missing).',
      );

      _analytics.logEvent(
        name: 'workout_refinement_success',
        parameters: {
          'user_id': userId,
          'refinement_count': state.refinementHistory.length,
          'exercise_count': _countExercises(refinedWorkout),
          'ai_service': _aiService.runtimeType.toString(),
        },
      );
    } catch (e, stackTrace) {
      final errorMessage = 'Workout refinement failed: ${e.toString()}';
      // Revert to the previous state on failure
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        workoutData: currentWorkout, // Revert data
        refinementHistory: List<Map<String, dynamic>>.from(
          state.refinementHistory,
        )..removeLast(), // Remove added history state
        clearChangesSummary: true,
      );
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'refineWorkout',
          'userId': userId,
          'refinementRequest_length': refinementRequest.length,
          'refinement_count': state.refinementHistory.length,
          'ai_service': _aiService.runtimeType.toString(),
        },
      );
    }
  }

  // --- undoRefinement method remains the same ---
  void undoRefinement() {
    if (state.refinementHistory.isEmpty) return;

    final previousWorkoutData = state.refinementHistory.last;
    final updatedHistory = List<Map<String, dynamic>>.from(
      state.refinementHistory,
    )..removeLast();

    state = state.copyWith(
      workoutData: previousWorkoutData,
      refinementHistory: updatedHistory,
      changesSummary: 'Reverted to previous version.',
      clearError: true,
    );

    _analytics.logEvent(
      name: 'workout_refinement_undo',
      parameters: {'remaining_history_count': updatedHistory.length},
    );
  }

  // --- reset method remains the same ---
  void reset() {
    state = WorkoutGenerationState();
    _analytics.logEvent(name: 'workout_generation_reset');
  }

  // --- _countExercises helper remains the same ---
  int _countExercises(Map<String, dynamic>? workoutData) {
    if (workoutData == null ||
        workoutData['sections'] == null ||
        !(workoutData['sections'] is List)) {
      return 0;
    }
    int count = 0;
    try {
      final sections = workoutData['sections'] as List;
      for (final section in sections) {
        if (section is Map && section['exercises'] is List) {
          count += (section['exercises'] as List).length;
        }
      }
    } catch (e) {
      debugPrint("Error counting exercises: $e");
    }
    return count;
  }
}

final workoutGenerationProvider = StateNotifierProvider.autoDispose<
  WorkoutGenerationNotifier,
  WorkoutGenerationState
>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  final analytics = ref.watch(analyticsServiceProvider);

  return WorkoutGenerationNotifier(aiService, analytics);
});
