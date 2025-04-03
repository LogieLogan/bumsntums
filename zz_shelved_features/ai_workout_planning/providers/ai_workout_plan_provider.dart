// // lib/features/ai_workout_planning/providers/ai_workout_plan_provider.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../models/ai_workout_plan_model.dart';
// import '../repositories/ai_workout_plan_repository.dart';
// import '../models/plan_generation_parameters.dart';
// import '../../../shared/analytics/firebase_analytics_service.dart';

// // Provider to get all AI workout plans for a user
// final aiWorkoutPlansProvider =
//     FutureProvider.family<List<AiWorkoutPlan>, String>((ref, userId) async {
//       final repository = ref.read(aiWorkoutPlanRepositoryProvider);
//       return repository.getAiWorkoutPlans(userId);
//     });

// // State for managing AI plan selection and actions
// class AiWorkoutPlanState {
//   final bool isLoading;
//   final String? errorMessage;
//   final List<AiWorkoutPlan> plans;
//   final AiWorkoutPlan? selectedPlan;

//   AiWorkoutPlanState({
//     this.isLoading = false,
//     this.errorMessage,
//     this.plans = const [],
//     this.selectedPlan,
//   });

//   AiWorkoutPlanState copyWith({
//     bool? isLoading,
//     String? errorMessage,
//     List<AiWorkoutPlan>? plans,
//     AiWorkoutPlan? selectedPlan,
//     bool clearError = false,
//     bool clearSelectedPlan = false,
//   }) {
//     return AiWorkoutPlanState(
//       isLoading: isLoading ?? this.isLoading,
//       errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
//       plans: plans ?? this.plans,
//       selectedPlan:
//           clearSelectedPlan ? null : (selectedPlan ?? this.selectedPlan),
//     );
//   }
// }

// // Notifier for AI workout plan actions
// class AiWorkoutPlanNotifier extends StateNotifier<AiWorkoutPlanState> {
//   final AiWorkoutPlanRepository _repository;
//   final AnalyticsService _analytics;
//   final String _userId;

//   AiWorkoutPlanNotifier(this._repository, this._analytics, this._userId)
//     : super(AiWorkoutPlanState()) {
//     // Load plans when initialized
//     loadPlans();
//   }

//   Future<void> loadPlans() async {
//     state = state.copyWith(isLoading: true, clearError: true);
//     try {
//       final plans = await _repository.getAiWorkoutPlans(_userId);
//       state = state.copyWith(isLoading: false, plans: plans);
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         errorMessage: 'Failed to load workout plans: $e',
//       );
//     }
//   }

//   Future<void> selectPlan(String planId) async {
//     state = state.copyWith(isLoading: true, clearError: true);
//     try {
//       final plan = await _repository.getAiWorkoutPlan(planId);
//       state = state.copyWith(isLoading: false, selectedPlan: plan);
//       _analytics.logEvent(
//         name: 'ai_workout_plan_selected',
//         parameters: {'plan_id': planId},
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         errorMessage: 'Failed to select workout plan: $e',
//       );
//     }
//   }

//   Future<void> startPlan(String planId, DateTime startDate) async {
//     state = state.copyWith(isLoading: true, clearError: true);
//     try {
//       _analytics.logEvent(
//         name: 'ai_workout_plan_start_initiated',
//         parameters: {'plan_id': planId, 'user_id': _userId},
//       );

//       // First, check if the plan exists
//       final plan = await _repository.getAiWorkoutPlan(planId);
//       if (plan == null) {
//         throw Exception('Plan not found');
//       }

//       // Validate that the plan has workouts
//       if (plan.workouts.isEmpty) {
//         throw Exception('Plan does not contain any workouts');
//       }

//       // Start the plan (convert to workout plan and schedule workouts)
//       await _repository.startAiWorkoutPlan(planId, _userId, startDate);

//       state = state.copyWith(isLoading: false);

//       _analytics.logEvent(
//         name: 'ai_workout_plan_started_successfully',
//         parameters: {
//           'plan_id': planId,
//           'start_date': startDate.toString(),
//           'days_per_week': plan.daysPerWeek,
//           'duration_days': plan.durationDays,
//         },
//       );

//       // Clear any selected plan after successful start
//       state = state.copyWith(clearSelectedPlan: true);
//     } catch (e) {
//       _analytics.logError(
//         error: 'Failed to start workout plan: $e',
//         parameters: {'plan_id': planId, 'user_id': _userId},
//       );

//       state = state.copyWith(
//         isLoading: false,
//         errorMessage: 'Failed to start workout plan: $e',
//       );

//       // Re-throw the exception to allow UI to handle it
//       throw e;
//     }
//   }

