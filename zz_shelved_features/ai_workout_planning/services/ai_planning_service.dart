// // lib/features/ai_workout_planning/services/ai_planning_service.dart
// import 'package:bums_n_tums/features/workouts/models/exercise.dart';
// import 'package:bums_n_tums/features/workouts/models/workout_section.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:uuid/uuid.dart';
// import '../../workout_planning/models/scheduled_workout.dart';
// import '../../workout_planning/models/workout_plan.dart';
// import '../../workout_planning/repositories/workout_planning_repository.dart';
// import '../../workouts/models/workout.dart';
// import '../../workouts/services/workout_service.dart';
// import '../../ai/services/openai_service.dart';
// import '../../../shared/analytics/firebase_analytics_service.dart';

// class AIPlanningService {
//   final WorkoutPlanningRepository _planningRepository;
//   final WorkoutService _workoutService;
//   final OpenAIService _aiService;
//   final AnalyticsService _analytics;
//   final _uuid = const Uuid();

//   AIPlanningService({
//     required WorkoutPlanningRepository planningRepository,
//     required WorkoutService workoutService,
//     required OpenAIService aiService,
//     required AnalyticsService analytics,
//   }) : _planningRepository = planningRepository,
//        _workoutService = workoutService,
//        _aiService = aiService,
//        _analytics = analytics;

//   Future<WorkoutPlan> generateWorkoutPlan({
//     required String userId,
//     required DateTime startDate,
//     required DateTime endDate,
//     required int daysPerWeek,
//     required List<String> focusAreas,
//     required String fitnessLevel,
//     String? planName,
//     Map<String, dynamic>? additionalParams,
//   }) async {
//     try {
//       _analytics.logEvent(
//         name: 'generate_ai_workout_plan',
//         parameters: {
//           'userId': userId,
//           'daysPerWeek': daysPerWeek,
//           'focusAreas': focusAreas.join(','),
//           'fitnessLevel': fitnessLevel,
//         },
//       );

//       // Calculate duration in days
//       final int durationDays = endDate.difference(startDate).inDays + 1;

//       // Additional parameters for plan generation
//       String? variationType = additionalParams?['variationType'] ?? 'balanced';
//       String? specialRequest = additionalParams?['specialRequest'];

//       // Get user profile data if available
//       Map<String, dynamic>? userProfileData =
//           additionalParams?['userProfileData'];

//       // Generate the plan with complete workouts using the AI service
//       final planData = await _aiService.generatePlan(
//         userId: userId,
//         durationDays: durationDays,
//         focusAreas: focusAreas,
//         daysPerWeek: daysPerWeek,
//         fitnessLevel: fitnessLevel,
//         variationType: variationType,
//         specialRequest: specialRequest,
//         userProfileData: userProfileData,
//       );

//       // Create actual workout documents in the database first
//       final workouts = await _createWorkoutsFromPlanData(userId, planData);

//       // Then create the workout plan
//       final plan = await _planningRepository.createWorkoutPlan(
//         userId,
//         planName ?? planData['planName'] ?? 'AI Workout Plan',
//         startDate,
//         endDate,
//         description: planData['planDescription'] ?? 'AI generated workout plan',
//       );

//       // Schedule each workout in the plan
//       final scheduledWorkouts = <ScheduledWorkout>[];
//       final scheduledWorkoutData =
//           planData['scheduledWorkouts'] as List<dynamic>;

//       for (int i = 0; i < scheduledWorkoutData.length; i++) {
//         final workoutData = scheduledWorkoutData[i] as Map<String, dynamic>;

//         // Skip rest days
//         if (workoutData['isRestDay'] == true) continue;

//         // Find the matching workout we created
//         final workoutId = workoutData['workoutId'];
//         if (workoutId == null) continue;

//         // Calculate the actual date for this workout
//         final dayNumber = workoutData['dayNumber'] as int? ?? i;
//         final offset = dayNumber - 1; // Convert to 0-based index
//         final workoutDate = startDate.add(Duration(days: offset));

//         // Schedule the workout
//         try {
//           final scheduledWorkout = await _planningRepository.scheduleWorkout(
//             plan.id,
//             workoutId,
//             userId,
//             workoutDate,
//           );

//           scheduledWorkouts.add(scheduledWorkout);
//         } catch (e) {
//           _analytics.logError(
//             error: 'Error scheduling workout: $e',
//             parameters: {'workoutId': workoutId, 'planId': plan.id},
//           );
//         }
//       }

//       // Update the plan with the scheduled workouts
//       final updatedPlan = plan.copyWith(scheduledWorkouts: scheduledWorkouts);

//       _analytics.logEvent(
//         name: 'ai_workout_plan_generated_successfully',
//         parameters: {
//           'plan_id': plan.id,
//           'workout_count': scheduledWorkouts.length,
//           'user_id': userId,
//         },
//       );

//       return updatedPlan;
//     } catch (e) {
//       _analytics.logError(
//         error: 'Error generating AI workout plan: $e',
//         parameters: {'userId': userId},
//       );
//       throw e;
//     }
//   }

