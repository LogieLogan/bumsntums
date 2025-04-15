// lib/features/workout_planning/screens/weekly_planning_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../providers/workout_planning_provider.dart';
import '../widgets/day_schedule_card.dart';
import '../widgets/workout_day_header.dart';
import 'workout_scheduling_screen.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/app_colors.dart';

class WeeklyPlanningScreen extends ConsumerStatefulWidget {
  final String userId;

  const WeeklyPlanningScreen({required this.userId, super.key});

  @override
  ConsumerState<WeeklyPlanningScreen> createState() =>
      _WeeklyPlanningScreenState();
}

class _WeeklyPlanningScreenState extends ConsumerState<WeeklyPlanningScreen> {
  DateTime _selectedWeekStart = _getStartOfWeek(DateTime.now());
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print("initState: addPostFrameCallback triggering initial fetch.");
        _fetchDataForWeek(_selectedWeekStart);
      }
    });
  }

  @override
  void dispose() {
    // Add this line:
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchDataForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));

    print("Fetching data for range: $weekStart to $weekEnd");
    ref
        .read(plannerItemsNotifierProvider(widget.userId).notifier)
        .fetchPlannerItemsForRange(weekStart, weekEnd);
  }

  static DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _changeWeek(int weeksToAdd) {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(
        Duration(days: weeksToAdd * 7),
      );
      print("Week changed, fetching new data.");
      _fetchDataForWeek(_selectedWeekStart);
    });
  }

  Future<void> _navigateAndScheduleWorkout(DateTime date) async {
    final bool? scheduleSuccess = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (context) => WorkoutSchedulingScreen(
              userId: widget.userId,
              scheduledDate: date,
              isLoggingMode: false,
            ),
      ),
    );

    if (scheduleSuccess == true && mounted) {
      print("Scheduling successful, invalidating and re-fetching data...");
    }
  }

  Future<void> _navigateAndLogWorkout(DateTime date) async {
    final bool? logSuccess = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (context) => WorkoutSchedulingScreen(
              userId: widget.userId,
              scheduledDate: date,
              isLoggingMode: true,
            ),
      ),
    );
    // --- Start of Changed Refresh Logic ---
    if (logSuccess == true && mounted) {
      print("Logging successful, invalidating and re-fetching data...");
    }
    // --- End of Changed Refresh Logic ---
  }

  @override
  Widget build(BuildContext context) {
    final plannerItemsState = ref.watch(
      plannerItemsNotifierProvider(widget.userId),
    );
    final weekStartFormatted = DateFormat('MMM d').format(_selectedWeekStart);
    final weekEndFormatted = DateFormat(
      'MMM d, yyyy',
    ).format(_selectedWeekStart.add(const Duration(days: 6)));

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeWeek(-1),
                  tooltip: 'Previous Week',
                ),
                Text(
                  '$weekStartFormatted - $weekEndFormatted',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeWeek(1),
                  tooltip: 'Next Week',
                ),
              ],
            ),
          ),

          Expanded(
            child: plannerItemsState.when(
              data: (items) {
                if (kDebugMode) {
                  print(
                    "Data received, building week view with ${items.length} items.",
                  );
                }
                return _buildWeekView(items, context);
              },
              loading: () {
                if (kDebugMode) {
                  print("Displaying loading indicator.");
                }

                return const Center(
                  child: LoadingIndicator(message: 'Loading schedule...'),
                );
              },
              error: (error, stack) {
                if (kDebugMode) {
                  print("Error loading plan: $error\n$stack");
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Schedule',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            print("Retrying fetch...");

                            ref.invalidate(
                              plannerItemsNotifierProvider(widget.userId),
                            );
                            _fetchDataForWeek(_selectedWeekStart);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(List<PlannerItem> allItems, BuildContext context) {
    final itemsByDay = groupBy(allItems, (PlannerItem item) {
      final date = item.itemDate;

      return DateTime(date.year, date.month, date.day);
    });
    final now = DateTime.now();

    if (kDebugMode) {
      print("--- Building Week View (Total Items: ${allItems.length}) ---");
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16.0),
      itemCount: 7,
      separatorBuilder:
          (context, index) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final dayDate = _selectedWeekStart.add(Duration(days: index));

        final dayDateKey = DateTime(dayDate.year, dayDate.month, dayDate.day);
        final dayItems = itemsByDay[dayDateKey] ?? [];

        final bool isToday =
            now.year == dayDate.year &&
            now.month == dayDate.month &&
            now.day == dayDate.day;

        if (kDebugMode) {
          print("Building Day ${index + 1}: $dayDateKey");
        }
        if (kDebugMode) {
          print("  Items for this day: ${dayItems.length}");
        }
        if (dayItems.isNotEmpty) {
          if (kDebugMode) {
            print(
              "  Item Details: ${dayItems.map((item) => '(${item.runtimeType} ID: ${item.id} Date: ${item.itemDate})').toList()}",
            );
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorkoutDayHeader(
                date: dayDate,
                isToday: isToday,
                workoutCount: dayItems.length,
              ),
              const SizedBox(height: 8),
              DayScheduleCard(
                day: dayDate,
                plannerItems: dayItems,
                userId: widget.userId,
                currentWeekStart: _selectedWeekStart,
                // onWorkoutTap: (item) {
                //   if (kDebugMode) {
                //     print("Tapped on item: ${item.id}");
                //   }
                // },
                onAddWorkout: () => _navigateAndScheduleWorkout(dayDate),
                onLogWorkout: () => _navigateAndLogWorkout(dayDate),
              ),
            ],
          ),
        );
      },
    );
  }
}
