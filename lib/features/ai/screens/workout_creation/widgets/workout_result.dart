// lib/features/ai/screens/workout_creation/widgets/workout_result.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../features/workouts/repositories/custom_workout_repository.dart';
import '../../../../../features/workouts/models/workout.dart';
import '../../../../../features/workouts/models/exercise.dart';
import '../../../../../features/workouts/screens/pre_workout_setup_screen.dart';
import '../../../../../features/auth/providers/user_provider.dart';
import '../../../../../shared/analytics/firebase_analytics_service.dart';

class WorkoutResult extends ConsumerWidget {
  final Map<String, dynamic> workoutData;
  final VoidCallback onStartRefinement;

  const WorkoutResult({
    Key? key,
    required this.workoutData,
    required this.onStartRefinement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = AnalyticsService();

    // Extract workout details
    final title = workoutData['title'] ?? 'Custom Workout';
    final description =
        workoutData['description'] ?? 'A personalized workout just for you.';
    final difficulty = workoutData['difficulty'] ?? 'beginner';
    final duration = workoutData['durationMinutes'] ?? 30;
    final calories = workoutData['estimatedCaloriesBurn'] ?? 150;
    final equipment = workoutData['equipment'] ?? [];
    final exercises = workoutData['exercises'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your ${_capitalizeFirst(workoutData['category'] ?? 'custom')} workout is ready!',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPersonalizedMessage(workoutData),
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Workout details card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and description
                Text(title, style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text(description, style: AppTextStyles.body),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(Icons.timer, '$duration min'),
                    _buildStatColumn(
                      Icons.local_fire_department,
                      '$calories cal',
                    ),
                    _buildStatColumn(
                      Icons.fitness_center,
                      _capitalizeFirst(difficulty),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Equipment list if present
                if (equipment is List && equipment.isNotEmpty) ...[
                  Text(
                    'Equipment:',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(equipment.length, (index) {
                      return Chip(
                        label: Text(equipment[index].toString()),
                        backgroundColor: AppColors.popTurquoise.withOpacity(
                          0.1,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],

                // Exercise list header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercises (${exercises.length})',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Sets × Reps',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ],
                ),
                const Divider(),

                // Exercise list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exercises.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final name = exercise['name'] ?? 'Exercise ${index + 1}';
                    final description = exercise['description'] ?? '';
                    final sets = exercise['sets'] ?? 3;
                    final reps = exercise['reps'] ?? 10;
                    final isRepBased = (exercise['durationSeconds'] == null);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              isRepBased
                                  ? '$sets × $reps'
                                  : '$sets × ${exercise['durationSeconds']}s',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.mediumGrey,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Refine'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  onStartRefinement();
                  analytics.logEvent(name: 'workout_refinement_started');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.salmon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  _startWorkout(context, workoutData);
                  analytics.logEvent(
                    name: 'ai_workout_started',
                    parameters: {'workout_title': title},
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save to My Workouts'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () async {
              await _saveWorkout(context, ref, workoutData);
              analytics.logEvent(
                name: 'ai_workout_saved',
                parameters: {'workout_title': title},
              );
            },
          ),
        ),
        const SizedBox(height: 32),

        // Feedback section
        // Continuing lib/features/ai/screens/workout_creation/widgets/workout_result.dart
        // Feedback section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How was this workout suggestion?',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeedbackButton(Icons.thumb_down, 'Too Easy', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thanks for your feedback!'),
                      ),
                    );
                    analytics.logEvent(
                      name: 'workout_feedback',
                      parameters: {'rating': 'too_easy'},
                    );
                  }),
                  _buildFeedbackButton(Icons.check_circle, 'Just Right', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thanks for your feedback!'),
                      ),
                    );
                    analytics.logEvent(
                      name: 'workout_feedback',
                      parameters: {'rating': 'just_right'},
                    );
                  }),
                  _buildFeedbackButton(Icons.fitness_center, 'Too Hard', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thanks for your feedback!'),
                      ),
                    );
                    analytics.logEvent(
                      name: 'workout_feedback',
                      parameters: {'rating': 'too_hard'},
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppColors.salmon),
        const SizedBox(height: 4),
        Text(
          text,
          style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFeedbackButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: AppColors.darkGrey),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.small),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWorkout(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> workoutData,
  ) async {
    try {
      // Get the user ID
      final userProfile = await ref.read(userProfileProvider.future);
      if (userProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load user profile')),
        );
        return;
      }

      // Create a workout model from the data
      final workout = _createWorkoutFromData(workoutData);

      // Save to repository
      final repository = CustomWorkoutRepository();
      await repository.saveCustomWorkout(userProfile.userId, workout);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startWorkout(BuildContext context, Map<String, dynamic> workoutData) {
    // Create a workout model from the data
    final workout = _createWorkoutFromData(workoutData);

    // Navigate to pre-workout setup screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PreWorkoutSetupScreen(workout: workout),
      ),
    );
  }

  Workout _createWorkoutFromData(Map<String, dynamic> data) {
    // Extract exercises
    final exercisesList = data['exercises'] as List<dynamic>? ?? [];
    final exercises =
        exercisesList.map((e) {
          return Exercise(
            id: (e['name'] ?? 'exercise').hashCode.toString(),
            name: e['name'] ?? 'Unnamed Exercise',
            description: e['description'] ?? 'No description available',
            imageUrl: 'assets/images/placeholder_exercise.jpg',
            sets: e['sets'] ?? 3,
            reps: e['reps'] ?? 10,
            durationSeconds: e['durationSeconds'],
            restBetweenSeconds: e['restBetweenSeconds'] ?? 30,
            targetArea: e['targetArea'] ?? 'Core',
          );
        }).toList();

    // Create the workout model
    return Workout(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] ?? 'Custom Workout',
      description:
          data['description'] ?? 'A personalized workout created just for you.',
      imageUrl: 'assets/images/placeholder_workout.jpg',
      category: _getCategoryFromName(data['category']),
      difficulty: _getDifficultyFromName(data['difficulty']),
      durationMinutes: data['durationMinutes'] ?? 30,
      estimatedCaloriesBurn: data['estimatedCaloriesBurn'] ?? 150,
      isAiGenerated: true,
      createdAt: DateTime.now(),
      createdBy: 'ai',
      exercises: exercises,
      equipment:
          data['equipment'] != null ? List<String>.from(data['equipment']) : [],
      tags: ['ai-generated'],
      featured: false,
    );
  }

  WorkoutCategory _getCategoryFromName(String? name) {
    if (name == null) return WorkoutCategory.fullBody;

    switch (name.toLowerCase()) {
      case 'bums':
        return WorkoutCategory.bums;
      case 'tums':
        return WorkoutCategory.tums;
      case 'fullbody':
        return WorkoutCategory.fullBody;
      case 'cardio':
        return WorkoutCategory.cardio;
      case 'quick':
      case 'quickworkout':
        return WorkoutCategory.quickWorkout;
      default:
        return WorkoutCategory.fullBody;
    }
  }

  WorkoutDifficulty _getDifficultyFromName(String? name) {
    if (name == null) return WorkoutDifficulty.beginner;

    switch (name.toLowerCase()) {
      case 'beginner':
        return WorkoutDifficulty.beginner;
      case 'intermediate':
        return WorkoutDifficulty.intermediate;
      case 'advanced':
        return WorkoutDifficulty.advanced;
      default:
        return WorkoutDifficulty.beginner;
    }
  }

  String _getPersonalizedMessage(Map<String, dynamic> workout) {
    final category = workout['category'] ?? '';
    final difficulty = workout['difficulty'] ?? 'beginner';
    final duration = workout['durationMinutes'] ?? 30;

    if (category.toLowerCase() == 'bums') {
      return 'This workout focuses on strengthening and toning your glutes with $duration minutes of targeted exercises.';
    } else if (category.toLowerCase() == 'tums') {
      return 'Get ready to work your core with this $difficulty-level ab workout that fits into $duration minutes.';
    } else if (category.toLowerCase() == 'cardio') {
      return 'Boost your heart rate and burn calories with this $duration-minute cardio session.';
    } else if (category.toLowerCase() == 'fullbody') {
      return 'This complete full body workout targets all major muscle groups in just $duration minutes.';
    }

    return 'Based on your preferences, I\'ve created a $difficulty level workout that takes $duration minutes.';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
