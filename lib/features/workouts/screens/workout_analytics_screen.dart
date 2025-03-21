// lib/features/workouts/screens/workout_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/workout_stats.dart';
import '../models/workout_streak.dart';
import '../providers/workout_stats_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/indicators/loading_indicator.dart';

class WorkoutAnalyticsScreen extends ConsumerWidget {
  final String userId;

  const WorkoutAnalyticsScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userWorkoutStatsProvider(userId));
    final userStreakAsync = ref.watch(userWorkoutStreakProvider(userId));
    final workoutFrequencyAsync = ref.watch(
      workoutFrequencyDataProvider((
        userId: userId,
        days: 90, // Last 90 days
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('My Progress', style: AppTextStyles.h2),
        centerTitle: true,
        backgroundColor: AppColors.salmon,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'Workout Summary',
                icon: Icons.summarize,
                child: userStatsAsync.when(
                  data: (stats) => _buildSummaryStats(stats),
                  loading: () => const LoadingIndicator(),
                  error: (error, _) => _buildErrorWidget(error),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Current Streak',
                icon: Icons.local_fire_department,
                child: userStreakAsync.when(
                  data: (streak) => _buildStreakWidget(streak, context, ref),
                  loading: () => const LoadingIndicator(),
                  error: (error, _) => _buildErrorWidget(error),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Workout Frequency',
                icon: Icons.insights,
                child: workoutFrequencyAsync.when(
                  data: (frequencyData) => _buildFrequencyChart(frequencyData),
                  loading: () => const LoadingIndicator(),
                  error: (error, _) => _buildErrorWidget(error),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Body Focus Distribution',
                icon: Icons.pie_chart,
                child: userStatsAsync.when(
                  data: (stats) => _buildBodyFocusChart(stats),
                  loading: () => const LoadingIndicator(),
                  error: (error, _) => _buildErrorWidget(error),
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Activity Pattern',
                icon: Icons.access_time,
                child: userStatsAsync.when(
                  data: (stats) => _buildActivityPatternChart(stats),
                  loading: () => const LoadingIndicator(),
                  error: (error, _) => _buildErrorWidget(error),
                ),
              ),
            ],
          ),
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

  Widget _buildSummaryStats(UserWorkoutStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                value: stats.totalWorkoutsCompleted.toString(),
                label: 'Total Workouts',
                icon: Icons.fitness_center,
                color: AppColors.salmon,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                value: '${stats.totalWorkoutMinutes}',
                label: 'Total Minutes',
                icon: Icons.timer,
                color: AppColors.popBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                value: '${stats.averageWorkoutDuration}',
                label: 'Avg. Duration',
                icon: Icons.access_time,
                color: AppColors.popTurquoise,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                value: '${stats.caloriesBurned}',
                label: 'Calories Burned',
                icon: Icons.local_fire_department,
                color: AppColors.popCoral,
              ),
            ),
          ],
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

  Widget _buildStreakWidget(
    WorkoutStreak streak,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.salmon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      streak.currentStreak.toString(),
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.salmon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current Streak',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!streak.isStreakActive && streak.currentStreak > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed:
                              streak.streakProtectionsRemaining > 0
                                  ? () {
                                    _useStreakProtection(context, ref);
                                  }
                                  : null,
                          icon: const Icon(Icons.shield),
                          label: const Text('Protect Streak'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.salmon,
                            side: const BorderSide(color: AppColors.salmon),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                streak.streakProtectionsRemaining > 0
                    ? '${streak.streakProtectionsRemaining} streak protections available'
                    : 'No streak protections available',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mediumGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.popGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  streak.longestStreak.toString(),
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.popGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Longest Streak',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTrendChart(UserWorkoutStats stats) {
    if (stats.monthlyTrend.isEmpty) {
      return _buildEmptyDataWidget('No progress trend data available');
    }

    // Create month labels
    final now = DateTime.now();
    final labels = List.generate(6, (index) {
      final month = now.month - (5 - index);
      final adjustedMonth = month <= 0 ? month + 12 : month;
      return _getMonthAbbreviation(adjustedMonth);
    });

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              stats.monthlyTrend.reduce((a, b) => a > b ? a : b).toDouble() + 1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[value.toInt()],
                        style: AppTextStyles.caption,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            6,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: stats.monthlyTrend[index].toDouble(),
                  color: AppColors.popBlue,
                  width: 25,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildFrequencyChart(List<Map<String, dynamic>> frequencyData) {
    if (frequencyData.isEmpty) {
      return _buildEmptyDataWidget('No workout frequency data available');
    }

    // Process data for chart
    final spots = <FlSpot>[];
    for (int i = 0; i < frequencyData.length; i++) {
      spots.add(FlSpot(i.toDouble(), frequencyData[i]['count'].toDouble()));
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 15 == 0 &&
                      value.toInt() < frequencyData.length) {
                    final date = frequencyData[value.toInt()]['date'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        date.split('-').sublist(1).join('-'), // Show MM-DD
                        style: AppTextStyles.caption,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.salmon,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.salmon.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyFocusChart(UserWorkoutStats stats) {
    if (stats.workoutsByCategory.isEmpty) {
      return _buildEmptyDataWidget('No body focus data available');
    }

    // Process data for pie chart
    final sections =
        stats.workoutsByCategory.entries.map((entry) {
          final color = _getCategoryColor(entry.key);
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: '${entry.key}\n${entry.value}',
            color: color,
            radius: 100,
            titleStyle: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildActivityPatternChart(UserWorkoutStats stats) {
    if (stats.workoutsByDayOfWeek.every((count) => count == 0)) {
      return _buildEmptyDataWidget('No activity pattern data available');
    }

    // Days of week labels
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              stats.workoutsByDayOfWeek
                  .reduce((a, b) => a > b ? a : b)
                  .toDouble() +
              1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        days[value.toInt()],
                        style: AppTextStyles.caption,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            7,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: stats.workoutsByDayOfWeek[index].toDouble(),
                  color: AppColors.salmon,
                  width: 25,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            Icon(Icons.bar_chart, size: 64, color: AppColors.lightGrey),
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'bums':
        return AppColors.salmon;
      case 'tums':
        return AppColors.popCoral;
      case 'fullbody':
        return AppColors.popBlue;
      case 'cardio':
        return AppColors.popGreen;
      case 'quick':
        return AppColors.popTurquoise;
      default:
        return AppColors.mediumGrey;
    }
  }

  void _useStreakProtection(BuildContext context, WidgetRef ref) async {
    final actionsNotifier = ref.read(workoutStatsActionsProvider.notifier);

    final success = await actionsNotifier.useStreakProtection(userId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Streak protection applied!'),
          backgroundColor: AppColors.popGreen,
        ),
      );

      // Refresh the streak data
      ref.refresh(userWorkoutStreakProvider(userId));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to apply streak protection'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
