// // lib/features/ai_workout_planning/providers/plan_generation_provider.dart
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../ai/services/openai_service.dart';
// import '../../ai/providers/ai_service_provider.dart';
// import '../models/plan_generation_parameters.dart';
// import '../../../shared/analytics/firebase_analytics_service.dart';

// class PlanGenerationState {
//   final bool isLoading;
//   final Map<String, dynamic>? planData;
//   final String? error;
//   final PlanGenerationParameters parameters;
//   final List<Map<String, dynamic>> refinementHistory;
//   final String? changesSummary;

//   PlanGenerationState({
//     this.isLoading = false,
//     this.planData,
//     this.error,
//     PlanGenerationParameters? parameters,
//     List<Map<String, dynamic>>? refinementHistory,
//     this.changesSummary,
//   }) : 
//     parameters = parameters ?? PlanGenerationParameters(),
//     refinementHistory = refinementHistory ?? const [];

//   PlanGenerationState copyWith({
//     bool? isLoading,
//     Map<String, dynamic>? planData,
//     String? error,
//     PlanGenerationParameters? parameters,
//     List<Map<String, dynamic>>? refinementHistory,
//     String? changesSummary,
//   }) {
//     return PlanGenerationState(
//       isLoading: isLoading ?? this.isLoading,
//       planData: planData ?? this.planData,
//       error: error ?? this.error,
//       parameters: parameters ?? this.parameters,
//       refinementHistory: refinementHistory ?? this.refinementHistory,
//       changesSummary: changesSummary ?? this.changesSummary,
//     );
//   }
// }

// class PlanGenerationNotifier extends StateNotifier<PlanGenerationState> {
//   final OpenAIService _openAIService;
//   final AnalyticsService _analytics;

//   PlanGenerationNotifier(this._openAIService, this._analytics)
//       : super(PlanGenerationState());

//   void setParameters({
//     required int durationDays,
//     required int daysPerWeek,
//     required List<String> focusAreas,
//     required String variationType,
//     String? fitnessLevel,
//     String? specialRequest,
//     List<String>? equipment,
//   }) {
//     state = state.copyWith(
//       parameters: PlanGenerationParameters(
//         durationDays: durationDays,
//         daysPerWeek: daysPerWeek,
//         focusAreas: focusAreas,
//         variationType: variationType,
//         fitnessLevel: fitnessLevel ?? 'beginner',
//         specialRequest: specialRequest,
//         equipment: equipment,
//       ),
//     );
//   }

//   Future<void> generatePlan({
//     required String userId,
//     Map<String, dynamic>? userProfileData,
//   }) async {
//     try {
//       state = state.copyWith(isLoading: true, error: null);

//       final params = state.parameters;

//       // Log analytics event
//       _analytics.logEvent(
//         name: 'plan_generation_started',
//         parameters: {
//           'duration_days': params.durationDays,
//           'days_per_week': params.daysPerWeek,
//           'focus_areas': params.focusAreas.join(','),
//           'variation_type': params.variationType,
//         },
//       );

//       // Call the OpenAI service
//       final planData = await _openAIService.generatePlan(
//         userId: userId,
//         durationDays: params.durationDays,
//         daysPerWeek: params.daysPerWeek,
//         focusAreas: params.focusAreas,
//         variationType: params.variationType,
//         fitnessLevel: params.fitnessLevel,
//         specialRequest: params.specialRequest,
//         userProfileData: userProfileData,
//       );

//       // Update state with the generated plan
//       state = state.copyWith(
//         isLoading: false,
//         planData: planData,
//       );

//       // Log success
//       _analytics.logEvent(
//         name: 'plan_generation_success',
//         parameters: {
//           'user_id': userId,
//           'plan_id': planData['id'],
//           'duration_days': params.durationDays,
//         },
//       );
//     } catch (e) {
//       // Update state with error
//       state = state.copyWith(isLoading: false, error: e.toString());

//       // Log error
//       _analytics.logError(
//         error: e.toString(),
//         parameters: {
//           'context': 'generatePlan',
//           'userId': userId,
//         },
//       );
//     }
//   }

//   Future<void> refinePlan({
//     required String userId,
//     required String refinementRequest,
//   }) async {
//     try {
//       // Must have a plan to refine
//       if (state.planData == null) {
//         throw Exception('No plan to refine');
//       }

//       state = state.copyWith(
//         isLoading: true,
//         error: null,
//         changesSummary: null,
//       );

//       // Save current plan to history before refining
//       final currentPlan = state.planData!;
//       final updatedHistory = List<Map<String, dynamic>>.from(
//         state.refinementHistory,
//       )..add(currentPlan);

//       // TODO: Call the OpenAI service to refine the plan
//       // This would be similar to the workout refinement logic
//       // For now, we'll add a mock implementation

//       // Log success
//       _analytics.logEvent(
//         name: 'plan_refinement_success',
//         parameters: {
//           'user_id': userId,
//           'refinement_request': refinementRequest,
//           'refinement_count': updatedHistory.length,
//         },
//       );
//     } catch (e) {
//       state = state.copyWith(isLoading: false, error: e.toString());

//       // Log error
//       _analytics.logError(
//         error: e.toString(),
//         parameters: {
//           'context': 'refinePlan',
//           'userId': userId,
//           'refinementRequest': refinementRequest,
//         },
//       );
//     }
//   }

//   void reset() {
//     state = PlanGenerationState();
//   }
// }

// // Provider for plan generation
// final planGenerationProvider =
//     StateNotifierProvider<PlanGenerationNotifier, PlanGenerationState>((ref) {
//   final openAIService = ref.watch(openAIServiceProvider);
//   final analytics = AnalyticsService();
//   return PlanGenerationNotifier(openAIService, analytics);
// });