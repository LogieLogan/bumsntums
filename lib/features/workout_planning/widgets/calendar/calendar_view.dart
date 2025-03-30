// lib/features/workouts/widgets/calendar/calendar_view.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/workout_plan.dart';
import '../../../../shared/theme/color_palette.dart';

class CalendarView extends StatelessWidget {
  final Map<DateTime, List<dynamic>> events;
  final DateTime selectedDay;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;

  const CalendarView({
    Key? key,
    required this.events,
    required this.selectedDay,
    required this.focusedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedDay,
      calendarFormat: calendarFormat,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.twoWeeks: '2 Weeks',
        CalendarFormat.week: 'Week',
      },
      eventLoader: (day) {
        // Normalize the day to remove time component for comparison
        final normalizedDay = DateTime(day.year, day.month, day.day);
        return events[normalizedDay] ?? [];
      },
      selectedDayPredicate: (day) {
        return isSameDay(selectedDay, day);
      },
      onDaySelected: onDaySelected,
      onFormatChanged: onFormatChanged,
      onPageChanged: onPageChanged,
      calendarStyle: const CalendarStyle(
        markersMaxCount: 3,
        markersAlignment: Alignment.bottomCenter,
        markerMargin: EdgeInsets.symmetric(horizontal: 1),
      ),
      calendarBuilders: CalendarBuilders(
        // Enhanced marker builder for better visualization
        markerBuilder: (context, date, dateEvents) {
          if (dateEvents.isEmpty) return const SizedBox.shrink();

          // Check if this is a rest day
          final isRestDay = dateEvents.any((e) => e == 'REST_DAY');

          // Group events by type for better visualization
          final workouts = dateEvents.where((e) => e != 'REST_DAY').toList();

          // Calculate the overall intensity level for this day
          int intensityLevel = _calculateDayIntensity(workouts);

          // Get the dominant workout category
          String? dominantCategory = _getDominantCategory(workouts);

          return Positioned(
            bottom: 1,
            child: Column(
              children: [
                // Rest day indicator
                if (isRestDay)
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    width: 10,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                // Workout indicators
                if (workouts.isNotEmpty)
                  _buildWorkoutIndicators(
                    workouts,
                    intensityLevel,
                    dominantCategory,
                  ),
              ],
            ),
          );
        },

        // Enhanced selected day builder
        selectedBuilder: (context, date, _) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: AppColors.pink.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.pink, width: 1.5),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: const TextStyle(
                  color: AppColors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },

        // Enhanced today builder
        todayBuilder: (context, date, _) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: AppColors.pink.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.pink.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: const TextStyle(
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to build workout indicators
  Widget _buildWorkoutIndicators(
    List<dynamic> workouts,
    int intensityLevel,
    String? dominantCategory,
  ) {
    // Choose color based on category
    Color indicatorColor = _getCategoryColor(dominantCategory);

    // Build dots based on workout count and intensity
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        workouts.length < 3 ? workouts.length : 3, // Limit to 3 indicators
        (index) {
          // Vary size based on intensity
          final double size = 6.0 + (intensityLevel * 0.3);

          return Container(
            width: size,
            height: size,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: indicatorColor,
              boxShadow: [
                BoxShadow(
                  color: indicatorColor.withOpacity(0.3),
                  blurRadius: 1,
                  spreadRadius: 0.3,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to calculate day intensity
  int _calculateDayIntensity(List<dynamic> workouts) {
    if (workouts.isEmpty) return 0;

    int totalIntensity = 0;
    int countWithIntensity = 0;

    for (final event in workouts) {
      if (event is ScheduledWorkout) {
        totalIntensity += event.intensity;
        countWithIntensity++;
      }
    }

    if (countWithIntensity > 0) {
      return (totalIntensity / countWithIntensity).round();
    }

    // Default intensity based on number of workouts
    return workouts.length < 5 ? workouts.length + 1 : 5;
  }

  // Helper method to get dominant category
  String? _getDominantCategory(List<dynamic> workouts) {
    if (workouts.isEmpty) return null;

    Map<String, int> categories = {};

    for (final event in workouts) {
      if (event is ScheduledWorkout && event.workoutCategory != null) {
        categories[event.workoutCategory!] =
            (categories[event.workoutCategory!] ?? 0) + 1;
      }
    }

    if (categories.isEmpty) return null;

    // Find category with highest count
    String? dominant;
    int maxCount = 0;

    categories.forEach((category, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = category;
      }
    });

    return dominant;
  }

  // Helper method to get color for category
  Color _getCategoryColor(String? category) {
    if (category == null) return AppColors.pink;

    switch (category.toLowerCase()) {
      case 'bums':
        return AppColors.salmon;
      case 'tums':
        return AppColors.popCoral;
      case 'fullbody':
        return AppColors.popBlue;
      case 'cardio':
        return AppColors.popGreen;
      case 'quickworkout':
        return AppColors.popYellow;
      default:
        return AppColors.pink;
    }
  }
}