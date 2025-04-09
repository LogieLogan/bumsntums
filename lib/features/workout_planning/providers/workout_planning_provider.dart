// lib/features/workout_planning/providers/workout_planning_provider.dart
import 'package:bums_n_tums/features/workouts/models/workout_log.dart';
import 'package:bums_n_tums/features/workouts/services/workout_service.dart'; // Need WorkoutService to fetch logs
import 'package:bums_n_tums/features/workouts/providers/workout_provider.dart'; // Provider for WorkoutService
import 'package:cloud_firestore/cloud_firestore.dart'; // Direct Firestore access for logs
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../repositories/workout_planning_repository.dart';
import '../models/workout_plan.dart'; // Keep for potential reference if needed
import '../models/scheduled_workout.dart';

// --- 1. Define PlannerItem Sealed Class ---
abstract class PlannerItem extends Equatable {
  DateTime get itemDate; // Common property for sorting/grouping by date
  String get id; // Common ID property
}

class PlannedWorkoutItem extends PlannerItem {
  final ScheduledWorkout scheduledWorkout;

  PlannedWorkoutItem(this.scheduledWorkout);

  @override
  DateTime get itemDate => scheduledWorkout.scheduledDate;

  @override
  String get id => scheduledWorkout.id; // Use scheduledWorkout's ID

  @override
  List<Object?> get props => [scheduledWorkout];
}

class LoggedWorkoutItem extends PlannerItem {
  final WorkoutLog workoutLog;

  LoggedWorkoutItem(this.workoutLog);

  // Use completedAt for logs, ensure it's non-null or handle appropriately
  @override
  DateTime get itemDate => workoutLog.completedAt;

  @override
  String get id => workoutLog.id; // Use workoutLog's ID

  @override
  List<Object?> get props => [workoutLog];
}
// --- End PlannerItem Definition ---


// Repository provider (remains the same)
final workoutPlanningRepositoryProvider = Provider<WorkoutPlanningRepository>((ref) {
  // If WorkoutPlanningRepository needs WorkoutService, provide it here
  final workoutService = ref.watch(workoutServiceProvider);
  return WorkoutPlanningRepository(workoutService: workoutService);
});

// --- DEPRECATE OR REMOVE these providers as the notifier will handle the combined view ---
// final activeWorkoutPlanProvider = ...
// final scheduledWorkoutsProvider = ...
// final workoutPlansProvider = ...
// final weeklyWorkoutsProvider = ...
// ---

// --- 2. Change Notifier State and Dependencies ---
// Renamed Notifier for clarity
class PlannerItemsNotifier extends StateNotifier<AsyncValue<List<PlannerItem>>> {
  final WorkoutPlanningRepository _planningRepository;
  final WorkoutService _workoutService; // Dependency for fetching logs
  final String _userId;
  // Store the currently fetched range to avoid redundant fetches if needed
  DateTime? _fetchedRangeStart;
  DateTime? _fetchedRangeEnd;

  PlannerItemsNotifier(this._planningRepository, this._workoutService, this._userId)
      : super(const AsyncValue.loading()) {
    // Initial load could fetch for the current week, or wait for UI trigger
    // Let's wait for an explicit fetch call for now
  }

  // --- 4. Modify Fetching Logic ---
  Future<void> fetchPlannerItemsForRange(DateTime startDate, DateTime endDate) async {
    // Optional: Check if the requested range is already loaded
    // if (_fetchedRangeStart == startDate && _fetchedRangeEnd == endDate && state is AsyncData) {
    //   return; // Already loaded this range
    // }

    state = const AsyncValue.loading();
    _fetchedRangeStart = startDate;
    _fetchedRangeEnd = endDate;

    try {
      // Fetch scheduled workouts
      final scheduledWorkoutsFuture = _planningRepository.getScheduledWorkouts(_userId, startDate, endDate);

      // Fetch workout logs (using WorkoutService or direct query)
      // Option A: Using WorkoutService (if it has a getLogsByDateRange method)
      // final workoutLogsFuture = _workoutService.getWorkoutLogs(_userId, startDate, endDate);

      // Option B: Direct Firestore Query (as WorkoutService might not have this yet)
      final workoutLogsFuture = FirebaseFirestore.instance
          .collection('workout_logs')
          .doc(_userId)
          .collection('logs')
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate.add(const Duration(days: 1)))) // Ensure end date inclusivity
          .orderBy('completedAt', descending: true) // Order as needed
          .get();


