// lib/features/home/widgets/stats_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../workout_analytics/providers/workout_stats_provider.dart';
import '../../../shared/navigation/navigation.dart';

class StatsCard extends ConsumerWidget {
  final String userId;

  const StatsCard({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(workoutStatsProvider(userId));

    return GestureDetector(
      // Wrap in GestureDetector
      onTap: () {
        AppNavigation.navigateToWorkoutAnalytics(context, userId);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: statsAsync.when(
          data: (stats) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.insights,
                      color: AppColors.salmon,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Your Activity",
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.mediumGrey,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      context,
                      Icons.fitness_center,
                      "${stats.totalWorkouts}",
                      "Workouts",
                      AppColors.salmon,
                    ),
                    _buildStatDivider(),
                    _buildStatItem(
                      context,
                      Icons.local_fire_department,
                      "${stats.totalCaloriesBurned}",
                      "Calories",
                      AppColors.popCoral,
                    ),
                    _buildStatDivider(),
                    _buildStatItem(
                      context,
                      Icons.timer,
                      "${stats.totalMinutes}",
                      "Minutes",
                      AppColors.popBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Weekly progress indicator
                if (stats.totalWorkouts > 0) ...[
                  Row(
                    children: [
                      Text(
                        "Weekly goal: ${stats.weeklyCompleted}/${stats.weeklyGoal} workouts",
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.darkGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${(stats.weeklyProgress * 100).toInt()}%",
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.salmon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: stats.weeklyProgress,
                      backgroundColor: AppColors.paleGrey,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.salmon,
                      ),
                      minHeight: 10,
                    ),
                  ),
                  if (stats.currentStreak > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.popYellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: AppColors.popYellow,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${stats.currentStreak} day streak!",
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.popYellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else
                  Text(
                    "Complete your first workout to start tracking your progress!",
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.mediumGrey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (_, __) => Center(
                child: Text(
                  "Could not load workout stats",
                  style: AppTextStyles.small.copyWith(color: AppColors.error),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.darkGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 40, width: 1, color: AppColors.paleGrey);
  }
}
