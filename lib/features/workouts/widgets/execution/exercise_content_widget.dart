// lib/features/workouts/widgets/execution/exercise_content_widget.dart
import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../providers/workout_execution_provider.dart';
import 'exercise_timer.dart';
import 'rep_based_exercise_content.dart';
import '../exercise_demo_widget.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/theme/text_styles.dart';

class ExerciseContentWidget extends StatelessWidget {
  final Exercise exercise;
  final bool isPaused;
  final WorkoutExecutionState state;
  final VoidCallback completeSet;
  final VoidCallback onExerciseComplete;
  final void Function(Exercise) showExerciseInfoSheet;
  final int repCountdownSeconds;
  final bool showCompleteButton;

  const ExerciseContentWidget({
    super.key,
    required this.exercise,
    required this.isPaused,
    required this.state,
    required this.completeSet,
    required this.onExerciseComplete,
    required this.showExerciseInfoSheet,
    required this.repCountdownSeconds,
    this.showCompleteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTimedExercise = exercise.durationSeconds != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed-height elements at the top
          _buildExerciseHeader(context),
          const SizedBox(height: 12),

          // Put the main content in an Expanded to ensure it doesn't overflow
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExerciseDemo(context),
                  _buildFormTip(context),

                  // Timer or rep counter
                  isTimedExercise
                      ? ExerciseTimer(
                        durationSeconds: exercise.durationSeconds!,
                        isPaused: isPaused,
                        onComplete: onExerciseComplete,
                      )
                      : RepBasedExerciseContent(
                        reps: exercise.reps,
                        repCountdownSeconds: repCountdownSeconds,
                      ),

                  // Set progress indicators
                  Center(child: _buildSetProgressIndicators()),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom button always at the bottom with safe spacing
          if (showCompleteButton) _buildCompleteSetButton(),
        ],
      ),
    );
  }

  Widget _buildExerciseHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Exercise name and info button
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: AppTextStyles.h2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Info button
              GestureDetector(
                onTap: () => showExerciseInfoSheet(exercise),
                child: Container(
                  padding: const EdgeInsets.all(6),
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
        ),

        const SizedBox(width: 8),

        // Set indicator pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.salmon,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Set ${state.currentSet}/${exercise.sets}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseDemo(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.paleGrey,
      ),
      clipBehavior: Clip.hardEdge,
      child: ExerciseDemoWidget(
        exercise: exercise,
        showControls: false,
        autoPlay: !isPaused,
      ),
    );
  }

  Widget _buildFormTip(BuildContext context) {
    if (exercise.formTips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.popTurquoise.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.popTurquoise.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: AppColors.popTurquoise,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                exercise.formTips.first,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetProgressIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(exercise.sets, (index) {
        final isCompleted =
            index <
            (state
                    .completedExercises[state.currentExerciseIndex]
                    ?.setsCompleted ??
                0);
        final isCurrent = index == state.currentSet - 1;

        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isCompleted
                    ? AppColors.popGreen
                    : isCurrent
                    ? AppColors.salmon
                    : AppColors.paleGrey,
            border:
                isCurrent
                    ? Border.all(color: AppColors.salmon, width: 2)
                    : null,
          ),
        );
      }),
    );
  }

  Widget _buildCompleteSetButton() {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8), // Add vertical margin
      child: ElevatedButton(
        onPressed: completeSet,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.salmon,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          'COMPLETE SET',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
