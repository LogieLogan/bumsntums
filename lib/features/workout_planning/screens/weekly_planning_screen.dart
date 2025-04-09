// lib/features/workout_planning/screens/weekly_planning_screen.dart
import 'package:bums_n_tums/features/workout_planning/models/workout_plan.dart'; // Can likely remove this import
import 'package:bums_n_tums/features/workout_planning/providers/workout_planning_provider.dart'; // Keep for PlannerItem definition
import 'package:bums_n_tums/features/workouts/models/workout_log.dart'; // Needed for LoggedWorkoutItem type check
import 'package:bums_n_tums/features/workouts/screens/workout_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../widgets/day_schedule_card.dart';
import '../widgets/workout_day_header.dart';
import '../models/scheduled_workout.dart'; // Keep for PlannedWorkoutItem type check
import '../../../shared/theme/color_palette.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import 'package:collection/collection.dart'; // Import for groupBy

class WeeklyPlanningScreen extends ConsumerStatefulWidget {
  final String userId;

  const WeeklyPlanningScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  ConsumerState<WeeklyPlanningScreen> createState() =>
      _WeeklyPlanningScreenState();
}

class _WeeklyPlanningScreenState extends ConsumerState<WeeklyPlanningScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _currentWeekStart;
  // bool _showCalendarView = false; // Removed as it wasn't used in the provided code
  late TabController _tabController;
  final _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    // _tabController.addListener(_handleTabChange); // Listener not needed if only one tab

    // Initialize the week to the current week (starting on Monday)
    final now = DateTime.now();
    _currentWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    // --- Trigger initial fetch ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataForCurrentWeek();
    });

    _analyticsService.logScreenView(screenName: 'weekly_planning_screen');
  }

  @override
  void dispose() {
    // _tabController.removeListener(_handleTabChange); // Not needed
    _tabController.dispose();
    super.dispose();
  }

  // --- Helper to trigger fetch ---
  void _fetchDataForCurrentWeek() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    ref
        .read(plannerItemsNotifierProvider(widget.userId).notifier)
        .fetchPlannerItemsForRange(_currentWeekStart, weekEnd);
  }

  // void _handleTabChange() { // Not needed for single tab
  //   _analyticsService.logEvent(
  //     name: 'workout_planning_tab_change',
  //     parameters: {'tab_index': _tabController.index},
  //   );
  // }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _fetchDataForCurrentWeek(); // Fetch data for the new week
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
    _fetchDataForCurrentWeek(); // Fetch data for the new week
  }

  void _goToCurrentWeek() {
    final now = DateTime.now();
    final currentWeekMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    // Avoid unnecessary state change and fetch if already on current week
    if (_currentWeekStart != currentWeekMonday) {
      setState(() {
        _currentWeekStart = currentWeekMonday;
      });
      _fetchDataForCurrentWeek(); // Fetch data for the current week
    }
  }

  String _formatWeekRange() {
    final endOfWeek = _currentWeekStart.add(const Duration(days: 6));
    final formatter = DateFormat('MMM d');
    return '${formatter.format(_currentWeekStart)} - ${formatter.format(endOfWeek)}';
  }

  @override
  Widget build(BuildContext context) {
    // --- Watch the new provider ---
    final plannerItemsAsync = ref.watch(plannerItemsNotifierProvider(widget.userId));

    return Column(
      children: [
        // TabBar (remains the same)
        Container(
          color: AppColors.pink,
          child: TabBar(
            controller: _tabController,
            tabs: const [Tab(icon: Icon(Icons.view_week), text: 'Weekly Plan')],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
          ),
        ),

        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            // --- Pass the new AsyncValue state ---
            children: [_buildWeeklyView(plannerItemsAsync)],
          ),
        ),
      ],
    );
  }

  // --- Update method signature ---
  Widget _buildWeeklyView(AsyncValue<List<PlannerItem>> plannerItemsAsync) {
    return Column(
      children: [
        // Week navigation header (remains the same)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousWeek,
                iconSize: 28,
              ),
              TextButton(
                onPressed: _goToCurrentWeek,
                child: Text(
                  _formatWeekRange(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextWeek,
                iconSize: 28,
              ),
            ],
          ),
        ),

        // Main content
        Expanded(
          // --- Handle the new state type ---
          child: plannerItemsAsync.when(
            data: (items) => _buildWeeklySchedule(items), // Pass the list of items
            loading: () =>
                const LoadingIndicator(message: 'Loading your schedule...'), // Updated message
            error: (error, stack) => Center(
              child: Column( // Show error and a retry button
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading schedule: $error'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchDataForCurrentWeek,
                    child: const Text('Retry'),
                  )
                ],
              )
            ),
          ),
        ),
      ],
    );
  }

  // --- Update method signature and logic ---
  Widget _buildWeeklySchedule(List<PlannerItem> allItems) {
    // Prepare days of the week from Monday to Sunday
    final weekdays = List.generate(7, (index) {
      return _currentWeekStart.add(Duration(days: index));
    });

    // --- Group items by day ---
    final itemsByDay = allItems.groupListsBy((item) {
      // Normalize date to ignore time for grouping
      final date = item.itemDate;
      return DateTime(date.year, date.month, date.day);
    });

    return ListView.builder(
      itemCount: 7,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final day = weekdays[index];
        // Get items for the current day from the grouped map
        final itemsForDay = itemsByDay[day] ?? [];
        final isToday =
            day.year == DateTime.now().year &&
            day.month == DateTime.now().month &&
            day.day == DateTime.now().day;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WorkoutDayHeader(
              date: day,
              isToday: isToday,
              // Update workoutCount to reflect total items for the day
              workoutCount: itemsForDay.length,
            ),
            // --- Pass the items for the day to DayScheduleCard ---
            DayScheduleCard(
              day: day,
              plannerItems: itemsForDay, // Pass the filtered list
              userId: widget.userId,
              // onWorkoutTap remains conceptually similar but needs adjustment in DayScheduleCard
              onWorkoutTap: (item) {
                 if (item is PlannedWorkoutItem) {
                    // Navigate to workout detail for planned workout
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailScreen(
                          workoutId: item.scheduledWorkout.workoutId,
                        ),
                      ),
                    );
                  } else if (item is LoggedWorkoutItem) {
                    // TODO: Decide navigation for logged items (e.g., Log Detail Screen?)
                    print("Tapped logged item: ${item.workoutLog.workoutName}");
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Workout Log: ${item.workoutLog.workoutName}"))
                    );
                  }
              },
              onAddWorkout: () { // Action to schedule a NEW planned workout
                _analyticsService.logEvent(
                  name: 'add_workout_for_day_tapped',
                  parameters: {'day': DateFormat('yyyy-MM-dd').format(day)},
                );
                context
                    .push(
                      '/workout-scheduling', // Navigate to scheduling screen
                      extra: {'scheduledDate': day, 'userId': widget.userId},
                    )
                    .then((_) {
                      // --- Invalidate the provider on return ---
                      ref.invalidate(plannerItemsNotifierProvider(widget.userId));
                      // Or potentially call:
                      // ref.read(plannerItemsNotifierProvider(widget.userId).notifier).refreshCurrentRange();
                    });
              },
              // --- Add new callback for logging ---
              onLogWorkout: () {
                _analyticsService.logEvent(
                    name: 'log_workout_for_day_tapped',
                    parameters: {'day': DateFormat('yyyy-MM-dd').format(day)},
                  );
                 // TODO: Implement navigation/modal for manual logging screen
                 print("Log workout action tapped for $day");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Log workout for $day (Not Implemented Yet)"))
                  );
              }
            ),
            if (index < 6) const Divider(height: 16.0),
          ],
        );
      },
    );
  }
}