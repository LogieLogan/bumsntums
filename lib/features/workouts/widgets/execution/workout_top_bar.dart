// lib/features/workouts/widgets/execution/workout_top_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../models/workout.dart';
import '../../providers/workout_execution_provider.dart';
import 'exit_confirmation_dialog.dart';

class WorkoutTopBar extends ConsumerWidget {
  final String workoutTitle;
  final VoidCallback onExit;
  
  const WorkoutTopBar({
    Key? key,
    required this.workoutTitle,
    required this.onExit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(workoutExecutionProvider);
    final executionNotifier = ref.read(workoutExecutionProvider.notifier);
    
    // Format the elapsed time
    final hours = executionState.elapsedTime.inHours;
    final minutes = executionState.elapsedTime.inMinutes % 60;
    final seconds = executionState.elapsedTime.inSeconds % 60;
    
    final formattedTime = hours > 0 
        ? '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Exit button
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _showExitConfirmation(context),
              color: AppColors.darkGrey,
              tooltip: 'Exit Workout',
            ),
            
            // Workout title and timer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    workoutTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: AppColors.mediumGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Pause/resume button
            IconButton(
              icon: Icon(
                executionState.isPaused 
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
              ),
              onPressed: executionState.isPaused
                  ? executionNotifier.resumeWorkout
                  : executionNotifier.pauseWorkout,
              color: AppColors.salmon,
              tooltip: executionState.isPaused 
                  ? 'Resume Workout'
                  : 'Pause Workout',
            ),
          ],
        ),
      ),
    );
  }
  
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ExitConfirmationDialog(
        onContinue: () => Navigator.of(context).pop(),
        onExit: () {
          Navigator.of(context).pop(); // Close dialog
          onExit(); // Call the onExit callback
        },
      ),
    );
  }
}