//   Future<List<Workout>> _createWorkoutsFromPlanData(
//     String userId,
//     Map<String, dynamic> planData,
//   ) async {
//     final workouts = <Workout>[];

//     // Extract workout data from the plan
//     final workoutDataList = planData['workouts'] as List<dynamic>? ?? [];

//     for (final workoutData in workoutDataList) {
//       try {
//         // Convert workout data to a proper Workout object
//         final workout = await _createWorkoutFromData(userId, workoutData);

//         // Try to use the workout service to save the workout
//         try {
//           // Save to user's custom workouts collection directly
//           await FirebaseFirestore.instance
//               .collection('user_custom_workouts')
//               .doc(userId)
//               .collection('workouts')
//               .doc(workout.id)
//               .set(workout.toMap());

//           workouts.add(workout);

//           _analytics.logEvent(
//             name: 'plan_workout_created',
//             parameters: {
//               'workout_id': workout.id,
//               'workout_name': workout.title,
//               'user_id': userId,
//             },
//           );
//         } catch (e) {
//           _analytics.logError(
//             error: 'Error saving workout: $e',
//             parameters: {'userId': userId, 'workout_id': workout.id},
//           );
//         }
//       } catch (e) {
//         _analytics.logError(
//           error: 'Error creating workout from plan data: $e',
//           parameters: {'userId': userId},
//         );
//       }
//     }

//     return workouts;
//   }

//   Future<void> _saveWorkoutDirectly(Workout workout) async {
//     try {
//       final workoutMap = workout.toMap();
//       // Save to user's custom workouts collection
//       await FirebaseFirestore.instance
//           .collection('user_custom_workouts')
//           .doc(workout.createdBy)
//           .collection('workouts')
//           .doc(workout.id)
//           .set(workoutMap);
//     } catch (e) {
//       _analytics.logError(
//         error: 'Error saving workout directly to Firestore: $e',
//         parameters: {'workout_id': workout.id},
//       );
//       throw Exception('Failed to save workout directly: $e');
//     }
//   }

//   // Helper method to create a Workout object from raw data
//   Future<Workout> _createWorkoutFromData(
//     String userId,
//     Map<String, dynamic> data,
//   ) async {
//     // Extract exercise data
//     final exerciseDataList = data['exercises'] as List<dynamic>? ?? [];
//     final exercises = <Exercise>[];

//     for (final exerciseData in exerciseDataList) {
//       final exercise = Exercise(
//         id:
//             'exercise-${DateTime.now().millisecondsSinceEpoch}-${exercises.length}',
//         name: exerciseData['name'] ?? 'Exercise',
//         description: exerciseData['description'] ?? '',
//         targetArea: exerciseData['targetArea'] ?? 'Core',
//         sets: exerciseData['sets'] ?? 3,
//         reps: exerciseData['reps'] ?? 10,
//         durationSeconds: exerciseData['durationSeconds'],
//         restBetweenSeconds: exerciseData['restBetweenSeconds'] ?? 30,
//         imageUrl: '', // Default empty image URL
//       );

//       exercises.add(exercise);
//     }

//     // Extract other workout data
//     final workoutId =
//         data['id'] ?? 'workout-${DateTime.now().millisecondsSinceEpoch}';
//     final title = data['title'] ?? 'AI Generated Workout';
//     final description = data['description'] ?? 'A workout generated by AI';
//     final categoryStr = data['category'] ?? 'fullBody';
//     final difficultyStr = data['difficulty'] ?? 'beginner';
//     final durationMinutes = data['durationMinutes'] ?? 30;
//     final equipment = List<String>.from(data['equipment'] ?? []);

//     // Convert strings to enums
//     final category = _categoryFromString(categoryStr);
//     final difficulty = _difficultyFromString(difficultyStr);

//     // Create sections from exercises
//     final section = WorkoutSection(
//       id: 'section-${DateTime.now().millisecondsSinceEpoch}',
//       name: 'Main Workout',
//       exercises: exercises,
//       restAfterSection: 60,
//       type: SectionType.normal,
//     );

//     // Create the workout object
//     return Workout(
//       id: workoutId,
//       title: title,
//       description: description,
//       imageUrl: '', // Default empty image URL
//       category: category,
//       difficulty: difficulty,
//       durationMinutes: durationMinutes,
//       estimatedCaloriesBurn: data['estimatedCaloriesBurn'] ?? 200,
//       featured: false,
//       isAiGenerated: true,
//       createdAt: DateTime.now(),
//       createdBy: 'ai',
//       exercises: exercises, // For backward compatibility
//       equipment: equipment,
//       tags: ['ai-generated', 'plan-workout'],
//       sections: [section],
//     );
//   }

//   // Helper methods for string to enum conversion
//   WorkoutCategory _categoryFromString(String value) {
//     switch (value.toLowerCase()) {
//       case 'bums':
//         return WorkoutCategory.bums;
//       case 'tums':
//         return WorkoutCategory.tums;
//       case 'cardio':
//         return WorkoutCategory.cardio;
//       case 'quickworkout':
//       case 'quick workout':
//       case 'quick':
//         return WorkoutCategory.quickWorkout;
//       case 'fullbody':
//       case 'full body':
//       default:
//         return WorkoutCategory.fullBody;
//     }
//   }

