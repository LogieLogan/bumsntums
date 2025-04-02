// lib/features/workouts/widgets/execution/workout_top_bar.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/theme/text_styles.dart';
import '../../models/workout.dart';
import '../../providers/workout_execution_provider.dart';

class WorkoutTopBar extends StatelessWidget {
  final Workout workout;
  final WorkoutExecutionState state;
  final String formattedTime;
  final VoidCallback onClose;
  final VoidCallback onToggleVoice;

  const WorkoutTopBar({
    super.key,
    required this.workout,
    required this.state,
    required this.formattedTime,
    required this.onClose,
    required this.onToggleVoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back/close button
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, color: Colors.black, size: 24),
          ),

          // Workout title - with limited width to prevent overflow
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
              ),
              child: Text(
                workout.title,
                style: AppTextStyles.h3,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Right side controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timer display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.salmon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  formattedTime,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.salmon,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Voice toggle
              GestureDetector(
                onTap: onToggleVoice,
                child: Icon(
                  state.voiceGuidanceEnabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}