// lib/features/workout_analytics/widgets/workout_calendar_heatmap.dart
// Modified version to fix PageView issue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/workout_stats_provider.dart';
import '../../../shared/components/indicators/loading_indicator.dart';

class WorkoutCalendarHeatmap extends ConsumerStatefulWidget {
  final int months;
  final int daysToFetch;

  const WorkoutCalendarHeatmap({
    Key? key,
    this.months = 3, // Show 3 months by default
    this.daysToFetch = 90, // Fetch 90 days for 3 months
  }) : super(key: key);

  @override
  ConsumerState<WorkoutCalendarHeatmap> createState() =>
      _WorkoutCalendarHeatmapState();
}

class _WorkoutCalendarHeatmapState
    extends ConsumerState<WorkoutCalendarHeatmap> {
  int _currentMonthIndex = 0;
  late List<DateTime> _monthsToShow;

  @override
  void initState() {
    super.initState();
    _initMonths();
  }

  void _initMonths() {
    final now = DateTime.now();
    _monthsToShow =
        List.generate(widget.months, (index) {
          final month = now.month - index;
          final year = now.year - (month <= 0 ? 1 : 0);
          final adjustedMonth = month <= 0 ? month + 12 : month;
          return DateTime(year, adjustedMonth, 1);
        }).reversed.toList();

    _currentMonthIndex =
        _monthsToShow.length - 1; // Start with the current month
  }

  void _nextMonth() {
    if (_currentMonthIndex < _monthsToShow.length - 1) {
      setState(() {
        _currentMonthIndex++;
      });
    }
  }

  void _previousMonth() {
    if (_currentMonthIndex > 0) {
      setState(() {
        _currentMonthIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      "WorkoutCalendarHeatmap building. Watching frequency data with days: ${widget.daysToFetch}",
    );
    final userId = ref.watch(authStateProvider).value?.uid;

    // --- Watch the Provider ---
    // Watch the provider for frequency data
    final frequencyDataAsync = ref.watch(
      workoutFrequencyDataProvider(
        (
          userId: userId ?? '',
          days: widget.daysToFetch,
        ), // Provide default empty ID if null
      ),
    );

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
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: _currentMonthIndex > 0 ? _previousMonth : null,
                color:
                    _currentMonthIndex > 0
                        ? AppColors.salmon
                        : AppColors.lightGrey,
              ),
              Text(
                DateFormat(
                  'MMMM yyyy',
                ).format(_monthsToShow[_currentMonthIndex]),
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed:
                    _currentMonthIndex < _monthsToShow.length - 1
                        ? _nextMonth
                        : null,
                color:
                    _currentMonthIndex < _monthsToShow.length - 1
                        ? AppColors.salmon
                        : AppColors.lightGrey,
              ),
            ],
          ),
          const SizedBox(height: 16),

          frequencyDataAsync.when(
            data: (frequencyDataList) {
              // --- Convert the List<Map> to Map<String, int> for easy lookup ---
              final Map<String, int> workoutData = {
                for (var item in frequencyDataList)
                  item['date'] as String: item['count'] as int,
              };

              // --- Build Calendar with real data ---
              return AspectRatio(
                aspectRatio: 1.2,
                child: _buildCalendarMonth(
                  _monthsToShow[_currentMonthIndex],
                  workoutData, // <-- Use the fetched and converted data
                ),
              );
            },
            loading:
                () => const AspectRatio(
                  aspectRatio: 1.2, // Maintain size while loading
                  child: Center(child: LoadingIndicator()),
                ),
            error:
                (error, stack) => AspectRatio(
                  aspectRatio: 1.2, // Maintain size on error
                  child: Center(
                    child: Text(
                      'Error loading heatmap: $error',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
          ),

          const SizedBox(height: 16),

          // Legend
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildLegendItem('None', AppColors.offWhite),
              _buildLegendItem('1 Workout', AppColors.salmon.withOpacity(0.3)),
              _buildLegendItem('2 Workouts', AppColors.salmon.withOpacity(0.6)),
              _buildLegendItem('3+ Workouts', AppColors.salmon),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarMonth(DateTime month, Map<String, int> workoutData) {
    // Get total days in month
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // Get weekday of first day (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
    final firstDayWeekday = DateTime(month.year, month.month, 1).weekday % 7;

    // Days of week
    const days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    final shortHash = workoutData.hashCode.toRadixString(16);
    print(
      "_buildCalendarMonth (${DateFormat('MMMM yyyy').format(month)}): Using workoutData map (hash: $shortHash)",
    );

    return Column(
      children: [
        // Days of week header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:
              days
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.mediumGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: (daysInMonth + firstDayWeekday),
            itemBuilder: (context, index) {
              if (index < firstDayWeekday) {
                return const SizedBox.shrink(); // Empty cells before month starts
              }

              final day = index - firstDayWeekday + 1;
              final date = DateTime(month.year, month.month, day);
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final workoutCount = workoutData[dateStr] ?? 0;
              final isToday =
                  DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;

              if (workoutCount > 0 || isToday) {
                print(
                  "_buildCalendarMonth: Checking $dateStr, found count: $workoutCount",
                );
              }

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _getColorForWorkouts(workoutCount),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      isToday
                          ? Border.all(color: AppColors.salmon, width: 2)
                          : null,
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: AppTextStyles.small.copyWith(
                      color:
                          workoutCount > 0 || isToday
                              ? AppColors.darkGrey
                              : AppColors.mediumGrey,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getColorForWorkouts(int count) {
    if (count == 0) return AppColors.offWhite;
    if (count == 1) return AppColors.salmon.withOpacity(0.3);
    if (count == 2) return AppColors.salmon.withOpacity(0.6);
    return AppColors.salmon; // 3+ workouts
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border:
                color == AppColors.offWhite
                    ? Border.all(color: AppColors.lightGrey)
                    : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.mediumGrey),
        ),
      ],
    );
  }
}
