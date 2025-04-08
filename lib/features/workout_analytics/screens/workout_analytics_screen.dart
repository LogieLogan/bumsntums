// lib/features/workout_analytics/screens/workout_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/workout_stats.dart';
import '../models/workout_analytics_timeframe.dart';
import '../../workouts/models/workout_streak.dart';
import '../providers/workout_stats_provider.dart';
import '../widgets/workout_progress_chart.dart';
import '../widgets/body_focus_chart.dart';
import '../widgets/workout_calendar_heatmap.dart';
import '../widgets/analytics_stat_card.dart';
import '../widgets/period_selector.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class WorkoutAnalyticsScreen extends ConsumerStatefulWidget {
  final String userId;

  const WorkoutAnalyticsScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  ConsumerState<WorkoutAnalyticsScreen> createState() => _WorkoutAnalyticsScreenState();
}

class _WorkoutAnalyticsScreenState extends ConsumerState<WorkoutAnalyticsScreen> with SingleTickerProviderStateMixin {
  final _analyticsService = AnalyticsService();
  late TabController _tabController;
  AnalyticsTimeframe _timeframe = AnalyticsTimeframe.monthly;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _analyticsService.logScreenView(screenName: 'workout_analytics_screen');
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userStatsAsync = ref.watch(userWorkoutStatsProvider(widget.userId));
    final userStreakAsync = ref.watch(userWorkoutStreakProvider(widget.userId));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Analytics', style: AppTextStyles.h2),
        centerTitle: true,
        backgroundColor: AppColors.salmon,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: PeriodSelector(
              selectedPeriod: _timeframe,
              onPeriodChanged: (value) {
                setState(() {
                  _timeframe = value;
                });
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(userWorkoutStatsProvider(widget.userId));
          ref.refresh(userWorkoutStreakProvider(widget.userId));
          ref.refresh(workoutFrequencyDataProvider((userId: widget.userId, days: 90)));
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                userStatsAsync.when(
                  data: (stats) => _buildSummarySection(stats, context),
                  loading: () => const SizedBox(height: 200, child: LoadingIndicator()),
                  error: (error, _) => _buildErrorWidget(error),
                ),
                
                const SizedBox(height: 24),
                
                // Current streak section
                userStreakAsync.when(
                  data: (streak) => _buildStreakSection(streak, context, ref),
                  loading: () => const SizedBox(height: 150, child: LoadingIndicator()),
                  error: (error, _) => _buildErrorWidget(error),
                ),
                
                const SizedBox(height: 24),
                
                // Progress section
                Text('Your Progress', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                userStatsAsync.when(
                  data: (stats) => WorkoutProgressChart(
                    stats: stats,
                    timeframe: _timeframe,
                  ),
                  loading: () => const SizedBox(height: 200, child: LoadingIndicator()),
                  error: (error, _) => _buildErrorWidget(error),
                ),
                
                const SizedBox(height: 24),
                
                // Body focus distribution
                Text('Body Focus Areas', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                userStatsAsync.when(
                  data: (stats) => BodyFocusChart(
                    workoutsByCategory: stats.workoutsByCategory,
                    totalWorkouts: stats.totalWorkoutsCompleted,
                  ),
                  loading: () => const SizedBox(height: 250, child: LoadingIndicator()),
                  error: (error, _) => _buildErrorWidget(error),
                ),
                
                const SizedBox(height: 24),
                
                // Workout calendar heatmap
                Text('Workout Calendar', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const WorkoutCalendarHeatmap(),
                
                const SizedBox(height: 24),
                
                // Activity pattern
                Text('Activity Pattern', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                userStatsAsync.when(
                  data: (stats) => _buildActivityPatternChart(stats),
                  loading: () => const SizedBox(height: 200, child: LoadingIndicator()),
                  error: (error, _) => _buildErrorWidget(error),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(UserWorkoutStats stats, BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.salmon,
            AppColors.salmon.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Summary',
              style: AppTextStyles.h3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryStat(
                    value: stats.totalWorkoutsCompleted.toString(),
                    label: 'Total Workouts',
                    icon: Icons.fitness_center,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStat(
                    value: '${stats.totalWorkoutMinutes}',
                    label: 'Total Minutes',
                    icon: Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStat(
                    value: '${stats.caloriesBurned}',
                    label: 'Calories Burned',
                    icon: Icons.local_fire_department,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stats.averageWorkoutDuration > 30
                        ? Icons.thumb_up
                        : Icons.info_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Avg. workout: ${stats.averageWorkoutDuration} min',
                    style: AppTextStyles.small.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.small.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStreakSection(
    WorkoutStreak streak,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: AppColors.popYellow, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Current Streak',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: streak.isStreakActive
                              ? AppColors.popYellow.withOpacity(0.1)
                              : AppColors.mediumGrey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              streak.currentStreak.toString(),
                              style: AppTextStyles.h1.copyWith(
                                color: streak.isStreakActive
                                    ? AppColors.popYellow
                                    : AppColors.mediumGrey,
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
            ),
          ],
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
    final maxValue = stats.workoutsByDayOfWeek.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: days.map((day) {
              final index = days.indexOf(day);
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      day,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120 * (stats.workoutsByDayOfWeek[index] / maxValue),
                      width: 25,
                      decoration: BoxDecoration(
                        color: _getActivityBarColor(stats.workoutsByDayOfWeek[index], maxValue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stats.workoutsByDayOfWeek[index].toString(),
                      style: AppTextStyles.small.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Most active day: ${days[stats.workoutsByDayOfWeek.indexOf(maxValue.toInt())]}',
              style: AppTextStyles.body.copyWith(
                color: AppColors.darkGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityBarColor(int value, double maxValue) {
    if (value == 0) return AppColors.lightGrey;
    
    final ratio = value / maxValue;
    if (ratio < 0.3) return AppColors.popGreen.withOpacity(0.5);
    if (ratio < 0.6) return AppColors.popGreen.withOpacity(0.7);
    return AppColors.popGreen;
  }

  Widget _buildEmptyDataWidget(String message) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
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
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                ref.refresh(userWorkoutStatsProvider(widget.userId));
                ref.refresh(userWorkoutStreakProvider(widget.userId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _useStreakProtection(BuildContext context, WidgetRef ref) async {
    final actionsNotifier = ref.read(workoutStatsActionsProvider.notifier);
    final success = await actionsNotifier.useStreakProtection(widget.userId);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Streak protection applied!'),
          backgroundColor: AppColors.popGreen,
        ),
      );

      // Refresh the streak data
      ref.refresh(userWorkoutStreakProvider(widget.userId));
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