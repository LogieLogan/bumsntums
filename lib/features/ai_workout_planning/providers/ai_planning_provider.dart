// lib/features/ai_workout_planning/providers/ai_planning_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_planning_service.dart';
import '../../workouts/services/workout_service.dart';
import '../../ai/providers/openai_provider.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../workout_planning/providers/workout_planning_provider.dart';

// Provider for the AI planning service
final aiPlanningServiceProvider = Provider<AIPlanningService>((ref) {
  final planningRepository = ref.read(workoutPlanningRepositoryProvider);
  final workoutService = WorkoutService(AnalyticsService());
  final openAIService = ref.read(openAIServiceProvider);
  final analyticsService = AnalyticsService();

  return AIPlanningService(
    planningRepository: planningRepository,
    workoutService: workoutService,
    aiService: openAIService,
    analytics: analyticsService,
  );
});

// Simple class for the generation state
class GenerationState {
  final bool isLoading;
  final bool isComplete;
  final String? error;

  GenerationState({
    this.isLoading = false,
    this.isComplete = false,
    this.error,
  });
}

// Notifier class for AI plan generation
class AIPlanNotifier extends StateNotifier<GenerationState> {
  final AIPlanningService _planningService;
  final Ref _ref;

  AIPlanNotifier(this._planningService, this._ref) : super(GenerationState());

  Future<bool> generatePlan({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required int daysPerWeek,
    required List<String> focusAreas,
    required String fitnessLevel,
    String? planName,
    Map<String, dynamic>? additionalParams,
  }) async {
    state = GenerationState(isLoading: true);

    try {
      await _planningService.generateWorkoutPlan(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        daysPerWeek: daysPerWeek,
        focusAreas: focusAreas,
        fitnessLevel: fitnessLevel,
        planName: planName,
        additionalParams: additionalParams,
      );

      // Refresh planning provider to show the new plan
      _ref.invalidate(workoutPlanningNotifierProvider(userId));
      _ref.invalidate(activeWorkoutPlanProvider(userId));

      state = GenerationState(isComplete: true);
      return true;
    } catch (e) {
      print('Error generating AI plan: $e');
      state = GenerationState(error: e.toString());
      return false;
    }
  }
}

// Provider for AI plan generation
final aiPlanNotifierProvider =
    StateNotifierProvider<AIPlanNotifier, GenerationState>((ref) {
      final service = ref.read(aiPlanningServiceProvider);
      return AIPlanNotifier(service, ref);
    });
