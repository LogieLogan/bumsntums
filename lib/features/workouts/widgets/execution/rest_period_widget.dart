// lib/features/workouts/widgets/execution/rest_period_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/exercise.dart';
import '../../providers/workout_execution_provider.dart';
import 'rest_timer.dart';
import '../exercise_demo_widget.dart';
import '../../../../shared/theme/color_palette.dart';

class RestPeriodWidget extends ConsumerWidget {
  final WorkoutExecutionState state;
  final void Function(Exercise) showExerciseInfoSheet;

  const RestPeriodWidget({
    super.key,
    required this.state,
    required this.showExerciseInfoSheet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextExercise = state.nextExercise;
    if (nextExercise == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rest timer
          RestTimer(
            durationSeconds: state.restTimeRemaining,
            isPaused: state.isPaused,
            nextExerciseName: nextExercise.name,
            onComplete: () {
              ref.read(workoutExecutionProvider.notifier).endRestPeriod();
            },
            onAddTime: () => ref.read(workoutExecutionProvider.notifier).adjustRestTime(15),
            onReduceTime: () => ref.read(workoutExecutionProvider.notifier).adjustRestTime(-15, minimum: 5),
          ),

          const SizedBox(height: 24),

          // Coming up next header with info button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coming Up Next',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.salmon,
                ),
              ),

              // Info button
              GestureDetector(
                onTap: () => showExerciseInfoSheet(nextExercise),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.salmon.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: AppColors.salmon,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _buildNextExercisePreview(context, nextExercise),
          ),
        ],
      ),
    );
  }

  Widget _buildNextExercisePreview(BuildContext context, Exercise exercise) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name
          Text(
            exercise.name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGrey,
            ),
          ),

          const SizedBox(height: 12),

          // Exercise metrics
          Row(
            children: [
              // Sets & Reps/Duration
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.popBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  exercise.durationSeconds != null
                      ? '${exercise.sets} sets × ${exercise.durationSeconds} sec'
                      : '${exercise.sets} sets × ${exercise.reps} reps',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.popBlue,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Target area
              if (exercise.targetArea.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.popGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    exercise.targetArea,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.popGreen,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Next exercise preview
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: ExerciseDemoWidget(
              exercise: exercise,
              showControls: false,
              autoPlay: true,
            ),
          ),

          const SizedBox(height: 16),

          _buildPreparationSteps(context, exercise),
          _buildFormTip(context, exercise),
        ],
      ),
    );
  }

  Widget _buildPreparationSteps(BuildContext context, Exercise exercise) {
    if (exercise.preparationSteps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to Prepare',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.salmon,
          ),
        ),
        const SizedBox(height: 8),
        ...exercise.preparationSteps
            .take(2)
            .map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      size: 16,
                      color: AppColors.salmon,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        if (exercise.preparationSteps.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: () => showExerciseInfoSheet(exercise),
              child: Text(
                'See more...',
                style: TextStyle(
                  color: AppColors.popBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFormTip(BuildContext context, Exercise exercise) {
    if (exercise.formTips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.popTurquoise.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.popTurquoise.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: AppColors.popTurquoise,
              ),
              const SizedBox(width: 8),
              Text(
                'Form Tip',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.popTurquoise,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            exercise.formTips.first,
            style: const TextStyle(fontSize: 14),
          ),

          // Show more link if there are additional tips
          if (exercise.formTips.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => showExerciseInfoSheet(exercise),
                child: Text(
                  'More tips...',
                  style: TextStyle(
                    color: AppColors.popBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}