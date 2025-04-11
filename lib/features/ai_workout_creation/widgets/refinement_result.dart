// lib/features/ai_workout_creation/screens/workout_creation/widgets/refinement_result.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/buttons/secondary_button.dart';

class RefinementResult extends StatelessWidget {
  final Map<String, dynamic> workoutData;
  final String? changesSummary;
  final VoidCallback onUseWorkout;
  final VoidCallback onUndoChanges;
  final VoidCallback onRefineAgain;

  const RefinementResult({
    Key? key,
    required this.workoutData,
    this.changesSummary,
    required this.onUseWorkout,
    required this.onUndoChanges,
    required this.onRefineAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final exercises = workoutData['exercises'] as List? ?? [];
    final originalExercisesPreserved =
        changesSummary?.contains('Original exercises preserved') ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Changes summary section with better visibility
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                originalExercisesPreserved
                    ? AppColors.warning.withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  originalExercisesPreserved
                      ? AppColors.warning.withOpacity(0.3)
                      : AppColors.success.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    originalExercisesPreserved
                        ? Icons.info_outline
                        : Icons.check_circle,
                    color:
                        originalExercisesPreserved
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    originalExercisesPreserved
                        ? 'Workout Updated'
                        : 'Changes Applied',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          originalExercisesPreserved
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                changesSummary ?? 'Workout refined based on your feedback.',
                style: AppTextStyles.body,
              ),
              if (originalExercisesPreserved) ...[
                const SizedBox(height: 8),
                Text(
                  'For more specific exercise changes, try mentioning specific exercises or exercise types.',
                  style: AppTextStyles.small.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

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
                Text(
                  workoutData['title'] ?? 'Custom Workout',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 8),
                Text(
                  workoutData['description'] ??
                      'A personalized workout just for you.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      Icons.timer,
                      '${workoutData['durationMinutes'] ?? 30} min',
                    ),
                    _buildStatColumn(
                      Icons.local_fire_department,
                      '${workoutData['estimatedCaloriesBurn'] ?? 150} cal',
                    ),
                    _buildStatColumn(
                      Icons.fitness_center,
                      _capitalizeFirst(workoutData['difficulty'] ?? 'beginner'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

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
                if (exercises.isNotEmpty)
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
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'No exercises found',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Action buttons
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Undo changes button
            Expanded(
              child: SecondaryButton(
                text: 'Undo Changes',
                iconData: Icons.undo,
                onPressed: onUndoChanges,
              ),
            ),
            const SizedBox(width: 16),
            // Use workout button
            Expanded(
              child: PrimaryButton(
                text: 'Use Workout',
                onPressed: onUseWorkout,
              ),
            ),
          ],
        ),

        // Refine again button as a full-width option
        const SizedBox(height: 16),
        SecondaryButton(
          text: 'Refine Again',
          iconData: Icons.edit,
          onPressed: onRefineAgain,
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

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
