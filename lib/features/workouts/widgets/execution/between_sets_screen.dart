// Rename to: lib/features/workouts/widgets/execution/between_sets_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_execution_provider.dart';
import 'between_sets_timer.dart';
import '../../../../shared/theme/color_palette.dart';

class BetweenSetsScreen extends ConsumerWidget {
  final WorkoutExecutionState state;

  const BetweenSetsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextSet = state.currentSet + 1;
    final totalSets = state.currentExercise.sets;
    final exerciseName = state.currentExercise.name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Top part with title and timer
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rest Between Sets',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.popBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BetweenSetsTimer(
                        durationSeconds: state.setRestTimeRemaining,
                        isPaused: state.isPaused,
                        currentSet: state.currentSet,
                        totalSets: totalSets,
                        onComplete: () {
                          ref.read(workoutExecutionProvider.notifier).endSetRestPeriod();
                        },
                        onAddTime: () => ref.read(workoutExecutionProvider.notifier).adjustSetRestTime(15),
                        onReduceTime: () => ref.read(workoutExecutionProvider.notifier).adjustSetRestTime(-15, minimum: 5),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Fixed height bottom section
              SizedBox(
                height: 80, // Fixed height for bottom content
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Coming up text
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Coming up: Set $nextSet of $totalSets - $exerciseName',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    // Skip rest button
                    SizedBox(
                      height: 40,
                      width: 120,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(workoutExecutionProvider.notifier).endSetRestPeriod();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.popBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Skip Rest', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

}