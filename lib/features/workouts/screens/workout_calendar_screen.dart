// lib/features/workouts/screens/workout_calendar_screen.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_plan_editor_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_scheduling_screen.dart';
import 'package:bums_n_tums/features/workouts/widgets/calendar/recurring_workout_dialog.dart';
import 'package:bums_n_tums/features/workouts/widgets/calendar/rest_day_indicator.dart';
import 'package:bums_n_tums/features/workouts/widgets/calendar/workout_event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/workout_log.dart';
import '../models/workout_plan.dart';
import '../providers/workout_calendar_provider.dart';
import '../providers/workout_planning_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/providers/analytics_provider.dart';
import 'workout_detail_screen.dart';
import 'workout_analytics_screen.dart';

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
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late TabController _tabController;
  bool _hasLoggedInitialBuild = false;
  DateTime? _lastLoggedDate;
  final Set<String> _loggedDays = {};

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
    // Get the date range for the visible calendar
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 1, 1);
    final endDate = DateTime(now.year, now.month + 2, 0);

    // Fetch calendar data
    final calendarEventsAsync = ref.watch(
      combinedCalendarEventsProvider((
        userId: widget.userId,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    // Fetch rest day recommendations
    final restDaysAsync = ref.watch(
      restDayRecommendationsProvider(widget.userId),
    );

    // Fetch active workout plan
    final activePlanAsync = ref.watch(activeWorkoutPlanProvider(widget.userId));

    // Watch calendar state
    final calendarState = ref.watch(calendarStateProvider);

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
                  builder:
                      (context) =>
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
          // Calendar Tab - For viewing and managing individual workout sessions
          calendarEventsAsync.when(
            data: (events) {
              // Store events in provider for drag-and-drop operations
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(calendarStateProvider.notifier).updateEvents(events);
              });

              return Builder(
                builder: (context) {
                  // Combine the rest day recommendations with events for display
                  final Map<DateTime, List<dynamic>> combinedEvents = {
                    ...events,
                  };

                  // Add rest day indicators to the events map
                  restDaysAsync.whenData((restDays) {
                    for (final restDay in restDays) {
                      final key = DateTime(
                        restDay.year,
                        restDay.month,
                        restDay.day,
                      );
                      if (!combinedEvents.containsKey(key)) {
                        combinedEvents[key] = [];
                      }
                      // We'll use a string marker to indicate a rest day
                      // This will be handled differently in the event builder
                      combinedEvents[key]!.add('REST_DAY');
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref
                          .read(calendarStateProvider.notifier)
                          .updateHighlightedDates(restDays);
                    });
                  });

                  return _buildCalendarTab(combinedEvents, calendarState);
                },
              );
            },
            loading: () => const Center(child: LoadingIndicator()),
            error: (error, stackTrace) {
              print('Error loading calendar data: $error');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Could not load your workout calendar',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Refresh data
                        ref.refresh(
                          combinedCalendarEventsProvider((
                            userId: widget.userId,
                            startDate: DateTime(
                              DateTime.now().year,
                              DateTime.now().month - 1,
                              1,
                            ),
                            endDate: DateTime(
                              DateTime.now().year,
                              DateTime.now().month + 2,
                              0,
                            ),
                          )),
                        );
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Plans Tab - For creating and managing workout plans spanning multiple days
          activePlanAsync.when(
            data:
                (plan) => SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Workout Plans', style: AppTextStyles.h3),
                        const SizedBox(height: 8),
                        Text(
                          'Create structured workout programs that span multiple days or weeks',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                        ),
                        const SizedBox(height: 24),

                        plan != null
                            ?
                            // If there's a plan, use the existing method but make it more compact
                            _buildCompactPlanView(plan)
                            :
                            // If no plan, show the empty state
                            _buildNoPlanView(),

                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          onPressed: _createNewWorkoutPlan,
                          icon: const Icon(Icons.add),
                          label: Text(
                            plan != null
                                ? 'Create New Plan'
                                : 'Create Your First Plan',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.pink,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            loading: () => const Center(child: LoadingIndicator()),
            error:
                (error, stackTrace) =>
                    Center(child: Text('Error loading workout plan: $error')),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab(
    Map<DateTime, List<dynamic>> events,
    CalendarState calendarState,
  ) {
    return Stack(
      children: [
        // Main Calendar UI
        SingleChildScrollView(
          child: Column(
            children: [
              _buildCalendar(events, calendarState),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'View your scheduled workouts and track completed sessions',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _addWorkoutToSelectedDay,
                  icon: const Icon(Icons.add),
                  label: const Text('Schedule Workout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDayEventsSection(
                events[DateTime(
                      _selectedDay.year,
                      _selectedDay.month,
                      _selectedDay.day,
                    )] ??
                    [],
              ),
            ],
          ),
        ),

        // Drag Target Overlay (only visible when dragging)
        DragTarget<ScheduledWorkout>(
          builder: (context, candidateData, rejectedData) {
            // This will show when dragging a workout
            return Visibility(
              visible: candidateData.isNotEmpty, // Only show when dragging
              child: Container(
                color: Colors.black.withOpacity(0.1),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Drop to reschedule',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'To: ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          onAccept: (workout) {
            // Handle the rescheduling here
            _rescheduleWorkout(workout, _selectedDay);
          },
        ),
      ],
    );
  }

  Widget _buildCalendar(
    Map<DateTime, List<dynamic>> events,
    CalendarState calendarState,
  ) {
    // Add a set to track which days we've already logged
    final Set<String> _loggedDays = {};

    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.twoWeeks: '2 Weeks',
        CalendarFormat.week: 'Week',
      },
      eventLoader: (day) {
        // Normalize the day to remove time component for comparison
        final normalizedDay = DateTime(day.year, day.month, day.day);
        final dateKey = normalizedDay.toString();

        // Get events
        final eventsForDay = events[normalizedDay] ?? [];

        return eventsForDay;
      },

      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });

        // Clear the day from logged days to allow re-logging
        final selectedDayKey =
            DateTime(
              selectedDay.year,
              selectedDay.month,
              selectedDay.day,
            ).toString();
        _loggedDays.remove(selectedDayKey);

        ref.read(calendarStateProvider.notifier).selectDate(selectedDay);
      },
      // Rest of the method remains unchanged
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
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return const SizedBox.shrink();

          // Check if this is a rest day
          final isRestDay = events.any((e) => e == 'REST_DAY');

          // Count actual workout events (excluding rest day markers)
          final workoutCount = events.where((e) => e != 'REST_DAY').length;

          return Positioned(
            bottom: 1,
            child: Column(
              children: [
                if (isRestDay)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: RestDayIndicator(
                      isRecommended: true,
                      reason: 'Rest day recommended for recovery',
                    ),
                  ),
                if (workoutCount > 0)
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.pink,
                    ),
                    width: 8,
                    height: 8,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayEventsSection(List<dynamic> events) {
    final filteredEvents = events.where((e) => e != 'REST_DAY').toList();

    // Debug log only once per selection to reduce spam
    if (_lastLoggedDate == null || !isSameDay(_lastLoggedDate!, _selectedDay)) {
      print('Building day events section for ${_selectedDay.toString()}');
      print('Events for selected day: ${filteredEvents.length}');
      _lastLoggedDate = _selectedDay;
    }

    // Check if this day is a recommended rest day
    final isRestDay = events.any((e) => e == 'REST_DAY');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Workouts for ${_selectedDay.day}/${_selectedDay.month}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (filteredEvents.isNotEmpty)
                  Text(
                    '${filteredEvents.length} workout${filteredEvents.length != 1 ? 's' : ''}',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
              ],
            ),
          ),

          if (isRestDay)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: RestDayIndicator(
                isRecommended: true,
                reason: 'Rest day recommended for recovery',
              ),
            ),

          if (filteredEvents.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRestDay
                          ? 'Rest day recommended - no workouts scheduled'
                          : 'No workouts on this day',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];

                  // Only log the first few items to reduce spam
                  if (index < 2 &&
                      (_lastLoggedDate == null ||
                          !isSameDay(_lastLoggedDate!, _selectedDay))) {
                    print('Event type: ${event.runtimeType}');
                  } else if (index == 2 &&
                      filteredEvents.length > 3 &&
                      (_lastLoggedDate == null ||
                          !isSameDay(_lastLoggedDate!, _selectedDay))) {
                    print('... and ${filteredEvents.length - 2} more events');
                  }

                  if (event is WorkoutLog) {
                    // Only log the first few for each type
                    if (index < 2 &&
                        (_lastLoggedDate == null ||
                            !isSameDay(_lastLoggedDate!, _selectedDay))) {
                      print('Rendering WorkoutLog: ${event.workoutId}');
                    }
                    return WorkoutEventCard(
                      workout: event,
                      isDraggable: false,
                      onTap: () => _navigateToWorkoutDetail(event.workoutId),
                    );
                  } else if (event is ScheduledWorkout) {
                    // Only log the first few for each type
                    if (index < 2 &&
                        (_lastLoggedDate == null ||
                            !isSameDay(_lastLoggedDate!, _selectedDay))) {
                      print('Rendering ScheduledWorkout: ${event.title}');
                    }
                    return WorkoutEventCard(
                      workout: event,
                      onTap: () => _navigateToWorkoutDetail(event.workoutId),
                      onComplete:
                          event.isCompleted
                              ? null
                              : () => _markWorkoutAsCompleted(event),
                      onMakeRecurring:
                          event.isRecurring
                              ? null
                              : () => _makeWorkoutRecurring(event),
                      onReschedule:
                          (newDate) => _rescheduleWorkout(event, newDate),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
        ],
      ),
    );
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
      builder:
          (context) => RecurringWorkoutDialog(
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
            // Use the new calendar provider
            ref
                .read(calendarStateProvider.notifier)
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
            builder:
                (context) => AlertDialog(
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

              // Use the new calendar provider function
              ref
                  .read(calendarStateProvider.notifier)
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
          ref
              .read(calendarStateProvider.notifier)
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

  void _refreshCalendarData() {
    final now = DateTime.now();
    ref.refresh(
      combinedCalendarEventsProvider((
        userId: widget.userId,
        startDate: DateTime(now.year, now.month - 1, 1),
        endDate: DateTime(now.year, now.month + 2, 0),
      )),
    );
    ref.refresh(activeWorkoutPlanProvider(widget.userId));
    ref.refresh(restDayRecommendationsProvider(widget.userId));
  }

  void _addWorkoutToSelectedDay() {
    // Log analytics
    ref
        .read(analyticsServiceProvider)
        .logEvent(
          name: 'schedule_workout_initiated',
          parameters: {'date': _selectedDay.toIso8601String()},
        );

    // Check if there's an active plan or create one
    final activePlanAsync = ref.read(activeWorkoutPlanProvider(widget.userId));

    activePlanAsync.whenData((plan) async {
      String planId;

      if (plan == null) {
        // Create a simple plan if none exists
        final newPlan = WorkoutPlan(
          id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
          userId: widget.userId,
          name: 'My Workout Plan',
          startDate: DateTime.now(),
          goal: 'Stay fit and healthy',
          scheduledWorkouts: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save the new plan
        final createdPlanId = await ref
            .read(workoutPlanActionsProvider.notifier)
            .createWorkoutPlan(newPlan);

        if (createdPlanId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create workout plan'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        planId = createdPlanId;
      } else {
        planId = plan.id;
      }

      // Navigate to the dedicated scheduling screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => WorkoutSchedulingScreen(
                selectedDate: _selectedDay,
                userId: widget.userId,
                planId: planId,
              ),
        ),
      );

      // If workouts were scheduled, refresh the calendar
      if (result == true) {
        _refreshCalendarData();

        // Force a rebuild of the selected day section
        setState(() {
          // Re-select the current day to force a refresh of the events
          final currentSelectedDay = _selectedDay;
          _selectedDay = DateTime(1970); // Temporary different value
          _selectedDay = currentSelectedDay; // Set back to force rebuild
        });
      }
    });
  }

  void _scheduleWorkout(
    String userId,
    String planId,
    Workout workout,
    DateTime date,
  ) {
    // Use the enhanced calendar provider instead
    ref
        .read(calendarStateProvider.notifier)
        .scheduleWorkout(
          userId: userId,
          planId: planId,
          workout: workout,
          date: date,
          reminderEnabled: true,
        )
        .then((success) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${workout.title} scheduled for ${date.day}/${date.month}/${date.year}',
                ),
                backgroundColor: Colors.green,
              ),
            );

            // Refresh the data
            _refreshCalendarData();

            // Explicitly update the selected day to trigger UI refresh for that day
            setState(() {
              // Re-select the current day to force a refresh of the events
              final currentSelectedDay = _selectedDay;
              _selectedDay = DateTime(1970); // Temporary different value
              _selectedDay = currentSelectedDay; // Set back to force rebuild
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to schedule workout'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }

  Widget _buildCompactPlanView(WorkoutPlan plan) {
    // Use your existing implementation
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(plan.name, style: AppTextStyles.h2)),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editWorkoutPlan(plan),
            ),
          ],
        ),
        // Rest of your implementation...
        // ...
      ],
    );
  }

  Widget _buildNoPlanView() {
    // Use your existing implementation
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No active workout plan',
            style: AppTextStyles.h3.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a workout plan',
            style: AppTextStyles.body.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _createNewWorkoutPlan() {
    // Use your existing implementation
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
    // Use your existing implementation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WorkoutPlanEditorScreen(
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
