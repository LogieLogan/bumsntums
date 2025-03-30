// lib/features/workouts/screens/workout_calendar_screen.dart
import 'package:bums_n_tums/features/workout_planning/providers/workout_planning_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_plan.dart';
import '../providers/workout_calendar_provider.dart';
import '../widgets/calendar/calendar_tab_view.dart';
import '../widgets/calendar/plans_tab_view.dart';
import '../widgets/calendar/recurring_workout_dialog.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/providers/analytics_provider.dart';
import '../../workouts/screens/workout_detail_screen.dart';
import '../../workouts/screens/workout_analytics_screen.dart';
import 'workout_plan_editor_screen.dart';
import 'workout_scheduling_screen.dart';

class WorkoutCalendarScreen extends ConsumerStatefulWidget {
  final String userId;

  const WorkoutCalendarScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  ConsumerState<WorkoutCalendarScreen> createState() =>
      _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends ConsumerState<WorkoutCalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late TabController _tabController;
  bool _hasLoggedInitialBuild = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Log screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(analyticsServiceProvider)
          .logScreenView(screenName: 'workout_calendar');

      // Update calendar state with initial values
      ref.read(calendarStateProvider.notifier).selectDate(_selectedDay);
      ref.read(calendarStateProvider.notifier).changeFocusedMonth(_focusedDay);

    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoggedInitialBuild) {
      print('Building calendar with selected day: ${_selectedDay.toString()}');
      _hasLoggedInitialBuild = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Calendar', style: AppTextStyles.h2),
        centerTitle: true,
        backgroundColor: AppColors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      WorkoutAnalyticsScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Calendar'), Tab(text: 'Plans')],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Calendar Tab
          CalendarTabView(
            userId: widget.userId,
            selectedDay: _selectedDay,
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              ref.read(calendarStateProvider.notifier).selectDate(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
              ref
                  .read(calendarStateProvider.notifier)
                  .changeViewMode(
                    format == CalendarFormat.month
                        ? 'month'
                        : format == CalendarFormat.week
                        ? 'week'
                        : 'twoWeeks',
                  );
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              ref.read(calendarStateProvider.notifier).changeFocusedMonth(focusedDay);
            },
            onRescheduleWorkout: _rescheduleWorkout,
            onAddWorkout: _addWorkoutToSelectedDay,
            onNavigateToWorkoutDetail: _navigateToWorkoutDetail,
            onMarkWorkoutAsCompleted: _markWorkoutAsCompleted,
            onMakeWorkoutRecurring: _makeWorkoutRecurring,
          ),

          // Plans Tab
          PlansTabView(
            userId: widget.userId,
            onCreateNewPlan: _createNewWorkoutPlan,
            onEditPlan: _editWorkoutPlan,
          ),
        ],
      ),
    );
  }

  void _refreshCalendarData() {
    final now = DateTime.now();
    final _ = ref.refresh(
      combinedCalendarEventsProvider((
        userId: widget.userId,
        startDate: DateTime(now.year, now.month - 1, 1),
        endDate: DateTime(now.year, now.month + 2, 0),
      )),
    );
    final _ = ref.refresh(activeWorkoutPlanProvider(widget.userId));
    final _ = ref.refresh(restDayRecommendationsProvider(widget.userId));
  }

  void _navigateToWorkoutDetail(String workoutId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workoutId: workoutId),
      ),
    );
  }


  void _markWorkoutAsCompleted(ScheduledWorkout scheduled) {
    // Get the active plan ID from the provider
    final activePlanAsync = ref.read(activeWorkoutPlanProvider(widget.userId));

    activePlanAsync.whenData((plan) {
      if (plan != null) {
        // Use the workout planning provider to mark as completed
        ref
            .read(workoutPlanActionsProvider.notifier)
            .markWorkoutCompleted(
              widget.userId,
              plan.id,
              scheduled.workoutId,
              DateTime.now(),
            )
            .then((success) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Workout marked as completed'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Refresh the data
                _refreshCalendarData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to mark workout as completed'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
      }
    });
  }

  void _makeWorkoutRecurring(ScheduledWorkout scheduled) {
    showDialog(
      context: context,
      builder: (context) => RecurringWorkoutDialog(
        workoutTitle: scheduled.title,
        initialDate: scheduled.scheduledDate,
      ),
    ).then((settings) {
      if (settings != null && settings is RecurringWorkoutSettings) {
        // Get the active plan ID
        final activePlanAsync = ref.read(
          activeWorkoutPlanProvider(widget.userId),
        );

        activePlanAsync.whenData((plan) {
          if (plan != null) {
            // Use the actions provider
            ref.read(workoutActionsProvider.notifier)
                .setRecurringWorkout(
                  userId: widget.userId,
                  planId: plan.id,
                  workoutId: scheduled.workoutId,
                  startDate: scheduled.scheduledDate,
                  recurrencePattern: settings.patternName,
                  occurrences: settings.occurrences,
                )
                .then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Workout set to repeat ${settings.patternName} for ${settings.occurrences} occurrences',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Refresh the data
                    _refreshCalendarData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to set recurring workout'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
          }
        });
      }
    });
  }

  void _rescheduleWorkout(ScheduledWorkout workout, DateTime newDate) {
    // Get the active plan ID
    final activePlanAsync = ref.read(activeWorkoutPlanProvider(widget.userId));

    activePlanAsync.whenData((plan) {
      if (plan != null) {
        // Show confirmation dialog for recurring workouts
        if (workout.isRecurring) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reschedule Workout'),
              content: const Text(
                'This is a recurring workout. Do you want to reschedule just this occurrence or all future occurrences?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop('single'),
                  child: const Text('Just This One'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop('all'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('All Future Occurrences'),
                ),
              ],
            ),
          ).then((result) {
            if (result != null) {
              final applyToSeries = result == 'all';

              // Use the actions provider
              ref.read(workoutActionsProvider.notifier)
                  .rescheduleWorkout(
                    userId: widget.userId,
                    planId: plan.id,
                    workoutId: workout.workoutId,
                    oldDate: workout.scheduledDate,
                    newDate: newDate,
                    applyToSeries: applyToSeries,
                  )
                  .then((success) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Workout rescheduled to ${newDate.day}/${newDate.month}/${newDate.year}',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Refresh the data
                      _refreshCalendarData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to reschedule workout'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  });
            }
          });
        } else {
          // For non-recurring workouts, just reschedule
          ref.read(workoutActionsProvider.notifier)
              .rescheduleWorkout(
                userId: widget.userId,
                planId: plan.id,
                workoutId: workout.workoutId,
                oldDate: workout.scheduledDate,
                newDate: newDate,
                applyToSeries: false,
              )
              .then((success) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Workout rescheduled to ${newDate.day}/${newDate.month}/${newDate.year}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh the data
                  _refreshCalendarData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to reschedule workout'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
        }
      }
    });
  }

  Future<String?> _createDefaultPlan() async {
    final now = DateTime.now();
    final planId = const Uuid().v4();

    // Create a plan with a more descriptive name
    final plan = WorkoutPlan(
      id: planId,
      userId: widget.userId,
      name: '${_getMonthName(now.month)} Training Plan',
      description: 'Automatically created workout plan',
      startDate: now,
      goal: 'Stay fit and healthy',
      scheduledWorkouts: [],
      createdAt: now,
      updatedAt: now,
      colorName: null, // This will use the default color selection logic
    );

    final success = await ref
        .read(workoutPlanActionsProvider.notifier)
        .createWorkoutPlan(plan);

    return success;
  }

  // Helper to get month name
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  void _addWorkoutToSelectedDay() async {
    // Log analytics
    ref
        .read(analyticsServiceProvider)
        .logEvent(
          name: 'schedule_workout_initiated',
          parameters: {'date': _selectedDay.toIso8601String()},
        );

    // Check for active plan
    final activePlanAsync = await ref.read(
      activeWorkoutPlanProvider(widget.userId).future,
    );

    if (activePlanAsync == null) {
      // Create a default plan automatically if none exists
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Create Workout Plan'),
          content: const Text(
            'You need a workout plan to schedule workouts. Would you like to create one now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final planId = await _createDefaultPlan();
                if (planId != null) {
                  // Refresh the data
                  _refreshCalendarData();

                  // Navigate to workout scheduling
                  _navigateToWorkoutSelection(planId);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Plan'),
            ),
          ],
        ),
      );
    } else {
      // Use the existing active plan
      _navigateToWorkoutSelection(activePlanAsync.id);
    }
  }

  void _navigateToWorkoutSelection(String planId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSchedulingScreen(
          selectedDate: _selectedDay,
          userId: widget.userId,
          planId: planId,
        ),
      ),
    );

    // If workouts were scheduled, refresh the calendar
    if (result == true) {
      _refreshCalendarData();
    }
  }

  void _createNewWorkoutPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutPlanEditorScreen(userId: widget.userId),
      ),
    ).then((_) {
      // Refresh the data when returning from the editor
      _refreshCalendarData();
    });
  }

  void _editWorkoutPlan(WorkoutPlan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutPlanEditorScreen(
          userId: widget.userId,
          existingPlan: plan,
        ),
      ),
    ).then((_) {
      // Refresh the data when returning from the editor
      _refreshCalendarData();
    });
  }
}