      // Wait for both fetches to complete
      final results = await Future.wait([
          scheduledWorkoutsFuture,
          workoutLogsFuture,
      ]);

      final scheduledWorkouts = results[0] as List<ScheduledWorkout>;
      final logSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;

      final workoutLogs = logSnapshot.docs.map((doc) {
         try {
            return WorkoutLog.fromMap({'id': doc.id, ...doc.data()});
          } catch (e) {
            print("Error parsing WorkoutLog ${doc.id}: $e");
            return null; // Handle parsing error, maybe filter out nulls later
          }
      }).whereNotNull().toList(); // Filter out any logs that failed to parse


      // Combine into PlannerItem list
      final List<PlannerItem> combinedItems = [];

      // Add planned items
      for (final sw in scheduledWorkouts) {
          // *** Crucial Decision: Avoid Duplicates ***
          // If a scheduled workout is marked completed, should we show it *and* the log?
          // Option 1: Show both (distinguish visually in UI)
          // Option 2: If completed, *only* show the LoggedWorkoutItem.
          // Option 3: If completed, show the LoggedWorkoutItem, potentially linking back to the plan details.

          // Let's go with Option 1 for now (show both if completed), UI can decide how to display.
          // You might refine this later.
          combinedItems.add(PlannedWorkoutItem(sw));
      }

      // Add logged items
      for (final log in workoutLogs) {
        combinedItems.add(LoggedWorkoutItem(log));
      }

      // Sort by date (optional, but good for consistency)
      combinedItems.sort((a, b) => a.itemDate.compareTo(b.itemDate));

