// lib/features/workout_planning/providers/workout_planning_provider.dart
import 'package:bums_n_tums/features/workouts/models/workout_log.dart';
import 'package:bums_n_tums/features/workouts/services/workout_service.dart';
import 'package:bums_n_tums/features/workouts/providers/workout_provider.dart';
import 'package:bums_n_tums/features/workout_analytics/services/workout_stats_service.dart';
import 'package:bums_n_tums/features/workout_analytics/providers/workout_stats_provider.dart';
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../repositories/workout_planning_repository.dart';
import '../models/workout_plan.dart';
import '../models/scheduled_workout.dart';
import '../models/planner_item.dart';


// --- Provider definition remains the same ---
final workoutPlanningRepositoryProvider = Provider<WorkoutPlanningRepository>((
  ref,
) {
  final workoutService = ref.watch(workoutServiceProvider);
  return WorkoutPlanningRepository(workoutService: workoutService);
});


class PlannerItemsNotifier
    extends StateNotifier<AsyncValue<List<PlannerItem>>> {
  final WorkoutPlanningRepository _planningRepository;
  final WorkoutService _workoutService;
  final String _userId;
  final WorkoutStatsService _statsService;
  DateTime? _fetchedRangeStart;
  DateTime? _fetchedRangeEnd;
  final Ref _ref;

  // --- Constructor and other methods remain the same up to deletePlannerItem ---
    PlannerItemsNotifier(
    this._planningRepository,
    this._workoutService,
    this._statsService,
    this._userId,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    final now = DateTime.now();
    final initialStartDate = now.subtract(Duration(days: now.weekday - DateTime.monday));
    final initialEndDate = initialStartDate.add(const Duration(days: 6));
    if (kDebugMode) { // Added braces
      print(
        "Notifier Initialized for user $_userId. Triggering initial fetch for $initialStartDate to $initialEndDate.",
      );
    }
    fetchPlannerItemsForRange(initialStartDate, initialEndDate);
  }

  Future<void> fetchPlannerItemsForRange(
    DateTime startDateInput,
    DateTime endDateInput,
  ) async {
    final DateTime normalizedStartDate = DateTime(
      startDateInput.year, startDateInput.month, startDateInput.day, 0, 0, 0, 0,
    );
    final DateTime normalizedEndDateExclusive = DateTime(
      endDateInput.year, endDateInput.month, endDateInput.day, 0, 0, 0, 0,
    ).add(const Duration(days: 1));
     final DateTime normalizedEndDateInclusive = DateTime(
       endDateInput.year, endDateInput.month, endDateInput.day, 23, 59, 59, 999,
    );

    if (state is AsyncLoading && _fetchedRangeStart == normalizedStartDate && _fetchedRangeEnd == normalizedEndDateInclusive) {
       if (kDebugMode) { // Added braces
         print("Notifier: Fetch already in progress for this range. Skipping.");
       }
       return;
    }
     if (state is! AsyncLoading || _fetchedRangeStart != normalizedStartDate || _fetchedRangeEnd != normalizedEndDateInclusive) {
        if (mounted) {
          state = const AsyncValue.loading();
           if (kDebugMode) { // Added braces
             print("Notifier: Set state to loading for range fetch.");
           }
        } else {
          return;
        }
     }

    _fetchedRangeStart = normalizedStartDate;
    _fetchedRangeEnd = normalizedEndDateInclusive;
    if (kDebugMode) { // Added braces
      print("Notifier: Starting fetch for NORMALISED range: $normalizedStartDate to $normalizedEndDateExclusive (exclusive end)");
    }

    try {
      final scheduledWorkoutsFuture = _planningRepository.getScheduledWorkouts(
        _userId, normalizedStartDate, normalizedEndDateInclusive,
      );
      final workoutLogsFuture = FirebaseFirestore.instance
          .collection('workout_logs').doc(_userId).collection('logs')
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedStartDate))
          .where('completedAt', isLessThan: Timestamp.fromDate(normalizedEndDateExclusive))
          .orderBy('completedAt', descending: true)
          .get();

      final results = await Future.wait([scheduledWorkoutsFuture, workoutLogsFuture]);
      final scheduledWorkouts = results[0] as List<ScheduledWorkout>;
      final logSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final List<WorkoutLog> workoutLogs = List<WorkoutLog>.from(
        logSnapshot.docs.map((doc) {
          try {
            return WorkoutLog.fromMap({'id': doc.id, ...doc.data()});
          } catch (e) {
             if (kDebugMode) { // Added braces
               print("Error parsing WorkoutLog ${doc.id}: $e");
             }
            return null;
          }
        }).whereNotNull(),
      );

      if (kDebugMode) { // Added braces
        print("Notifier: Fetched ${scheduledWorkouts.length} scheduled workouts.");
        print("Notifier: Fetched ${workoutLogs.length} workout logs.");
      }

      final List<PlannerItem> combinedItems = [
        ...scheduledWorkouts.map((sw) => PlannedWorkoutItem(sw)),
        ...workoutLogs.map((log) => LoggedWorkoutItem(log)),
      ];
      combinedItems.sort((a, b) => a.itemDate.compareTo(b.itemDate));

      if (kDebugMode) { // Added braces
        print("Notifier: Combined list has ${combinedItems.length} items. Scheduling state update.");
      }

      if (mounted) {
        Future.microtask(() {
          if (mounted) {
             if (kDebugMode) { // Added braces
               print("Notifier: Microtask executing. Setting state to data.");
             }
            state = AsyncValue.data(combinedItems);
          }
        });
      }
    } catch (e, stackTrace) {
       if (kDebugMode) { // Added braces
         print("Notifier: Error fetching planner items: $e\n$stackTrace");
       }
      if (mounted) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<String?> _ensureAndGetActivePlanId() async {
    WorkoutPlan? activePlan = await _planningRepository.getActiveWorkoutPlan(_userId);
    if (activePlan == null) {
       if (kDebugMode) { // Added braces
         print("No active plan found. Creating a default plan for user: $_userId");
       }
      try {
        final now = DateTime.now();
        final defaultEndDate = DateTime(now.year + 5, now.month, now.day);
        activePlan = await _planningRepository.createWorkoutPlan(
          _userId, "My Schedule", now, defaultEndDate,
          description: "Default schedule for workouts.",
        );
         if (kDebugMode) { // Added braces
           print("Default plan created with ID: ${activePlan.id}");
         }
      } catch (e) {
         if (kDebugMode) { // Added braces
           print("Error creating default workout plan: $e");
         }
        return null;
      }
    }
    return activePlan.id;
  }

  Future<ScheduledWorkout> scheduleWorkout(
    String workoutId, DateTime scheduledDate, {TimeOfDay? preferredTime}
  ) async {
    final String? planId = await _ensureAndGetActivePlanId();
    if (planId == null) {
       if (kDebugMode) { // Added braces
         print("Error: Could not find or create a workout plan ID to schedule workout.");
       }
      throw Exception("Failed to get or create a plan for scheduling.");
    }
    try {
      final scheduledWorkout = await _planningRepository.scheduleWorkout(
        planId, workoutId, _userId, scheduledDate, preferredTime: preferredTime,
      );
       if (kDebugMode) { // Added braces
         print("Notifier: Workout scheduled successfully: ${scheduledWorkout.id}");
       }

      if (state is AsyncData<List<PlannerItem>> &&
          _fetchedRangeStart != null && _fetchedRangeEnd != null &&
          !scheduledDate.isBefore(_fetchedRangeStart!) &&
           scheduledDate.isBefore(_fetchedRangeEnd!.add(const Duration(days: 1)))) {
        final currentItems = List<PlannerItem>.from(state.value!);
        // Correct ID access for PlannedWorkoutItem
        if (!currentItems.any((item) => item is PlannedWorkoutItem && item.scheduledWorkout.id == scheduledWorkout.id)) {
          currentItems.add(PlannedWorkoutItem(scheduledWorkout));
          currentItems.sort((a, b) => a.itemDate.compareTo(b.itemDate));
          if (mounted) {
            state = AsyncValue.data(currentItems);
             if (kDebugMode) { // Added braces
               print("Notifier: Optimistically added scheduled item ${scheduledWorkout.id} to local state.");
             }
          }
        }
      } else {
         if (kDebugMode) { // Added braces
           print("Notifier: Scheduled item outside fetched range, not adding optimistically.");
         }
      }
      return scheduledWorkout;
    } catch (e, stackTrace) {
       if (kDebugMode) { // Added braces
         print("Error in scheduleWorkout repository call: $e\n$stackTrace");
       }
      throw Exception("Failed to schedule workout: $e");
    }
  }

 Future<void> markScheduledItemComplete(ScheduledWorkout scheduledWorkout) async {
     if (scheduledWorkout.isCompleted) {
        if (kDebugMode) { // Added braces
          print("Notifier: Workout ${scheduledWorkout.id} is already marked complete.");
        }
        return;
     }
     Workout? workout = await _fetchWorkoutDetailsIfNeededInternal(scheduledWorkout);
     if (workout == null) {
        throw Exception("Could not fetch workout details for ${scheduledWorkout.workoutId}. Cannot complete.");
     }
     try {
        final now = DateTime.now();
        final completedAt = DateTime(
           scheduledWorkout.scheduledDate.year, scheduledWorkout.scheduledDate.month, scheduledWorkout.scheduledDate.day,
           now.hour, now.minute, now.second
        );
        final durationMinutes = workout.durationMinutes;
        final startedAt = completedAt.subtract(Duration(minutes: durationMinutes));
        final newLog = WorkoutLog(
          id: const Uuid().v4(), userId: _userId, workoutId: workout.id, startedAt: startedAt,
          completedAt: completedAt, durationMinutes: durationMinutes, caloriesBurned: workout.estimatedCaloriesBurn,
          exercisesCompleted: const [], userFeedback: const UserFeedback(rating: 3), isShared: false,
          privacy: 'private', isOfflineCreated: false, syncStatus: 'synced',
          workoutCategory: workout.category.name, workoutName: workout.title, targetAreas: workout.tags,
          source: WorkoutLogSource.scheduled,
        );
        await _workoutService.logCompletedWorkout(newLog);
        await _statsService.updateStatsFromWorkoutLog(newLog);
        final String? planId = await _ensureAndGetActivePlanId();
        if (planId == null) {
          throw Exception("Could not find active plan to mark workout complete.");
        }
        await _planningRepository.markWorkoutCompleted(planId, scheduledWorkout.id, completedAt: completedAt);
         if (kDebugMode) { // Added braces
           print("Notifier: Successfully marked item ${scheduledWorkout.id} complete and updated stats.");
         }
         if (kDebugMode) { // Added braces
           print("Notifier: Invalidating stats providers after marking complete...");
         }
        _ref.invalidate(workoutStatsProvider(_userId));
        _ref.invalidate(userWorkoutStatsProvider(_userId));
        _ref.invalidate(userWorkoutStreakProvider(_userId));
         if (kDebugMode) { // Added braces
           print("Notifier: Stats providers invalidated.");
         }
         if (state is AsyncData<List<PlannerItem>>) {
            final currentItems = List<PlannerItem>.from(state.value!);
            // Correct ID access for PlannedWorkoutItem
            final itemIndex = currentItems.indexWhere((item) => item is PlannedWorkoutItem && item.scheduledWorkout.id == scheduledWorkout.id);
            if (itemIndex != -1) {
               currentItems[itemIndex] = PlannedWorkoutItem(
                  scheduledWorkout.copyWith(isCompleted: true, completedAt: completedAt),
               );
               currentItems.sort((a, b) => a.itemDate.compareTo(b.itemDate));
               if (mounted) {
                  state = AsyncValue.data(currentItems);
                   if (kDebugMode) { // Added braces
                     print("Notifier: Optimistically updated item ${scheduledWorkout.id} to completed in local state.");
                   }
               }
            } else {
              // Correct ID access for LoggedWorkoutItem
               if (!currentItems.any((i) => i is LoggedWorkoutItem && i.workoutLog.id == newLog.id)) {
                  currentItems.add(LoggedWorkoutItem(newLog));
                  currentItems.sort((a, b) => a.itemDate.compareTo(b.itemDate));
                  if (mounted) {
                     state = AsyncValue.data(currentItems);
                      if (kDebugMode) { // Added braces
                        print("Notifier: Scheduled item not found in range, added LoggedWorkoutItem ${newLog.id} optimistically.");
                      }
                  }
               } else {
                   if (kDebugMode) { // Added braces
                     print("Notifier: Warning - Could not find item ${scheduledWorkout.id} for optimistic update, log ${newLog.id} already exists?.");
                   }
               }
            }
         }
     } catch (e) {
        if (kDebugMode) { // Added braces
          print("Notifier: Error during mark complete process for ${scheduledWorkout.id}: $e");
        }
        throw Exception("Failed to mark workout complete: $e");
     }
  }

  // --- Method with corrected ID access and Linting fix ---
  Future<void> deletePlannerItem(PlannerItem itemToDelete) async {
    List<PlannerItem>? previousItems;
    if (state is AsyncData<List<PlannerItem>>) {
      previousItems = List.from(state.value!);
    }

    String itemId; // Variable to hold the correct ID
    if (itemToDelete is PlannedWorkoutItem) {
      itemId = itemToDelete.scheduledWorkout.id;
    } else if (itemToDelete is LoggedWorkoutItem) {
      itemId = itemToDelete.workoutLog.id;
    } else {
       if (kDebugMode) { // Added braces
         print("Notifier: Deletion requested for unknown PlannerItem type: ${itemToDelete.runtimeType}");
       }
       throw UnimplementedError("Deleting this type of planner item is not supported.");
    }

    // Optimistic removal
    if (previousItems != null) {
      // Use the derived itemId for comparison
      final itemIndex = previousItems.indexWhere((item) {
        if (item is PlannedWorkoutItem) return item.scheduledWorkout.id == itemId;
        if (item is LoggedWorkoutItem) return item.workoutLog.id == itemId;
        return false;
      });

      if (itemIndex != -1) {
        previousItems.removeAt(itemIndex);
        if (mounted) {
          state = AsyncValue.data(List.from(previousItems));
           if (kDebugMode) { // Added braces
             print("Notifier: Optimistically removed item $itemId from local state.");
           }
        }
      }
    }

    // Backend deletion
    if (itemToDelete is PlannedWorkoutItem) {
      final String? planId = await _ensureAndGetActivePlanId();
      if (planId == null) {
        if (previousItems != null && mounted) { // Added braces around state update
          state = AsyncValue.data(previousItems);
        }
        throw Exception("Failed to find plan context for deletion.");
      }
      try {
        await _planningRepository.deleteScheduledWorkout(planId, itemToDelete.scheduledWorkout.id);
         if (kDebugMode) { // Added braces
           print("Notifier: Deleted PlannedWorkoutItem ${itemToDelete.scheduledWorkout.id} from backend.");
         }
      } catch (e) {
         if (kDebugMode) { // Added braces
           print("Notifier: Error deleting planned item ${itemToDelete.scheduledWorkout.id}: $e");
         }
        // Revert optimistic removal on error
        if (previousItems != null && mounted) {
          state = AsyncValue.data(previousItems);
           if (kDebugMode) { // Added braces
             print("Notifier: Reverted optimistic removal for ${itemToDelete.scheduledWorkout.id} due to error.");
           }
        }
        throw e; // Re-throw the error
      }
    } else if (itemToDelete is LoggedWorkoutItem) {
       try {
          // Call the service method (which we will add next)
          await _workoutService.deleteWorkoutLog(itemToDelete.workoutLog);
           if (kDebugMode) { // Added braces
             print("Notifier: Deleted LoggedWorkoutItem ${itemToDelete.workoutLog.id} from backend.");
           }
       } catch (e) {
           if (kDebugMode) { // Added braces
             print("Notifier: Error deleting logged item ${itemToDelete.workoutLog.id}: $e");
           }
          // Revert optimistic removal on error
          if (previousItems != null && mounted) {
            state = AsyncValue.data(previousItems);
             if (kDebugMode) { // Added braces
               print("Notifier: Reverted optimistic removal for ${itemToDelete.workoutLog.id} due to error.");
             }
          }
          throw e; // Re-throw the error
       }
    }
    // No else needed here as we handled unknown types earlier
  }


  Future<Workout?> _fetchWorkoutDetailsIfNeededInternal(ScheduledWorkout scheduledWorkout) async {
    Workout? workout = scheduledWorkout.workout;
    if (workout == null || (workout.exercises.isEmpty && workout.sections.isEmpty)) {
       if (kDebugMode) { // Added braces
         print("Notifier Internal: Fetching details for ${scheduledWorkout.workoutId}");
       }
      try {
        workout = await _workoutService.getWorkoutById(scheduledWorkout.workoutId);
        if (workout == null) {
           if (kDebugMode) { // Added braces
             print("Notifier Internal: Workout ${scheduledWorkout.workoutId} not found.");
           }
           return null;
        }
      } catch (e) {
         if (kDebugMode) { // Added braces
           print("Notifier Internal: Error fetching workout ${scheduledWorkout.workoutId}: $e");
         }
        return null;
      }
    } else {
        if (kDebugMode) { // Added braces
          print("Notifier Internal: Using cached/preloaded details for ${scheduledWorkout.workoutId}");
        }
    }
    return workout;
  }
}


// --- Family provider definition remains the same ---
final plannerItemsNotifierProvider = StateNotifierProvider.family<
  PlannerItemsNotifier,
  AsyncValue<List<PlannerItem>>,
  String
>((ref, userId) {
  final planningRepository = ref.watch(workoutPlanningRepositoryProvider);
  final workoutService = ref.watch(workoutServiceProvider);
  final statsService = ref.watch(workoutStatsServiceProvider);
  return PlannerItemsNotifier(
    planningRepository,
    workoutService,
    statsService,
    userId,
    ref,
  );
});