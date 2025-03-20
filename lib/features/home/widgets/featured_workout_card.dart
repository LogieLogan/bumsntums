// lib/features/home/widgets/featured_workout_card.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../features/workouts/screens/workout_detail_screen.dart';

class FeaturedWorkoutCard extends StatelessWidget {
  final String workoutId;
  final String title;
  final int durationMinutes;
  final int exerciseCount;
  final String difficultyLevel;

  const FeaturedWorkoutCard({
    Key? key,
    required this.workoutId,
    this.title = 'Beginner Bums & Tums',
    this.durationMinutes = 20,
    this.exerciseCount = 8,
    this.difficultyLevel = 'Beginner',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.salmon.withOpacity(0.7),
                      AppColors.popCoral,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.popYellow,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Featured',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 14,
                      color: AppColors.mediumGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$durationMinutes min',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.fitness_center,
                      size: 14,
                      color: AppColors.mediumGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$exerciseCount exercises',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.salmon.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        difficultyLevel,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.salmon,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailScreen(
                          workoutId: workoutId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.salmon,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  child: const Text('Start Workout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}