// lib/features/ai_workout_screen/providers/workout_generation_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workouts/models/workout.dart';
import '../../ai/services/openai_service.dart';
import '../../ai/providers/ai_service_provider.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

// Define the state class properly
class WorkoutGenerationState {
  final bool isLoading;
  final Map<String, dynamic>? workoutData;
  final String? error;
  final Map<String, dynamic> parameters;
  final List<Map<String, dynamic>> refinementHistory;
  final String? changesSummary;
  final String? originalRequest; // Add this field

  WorkoutGenerationState({
    this.isLoading = false,
    this.workoutData,
    this.error,
    this.parameters = const {},
    this.refinementHistory = const [],
    this.changesSummary,
    this.originalRequest, // Add this parameter
  });

  WorkoutGenerationState copyWith({
    bool? isLoading,
    Map<String, dynamic>? workoutData,
    String? error,
    Map<String, dynamic>? parameters,
    List<Map<String, dynamic>>? refinementHistory,
    String? changesSummary,
    String? originalRequest, // Add this parameter
  }) {
    return WorkoutGenerationState(
      isLoading: isLoading ?? this.isLoading,
      workoutData: workoutData ?? this.workoutData,
      error: error ?? this.error,
      parameters: parameters ?? this.parameters,
      refinementHistory: refinementHistory ?? this.refinementHistory,
      changesSummary: changesSummary ?? this.changesSummary,
      originalRequest:
          originalRequest ?? this.originalRequest, // Include it here
    );
  }

  WorkoutGenerationState updateParameters(Map<String, dynamic> newParams) {
    final updatedParams = Map<String, dynamic>.from(parameters);
    updatedParams.addAll(newParams);

    return copyWith(parameters: updatedParams);
  }
}

// Define the notifier class - remove the duplicate declaration
class WorkoutGenerationNotifier extends StateNotifier<WorkoutGenerationState> {
  final OpenAIService _openAIService;
  final AnalyticsService _analytics;

  WorkoutGenerationNotifier(this._openAIService, this._analytics)
    : super(WorkoutGenerationState());

  // Set initial parameters
  void setParameters({
    required String workoutCategory,
    required int durationMinutes,
    required List<String> focusAreas,
    String? specialRequest,
    List<String>? equipment,
  }) {
    state = state.updateParameters({
      'workoutCategory': workoutCategory,
      'durationMinutes': durationMinutes,
      'focusAreas': focusAreas,
      if (specialRequest != null) 'specialRequest': specialRequest,
      if (equipment != null) 'equipment': equipment,
    });
  }

  // Update a parameter
  void updateParameter(String key, dynamic value) {
    state = state.updateParameters({key: value});
  }

