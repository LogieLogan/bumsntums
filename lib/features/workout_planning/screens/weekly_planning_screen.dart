// lib/features/workout_planning/screens/weekly_planning_screen.dart
import 'package:bums_n_tums/features/workout_planning/models/planner_item.dart';
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
import '../../../shared/analytics/firebase_analytics_service.dart'; // Import Analytics

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
  // Instantiate AnalyticsService if needed directly, or use provider
  final AnalyticsService _analyticsService =
      AnalyticsService(); // Or ref.read(analyticsProvider) if preferred

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _analyticsService.logScreenView(screenName: 'weekly_planning');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (kDebugMode) {
          print("initState: addPostFrameCallback triggering initial fetch.");
        }
        _fetchDataForWeek(_selectedWeekStart);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchDataForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    _analyticsService.logEvent(
      name: 'plan_fetch_week',
      parameters: {'week_start': DateFormat('yyyy-MM-dd').format(weekStart)},
    );
    if (kDebugMode) {
      print("Fetching data for range: $weekStart to $weekEnd");
    }
    ref
        .read(plannerItemsNotifierProvider(widget.userId).notifier)
        .fetchPlannerItemsForRange(weekStart, weekEnd);
  }

  // Use DateTime.monday for consistency
  static DateTime _getStartOfWeek(DateTime date) {
    int daysToSubtract = date.weekday - DateTime.monday;
    if (daysToSubtract < 0) {
      daysToSubtract += 7; // Handle cases where weekday is Sunday (7)
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  void _changeWeek(int weeksToAdd) {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(
        Duration(days: weeksToAdd * 7),
      );
      _analyticsService.logEvent(
        name: 'plan_change_week',
        parameters: {
          'direction': weeksToAdd > 0 ? 'next' : 'previous',
          'new_week_start': DateFormat('yyyy-MM-dd').format(_selectedWeekStart),
        },
      );
      if (kDebugMode) {
        print("Week changed, fetching new data for $_selectedWeekStart.");
      }
      _fetchDataForWeek(_selectedWeekStart);
    });
  }

  // --- Add Go To Today Method ---
  void _goToToday() {
    final today = DateTime.now();
    final startOfCurrentWeek = _getStartOfWeek(today);
    if (_selectedWeekStart != startOfCurrentWeek) {
      _analyticsService.logEvent(name: 'plan_go_to_today');
      setState(() {
        _selectedWeekStart = startOfCurrentWeek;
        if (kDebugMode) {
          print(
            "Navigating to current week ($_selectedWeekStart), fetching data.",
          );
        }
        _fetchDataForWeek(_selectedWeekStart);
      });
      // Optionally scroll to today if needed
      // _scrollToToday(); // Implement if necessary
    }
  }
  // --- End Go To Today Method ---

  Future<void> _navigateAndScheduleWorkout(DateTime date) async {
    _analyticsService.logEvent(
      name: 'plan_navigate_schedule',
      parameters: {'date': DateFormat('yyyy-MM-dd').format(date)},
    );
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
      _analyticsService.logEvent(name: 'plan_schedule_success');
      if (kDebugMode) {
        print("Scheduling successful, invalidating and re-fetching data...");
      }
      // Refresh data
      _fetchDataForWeek(_selectedWeekStart);
    }
  }

  Future<void> _navigateAndLogWorkout(DateTime date) async {
    _analyticsService.logEvent(
      name: 'plan_navigate_log',
      parameters: {'date': DateFormat('yyyy-MM-dd').format(date)},
    );
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

    if (logSuccess == true && mounted) {
      _analyticsService.logEvent(name: 'plan_log_success');
      if (kDebugMode) {
        print("Logging successful, invalidating and re-fetching data...");
      }
      // Refresh data
      _fetchDataForWeek(_selectedWeekStart);
    }
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
      appBar: AppBar(
        title: const Text('Weekly Plan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to Today',
            onPressed: _goToToday,
          ),
        ],
      ),
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
              // --- Corrected Error Builder ---
              error: (error, stack) {
                if (kDebugMode) {
                  print("Error loading plan: $error\n$stack");
                }
                // Call logError WITHOUT stackTrace parameter
                _analyticsService.logError(
                  error: 'Failed to load weekly plan: ${error.toString()}',
                  // stackTrace: stack, // REMOVED THIS LINE
                  parameters: {'user_id': widget.userId},
                );
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
                          'Could not load your plan. Please check your connection and try again.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        if (kDebugMode)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              error.toString(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _analyticsService.logEvent(
                              name: 'plan_retry_fetch',
                            );
                            if (kDebugMode) {
                              print("Retrying fetch...");
                            }
                            _fetchDataForWeek(_selectedWeekStart);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              // --- End Corrected Error Builder ---
            ),
          ),
        ],
      ),
    );
  }

  // _buildWeekView remains the same as the last corrected version
  Widget _buildWeekView(List<PlannerItem> allItems, BuildContext context) {
    // Group items by the start of the day to handle potential time zone issues
    final itemsByDay = groupBy(allItems, (PlannerItem item) {
      final localDate =
          item.itemDate.toLocal(); // Convert to local time zone for grouping
      return DateTime(localDate.year, localDate.month, localDate.day);
    });
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day); // Key for today

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
        final dayItems =
            itemsByDay[dayDateKey] ?? []; // Get items for this specific day
        final bool isToday = dayDateKey == todayKey; // Check if it's today

        if (kDebugMode) {
          final itemDetails =
              dayItems.map((item) {
                String idString;
                if (item is PlannedWorkoutItem) {
                  idString = item.scheduledWorkout.id;
                } else if (item is LoggedWorkoutItem) {
                  idString = item.workoutLog.id;
                } else {
                  idString = 'unknown_id';
                }
                return '(${item.runtimeType} ID: $idString Date: ${item.itemDate.toLocal()})';
              }).toList();

          print("Building Day ${index + 1}: $dayDateKey (Is Today: $isToday)");
          print("  Items for this day: ${dayItems.length}");
          if (dayItems.isNotEmpty) {
            print("  Item Details: $itemDetails");
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
              // Pass the correctly typed items for the day
              DayScheduleCard(
                day: dayDate,
                plannerItems: dayItems,
                userId: widget.userId,
                currentWeekStart: _selectedWeekStart,
                onAddWorkout: () => _navigateAndScheduleWorkout(dayDate),
                onLogWorkout: () => _navigateAndLogWorkout(dayDate),
              ),
            ],
          ),
        );
      },
    );
  }
} // End of _WeeklyPlanningScreenState
