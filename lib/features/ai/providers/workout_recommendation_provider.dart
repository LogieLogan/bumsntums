// lib/features/ai/providers/workout_recommendation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/workouts/models/workout.dart';
import 'openai_provider.dart';
import '../services/openai_service.dart';

// State for workout recommendation
class WorkoutRecommendationState {
  final bool isLoading;
  final Map<String, dynamic>? workoutData;
  final String? error;

  WorkoutRecommendationState({
    this.isLoading = false,
    this.workoutData,
    this.error,
  });

  WorkoutRecommendationState copyWith({
    bool? isLoading,
    Map<String, dynamic>? workoutData,
    String? error,
  }) {
    return WorkoutRecommendationState(
      isLoading: isLoading ?? this.isLoading,
      workoutData: workoutData ?? this.workoutData,
      error: error ?? this.error,
    );
  }
}

// Notifier for workout recommendation
class WorkoutRecommendationNotifier
    extends StateNotifier<WorkoutRecommendationState> {
  final OpenAIService _openAIService;

  WorkoutRecommendationNotifier(this._openAIService)
    : super(WorkoutRecommendationState());

  Future<void> generateWorkout({
    required String userId,
    String? specificRequest,
    WorkoutCategory? category,
    int? maxMinutes,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final workoutData = await _openAIService.generateWorkoutRecommendation(
        userId: userId,
        specificRequest: specificRequest,
        category: category,
        maxMinutes: maxMinutes,
      );

      state = state.copyWith(isLoading: false, workoutData: workoutData);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = WorkoutRecommendationState();
  }
}

// Provider for workout recommendation
final workoutRecommendationProvider = StateNotifierProvider<
  WorkoutRecommendationNotifier,
  WorkoutRecommendationState
>((ref) {
  final openAIService = ref.watch(openAIServiceProvider);
  return WorkoutRecommendationNotifier(openAIService);
});
