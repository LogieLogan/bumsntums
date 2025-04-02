// lib/features/workouts/widgets/execution/workout_bottom_controls.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../providers/workout_execution_provider.dart';

class WorkoutBottomControls extends StatelessWidget {
  final WorkoutExecutionState state;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onNext;

  const WorkoutBottomControls({
    super.key,
    required this.state,
    required this.onPause,
    required this.onResume,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play/Pause button (no background)
          GestureDetector(
            onTap: state.isPaused ? onResume : onPause,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                state.isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),

          // Next button if not the last exercise
          if (!state.isLastExercise)
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: GestureDetector(
                onTap: onNext,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.popBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.popBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}