      state = AsyncValue.data(combinedItems);

    } catch (e, stackTrace) {
      print("Error fetching planner items: $e");
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // --- 5. Update CRUD Methods (Example: Deleting) ---

  // Schedule Workout: Adds a PlannedWorkoutItem
  Future<void> scheduleWorkout( String workoutId, DateTime scheduledDate, {TimeOfDay? preferredTime}) async {
       // Find the active plan ID first (or handle cases without plans)
       // This logic might need adjustment based on whether you still require plans
       final activePlan = await _planningRepository.getActiveWorkoutPlan(_userId); // You might need a way to get the plan ID
       if (activePlan == null) {
         // Handle error: Cannot schedule without an active plan (or adjust logic)
         print("Error: No active workout plan found to schedule workout.");
         // Optionally update state to reflect the error
         // state = AsyncValue.error("No active plan", StackTrace.current);
         return;
       }

       try {
           final scheduledWorkout = await _planningRepository.scheduleWorkout(
               activePlan.id, // Use the fetched plan ID
               workoutId,
               _userId,
               scheduledDate,
               preferredTime: preferredTime,
           );

           // Add to current state if it's within the fetched range
           if (state.hasValue &&
               _fetchedRangeStart != null && _fetchedRangeEnd != null &&
               !scheduledDate.isBefore(_fetchedRangeStart!) &&
               !scheduledDate.isAfter(_fetchedRangeEnd!))
           {
               final currentItems = List<PlannerItem>.from(state.value!);
               currentItems.add(PlannedWorkoutItem(scheduledWorkout));
               currentItems.sort((a, b) => a.itemDate.compareTo(b.itemDate));
               state = AsyncValue.data(currentItems);
           } else {
               // If outside range, just invalidate to force refetch next time range is viewed
               // Or trigger a refetch immediately if desired
               fetchPlannerItemsForRange(_fetchedRangeStart!, _fetchedRangeEnd!);
           }
       } catch (e, stackTrace) {
           state = AsyncValue.error(e, stackTrace); // Propagate error
       }
   }


  // Delete Item (Handles both Planned and Logged - though logging deletion might be restricted)
  Future<void> deletePlannerItem(PlannerItem item) async {
      if (!state.hasValue) return;

      final currentItems = List<PlannerItem>.from(state.value!);
      final itemIndex = currentItems.indexWhere((i) => i.id == item.id);
      if (itemIndex == -1) return; // Item not found

      // Optimistic UI update
      currentItems.removeAt(itemIndex);
      state = AsyncValue.data(List.from(currentItems)); // Create new list

      try {
          if (item is PlannedWorkoutItem) {
              // Find the plan ID associated with this scheduled item - this is tricky now!
              // You might need to fetch the plan ID or adjust the repository method.
              // For simplicity, let's assume you can get the plan ID.
              final plan = await _planningRepository.getActiveWorkoutPlan(_userId); // Example fetch
              if (plan != null) {
                 await _planningRepository.deleteScheduledWorkout(plan.id, item.scheduledWorkout.id);
              } else {
                throw Exception("Could not find plan to delete scheduled workout from.");
              }
          } else if (item is LoggedWorkoutItem) {
              // Decide if deleting logs from the planner is allowed.
              // If so, call a method in WorkoutService or repository to delete the log.
              // Example: await _workoutService.deleteWorkoutLog(item.workoutLog.id);
              print("Deleting workout logs is not implemented in this example.");
              // If deletion fails, revert UI state
              // fetchPlannerItemsForRange(_fetchedRangeStart!, _fetchedRangeEnd!); // Re-fetch to correct
              throw UnimplementedError("Deleting workout logs not implemented.");
          }
      } catch (e, stackTrace) {
          print("Error deleting planner item: $e");
          // Revert optimistic update on failure
           fetchPlannerItemsForRange(_fetchedRangeStart!, _fetchedRangeEnd!); // Re-fetch
           // Optionally update state to AsyncError temporarily
      }
  }


  // --- 6. Remove/Adjust Plan-Specific Logic ---
  // - createWorkoutPlan might live elsewhere (e.g., a separate PlanManagementProvider)
  // - markWorkoutCompleted (on a ScheduledWorkout) is less relevant now, as completion creates a LoggedWorkoutItem.
  // - updateScheduledWorkout needs similar logic to deletePlannerItem regarding plan ID.


  // Helper to potentially refresh data if needed externally
  void refreshCurrentRange() {
    if (_fetchedRangeStart != null && _fetchedRangeEnd != null) {
      fetchPlannerItemsForRange(_fetchedRangeStart!, _fetchedRangeEnd!);
    }
  }


  // Method to add a manually logged workout (called after saving via WorkoutService)
  // This is primarily for optimistic UI updates if desired, otherwise invalidation handles it.
  void addManuallyLoggedWorkout(WorkoutLog log) {
      if (state.hasValue &&
          _fetchedRangeStart != null && _fetchedRangeEnd != null &&
          !log.completedAt.isBefore(_fetchedRangeStart!) &&
           log.completedAt.isBefore(_fetchedRangeEnd!.add(const Duration(days: 1)))) // Check if within range
      {
           final currentItems = List<PlannerItem>.from(state.value!);
           // Avoid adding duplicates if invalidation already added it
           if (!currentItems.any((item) => item is LoggedWorkoutItem && item.workoutLog.id == log.id)) {
               currentItems.add(LoggedWorkoutItem(log));
               currentItems.sort((a, b) => a.itemDate.compareTo(b.itemDate));
               state = AsyncValue.data(currentItems);
           }
       }
       // No need to else{} here, as invalidation from WorkoutCompletionScreen should handle refreshes
       // if the log is outside the currently viewed range.
  }

}

// --- 7. Update Provider Definitions ---
// Renamed provider
final plannerItemsNotifierProvider = StateNotifierProvider.family<PlannerItemsNotifier, AsyncValue<List<PlannerItem>>, String>((ref, userId) {
  final planningRepository = ref.watch(workoutPlanningRepositoryProvider);
  final workoutService = ref.watch(workoutServiceProvider); // Get WorkoutService instance
  return PlannerItemsNotifier(planningRepository, workoutService, userId);
});