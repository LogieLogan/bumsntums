// lib/features/workouts/providers/workout_scheduling_provider.dart
import 'package:bums_n_tums/shared/analytics/firebase_analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../../../shared/providers/analytics_provider.dart';

// Enum for time slots
enum TimeSlot { morning, lunch, evening }

// Class to hold workout with time slot
class ScheduledWorkoutItem {
  final Workout workout;
  TimeSlot timeSlot;

  ScheduledWorkoutItem({
    required this.workout,
    this.timeSlot = TimeSlot.morning,
  });
}

class WorkoutSchedulingNotifier extends StateNotifier<List<ScheduledWorkoutItem>> {
  final AnalyticsService _analytics;

  WorkoutSchedulingNotifier(this._analytics) : super([]);

  void addWorkout(Workout workout, {TimeSlot timeSlot = TimeSlot.morning}) {
    // Check if workout is already selected
    final existingIndex = state.indexWhere((item) => item.workout.id == workout.id);

    if (existingIndex >= 0) {
      // Remove if already selected
      final newState = List<ScheduledWorkoutItem>.from(state);
      newState.removeAt(existingIndex);
      state = newState;
      
      _analytics.logEvent(
        name: 'workout_removed_from_schedule',
        parameters: {'workout_id': workout.id},
      );
    } else {
      // Add if not selected
      state = [...state, ScheduledWorkoutItem(workout: workout, timeSlot: timeSlot)];
      
      _analytics.logEvent(
        name: 'workout_added_to_schedule',
        parameters: {'workout_id': workout.id},
      );
    }
  }

  void updateTimeSlot(int index, TimeSlot newTimeSlot) {
    if (index < 0 || index >= state.length) return;

    final newState = List<ScheduledWorkoutItem>.from(state);
    newState[index].timeSlot = newTimeSlot;
    state = newState;
    
    _analytics.logEvent(
      name: 'workout_time_slot_changed',
      parameters: {
        'workout_id': state[index].workout.id,
        'time_slot': newTimeSlot.toString()
      },
    );
  }

  void removeWorkout(int index) {
    if (index < 0 || index >= state.length) return;

    final workoutId = state[index].workout.id;
    final newState = List<ScheduledWorkoutItem>.from(state);
    newState.removeAt(index);
    state = newState;
    
    _analytics.logEvent(
      name: 'workout_removed_from_schedule',
      parameters: {'workout_id': workoutId},
    );
  }

  void clearAll() {
    state = [];
    
    _analytics.logEvent(name: 'schedule_selection_cleared');
  }

  bool isWorkoutSelected(String workoutId) {
    return state.any((item) => item.workout.id == workoutId);
  }
}

final workoutSchedulingProvider = StateNotifierProvider<WorkoutSchedulingNotifier, List<ScheduledWorkoutItem>>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return WorkoutSchedulingNotifier(analytics);
});