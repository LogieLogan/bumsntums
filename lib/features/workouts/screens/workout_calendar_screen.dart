// lib/features/workouts/screens/workout_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/workout_plan.dart';
import '../models/workout_log.dart';
import '../providers/workout_planning_provider.dart';
import '../providers/workout_stats_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import 'workout_detail_screen.dart';

class WorkoutCalendarScreen extends ConsumerStatefulWidget {
  final String userId;

  const WorkoutCalendarScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  ConsumerState<WorkoutCalendarScreen> createState() =>
      _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends ConsumerState<WorkoutCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    // Get the workout history and active plan for the calendar
    final workoutHistoryAsync = ref.watch(
      workoutCalendarDataProvider((
        userId: widget.userId,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now().add(const Duration(days: 30)),
      )),
    );

    final activePlanAsync = ref.watch(activeWorkoutPlanProvider(widget.userId));

    // Combine history and active plan data
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Calendar', style: AppTextStyles.h2),
        centerTitle: true,
        backgroundColor: AppColors.salmon,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreatePlanDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: workoutHistoryAsync.when(
              data: (workoutsByDate) {
                return activePlanAsync.when(
                  data: (activePlan) {
                    // Process data for the calendar
                    final Map<DateTime, List<dynamic>> events = _processEvents(
                      workoutsByDate,
                      activePlan,
                    );

                    return _buildCalendarWithEvents(events);
                  },
                  loading: () => LoadingIndicator(),
                  error: (error, stackTrace) {
                    return _buildCalendarWithEvents({});
                  },
                );
              },
              loading: () => LoadingIndicator(),
              error: (error, stackTrace) {
                return Center(
                  child: Text('Error loading calendar data: $error'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => WorkoutDetailScreen(
                    workoutId:
                        'workout_id', // Replace with actual recommendation
                  ),
            ),
          );
        },
        backgroundColor: AppColors.salmon,
        child: const Icon(Icons.fitness_center),
      ),
    );
  }

  Widget _buildCalendarWithEvents(Map<DateTime, List<dynamic>> events) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: (day) {
            // Clean date (remove time)
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
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppColors.salmon.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: AppColors.salmon,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: AppColors.popCoral,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonDecoration: BoxDecoration(
              color: AppColors.salmon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: TextStyle(color: AppColors.salmon),
            formatButtonShowsNext: false,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildEventList(events[_selectedDay] ?? [])),
      ],
    );
  }

  Widget _buildEventList(List<dynamic> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 64, color: AppColors.lightGrey),
            const SizedBox(height: 16),
            Text(
              'No workouts scheduled for this day',
              style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _showAddWorkoutDialog(context, _selectedDay);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salmon,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        if (event is WorkoutLog) {
          // Past workout (completed)
          return _buildCompletedWorkoutCard(event);
        } else if (event is ScheduledWorkout) {
          // Future workout (planned)
          return _buildScheduledWorkoutCard(event);
        }

        return const SizedBox.shrink(); // Fallback
      },
    );
  }

  Widget _buildCompletedWorkoutCard(WorkoutLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.popGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: AppColors.popGreen),
        ),
        title: Text(
          'Completed: ${log.workoutId}',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${log.durationMinutes} minutes • ${log.caloriesBurned} calories',
          style: AppTextStyles.small,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to workout details or log details
        },
      ),
    );
  }

  Widget _buildScheduledWorkoutCard(ScheduledWorkout scheduled) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.popBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.event, color: AppColors.popBlue),
        ),
        title: Text(
          scheduled.title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          scheduled.isRecurring ? 'Recurring workout' : 'Scheduled workout',
          style: AppTextStyles.small,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.mediumGrey),
              onPressed: () {
                // Edit scheduled workout
              },
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow, color: AppColors.salmon),
              onPressed: () {
                // Start this workout
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            WorkoutDetailScreen(workoutId: scheduled.workoutId),
                  ),
                );
              },
            ),
          ],
        ),
        onTap: () {
          // View workout details
          Navigator.of(context).push(
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

  // Helper to process events from different sources
  Map<DateTime, List<dynamic>> _processEvents(
    Map<DateTime, List<WorkoutLog>> workoutsByDate,
    WorkoutPlan? activePlan,
  ) {
    final Map<DateTime, List<dynamic>> events = {};

    // Add completed workouts to events
    workoutsByDate.forEach((date, logs) {
      events[date] = logs;
    });

    // Add scheduled workouts from active plan
    if (activePlan != null) {
      for (final scheduled in activePlan.scheduledWorkouts) {
        final date = DateTime(
          scheduled.scheduledDate.year,
          scheduled.scheduledDate.month,
          scheduled.scheduledDate.day,
        );

        if (events.containsKey(date)) {
          events[date]!.add(scheduled);
        } else {
          events[date] = [scheduled];
        }
      }
    }

    return events;
  }

  void _showCreatePlanDialog(BuildContext context) {
    // Implementation for creating a new workout plan
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Workout Plan', style: AppTextStyles.h3),
          content: const Text('Choose how to create your workout plan:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _createCustomPlan();
              },
              child: const Text('Custom Plan'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createAIRecommendedPlan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salmon,
                foregroundColor: Colors.white,
              ),
              child: const Text('AI Recommended'),
            ),
          ],
        );
      },
    );
  }

  void _showAddWorkoutDialog(BuildContext context, DateTime date) {
    // Implementation for adding a workout to a specific date
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Workout', style: AppTextStyles.h3),
          content: const Text('Select a workout to add to this day:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to workout browse screen
                // with callback to add selected workout to this date
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salmon,
                foregroundColor: Colors.white,
              ),
              child: const Text('Browse Workouts'),
            ),
          ],
        );
      },
    );
  }

  void _createCustomPlan() {
    // Navigate to custom plan creation screen (implementation omitted)
  }

  void _createAIRecommendedPlan() async {
    final actionsNotifier = ref.read(workoutPlanActionsProvider.notifier);

    // You would get these values from user profile in production code
    final focusAreas = ['bums', 'tums'];
    final weeklyWorkoutDays = 3;
    final fitnessLevel = 'beginner';

    final plan = await actionsNotifier.generateRecommendedPlan(
      widget.userId,
      focusAreas,
      weeklyWorkoutDays,
      fitnessLevel,
    );

    if (plan != null && mounted) {
      await actionsNotifier.createWorkoutPlan(plan);

      // Refresh the data
      ref.refresh(activeWorkoutPlanProvider(widget.userId));
      ref.refresh(
        workoutCalendarDataProvider((
          userId: widget.userId,
          startDate: DateTime.now().subtract(const Duration(days: 365)),
          endDate: DateTime.now().add(const Duration(days: 30)),
        )),
      );
    }
  }
}
