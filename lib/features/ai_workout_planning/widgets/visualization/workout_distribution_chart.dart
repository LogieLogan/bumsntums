// lib/features/ai_workout_planning/widgets/visualization/workout_distribution_chart.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';

class WorkoutDistributionChart extends StatelessWidget {
  final Map<String, dynamic> planData;

  const WorkoutDistributionChart({Key? key, required this.planData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract scheduled workouts
    final scheduledWorkouts =
        planData['scheduledWorkouts'] as List<dynamic>? ?? [];

    // Count workouts by category
    final workoutsByCategory = <String, int>{};
    int totalWorkouts = 0;
    int restDays = 0;

    for (final workout in scheduledWorkouts) {
      final isRestDay = workout['isRestDay'] as bool? ?? false;

      if (isRestDay) {
        restDays++;
        continue;
      }

      totalWorkouts++;
      final category = workout['category'] as String? ?? 'Unknown';
      workoutsByCategory[category] = (workoutsByCategory[category] ?? 0) + 1;
    }

    // Sort categories by count
    final sortedCategories =
        workoutsByCategory.keys.toList()..sort(
          (a, b) => workoutsByCategory[b]!.compareTo(workoutsByCategory[a]!),
        );

    return SingleChildScrollView(
      // Wrap in SingleChildScrollView to handle potential overflow
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan summary stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                context,
                'Total Days',
                '${scheduledWorkouts.length}',
                Icons.calendar_today,
              ),
              _buildStatCard(
                context,
                'Workouts',
                '$totalWorkouts',
                Icons.fitness_center,
              ),
              _buildStatCard(context, 'Rest Days', '$restDays', Icons.hotel),
            ],
          ),

          const SizedBox(height: 24),

          // Workout distribution chart
          Text(
            'Workout Distribution',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          ...sortedCategories.map((category) {
            final count = workoutsByCategory[category]!;
            final percentage = (count / totalWorkouts * 100).round();

            // Get color based on category
            Color color;
            switch (category.toLowerCase()) {
              case 'bums':
                color = AppColors.pink;
                break;
              case 'tums':
                color = AppColors.popCoral;
                break;
              case 'fullbody':
                color = AppColors.popBlue;
                break;
              case 'cardio':
                color = AppColors.popGreen;
                break;
              default:
                color = AppColors.popYellow;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        category.toLowerCase() == 'fullbody'
                            ? 'Full Body'
                            : category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '$count workouts ($percentage%)',
                        style: TextStyle(color: AppColors.mediumGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: count / totalWorkouts,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.pink.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.pink, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
        ),
      ],
    );
  }
}
