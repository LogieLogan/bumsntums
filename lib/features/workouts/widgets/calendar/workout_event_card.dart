// lib/features/workouts/widgets/calendar/workout_event_card.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/theme/text_styles.dart';
import '../../models/workout_log.dart';
import '../../models/workout_plan.dart';

enum WorkoutEventType {
  scheduled,
  completed,
  missed,
}

class WorkoutEventCard extends StatefulWidget {
  final dynamic workout; // ScheduledWorkout or WorkoutLog
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onMakeRecurring;
  final Function(DateTime)? onReschedule;
  final bool isDraggable;
  
  const WorkoutEventCard({
    Key? key,
    required this.workout,
    this.onTap,
    this.onComplete,
    this.onMakeRecurring,
    this.onReschedule,
    this.isDraggable = true,
  }) : super(key: key);

  @override
  State<WorkoutEventCard> createState() => _WorkoutEventCardState();
}

class _WorkoutEventCardState extends State<WorkoutEventCard> {
  WorkoutEventType _getEventType() {
    if (widget.workout is WorkoutLog) {
      return WorkoutEventType.completed;
    }
    
    if (widget.workout is ScheduledWorkout) {
      final scheduled = widget.workout as ScheduledWorkout;
      
      if (scheduled.isCompleted) {
        return WorkoutEventType.completed;
      }
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final scheduledDate = DateTime(
        scheduled.scheduledDate.year,
        scheduled.scheduledDate.month,
        scheduled.scheduledDate.day,
      );
      
      if (scheduledDate.isBefore(today)) {
        return WorkoutEventType.missed;
      }
      
      return WorkoutEventType.scheduled;
    }
    
    return WorkoutEventType.scheduled; // Default
  }

  Color _getEventColor() {
    switch (_getEventType()) {
      case WorkoutEventType.completed:
        return AppColors.popGreen;
      case WorkoutEventType.missed:
        return Colors.grey;
      case WorkoutEventType.scheduled:
        return AppColors.popCoral;
    }
  }

  Widget _getEventIcon() {
    switch (_getEventType()) {
      case WorkoutEventType.completed:
        return const Icon(Icons.check_circle, color: Colors.white);
      case WorkoutEventType.missed:
        return const Icon(Icons.timer_off, color: Colors.white);
      case WorkoutEventType.scheduled:
        return const Icon(Icons.fitness_center, color: Colors.white);
    }
  }

  String _getEventTitle() {
    if (widget.workout is WorkoutLog) {
      return 'Completed Workout'; // In a real app, fetch workout title
    }
    
    if (widget.workout is ScheduledWorkout) {
      return (widget.workout as ScheduledWorkout).title;
    }
    
    return 'Workout';
  }

  String _getEventSubtitle() {
    if (widget.workout is WorkoutLog) {
      final log = widget.workout as WorkoutLog;
      return '${log.durationMinutes} mins • ${log.caloriesBurned} calories';
    }
    
    if (widget.workout is ScheduledWorkout) {
      final scheduled = widget.workout as ScheduledWorkout;
      final date = scheduled.scheduledDate;
      return 'Scheduled for ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    return '';
  }

  bool _showCompleteButton() {
    return _getEventType() == WorkoutEventType.scheduled && widget.onComplete != null;
  }

  bool _showRecurringButton() {
    return _getEventType() == WorkoutEventType.scheduled && 
           widget.onMakeRecurring != null &&
           widget.workout is ScheduledWorkout &&
           !(widget.workout as ScheduledWorkout).isRecurring;
  }

  @override
  Widget build(BuildContext context) {
    // Create a basic card
    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEventColor(),
          child: _getEventIcon(),
        ),
        title: Text(
          _getEventTitle(),
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getEventSubtitle()),
            if (_showCompleteButton() || _showRecurringButton())
              Row(
                children: [
                  if (_showCompleteButton())
                    TextButton.icon(
                      onPressed: widget.onComplete,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Complete'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.popGreen,
                      ),
                    ),
                  if (_showCompleteButton() && _showRecurringButton())
                    const SizedBox(width: 8),
                  if (_showRecurringButton())
                    TextButton.icon(
                      onPressed: widget.onMakeRecurring,
                      icon: const Icon(Icons.repeat, size: 16),
                      label: const Text('Repeat'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppColors.popBlue,
                      ),
                    ),
                ],
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: widget.onTap,
      ),
    );
    
    // If not draggable, return the card as is
    if (!widget.isDraggable || widget.onReschedule == null || 
        _getEventType() != WorkoutEventType.scheduled) {
      return card;
    }
    
    // Otherwise, make it draggable
    return LongPressDraggable<ScheduledWorkout>(
      data: widget.workout as ScheduledWorkout,
      feedback: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(8.0),
          child: card,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: card,
      ),
      onDragEnd: (details) {
        // When user drops the workout, we need to determine the target date
        // This is a simplified implementation, in a real app you would want to
        // calculate the actual day based on the position
        if (details.wasAccepted && widget.onReschedule != null) {
          // For now, let's just reschedule to tomorrow as an example
          final now = DateTime.now();
          final tomorrow = DateTime(now.year, now.month, now.day + 1);
          widget.onReschedule!(tomorrow);
        }
      },
      child: card,
    );
  }
}