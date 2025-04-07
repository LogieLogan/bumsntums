// lib/features/workouts/widgets/execution/rest_period_widget.dart
import 'package:bums_n_tums/features/workouts/widgets/execution/exercise_info_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../models/exercise.dart';
import '../../providers/workout_execution_provider.dart';
import 'rest_timer.dart';
import '../exercise_demo_widget.dart';

class RestPeriodWidget extends ConsumerWidget {
  final Exercise nextExercise;
  final bool isBetweenSets;
  final VoidCallback onComplete;

  const RestPeriodWidget({
    Key? key,
    required this.nextExercise,
    required this.isBetweenSets,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(workoutExecutionProvider);
    final executionNotifier = ref.read(workoutExecutionProvider.notifier);
    final currentExercise = ref.read(workoutExecutionProvider).currentExercise!;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.paleGrey,
            child: Center(
              child: Text(
                isBetweenSets
                    ? 'Rest Before Next Set'
                    : 'Rest Before Next Exercise',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Timer
                    RestTimer(
                      durationSeconds:
                          executionState.remainingRestSeconds ?? 30,
                      isPaused: executionState.isPaused,
                      nextExerciseName: nextExercise.name,
                      onComplete: onComplete,
                      onAddTime: () => executionNotifier.adjustRestTime(15),
                      onReduceTime: () => executionNotifier.adjustRestTime(-15),
                    ),

                    const SizedBox(height: 24),

                    // Display next exercise info if between exercises (not sets)
                    if (!isBetweenSets) ...[
                      const Text(
                        'Coming Up Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrey,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Exercise preview card
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
                              // Exercise name
                              Text(
                                nextExercise.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkGrey,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Exercise details
                              Text(
                                nextExercise.durationSeconds != null
                                    ? '${nextExercise.sets} sets × ${nextExercise.durationSeconds}s each'
                                    : '${nextExercise.sets} sets × ${nextExercise.reps} reps each',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.mediumGrey,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Exercise demo
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColors.paleGrey,
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: ExerciseDemoWidget(
                                  exercise: nextExercise,
                                  autoPlay: true,
                                  showControls: false,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Quick form tips
                              if (nextExercise.formTips.isNotEmpty) ...[
                                const Text(
                                  'Quick Form Tips:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.salmon,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                ...nextExercise.formTips
                                    .take(2)
                                    .map(
                                      (tip) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: AppColors.popGreen,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                tip,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: onComplete,
                          icon: const Icon(Icons.skip_next),
                          label: const Text('SKIP REST'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.salmon,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(
                            Icons.info_outline,
                            color: AppColors.popBlue,
                          ),
                          onPressed: () => _showExerciseInfo(context),
                          tooltip: 'Exercise Information',
                          padding: const EdgeInsets.all(12),
                          constraints:
                              const BoxConstraints(), // Removes default minimum size
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder:
          (context) => ExerciseInfoSheet(
            exercise: isBetweenSets ? nextExercise : nextExercise,
          ),
    );
  }
}
