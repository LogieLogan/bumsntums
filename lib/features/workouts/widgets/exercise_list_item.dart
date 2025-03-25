// lib/features/workouts/widgets/exercise_list_item.dart
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../../../shared/theme/color_palette.dart';
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
            
            // Exercise image using our new widget
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
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    )
                  else
                    Text(
                      '${exercise.sets} sets of ${exercise.reps} reps',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
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
            ),
            
            // Chevron icon
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}