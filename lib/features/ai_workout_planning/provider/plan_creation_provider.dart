// lib/features/ai_workout_planning/providers/plan_creation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ai/services/openai_service.dart';
import '../../ai/providers/ai_service_provider.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

// Define the state class
class PlanCreationState {
  final bool isLoading;
  final String? planText;
  final String? error;
  final Map<String, dynamic> parameters;

  PlanCreationState({
    this.isLoading = false,
    this.planText,
    this.error,
    this.parameters = const {},
  });

  PlanCreationState copyWith({
    bool? isLoading,
    String? planText,
    String? error,
    Map<String, dynamic>? parameters,
  }) {
    return PlanCreationState(
      isLoading: isLoading ?? this.isLoading,
      planText: planText ?? this.planText,
      error: error ?? this.error,
      parameters: parameters ?? this.parameters,
    );
  }

  PlanCreationState updateParameters(Map<String, dynamic> newParams) {
    final updatedParams = Map<String, dynamic>.from(parameters);
    updatedParams.addAll(newParams);
    
    return copyWith(parameters: updatedParams);
  }
}

class PlanCreationNotifier extends StateNotifier<PlanCreationState> {
  final OpenAIService _openAIService;
  final AnalyticsService _analytics;

  PlanCreationNotifier(this._openAIService, this._analytics)
      : super(PlanCreationState());

  // Set initial parameters
  void setParameters({
    required int durationDays,
    required List<String> focusAreas,
    int? daysPerWeek,
    String? specialRequest,
  }) {
    state = state.updateParameters({
      'durationDays': durationDays,
      'focusAreas': focusAreas,
      if (daysPerWeek != null) 'daysPerWeek': daysPerWeek,
      if (specialRequest != null) 'specialRequest': specialRequest,
    });
  }

  // Update a parameter
  void updateParameter(String key, dynamic value) {
    state = state.updateParameters({key: value});
  }

  // Generate a plan
  Future<void> generatePlan({
    required String userId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final params = state.parameters;
      
      // Extract parameters
      final durationDays = params['durationDays'] ?? 7;
      final focusAreas = params['focusAreas'] ?? ['Full Body'];
      final daysPerWeek = params['daysPerWeek'];
      final specialRequest = params['specialRequest'];

      // Make sure focusAreas is properly converted to a List<String>
      List<String> safeAreasList;
      if (focusAreas is List) {
        safeAreasList = focusAreas.map((e) => e.toString()).toList();
      } else if (focusAreas is String) {
        safeAreasList = [focusAreas];
      } else {
        safeAreasList = ['Full Body'];
      }

      // Generate the plan
      final planText = await _openAIService.generatePlan(
        userId: userId,
        durationDays: durationDays is int ? durationDays : 7,
        focusAreas: safeAreasList,
        daysPerWeek: daysPerWeek is int ? daysPerWeek : null,
        specialRequest: specialRequest is String ? specialRequest : null,
      );

      state = state.copyWith(isLoading: false, planText: planText);

      // Log success
      _analytics.logEvent(
        name: 'plan_generation_success',
        parameters: {
          'user_id': userId,
          'duration_days': durationDays,
          'focus_areas': safeAreasList.join(','),
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());

      // Log error
      _analytics.logError(
        error: e.toString(),
        parameters: {
          'context': 'generatePlan',
          'userId': userId,
        },
      );
    }
  }

  // Reset state
  void reset() {
    state = PlanCreationState();
  }
}

// Provider for plan creation
final planCreationProvider = StateNotifierProvider
    <PlanCreationNotifier, PlanCreationState>((ref) {
  final openAIService = ref.watch(openAIServiceProvider);
  final analytics = AnalyticsService();
  return PlanCreationNotifier(openAIService, analytics);
});