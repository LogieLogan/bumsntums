// lib/features/workouts/widgets/execution/exercise_content_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../models/exercise.dart';
import '../../providers/workout_execution_provider.dart';
import '../exercise_demo_widget.dart';
import 'exercise_timer.dart';
import 'rep_based_exercise_content.dart';

class ExerciseContentWidget extends ConsumerWidget {
  final Exercise exercise;
  final int currentSet;
  final VoidCallback onComplete;
  final VoidCallback onInfoTap;

  const ExerciseContentWidget({
    Key? key,
    required this.exercise,
    required this.currentSet,
    required this.onComplete,
    required this.onInfoTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(workoutExecutionProvider);
    final bool isTimeBased = exercise.durationSeconds != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // Use a SingleChildScrollView to prevent overflow
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise name and set counter
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set ${currentSet + 1} of ${exercise.sets}',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.mediumGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Info button
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: onInfoTap,
                    tooltip: 'Exercise Information',
                    color: AppColors.salmon,
                  ),
                ],
              ),
            ),
            
            // Exercise demonstration - Constrain the height
            Container(
              height: 200, // Fixed height to prevent layout issues
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: ExerciseDemoWidget(
                exercise: exercise,
                autoPlay: true,
                showControls: false,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Exercise timer or rep counter - using a fixed height container
            SizedBox(
              height: 180, // Fixed height for timer/rep counter
              child: isTimeBased
                ? ExerciseTimer(
                    durationSeconds: executionState.remainingExerciseSeconds ?? 
                        exercise.durationSeconds!,
                    isPaused: executionState.isPaused,
                    onComplete: onComplete,
                  )
                : RepBasedExerciseContent(
                    reps: exercise.reps,
                    repCountdownSeconds: 60, // Default time for completing reps
                  ),
            ),
                
            const SizedBox(height: 16),
            
            // Quick form tips
            if (exercise.formTips.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16), // Add bottom margin
                decoration: BoxDecoration(
                  color: AppColors.paleGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.salmon,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Form Tip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.salmon,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // Just show one random tip to keep it concise
                      exercise.formTips.first,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Add some bottom padding to ensure there's space
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}