// lib/features/workouts/widgets/calendar/workout_event_card.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/theme/text_styles.dart';
import '../../../workouts/models/workout_log.dart';
import '../../models/workout_plan.dart';

enum WorkoutEventType { scheduled, completed, missed }

class WorkoutEventCard extends StatefulWidget {
  final dynamic workout; // ScheduledWorkout or WorkoutLog
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onMakeRecurring;
  final Function(DateTime)? onReschedule;
  final bool isDraggable;
  final WorkoutPlan? plan;
  final bool showIntensity;
  final bool showTargetAreas;

  const WorkoutEventCard({
    Key? key,
    required this.workout,
    this.onTap,
    this.onComplete,
    this.onMakeRecurring,
    this.onReschedule,
    this.isDraggable = true,
    this.plan,
    this.showIntensity = false,
    this.showTargetAreas = false,
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
    return _getEventType() == WorkoutEventType.scheduled &&
        widget.onComplete != null;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
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

                // Plan indicator if available
                if (widget.plan != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.plan!.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.plan!.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.plan!.color,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onTap,
          ),

          // Show intensity if enabled
          if (widget.showIntensity && _getEventIntensity() > 0)
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 4.0,
              ),
              child: Row(
                children: [
                  Text(
                    'Intensity:',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildIntensityIndicator(_getEventIntensity()),
                ],
              ),
            ),

          // Show target areas if enabled
          if (widget.showTargetAreas && _getEventTargetAreas().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 8.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Targets:',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children:
                          _getEventTargetAreas()
                              .map((area) => _buildTargetAreaChip(area))
                              .toList(),
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          if (_showCompleteButton() || _showRecurringButton())
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 8.0,
              ),
              child: Row(
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
            ),
        ],
      ),
    );

    // If not draggable, return the card as is
    if (!widget.isDraggable ||
        widget.onReschedule == null ||
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
      childWhenDragging: Opacity(opacity: 0.5, child: card),
      onDragEnd: (details) {
        if (details.wasAccepted && widget.onReschedule != null) {
          final now = DateTime.now();
          final tomorrow = DateTime(now.year, now.month, now.day + 1);
          widget.onReschedule!(tomorrow);
        }
      },
      child: card,
    );
  }

  // Helper method to build intensity indicator
  Widget _buildIntensityIndicator(int intensity) {
    return Row(
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(
            index < intensity ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: index < intensity ? AppColors.pink : Colors.grey[300],
          ),
        );
      }),
    );
  }

  // Helper method to build target area chip
  Widget _buildTargetAreaChip(String area) {
    Color chipColor;
    switch (area.toLowerCase()) {
      case 'bums':
        chipColor = AppColors.salmon;
        break;
      case 'tums':
        chipColor = AppColors.popCoral;
        break;
      case 'arms':
        chipColor = AppColors.popBlue;
        break;
      case 'legs':
        chipColor = AppColors.popGreen;
        break;
      case 'back':
        chipColor = AppColors.popYellow;
        break;
      default:
        chipColor = AppColors.mediumGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 0.5),
      ),
      child: Text(
        area,
        style: AppTextStyles.caption.copyWith(color: chipColor),
      ),
    );
  }

  // Helper methods to get workout properties
  int _getEventIntensity() {
    if (widget.workout is ScheduledWorkout) {
      return (widget.workout as ScheduledWorkout).intensity;
    }
    // Default medium intensity
    return 3;
  }

  List<String> _getEventTargetAreas() {
    if (widget.workout is ScheduledWorkout) {
      return (widget.workout as ScheduledWorkout).targetAreas;
    } else if (widget.workout is WorkoutLog) {
      return (widget.workout as WorkoutLog).targetAreas;
    }
    return [];
  }
}
