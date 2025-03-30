// lib/features/workout_planning/widgets/calendar_view.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/scheduled_workout.dart';
import '../providers/workout_planning_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/components/indicators/loading_indicator.dart';

class CalendarView extends ConsumerStatefulWidget {
  final String userId;
  final Function(DateTime) onDaySelected;

  const CalendarView({
    Key? key,
    required this.userId,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    // Get the start and end dates for the visible calendar range
    final firstDay = DateTime(
      _focusedDay.year - 1,
      _focusedDay.month,
      _focusedDay.day,
    );
    final lastDay = DateTime(
      _focusedDay.year + 1,
      _focusedDay.month,
      _focusedDay.day,
    );
    final textTheme = Theme.of(context).textTheme;

    // Load scheduled workouts for the visible range
    final scheduledWorkoutsAsync = ref.watch(
      scheduledWorkoutsProvider((
        userId: widget.userId,
        start: firstDay,
        end: lastDay,
      )),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Tap on a day to see details',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.mediumGrey),
          ),
        ),

        scheduledWorkoutsAsync.when(
          data: (scheduledWorkouts) => _buildCalendar(scheduledWorkouts),
          loading:
              () => const Expanded(
                child: LoadingIndicator(message: 'Loading calendar...'),
              ),
          error:
              (error, stack) => Expanded(
                child: Center(child: Text('Error loading calendar: $error')),
              ),
        ),
      ],
    );
  }

  Widget _buildCalendar(List<ScheduledWorkout> scheduledWorkouts) {
    // Create a map of dates to workouts for event markers
    final workoutsByDay = <DateTime, List<ScheduledWorkout>>{};

    for (final workout in scheduledWorkouts) {
      final date = DateTime(
        workout.scheduledDate.year,
        workout.scheduledDate.month,
        workout.scheduledDate.day,
      );

      if (workoutsByDay.containsKey(date)) {
        workoutsByDay[date]!.add(workout);
      } else {
        workoutsByDay[date] = [workout];
      }
    }

    return Expanded(
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(
              _focusedDay.year - 1,
              _focusedDay.month,
              _focusedDay.day,
            ),
            lastDay: DateTime(
              _focusedDay.year + 1,
              _focusedDay.month,
              _focusedDay.day,
            ),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                widget.onDaySelected(selectedDay);
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: (day) {
              final date = DateTime(day.year, day.month, day.day);
              return workoutsByDay[date] ?? [];
            },
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: AppColors.pink,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.pink.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.pink,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonTextStyle: const TextStyle().copyWith(
                color: Colors.white,
              ),
              formatButtonDecoration: BoxDecoration(
                color: AppColors.pink,
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),

          const SizedBox(height: 8.0),

          // Display selected day's workouts
          if (_selectedDay != null)
            Expanded(child: _buildSelectedDayWorkouts(workoutsByDay)),
        ],
      ),
    );
  }

  Widget _buildSelectedDayWorkouts(
    Map<DateTime, List<ScheduledWorkout>> workoutsByDay,
  ) {
    final date = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final workouts = workoutsByDay[date] ?? [];
    final textTheme = Theme.of(context).textTheme;

    if (workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 48, color: AppColors.lightGrey),
            const SizedBox(height: 16),
            Text(
              'No workouts scheduled for this day',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.mediumGrey,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // Navigate to workout selection for this day
                Navigator.pushNamed(
                  context,
                  '/workout-browse',
                  arguments: {'scheduledDate': _selectedDay},
                ).then((_) {
                  // Refresh data when returning
                  final _ = ref.refresh(
                    scheduledWorkoutsProvider((
                      userId: widget.userId,
                      start: DateTime(
                        _focusedDay.year - 1,
                        _focusedDay.month,
                        _focusedDay.day,
                      ),
                      end: DateTime(
                        _focusedDay.year + 1,
                        _focusedDay.month,
                        _focusedDay.day,
                      ),
                    )),
                  );
                });
              },
              icon: Icon(Icons.add, color: AppColors.pink),
              label: Text(
                'Add a workout',
                style: TextStyle(color: AppColors.pink),
              ),
            ),
          ],
        ),
      );
    }

    final dateFormatter = DateFormat('EEEE, MMMM d');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            dateFormatter.format(_selectedDay!),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 8.0),

        Expanded(
          child: ListView.builder(
            itemCount: workouts.length,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemBuilder: (context, index) {
              final workout = workouts[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        workout.isCompleted
                            ? AppColors.success
                            : (workout.workout != null
                                ? _getCategoryColor(
                                  workout.workout!.category,
                                )
                                : AppColors.popTurquoise),
                    child: Icon(
                      workout.isCompleted ? Icons.check : Icons.fitness_center,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    workout.workout?.title ?? 'Unknown Workout',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration:
                          workout.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                    ),
                  ),
                  subtitle:
                      workout.workout != null
                          ? Text(
                            '${_getDifficultyName(workout.workout!.difficulty)} · ${workout.workout!.durationMinutes} min',
                            style: textTheme.bodySmall,
                          )
                          : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          workout.isCompleted
                              ? Icons.refresh
                              : Icons.check_circle_outline,
                          color:
                              workout.isCompleted
                                  ? AppColors.mediumGrey
                                  : AppColors.success,
                        ),
                        onPressed: () {
                          if (workout.isCompleted) {
                            // Reset completion status logic
                          } else {
                            // Mark as completed
                            ref
                                .read(
                                  workoutPlanningNotifierProvider(
                                    widget.userId,
                                  ).notifier,
                                )
                                .markWorkoutCompleted(workout.id);
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () {
                          // Delete workout logic
                          ref
                              .read(
                                workoutPlanningNotifierProvider(
                                  widget.userId,
                                ).notifier,
                              )
                              .deleteScheduledWorkout(workout.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to workout detail
                    Navigator.pushNamed(
                      context,
                      '/workout-detail',
                      arguments: {'id': workout.workoutId},
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

  Color _getCategoryColor(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return AppColors.pink;
      case WorkoutCategory.tums:
        return AppColors.popCoral;
      case WorkoutCategory.fullBody:
        return AppColors.popBlue;
      case WorkoutCategory.cardio:
        return AppColors.popGreen;
      case WorkoutCategory.quickWorkout:
        return AppColors.popYellow;
    }
  }

  String _getDifficultyName(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return 'Beginner';
      case WorkoutDifficulty.intermediate:
        return 'Intermediate';
      case WorkoutDifficulty.advanced:
        return 'Advanced';
    }
  }
}
