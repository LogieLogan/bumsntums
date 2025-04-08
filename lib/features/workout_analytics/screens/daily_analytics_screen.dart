import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../models/workout_stats.dart';
import '../providers/workout_stats_provider.dart';
import '../../workouts/screens/workout_history_screen.dart';

class DailyAnalyticsScreen extends ConsumerWidget {
  final String userId;

  const DailyAnalyticsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userWorkoutStatsProvider(userId));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Today\'s Workout',
              icon: Icons.today,
              child: userStatsAsync.when(
                data: (stats) => _buildTodayWorkout(stats, context, today),
                loading: () => const LoadingIndicator(),
                error: (error, _) => _buildErrorWidget(error),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Recent Activity',
              icon: Icons.history,
              child: userStatsAsync.when(
                data: (stats) => _buildRecentActivity(stats, context),
                loading: () => const LoadingIndicator(),
                error: (error, _) => _buildErrorWidget(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.salmon, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildTodayWorkout(UserWorkoutStats stats, BuildContext context, DateTime today) {
    // Check if user worked out today
    final hasWorkoutToday = stats.lastWorkoutDate.year == today.year &&
        stats.lastWorkoutDate.month == today.month &&
        stats.lastWorkoutDate.day == today.day;
    
    if (!hasWorkoutToday) {
      return _buildEmptyDataWidget('No workout completed today');
    }
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                value: '1',  // Assuming 1 workout today
                label: 'Workouts Today',
                icon: Icons.fitness_center,
                color: AppColors.salmon,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                value: '${stats.lastWorkoutDate.hour}:${stats.lastWorkoutDate.minute.toString().padLeft(2, '0')}',
                label: 'Last Workout',
                icon: Icons.access_time,
                color: AppColors.popBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to workout history to see today's workout details
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const WorkoutHistoryScreen(),
              ),
            );
          },
          icon: const Icon(Icons.visibility),
          label: const Text('View Today\'s Workout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.salmon,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(UserWorkoutStats stats, BuildContext context) {
    final lastWorkoutDate = stats.lastWorkoutDate;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dayBefore = DateTime(now.year, now.month, now.day - 2);

    String lastWorkoutText;
    Color statusColor;

    // Format the workout recency text
    if (lastWorkoutDate.year == now.year && 
        lastWorkoutDate.month == now.month && 
        lastWorkoutDate.day == now.day) {
      lastWorkoutText = 'Today';
      statusColor = AppColors.popGreen;
    } else if (lastWorkoutDate.year == yesterday.year && 
               lastWorkoutDate.month == yesterday.month && 
               lastWorkoutDate.day == yesterday.day) {
      lastWorkoutText = 'Yesterday';
      statusColor = AppColors.popBlue;
    } else if (lastWorkoutDate.year == dayBefore.year && 
               lastWorkoutDate.month == dayBefore.month && 
               lastWorkoutDate.day == dayBefore.day) {
      lastWorkoutText = '2 days ago';
      statusColor = AppColors.popTurquoise;
    } else {
      // Calculate days difference
      final difference = now.difference(lastWorkoutDate).inDays;
      lastWorkoutText = '$difference days ago';
      statusColor = difference <= 7 ? AppColors.popYellow : AppColors.popCoral;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                lastWorkoutText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Last workout completed',
                style: AppTextStyles.small,
              ),
            )
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Workout Consistency',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'You\'ve completed ${stats.totalWorkoutsCompleted} workouts in total.',
          style: AppTextStyles.small,
        ),
        const SizedBox(height: 4),
        if (stats.currentStreak > 0)
          Text(
            'Keep going! You\'re on a ${stats.currentStreak} day streak!',
            style: AppTextStyles.small.copyWith(
              color: AppColors.popGreen,
              fontWeight: FontWeight.bold,
            ),
          )
        else
          Text(
            'Start a workout today to begin a streak!',
            style: AppTextStyles.small.copyWith(
              color: AppColors.popCoral,
            ),
          ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const WorkoutHistoryScreen(),
              ),
            );
          },
          icon: const Icon(Icons.history),
          label: const Text('View Workout History'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.popBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDataWidget(String message) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: AppColors.lightGrey),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error loading data: $error',
              style: AppTextStyles.body.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}