//   Future<void> deletePlan(String planId) async {
//     state = state.copyWith(isLoading: true, clearError: true);
//     try {
//       await _repository.deleteAiWorkoutPlan(planId);
//       // Reload plans after deletion
//       await loadPlans();
//       _analytics.logEvent(
//         name: 'ai_workout_plan_deleted',
//         parameters: {'plan_id': planId},
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         errorMessage: 'Failed to delete workout plan: $e',
//       );
//     }
//   }

//   Future<void> saveGeneratedPlan({
//     required Map<String, dynamic> planData,
//     required PlanGenerationParameters parameters,
//   }) async {
//     state = state.copyWith(isLoading: true, clearError: true);
//     try {
//       _analytics.logEvent(
//         name: 'ai_workout_plan_save_initiated',
//         parameters: {
//           'user_id': _userId,
//           'duration_days': parameters.durationDays,
//           'days_per_week': parameters.daysPerWeek,
//         },
//       );

//       // Log the plan structure for debugging
//       debugPrint('Plan data structure: ${planData.keys.join(', ')}');

//       // Check for workouts key - IMPORTANT: OpenAI might use different key names
//       List<dynamic> workouts = [];

//       // Check for various possible key names for workouts
//       if (planData.containsKey('workouts')) {
//         workouts = planData['workouts'] as List<dynamic>;
//       } else if (planData.containsKey('scheduledWorkouts')) {
//         workouts = planData['scheduledWorkouts'] as List<dynamic>;
//       } else {
//         // If we can't find workouts directly, we need to construct them
//         // from the plan data we have
//         debugPrint('Creating workouts from available plan data');

//         // Construct a workouts array based on the plan structure
//         final daysPerWeek = parameters.daysPerWeek;
//         final durationDays = parameters.durationDays;

//         // Get available workouts for the focus areas
//         final List<Map<String, dynamic>> constructedWorkouts = [];

//         // Create stub workout data for each workout day
//         for (int i = 0; i < durationDays; i++) {
//           // Only add workouts for active days based on days per week
//           if (i % 7 < daysPerWeek) {
//             final workoutData = {
//               'workoutId':
//                   'template_${parameters.focusAreas.first.toLowerCase()}',
//               'name': 'Day ${i + 1} Workout',
//               'description': 'Generated workout for day ${i + 1}',
//               'category': parameters.focusAreas.first,
//               'difficulty': parameters.fitnessLevel,
//               'dayIndex': i,
//             };
//             constructedWorkouts.add(workoutData);
//           }
//         }

//         // Update the plan data with constructed workouts
//         planData['workouts'] = constructedWorkouts;
//         workouts = constructedWorkouts;

//         debugPrint(
//           'Created ${constructedWorkouts.length} workouts from plan data',
//         );
//       }

//       if (workouts.isEmpty) {
//         throw Exception('No workouts found or created for this plan');
//       }

//       // Create the AI workout plan
//       final planId = await _repository.createAiWorkoutPlanFromData(
//         userId: _userId,
//         planData: planData,
//         durationDays: parameters.durationDays,
//         daysPerWeek: parameters.daysPerWeek,
//         focusAreas: parameters.focusAreas,
//         variationType: parameters.variationType,
//         fitnessLevel: parameters.fitnessLevel,
//         specialRequest: parameters.specialRequest,
//       );

//       // Reload plans after creating a new one
//       await loadPlans();

//       // Select the newly created plan
//       await selectPlan(planId);

//       _analytics.logEvent(
//         name: 'ai_workout_plan_saved_successfully',
//         parameters: {
//           'plan_id': planId,
//           'user_id': _userId,
//           'workout_count': workouts.length,
//         },
//       );
//     } catch (e, stackTrace) {
//       // Log to analytics
//       _analytics.logError(
//         error: 'Failed to save generated workout plan: $e',
//         parameters: {'user_id': _userId},
//       );

//       // Log to console for debugging
//       debugPrint('Error saving workout plan: $e');
//       debugPrint('Stack trace: $stackTrace');

//       // Update state with error
//       state = state.copyWith(
//         isLoading: false,
//         errorMessage: 'Failed to save generated workout plan: $e',
//       );

//       // Re-throw the exception
//       throw e;
//     }
//   }

//   void clearSelectedPlan() {
//     state = state.copyWith(clearSelectedPlan: true);
//   }
// }

// // Provider for AI workout plan actions
// final aiWorkoutPlanNotifierProvider = StateNotifierProvider.family<
//   AiWorkoutPlanNotifier,
//   AiWorkoutPlanState,
//   String
// >((ref, userId) {
//   final repository = ref.read(aiWorkoutPlanRepositoryProvider);
//   final analytics = AnalyticsService();
//   return AiWorkoutPlanNotifier(repository, analytics, userId);
// });
