// lib/features/workouts/screens/workout_calendar_screen.dart
import 'package:bums_n_tums/features/workouts/screens/workout_analytics_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/workout_log.dart';
import '../providers/workout_stats_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import 'workout_browse_screen.dart';
import 'workout_detail_screen.dart';

// Simple provider for workout history
final simpleWorkoutHistoryProvider = FutureProvider.family<Map<DateTime, List<WorkoutLog>>, String>(
  (ref, userId) async {
    final firestore = FirebaseFirestore.instance;
    Map<DateTime, List<WorkoutLog>> workoutsByDate = {};

    try {
      // Get workout logs for the past year
      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));

      final logsSnapshot = await firestore
          .collection('user_workout_history')
          .doc(userId)
          .collection('logs')
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(oneYearAgo))
          .get();

      // Process the workout logs
      for (final doc in logsSnapshot.docs) {
        final log = WorkoutLog.fromMap({'id': doc.id, ...doc.data()});
        
        // Group by date (ignore time)
        final date = DateTime(
          log.completedAt.year,
          log.completedAt.month,
          log.completedAt.day,
        );
        
        if (workoutsByDate.containsKey(date)) {
          workoutsByDate[date]!.add(log);
        } else {
          workoutsByDate[date] = [log];
        }
      }

      return workoutsByDate;
    } catch (e) {
      print('Error fetching workout history: $e');
      return {}; // Return empty map on error
    }
  }
);

class WorkoutCalendarScreen extends ConsumerStatefulWidget {
  final String userId;

  const WorkoutCalendarScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  ConsumerState<WorkoutCalendarScreen> createState() =>
      _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState
    extends ConsumerState<WorkoutCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final workoutHistoryAsync = ref.watch(simpleWorkoutHistoryProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Calendar', style: AppTextStyles.h2),
        centerTitle: true,
        backgroundColor: AppColors.salmon,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              // Navigate to analytics screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutAnalyticsScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: workoutHistoryAsync.when(
              data: (workoutsByDate) {
                return _buildCalendarWithEvents(workoutsByDate);
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
                          ref.refresh(simpleWorkoutHistoryProvider(widget.userId));
                        },
                        child: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.salmon,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addWorkoutToSelectedDay(),
        backgroundColor: AppColors.salmon,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarWithEvents(Map<DateTime, List<WorkoutLog>> workoutsByDate) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: (day) {
            final date = DateTime(day.year, day.month, day.day);
            return workoutsByDate[date] ?? [];
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
        Expanded(
          child: _buildSelectedDayWorkouts(workoutsByDate[_selectedDay] ?? []),
        ),
      ],
    );
  }

  Widget _buildSelectedDayWorkouts(List<WorkoutLog> workouts) {
    if (workouts.isEmpty) {
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
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _addWorkoutToSelectedDay(),
              child: const Text('Add Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salmon,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.salmon,
              child: const Icon(Icons.fitness_center, color: Colors.white),
            ),
            title: Text(
              workout.workoutId,
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
                  builder: (context) => WorkoutDetailScreen(
                    workoutId: workout.workoutId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _addWorkoutToSelectedDay() {
    // Navigate to workout browse screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutBrowseScreen(),
      ),
    ).then((selectedWorkout) {
      if (selectedWorkout != null) {
        // Here you would typically save this to Firebase
        // For MVP, we'll just show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout added to schedule'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the data
        ref.refresh(simpleWorkoutHistoryProvider(widget.userId));
      }
    });
  }
}