//   WorkoutDifficulty _difficultyFromString(String value) {
//     switch (value.toLowerCase()) {
//       case 'intermediate':
//         return WorkoutDifficulty.intermediate;
//       case 'advanced':
//         return WorkoutDifficulty.advanced;
//       case 'beginner':
//       default:
//         return WorkoutDifficulty.beginner;
//     }
//   }

//   // // Create a workout schedule with optimal training days
//   // Future<List<ScheduledWorkout>> _createWorkoutSchedule(
//   //   String userId,
//   //   String planId,
//   //   DateTime startDate,
//   //   DateTime endDate,
//   //   int daysPerWeek,
//   //   List<Workout> availableWorkouts,
//   // ) async {
//   //   final scheduledWorkouts = <ScheduledWorkout>[];

//   //   // Determine optimal training days
//   //   List<int> trainingDays = _determineOptimalDays(daysPerWeek);

//   //   // Get all dates between start and end
//   //   int totalDays = endDate.difference(startDate).inDays + 1;
//   //   List<DateTime> allDates = [];

//   //   for (int i = 0; i < totalDays; i++) {
//   //     allDates.add(startDate.add(Duration(days: i)));
//   //   }

//   //   // Filter dates to include only training days
//   //   List<DateTime> trainingDates =
//   //       allDates.where((date) => trainingDays.contains(date.weekday)).toList();

//   //   // Create a balanced workout selection
//   //   final balancedWorkouts = _createBalancedSelection(
//   //     availableWorkouts,
//   //     trainingDates.length,
//   //   );

//   //   // Schedule each workout
//   //   for (
//   //     int i = 0;
//   //     i < trainingDates.length && i < balancedWorkouts.length;
//   //     i++
//   //   ) {
//   //     try {
//   //       final scheduledWorkout = await _planningRepository.scheduleWorkout(
//   //         planId,
//   //         balancedWorkouts[i].id,
//   //         userId,
//   //         trainingDates[i],
//   //       );

//   //       scheduledWorkouts.add(scheduledWorkout);
//   //     } catch (e) {
//   //       print('Error scheduling workout: $e');
//   //     }
//   //   }

//   //   return scheduledWorkouts;
//   // }

//   // Create a balanced workout selection
//   List<Workout> _createBalancedSelection(List<Workout> workouts, int count) {
//     if (workouts.isEmpty) {
//       return [];
//     }

//     // Group workouts by category
//     final byCategory = <WorkoutCategory, List<Workout>>{};

//     for (final workout in workouts) {
//       if (!byCategory.containsKey(workout.category)) {
//         byCategory[workout.category] = [];
//       }
//       byCategory[workout.category]!.add(workout);
//     }

//     // Create a balanced selection
//     final result = <Workout>[];
//     final categories = byCategory.keys.toList();

//     // Ensure we don't exceed available workouts
//     final targetCount = count > workouts.length ? workouts.length : count;

//     while (result.length < targetCount) {
//       for (final category in categories) {
//         if (byCategory[category]!.isNotEmpty && result.length < targetCount) {
//           // Take workouts from each category in rotation
//           result.add(byCategory[category]!.first);

//           // Move this workout to the end for variety
//           final workout = byCategory[category]!.removeAt(0);
//           byCategory[category]!.add(workout);
//         }
//       }
//     }

//     return result;
//   }

//   // Determine optimal training days based on days per week
//   List<int> _determineOptimalDays(int daysPerWeek) {
//     switch (daysPerWeek) {
//       case 1:
//         return [1]; // Monday
//       case 2:
//         return [1, 4]; // Monday, Thursday
//       case 3:
//         return [1, 3, 5]; // Monday, Wednesday, Friday
//       case 4:
//         return [1, 3, 5, 7]; // Monday, Wednesday, Friday, Sunday
//       case 5:
//         return [1, 2, 4, 5, 7]; // Monday, Tuesday, Thursday, Friday, Sunday
//       case 6:
//         return [1, 2, 3, 5, 6, 7]; // All days except Thursday
//       case 7:
//         return [1, 2, 3, 4, 5, 6, 7]; // All days
//       default:
//         return [1, 3, 5]; // Default to 3 days (M, W, F)
//     }
//   }

//   // Calculate target area distribution based on scheduled workouts
//   Map<String, double> _calculateTargetAreaDistribution(
//     List<ScheduledWorkout> scheduledWorkouts,
//   ) {
//     final distribution = <String, double>{};

//     for (final scheduledWorkout in scheduledWorkouts) {
//       final workout = scheduledWorkout.workout;
//       if (workout != null) {
//         // Count by category
//         final category = workout.category.name;
//         distribution[category] = (distribution[category] ?? 0) + 1;
//       }
//     }

//     // Convert to percentages
//     final total = distribution.values.fold<double>(
//       0,
//       (sum, value) => sum + value,
//     );
//     if (total > 0) {
//       distribution.forEach((key, value) {
//         distribution[key] = (value / total) * 100;
//       });
//     }

//     return distribution;
//   }
// }
