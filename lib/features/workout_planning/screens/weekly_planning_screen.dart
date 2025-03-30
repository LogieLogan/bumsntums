// lib/features/workout_planning/screens/weekly_planning_screen.dart
import 'package:bums_n_tums/features/workout_planning/models/workout_plan.dart';
import 'package:bums_n_tums/features/workout_planning/providers/workout_planning_provider.dart';
import 'package:bums_n_tums/features/workout_planning/screens/ai_plan_creation_screen.dart';
import 'package:bums_n_tums/features/workout_planning/widgets/plan_analytics_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../widgets/day_schedule_card.dart';
import '../widgets/workout_day_header.dart';
import '../widgets/calendar_view.dart';
import '../models/scheduled_workout.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

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
  bool _showCalendarView = false;
  late TabController _tabController;
  final _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Initialize the week to the current week (starting on Monday)
    final now = DateTime.now();
    _currentWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    _analyticsService.logScreenView(screenName: 'weekly_planning_screen');
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      _showCalendarView = _tabController.index == 1;
    });

    _analyticsService.logEvent(
      name: 'workout_planning_tab_change',
      parameters: {'tab_index': _tabController.index},
    );
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _goToCurrentWeek() {
    final now = DateTime.now();
    setState(() {
      _currentWeekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
    });
  }

  String _formatWeekRange() {
    final endOfWeek = _currentWeekStart.add(const Duration(days: 6));
    final formatter = DateFormat('MMM d');
    return '${formatter.format(_currentWeekStart)} - ${formatter.format(endOfWeek)}';
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(workoutPlanningNotifierProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_showCalendarView ? 'Workout Calendar' : 'Workout Plan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly Plan', icon: Icon(Icons.view_week)),
            Tab(text: 'Calendar', icon: Icon(Icons.calendar_today)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeeklyView(planState),
          if (planState.value != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: PlanAnalyticsCard(plan: planState.value!),
            ),
            const SizedBox(height: 16),
          ],

          CalendarView(
            userId: widget.userId,
            onDaySelected: (selectedDay) {
              // Navigate to day detail or handle selection
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_workout',
            onPressed: () {
              _analyticsService.logEvent(name: 'add_scheduled_workout_tapped');
              context
                  .push(
                    '/workout-scheduling',
                    extra: {
                      'scheduledDate': DateTime.now(),
                      'userId': widget.userId,
                    },
                  )
                  .then((_) {
                    // Refresh data when returning from workout selection
                    final _ = ref.refresh(
                      workoutPlanningNotifierProvider(widget.userId),
                    );
                  });
            },
            child: const Icon(Icons.add),
            backgroundColor: AppColors.pink,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'ai_plan',
            onPressed: () {
              _analyticsService.logEvent(name: 'create_ai_plan_tapped');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AIPlanCreationScreen(userId: widget.userId),
                ),
              ).then((_) {
                // Refresh data when returning from AI plan creation
                final _ = ref.refresh(
                  workoutPlanningNotifierProvider(widget.userId),
                );
              });
            },
            label: const Text('AI Plan'),
            icon: const Icon(Icons.auto_awesome),
            backgroundColor: AppColors.popBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyView(AsyncValue<WorkoutPlan?> planState) {
    return Column(
      children: [
        // Week navigation header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousWeek,
              ),
              TextButton(
                onPressed: _goToCurrentWeek,
                child: Text(
                  _formatWeekRange(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextWeek,
              ),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: planState.when(
            data: (plan) => _buildWeeklySchedule(plan),
            loading:
                () =>
                    const LoadingIndicator(message: 'Loading your workouts...'),
            error:
                (error, stack) =>
                    Center(child: Text('Error loading workout plan: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySchedule(WorkoutPlan? plan) {
    // Prepare days of the week from Monday to Sunday
    final weekdays = List.generate(7, (index) {
      return _currentWeekStart.add(Duration(days: index));
    });

    // Get workouts for each day
    final workoutsByDay = <DateTime, List<ScheduledWorkout>>{};
    for (final day in weekdays) {
      workoutsByDay[day] = plan?.getWorkoutsForDay(day) ?? [];
    }

    return ListView.builder(
      itemCount: 7,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final day = weekdays[index];
        final workouts = workoutsByDay[day] ?? [];
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
              workoutCount: workouts.length,
            ),
            // lib/features/workout_planning/screens/weekly_planning_screen.dart (continued)
            if (workouts.isEmpty)
              DayScheduleCard(
                day: day,
                workouts: [],
                userId: widget.userId,
                onWorkoutTap: (workout) {
                  // Navigate to workout detail
                },
                onAddWorkout: () {
                  // Navigate to workout selection screen for this specific day
                  _analyticsService.logEvent(
                    name: 'add_workout_for_day_tapped',
                    parameters: {'day': DateFormat('yyyy-MM-dd').format(day)},
                  );

                  context.push('/workout-scheduling').then((_) {
                    // Refresh data when returning from workout selection
                    final _ = ref.refresh(
                      workoutPlanningNotifierProvider(widget.userId),
                    );
                  });
                },
              )
            else
              DayScheduleCard(
                day: day,
                workouts: workouts,
                userId: widget.userId,
                onWorkoutTap: (workout) {
                  // Navigate to workout detail
                  context.push('/workout-detail/${workout.workoutId}');
                },
                onAddWorkout: () {
                  // Navigate to workout selection screen for this specific day
                  _analyticsService.logEvent(
                    name: 'add_workout_for_day_tapped',
                    parameters: {'day': DateFormat('yyyy-MM-dd').format(day)},
                  );

                  context
                      .push('/workout-browse', extra: {'scheduledDate': day})
                      .then((_) {
                        // Refresh data when returning from workout selection
                        final _ = ref.refresh(
                          workoutPlanningNotifierProvider(widget.userId),
                        );
                      });
                },
              ),

            // Add a divider if not the last day
            if (index < 6) const Divider(height: 16.0),
          ],
        );
      },
    );
  }
}
