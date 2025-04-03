// lib/features/workout_planning/screens/weekly_planning_screen.dart
import 'package:bums_n_tums/features/workout_planning/models/workout_plan.dart';
import 'package:bums_n_tums/features/workout_planning/providers/workout_planning_provider.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_detail_screen.dart';
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

    return Column(
      children: [
        // App bar with actions
        // AppBar(
        //   title: const Text('Plan'),
        //   actions: [
        //     IconButton(
        //       icon: const Icon(Icons.save_alt),
        //       onPressed: _navigateToSavedPlans,
        //       tooltip: 'Saved Plans',
        //     ),
        //   ],
        // ),

        // TabBar
        Container(
          color: AppColors.pink,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.view_week), text: 'Weekly Plan'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
          ),
        ),

        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildWeeklyView(planState),
              CalendarView(
                userId: widget.userId,
                onDaySelected: (selectedDay) {
                  // Handle day selection
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyView(AsyncValue<WorkoutPlan?> planState) {
    return Column(
      children: [
        // Week navigation header
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

        // AI Plan Card
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
        //   child: Card(
        //     elevation: 2,
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //     child: InkWell(
        //       onTap: () {
        //         _analyticsService.logEvent(name: 'create_ai_plan_tapped');
        //         Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //             builder:
        //                 (context) =>
        //                     AIPlanCreationScreen(userId: widget.userId),
        //           ),
        //         ).then((_) {
        //           final _ = ref.refresh(
        //             workoutPlanningNotifierProvider(widget.userId),
        //           );
        //         });
        //       },
        //       borderRadius: BorderRadius.circular(12),
        //       child: Padding(
        //         padding: const EdgeInsets.all(16.0),
        //         child: Row(
        //           children: [
        //             Container(
        //               padding: const EdgeInsets.all(10.0),
        //               decoration: BoxDecoration(
        //                 color: AppColors.popBlue.withOpacity(0.1),
        //                 borderRadius: BorderRadius.circular(8),
        //               ),
        //               child: Icon(
        //                 Icons.auto_awesome,
        //                 color: AppColors.popBlue,
        //                 size: 22,
        //               ),
        //             ),
        //             const SizedBox(width: 16),
        //             Expanded(
        //               child: Column(
        //                 crossAxisAlignment: CrossAxisAlignment.start,
        //                 children: [
        //                   Text(
        //                     'AI Workout Plan',
        //                     style: Theme.of(context).textTheme.titleMedium
        //                         ?.copyWith(fontWeight: FontWeight.bold),
        //                   ),
        //                   Text(
        //                     'Let AI create a personalized workout schedule for you',
        //                     style: Theme.of(context).textTheme.bodySmall
        //                         ?.copyWith(color: AppColors.mediumGrey),
        //                   ),
        //                 ],
        //               ),
        //             ),
        //             Icon(
        //               Icons.arrow_forward_ios,
        //               size: 16,
        //               color: AppColors.mediumGrey,
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ),
        // ),

        // const SizedBox(height: 12),

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
                  _analyticsService.logEvent(
                    name: 'add_workout_for_day_tapped',
                    parameters: {'day': DateFormat('yyyy-MM-dd').format(day)},
                  );

                  context
                      .push(
                        '/workout-scheduling',
                        extra: {'scheduledDate': day, 'userId': widget.userId},
                      )
                      .then((_) {
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              WorkoutDetailScreen(workoutId: workout.workoutId),
                    ),
                  );
                },
                onAddWorkout: () {
                  _analyticsService.logEvent(
                    name: 'add_workout_for_day_tapped',
                    parameters: {'day': DateFormat('yyyy-MM-dd').format(day)},
                  );

                  context
                      .push(
                        '/workout-scheduling',
                        extra: {'scheduledDate': day, 'userId': widget.userId},
                      )
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

  // void _navigateToSavedPlans() {
  //   _analyticsService.logEvent(name: 'view_saved_plans_from_appbar');
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => SavedPlansScreen(userId: widget.userId),
  //     ),
  //   );
  // }
}
