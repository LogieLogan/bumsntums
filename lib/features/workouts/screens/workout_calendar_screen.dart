// lib/features/workouts/screens/workout_calendar_screen.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_plan_editor_screen.dart';
import 'package:bums_n_tums/features/workouts/widgets/workout_progress_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/workout_log.dart';
import '../models/workout_plan.dart';
import '../providers/workout_calendar_provider.dart';
import '../providers/workout_planning_provider.dart';
import '../providers/workout_stats_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/providers/analytics_provider.dart';
import 'workout_browse_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Log screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(analyticsServiceProvider)
          .logScreenView(screenName: 'workout_calendar');
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

    // Fetch combined calendar events (workouts and planned sessions)
    final calendarEventsAsync = ref.watch(
      combinedCalendarEventsProvider((
        userId: widget.userId,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    // Fetch active workout plan
    final activePlanAsync = ref.watch(activeWorkoutPlanProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Calendar', style: AppTextStyles.h2),
        centerTitle: true,
        backgroundColor: AppColors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
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
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TableCalendar(
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
                        final date = DateTime(day.year, day.month, day.day);
                        return events[date] ?? [];
                      },
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      // Keep other calendar settings
                    ),
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
                    Container(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(context).size.height *
                            0.4, // Fixed percentage of screen height
                      ),
                      child: _buildSelectedDayEvents(
                        events[_selectedDay] ?? [],
                      ),
                    ),
                  ],
                ),
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

  Widget _buildCompactPlanView(WorkoutPlan plan) {
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
        if (plan.description != null && plan.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            plan.description!,
            style: AppTextStyles.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Goal: ${plan.goal}',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Start: ${plan.startDate.day}/${plan.startDate.month}/${plan.startDate.year}',
                style: AppTextStyles.small,
              ),
            ),
            if (plan.endDate != null)
              Expanded(
                child: Text(
                  'End: ${plan.endDate!.day}/${plan.endDate!.month}/${plan.endDate!.year}',
                  style: AppTextStyles.small,
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),

        // Add the progress chart here
        WorkoutProgressChart(plan: plan),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Scheduled Workouts', style: AppTextStyles.h3),
            TextButton(
              onPressed: () => _editWorkoutPlan(plan),
              child: const Text('Edit Plan'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Use a fixed height container for the list
        Container(
          height: 300, // Fixed height
          child:
              plan.scheduledWorkouts.isEmpty
                  ? Center(
                    child: Text(
                      'No workouts scheduled yet',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  )
                  : ListView.builder(
                    itemCount: plan.scheduledWorkouts.length,
                    itemBuilder: (context, index) {
                      final workout = plan.scheduledWorkouts[index];
                      final isToday = isSameDay(
                        workout.scheduledDate,
                        DateTime.now(),
                      );
                      final isPast = workout.scheduledDate.isBefore(
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ),
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true, // More compact
                          leading: CircleAvatar(
                            radius: 16, // Smaller
                            backgroundColor:
                                workout.isCompleted
                                    ? AppColors.popGreen
                                    : isPast
                                    ? Colors.grey
                                    : AppColors.popCoral,
                            child: Icon(
                              workout.isCompleted
                                  ? Icons.check_circle
                                  : Icons.fitness_center,
                              size: 14, // Smaller
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            workout.title,
                            style: AppTextStyles.body.copyWith(
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14, // Smaller font
                            ),
                          ),
                          subtitle: Text(
                            '${workout.scheduledDate.day}/${workout.scheduledDate.month}/${workout.scheduledDate.year}',
                            style: AppTextStyles.small.copyWith(fontSize: 12),
                          ),
                          trailing:
                              workout.isCompleted
                                  ? const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 16,
                                  )
                                  : isPast
                                  ? const Icon(
                                    Icons.schedule,
                                    color: Colors.grey,
                                    size: 16,
                                  )
                                  : null,
                          onTap: () {
                            // Navigate to workout details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => WorkoutDetailScreen(
                                      workoutId: workout.workoutId,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildNoPlanView() {
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

  Widget _buildSelectedDayEvents(List<dynamic> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No workouts on this day',
              style: AppTextStyles.body.copyWith(color: Colors.grey[500]),
            ),
            // Remove the duplicate button here
          ],
        ),
      );
    }

    // Sort events: scheduled first, then completed
    final sortedEvents = [...events];
    sortedEvents.sort((a, b) {
      // ScheduledWorkout that is not completed comes first
      if (a is ScheduledWorkout && b is WorkoutLog) {
        return a.isCompleted ? 1 : -1;
      }
      if (a is WorkoutLog && b is ScheduledWorkout) {
        return b.isCompleted ? -1 : 1;
      }
      return 0;
    });

    return ListView.builder(
      itemCount: sortedEvents.length,
      itemBuilder: (context, index) {
        final event = sortedEvents[index];

        // Display differently based on event type
        if (event is WorkoutLog) {
          return _buildCompletedWorkoutCard(event);
        } else if (event is ScheduledWorkout) {
          return _buildScheduledWorkoutCard(event);
        } else {
          return const SizedBox(); // Fallback for unknown event types
        }
      },
    );
  }

  Widget _buildCompletedWorkoutCard(WorkoutLog workout) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.popGreen,
          child: const Icon(Icons.check_circle, color: Colors.white),
        ),
        title: Text(
          workout.workoutId, // In a real implementation, fetch workout title
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${workout.durationMinutes} minutes • ${workout.caloriesBurned} calories',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to workout details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      WorkoutDetailScreen(workoutId: workout.workoutId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduledWorkoutCard(ScheduledWorkout scheduled) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              scheduled.isCompleted ? AppColors.popGreen : AppColors.popCoral,
          child: Icon(
            scheduled.isCompleted ? Icons.check_circle : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(
          scheduled.title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              scheduled.reminderTime != null
                  ? '${scheduled.reminderTime!.hour}:${scheduled.reminderTime!.minute.toString().padLeft(2, '0')}'
                  : 'No reminder set',
            ),
            if (!scheduled.isCompleted) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => _markWorkoutAsCompleted(scheduled),
                child: const Text('Complete'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.popGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to workout details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      WorkoutDetailScreen(workoutId: scheduled.workoutId),
            ),
          );
        },
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

  void _addWorkoutToSelectedDay() {
    // Log analytics
    ref
        .read(analyticsServiceProvider)
        .logEvent(
          name: 'schedule_workout_initiated',
          parameters: {'date': _selectedDay.toIso8601String()},
        );

    // Navigate to workout browse screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutBrowseScreen()),
    ).then((selectedWorkout) {
      if (selectedWorkout != null && selectedWorkout is Workout) {
        // Get the current user ID
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be logged in to schedule workouts'),
            ),
          );
          return;
        }

        // Check if there's an active plan
        final activePlanAsync = ref.read(activeWorkoutPlanProvider(userId));

        activePlanAsync.whenData((plan) async {
          if (plan == null) {
            // Create a simple plan if none exists
            final newPlan = WorkoutPlan(
              id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
              userId: userId,
              name: 'My Workout Plan',
              startDate: DateTime.now(),
              goal: 'Stay fit and healthy',
              scheduledWorkouts: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            // Save the new plan
            await ref
                .read(workoutPlanActionsProvider.notifier)
                .savePlan(newPlan);

            // Schedule the workout
            _scheduleWorkout(userId, newPlan.id, selectedWorkout, _selectedDay);
          } else {
            // Schedule in existing plan
            _scheduleWorkout(userId, plan.id, selectedWorkout, _selectedDay);
          }
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
    // Create scheduled workout
    final scheduledWorkout = ScheduledWorkout(
      workoutId: workout.id,
      title: workout.title,
      workoutImageUrl: workout.imageUrl,
      scheduledDate: date,
    );

    // Save to the plan
    ref
        .read(workoutPlanActionsProvider.notifier)
        .addWorkoutToPlan(userId, planId, scheduledWorkout)
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
            ref.refresh(
              combinedCalendarEventsProvider((
                userId: userId,
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

  void _createNewWorkoutPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutPlanEditorScreen(userId: widget.userId),
      ),
    ).then((_) {
      // Refresh the data when returning from the editor
      ref.refresh(activeWorkoutPlanProvider(widget.userId));

      // Also refresh the calendar data
      final now = DateTime.now();
      ref.refresh(
        combinedCalendarEventsProvider((
          userId: widget.userId,
          startDate: DateTime(now.year, now.month - 1, 1),
          endDate: DateTime(now.year, now.month + 2, 0),
        )),
      );
    });
  }

  void _editWorkoutPlan(WorkoutPlan plan) {
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
      ref.refresh(activeWorkoutPlanProvider(widget.userId));

      // Also refresh the calendar data
      final now = DateTime.now();
      ref.refresh(
        combinedCalendarEventsProvider((
          userId: widget.userId,
          startDate: DateTime(now.year, now.month - 1, 1),
          endDate: DateTime(now.year, now.month + 2, 0),
        )),
      );
    });
  }

  Widget _buildPlanTab(WorkoutPlan plan) {
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
        if (plan.description != null) ...[
          const SizedBox(height: 8),
          Text(plan.description!, style: AppTextStyles.body),
        ],
        const SizedBox(height: 16),
        Text(
          'Goal: ${plan.goal}',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Start date: ${plan.startDate.day}/${plan.startDate.month}/${plan.startDate.year}',
          style: AppTextStyles.small,
        ),
        if (plan.endDate != null) ...[
          Text(
            'End date: ${plan.endDate!.day}/${plan.endDate!.month}/${plan.endDate!.year}',
            style: AppTextStyles.small,
          ),
        ],

        const SizedBox(height: 24),

        // Add the progress chart here
        WorkoutProgressChart(plan: plan),

        const SizedBox(height: 24),

        Text('Scheduled Workouts', style: AppTextStyles.h3),
        const SizedBox(height: 8),

        // Use a fixed height container for the list to prevent overflow
        SizedBox(
          height: 300, // Fixed height for the list
          child:
              plan.scheduledWorkouts.isEmpty
                  ? Center(
                    child: Text(
                      'No workouts scheduled yet',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  )
                  : ListView.builder(
                    itemCount: plan.scheduledWorkouts.length,
                    itemBuilder: (context, index) {
                      final workout = plan.scheduledWorkouts[index];
                      final isToday = isSameDay(
                        workout.scheduledDate,
                        DateTime.now(),
                      );
                      final isPast = workout.scheduledDate.isBefore(
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ),
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isToday ? AppColors.paleGrey : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                workout.isCompleted
                                    ? AppColors.popGreen
                                    : isPast
                                    ? Colors.grey
                                    : AppColors.popCoral,
                            child: Icon(
                              workout.isCompleted
                                  ? Icons.check_circle
                                  : Icons.fitness_center,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            workout.title,
                            style: AppTextStyles.body.copyWith(
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${workout.scheduledDate.day}/${workout.scheduledDate.month}/${workout.scheduledDate.year}',
                          ),
                          trailing:
                              workout.isCompleted
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : isPast
                                  ? const Icon(
                                    Icons.schedule,
                                    color: Colors.grey,
                                  )
                                  : null,
                          onTap: () {
                            // Navigate to workout details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => WorkoutDetailScreen(
                                      workoutId: workout.workoutId,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
