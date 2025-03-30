// lib/features/workouts/widgets/calendar/day_events_section.dart
import 'package:flutter/material.dart';
import '../../../workouts/models/workout_log.dart';
import '../../models/workout_plan.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/theme/text_styles.dart';
import 'workout_event_card.dart';

class DayEventsSection extends StatelessWidget {
  final List<dynamic> events;
  final DateTime selectedDay;
  final Function(String) onNavigateToWorkoutDetail;
  final Function(ScheduledWorkout) onMarkWorkoutAsCompleted;
  final Function(ScheduledWorkout) onMakeWorkoutRecurring;
  final Function(ScheduledWorkout, DateTime) onRescheduleWorkout;
  final VoidCallback onAddWorkout;

  const DayEventsSection({
    Key? key,
    required this.events,
    required this.selectedDay,
    required this.onNavigateToWorkoutDetail,
    required this.onMarkWorkoutAsCompleted,
    required this.onMakeWorkoutRecurring,
    required this.onRescheduleWorkout,
    required this.onAddWorkout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredEvents = events.where((e) => e != 'REST_DAY').toList();

    // Check if this day is a recommended rest day
    final isRestDay = events.any((e) => e == 'REST_DAY');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with improved styling
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Workouts for ${selectedDay.day}/${selectedDay.month}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (filteredEvents.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredEvents.length} workout${filteredEvents.length != 1 ? 's' : ''}',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (isRestDay) _buildRestDayCard(context),

          if (filteredEvents.isEmpty && !isRestDay)
            _buildEmptyDayCard(context)
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  return _buildEnhancedWorkoutCard(event);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedWorkoutCard(dynamic event) {
    if (event is WorkoutLog) {
      // Enhanced completed workout card
      return WorkoutEventCard(
        workout: event,
        isDraggable: false,
        showIntensity: true,
        showTargetAreas: true,
        onTap: () => onNavigateToWorkoutDetail(event.workoutId),
      );
    } else if (event is ScheduledWorkout) {
      // Enhanced scheduled workout card
      return WorkoutEventCard(
        workout: event,
        showIntensity: true,
        showTargetAreas: true,
        onTap: () => onNavigateToWorkoutDetail(event.workoutId),
        onComplete:
            event.isCompleted ? null : () => onMarkWorkoutAsCompleted(event),
        onMakeRecurring:
            event.isRecurring ? null : () => onMakeWorkoutRecurring(event),
        onReschedule: (newDate) => onRescheduleWorkout(event, newDate),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRestDayCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.paleGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bedtime_outlined, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rest Day Recommended',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Recovery helps improve results and prevent injury',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Show recovery activities dialog
                _showRecoveryActivitiesDialog(context);
              },
              icon: const Icon(Icons.healing),
              label: const Text('View Recovery Activities'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecoveryActivitiesDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recovery Activities', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                'Try these activities to enhance your recovery',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.mediumGrey,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecoveryActivity(
                'Light stretching',
                '10-15 minutes of gentle stretches',
                Icons.self_improvement,
              ),
              _buildRecoveryActivity(
                'Hydration',
                'Drink plenty of water throughout the day',
                Icons.water_drop,
              ),
              _buildRecoveryActivity(
                'Sleep',
                'Aim for 7-9 hours of quality sleep',
                Icons.bedtime,
              ),
              _buildRecoveryActivity(
                'Walking',
                '20-30 minutes of easy walking',
                Icons.directions_walk,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecoveryActivity(
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(description, style: AppTextStyles.small),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayCard(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No workouts scheduled',
              style: AppTextStyles.body.copyWith(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddWorkout,
              icon: const Icon(Icons.add),
              label: const Text('Schedule Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}