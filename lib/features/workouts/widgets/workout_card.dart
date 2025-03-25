// lib/features/workouts/widgets/workout_card.dart
import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/services/exercise_media_service.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  final bool isCompact;

  const WorkoutCard({
    super.key,
    required this.workout,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: 8,
          horizontal: isCompact ? 4 : 16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Workout image using our enhanced service
              ExerciseMediaService.workoutImage(
                imageUrl: workout.imageUrl,
                category: workout.category,
                height: isCompact ? 120 : 200,
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(20),
              ),

              // Gradient overlay for text readability
              Container(
                height: isCompact ? 120 : 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),

              // Workout info overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        workout.title,
                        style:
                            isCompact
                                ? textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                )
                                : textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (!isCompact) const SizedBox(height: 4),

                      // Difficulty & duration row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Difficulty badge
                            _buildInfoBadge(
                              getDifficultyIcon(workout.difficulty),
                              getDifficultyText(workout.difficulty),
                              getDifficultyColor(workout.difficulty),
                            ),

                            const SizedBox(width: 8),

                            // Duration badge
                            _buildInfoBadge(
                              Icons.timer,
                              '${workout.durationMinutes} min',
                              AppColors.popTurquoise,
                            ),

                            if (workout.equipment.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              // Equipment badge (simplified for compact mode)
                              if (isCompact)
                                _buildInfoBadge(
                                  Icons.fitness_center,
                                  workout.equipment.length > 1
                                      ? 'Equipment'
                                      : workout.equipment.first,
                                  AppColors.popBlue,
                                )
                              else
                                _buildInfoBadge(
                                  Icons.fitness_center,
                                  workout.equipment.join(', '),
                                  AppColors.popBlue,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Featured badge
              if (workout.featured)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.popYellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.black87, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Featured',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData getDifficultyIcon(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return Icons.sentiment_satisfied;
      case WorkoutDifficulty.intermediate:
        return Icons.sentiment_neutral;
      case WorkoutDifficulty.advanced:
        return Icons.sentiment_very_dissatisfied;
    }
  }

  String getDifficultyText(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return 'Beginner';
      case WorkoutDifficulty.intermediate:
        return 'Intermediate';
      case WorkoutDifficulty.advanced:
        return 'Advanced';
    }
  }

  Color getDifficultyColor(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return AppColors.popGreen;
      case WorkoutDifficulty.intermediate:
        return AppColors.popCoral;
      case WorkoutDifficulty.advanced:
        return AppColors.terracotta;
    }
  }
}
