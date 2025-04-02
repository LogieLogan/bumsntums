// lib/features/workouts/widgets/execution/rep_based_exercise_content.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/color_palette.dart';

class RepBasedExerciseContent extends StatelessWidget {
  final int reps;
  final int repCountdownSeconds;

  const RepBasedExerciseContent({
    super.key,
    required this.reps,
    required this.repCountdownSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rep count
            Text(
              '$reps reps',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            // Time remaining
            Text(
              'Time remaining: ${_formatTime(repCountdownSeconds)}',
              style: TextStyle(fontSize: 14, color: AppColors.mediumGrey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}