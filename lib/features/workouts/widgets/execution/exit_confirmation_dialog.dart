// lib/features/workouts/widgets/execution/exit_confirmation_dialog.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';

class ExitConfirmationDialog extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onExit;

  const ExitConfirmationDialog({
    super.key,
    required this.onContinue,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cancel Workout?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to cancel this workout? Your progress will be lost.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: onContinue,
                  child: const Text('Continue'),
                ),
                ElevatedButton(
                  onPressed: onExit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.salmon,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancel Workout'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}