  Future<void> generateWorkout({
    required String userId,
    Map<String, dynamic>? userProfileData,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final params = state.parameters;

      // Extract user profile data for better context
      final userFitnessLevel = userProfileData?['fitnessLevel'] ?? 'beginner';
      final userAge = userProfileData?['age'];
      final userGoals = userProfileData?['goals'] as List<String>? ?? [];
      final userPreferredLocation = userProfileData?['preferredLocation'];
      final userHealthConditions =
          userProfileData?['healthConditions'] as List<String>? ?? [];

      // Extract parameters with proper defaults
      final workoutCategory = params['workoutCategory'] ?? 'fullBody';
      final durationMinutes = params['durationMinutes'] ?? 30;

      // Make sure these are properly cast to List<String>
      final List<String> focusAreas;
      if (params['focusAreas'] is List<String>) {
        focusAreas = params['focusAreas'] as List<String>;
      } else if (params['focusAreas'] is List) {
        focusAreas =
            (params['focusAreas'] as List).map((e) => e.toString()).toList();
      } else {
        focusAreas = ['Overall Fitness'];
      }

      final String? specialRequest = params['specialRequest'];

      final List<String> equipment;
      if (params['equipment'] is List<String>) {
        equipment = params['equipment'] as List<String>;
      } else if (params['equipment'] is List) {
        equipment =
            (params['equipment'] as List).map((e) => e.toString()).toList();
      } else {
        equipment = [];
      }

      // Debug
      debugPrint('Generating workout with:');
      debugPrint('Category: $workoutCategory');
      debugPrint('Duration: $durationMinutes minutes');
      debugPrint('Equipment: ${equipment.join(', ')}');
      debugPrint('Special Request: $specialRequest');
      debugPrint('Focus Areas: ${focusAreas.join(', ')}');

      // Map string category to enum
      WorkoutCategory category;
      switch (workoutCategory.toLowerCase()) {
        case 'bums':
          category = WorkoutCategory.bums;
          break;
        case 'tums':
          category = WorkoutCategory.tums;
          break;
        case 'fullbody':
          category = WorkoutCategory.fullBody;
          break;
        case 'cardio':
          category = WorkoutCategory.cardio;
          break;
        case 'quick':
        case 'quickworkout':
          category = WorkoutCategory.quickWorkout;
          break;
        default:
          category = WorkoutCategory.fullBody;
      }

      // Call the service with explicitly passed parameters
      final workoutData = await _openAIService.generateWorkoutRecommendation(
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
        healthConditions:
            userHealthConditions.isNotEmpty ? userHealthConditions : null,
      );

      // Update state
      state = state.copyWith(
        isLoading: false,
        workoutData: workoutData,
        originalRequest:
            'Create a ${category.name} workout for $durationMinutes minutes',
      );

      // Log success
      _analytics.logEvent(
        name: 'workout_generation_success',
        parameters: {
          'user_id': userId,
          'category': category.name,
          'duration': durationMinutes,
          'equipment_count': equipment.length,
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      _analytics.logError(
        error: e.toString(),
        parameters: {'context': 'generateWorkout', 'userId': userId},
      );
    }
  }

  Future<void> refineWorkout({
    required String userId,
    required String refinementRequest,
  }) async {
    try {
      // Must have a workout to refine
      if (state.workoutData == null) {
        throw Exception('No workout to refine');
      }

      state = state.copyWith(
        isLoading: true,
        error: null,
        changesSummary: null,
      );

      // Save current workout to history before refining
      final currentWorkout = state.workoutData!;
      final updatedHistory = List<Map<String, dynamic>>.from(
        state.refinementHistory,
      )..add(currentWorkout);

      // Pass the original request to the OpenAI service
      final refinedWorkout = await _openAIService.refineWorkout(
        userId: userId,
        originalWorkout: currentWorkout,
        refinementRequest: refinementRequest,
        originalRequest: state.originalRequest, // Pass the original request
      );

      // Extract and remove the changes summary if it exists
      String? changesSummary;
      if (refinedWorkout.containsKey('changesSummary')) {
        changesSummary = refinedWorkout['changesSummary'];
        refinedWorkout.remove('changesSummary');
      } else {
        // Generate a basic summary if none provided
        changesSummary = 'Workout refined based on your feedback.';
      }

      state = state.copyWith(
        isLoading: false,
        workoutData: refinedWorkout,
        refinementHistory: updatedHistory,
        changesSummary: changesSummary,
      );

      // Log success
      _analytics.logEvent(
        name: 'workout_refinement_success',
        parameters: {
          'user_id': userId,
          'refinement_request': refinementRequest,
          'refinement_count': updatedHistory.length,
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());

      // Log error
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'refineWorkout',
          'userId': userId,
          'refinementRequest': refinementRequest,
        },
      );
    }
  }

  // Add this method to WorkoutGenerationNotifier
  void undoRefinement() {
    if (state.refinementHistory.isEmpty) {
      return; // Nothing to undo
    }

    // Get the last workout from history
    final previousWorkoutData = state.refinementHistory.last;
    final updatedHistory = List<Map<String, dynamic>>.from(
      state.refinementHistory,
    )..removeLast();

    state = state.copyWith(
      workoutData: previousWorkoutData,
      refinementHistory: updatedHistory,
      changesSummary: 'Reverted to previous version of the workout.',
    );

    // Log undo action
    _analytics.logEvent(
      name: 'workout_refinement_undo',
      parameters: {'remaining_history_count': updatedHistory.length},
    );
  }

  // Reset the state
  void reset() {
    state = WorkoutGenerationState();
  }
}

// Provider for workout generation
final workoutGenerationProvider =
    StateNotifierProvider<WorkoutGenerationNotifier, WorkoutGenerationState>((
      ref,
    ) {
      final openAIService = ref.watch(openAIServiceProvider);
      final analytics = AnalyticsService();
      return WorkoutGenerationNotifier(openAIService, analytics);
    });
