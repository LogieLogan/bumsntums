// lib/features/ai/providers/workout_generation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workouts/models/workout.dart';
import '../services/openai_service.dart';
import 'ai_service_provider.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

// Define the state class properly
class WorkoutGenerationState {
  final bool isLoading;
  final Map<String, dynamic>? workoutData;
  final String? error;
  final Map<String, dynamic> parameters;

  WorkoutGenerationState({
    this.isLoading = false,
    this.workoutData,
    this.error,
    this.parameters = const {},
  });

  WorkoutGenerationState copyWith({
    bool? isLoading,
    Map<String, dynamic>? workoutData,
    String? error,
    Map<String, dynamic>? parameters,
  }) {
    return WorkoutGenerationState(
      isLoading: isLoading ?? this.isLoading,
      workoutData: workoutData ?? this.workoutData,
      error: error ?? this.error,
      parameters: parameters ?? this.parameters,
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

  // Generate a workout - update to use generateWorkoutRecommendation
  Future<void> generateWorkout({
    required String userId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final params = state.parameters;
      
      // Extract parameters
      final workoutCategory = params['workoutCategory'] ?? 'fullBody';
      final durationMinutes = params['durationMinutes'] ?? 30;
      final focusAreas = params['focusAreas'] ?? ['Full Body'];
      final specialRequest = params['specialRequest'];
      final equipment = params['equipment'];

      // Map params to WorkoutCategory
      WorkoutCategory? category;
      if (workoutCategory is String) {
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
            category = WorkoutCategory.quickWorkout;
            break;
        }
      }

      // Use the correct method name from OpenAIService
      final workoutData = await _openAIService.generateWorkoutRecommendation(
        userId: userId,
        specificRequest: specialRequest,
        category: category,
        maxMinutes: durationMinutes,
      );

      state = state.copyWith(isLoading: false, workoutData: workoutData);

      // Log success
      _analytics.logEvent(
        name: 'workout_generation_success',
        parameters: {
          'user_id': userId,
          'category': workoutCategory,
          'duration': durationMinutes,
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());

      // Log error
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'generateWorkout',
          'userId': userId,
        },
      );
    }
  }

  // Reset the state
  void reset() {
    state = WorkoutGenerationState();
  }
}

// Provider for workout generation
final workoutGenerationProvider = StateNotifierProvider<WorkoutGenerationNotifier, WorkoutGenerationState>((ref) {

  final openAIService = ref.watch(openAIServiceProvider);
  final analytics = AnalyticsService();
  return WorkoutGenerationNotifier(openAIService, analytics);
});