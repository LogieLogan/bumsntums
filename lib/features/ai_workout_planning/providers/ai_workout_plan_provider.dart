// lib/features/ai_workout_planning/providers/ai_workout_plan_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_workout_plan_model.dart';
import '../repositories/ai_workout_plan_repository.dart';
import '../models/plan_generation_parameters.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

// Provider to get all AI workout plans for a user
final aiWorkoutPlansProvider = FutureProvider.family<List<AiWorkoutPlan>, String>((ref, userId) async {
  final repository = ref.read(aiWorkoutPlanRepositoryProvider);
  return repository.getAiWorkoutPlans(userId);
});

// State for managing AI plan selection and actions
class AiWorkoutPlanState {
  final bool isLoading;
  final String? errorMessage;
  final List<AiWorkoutPlan> plans;
  final AiWorkoutPlan? selectedPlan;

  AiWorkoutPlanState({
    this.isLoading = false,
    this.errorMessage,
    this.plans = const [],
    this.selectedPlan,
  });

  AiWorkoutPlanState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<AiWorkoutPlan>? plans,
    AiWorkoutPlan? selectedPlan,
    bool clearError = false,
    bool clearSelectedPlan = false,
  }) {
    return AiWorkoutPlanState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      plans: plans ?? this.plans,
      selectedPlan: clearSelectedPlan ? null : (selectedPlan ?? this.selectedPlan),
    );
  }
}

// Notifier for AI workout plan actions
class AiWorkoutPlanNotifier extends StateNotifier<AiWorkoutPlanState> {
  final AiWorkoutPlanRepository _repository;
  final AnalyticsService _analytics;
  final String _userId;

  AiWorkoutPlanNotifier(this._repository, this._analytics, this._userId) 
      : super(AiWorkoutPlanState()) {
    // Load plans when initialized
    loadPlans();
  }

  Future<void> loadPlans() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final plans = await _repository.getAiWorkoutPlans(_userId);
      state = state.copyWith(
        isLoading: false,
        plans: plans,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load workout plans: $e',
      );
    }
  }

  Future<void> selectPlan(String planId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final plan = await _repository.getAiWorkoutPlan(planId);
      state = state.copyWith(
        isLoading: false,
        selectedPlan: plan,
      );
      _analytics.logEvent(
        name: 'ai_workout_plan_selected',
        parameters: {'plan_id': planId},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to select workout plan: $e',
      );
    }
  }

  Future<void> startPlan(String planId, DateTime startDate) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.startAiWorkoutPlan(planId, _userId, startDate);
      state = state.copyWith(isLoading: false);
      _analytics.logEvent(
        name: 'ai_workout_plan_started',
        parameters: {'plan_id': planId},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to start workout plan: $e',
      );
    }
  }

  Future<void> deletePlan(String planId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.deleteAiWorkoutPlan(planId);
      // Reload plans after deletion
      await loadPlans();
      _analytics.logEvent(
        name: 'ai_workout_plan_deleted',
        parameters: {'plan_id': planId},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete workout plan: $e',
      );
    }
  }

  Future<void> saveGeneratedPlan({
    required Map<String, dynamic> planData,
    required PlanGenerationParameters parameters,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final planId = await _repository.createAiWorkoutPlanFromData(
        userId: _userId,
        planData: planData,
        durationDays: parameters.durationDays,
        daysPerWeek: parameters.daysPerWeek,
        focusAreas: parameters.focusAreas,
        variationType: parameters.variationType,
        fitnessLevel: parameters.fitnessLevel,
        specialRequest: parameters.specialRequest,
      );
      
      // Reload plans after creating a new one
      await loadPlans();
      
      // Select the newly created plan
      await selectPlan(planId);
      
      _analytics.logEvent(
        name: 'ai_workout_plan_generated_and_saved',
        parameters: {'plan_id': planId},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save generated workout plan: $e',
      );
    }
  }

  void clearSelectedPlan() {
    state = state.copyWith(clearSelectedPlan: true);
  }
}

// Provider for AI workout plan actions
final aiWorkoutPlanNotifierProvider = StateNotifierProvider.family<
    AiWorkoutPlanNotifier, AiWorkoutPlanState, String>((ref, userId) {
  final repository = ref.read(aiWorkoutPlanRepositoryProvider);
  final analytics = AnalyticsService();
  return AiWorkoutPlanNotifier(repository, analytics, userId);
});