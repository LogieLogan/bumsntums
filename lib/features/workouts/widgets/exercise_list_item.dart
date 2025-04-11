// lib/features/workouts/widgets/exercise_list_item.dart
import 'package:bums_n_tums/shared/services/exercise_media_service.dart';
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../../../shared/theme/app_colors.dart';
import 'exercise_image_widget.dart';

class ExerciseListItem extends StatelessWidget {
  final Exercise exercise;
  final int index;
  final VoidCallback onTap;

  const ExerciseListItem({
    super.key,
    required this.exercise,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Check if this exercise has an associated video
    final hasVideo = ExerciseMediaService.hasVideo(exercise);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Exercise number
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.salmon,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Exercise image with play icon overlay if video is available
            Stack(
              children: [
                // The exercise image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ExerciseImageWidget(
                    exercise: exercise,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                // Video play indicator icon overlay
                if (hasVideo)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // Exercise details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (exercise.durationSeconds != null)
                    Text(
                      '${exercise.durationSeconds} seconds',
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                    )
                  else
                    Text(
                      '${exercise.sets} sets of ${exercise.reps} reps',
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),

                  Row(
                    children: [
                      if (hasVideo)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 8),
                          child: Text(
                            'Video Demo',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.popBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      if (exercise.modifications.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Has modifications',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.popGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron icon
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
