// lib/features/workout_planning/providers/workout_planning_provider.dart
import 'package:bums_n_tums/features/workouts/models/workout_log.dart';
import 'package:bums_n_tums/features/workouts/services/workout_service.dart';
import 'package:bums_n_tums/features/workouts/providers/workout_provider.dart';
import 'package:bums_n_tums/features/workout_analytics/services/workout_stats_service.dart';
import 'package:bums_n_tums/features/workout_analytics/providers/workout_stats_provider.dart';
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../repositories/workout_planning_repository.dart';
import '../models/workout_plan.dart'; // Import needed for _ensureAndGetActivePlanId
import '../models/scheduled_workout.dart';

abstract class PlannerItem extends Equatable {
  DateTime get itemDate;
  String get id;
}

class PlannedWorkoutItem extends PlannerItem {
  final ScheduledWorkout scheduledWorkout;
  PlannedWorkoutItem(this.scheduledWorkout);
  @override
  DateTime get itemDate => scheduledWorkout.scheduledDate;
  @override
  String get id => scheduledWorkout.id;
  @override
  List<Object?> get props => [scheduledWorkout];
}

class LoggedWorkoutItem extends PlannerItem {
  final WorkoutLog workoutLog;
  LoggedWorkoutItem(this.workoutLog);
  @override
  DateTime get itemDate => workoutLog.completedAt;
  @override
  String get id => workoutLog.id;
  @override
  List<Object?> get props => [workoutLog];
}

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

  PlannerItemsNotifier(
    this._planningRepository,
    this._workoutService,
    this._statsService,
    this._userId,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    // Initial fetch logic remains the same
    final now = DateTime.now();
    final initialStartDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final initialEndDate = initialStartDate.add(const Duration(days: 6));
    print(
      "Notifier Initialized for user $_userId. Triggering initial fetch for $initialStartDate to $initialEndDate.",
    );
    fetchPlannerItemsForRange(initialStartDate, initialEndDate);
  }

  Future<void> fetchPlannerItemsForRange(
    DateTime startDateInput,
    DateTime endDateInput,
  ) async {
    // Date normalization...
    final DateTime normalizedStartDate = DateTime(
      startDateInput.year,
      startDateInput.month,
      startDateInput.day,
      0,
      0,
      0,
      0,
    );
    final DateTime normalizedEndDateExclusive = DateTime(
      endDateInput.year,
      endDateInput.month,
      endDateInput.day,
      0,
      0,
      0,
      0,
    ).add(const Duration(days: 1));
    final DateTime normalizedEndDateInclusive = DateTime(
      endDateInput.year,
      endDateInput.month,
      endDateInput.day,
      23,
      59,
      59,
      999,
    );

    if (state is! AsyncLoading ||
        _fetchedRangeStart != normalizedStartDate ||
        _fetchedRangeEnd != normalizedEndDateInclusive) {
      if (mounted) {
        state = const AsyncValue.loading();
      } else {
        return;
      }
    }
    _fetchedRangeStart = normalizedStartDate;
    _fetchedRangeEnd = normalizedEndDateInclusive;
    print(
      "Notifier: Starting fetch for NORMALISED range: $normalizedStartDate to $normalizedEndDateExclusive (exclusive end)",
    );

    try {
      final scheduledWorkoutsFuture = _planningRepository.getScheduledWorkouts(
        _userId,
        normalizedStartDate,
        normalizedEndDateInclusive,
      );
      final workoutLogsFuture =
          FirebaseFirestore.instance
              .collection('workout_logs')
              .doc(_userId)
              .collection('logs')
              .where(
                'completedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedStartDate),
              ) // Start of start day
              .where(
                'completedAt',
                isLessThan: Timestamp.fromDate(normalizedEndDateExclusive),
              ) // Strictly less than start of next day
              .orderBy('completedAt', descending: true)
              .get();

      final results = await Future.wait([
        scheduledWorkoutsFuture,
        workoutLogsFuture,
      ]);
      final scheduledWorkouts = results[0] as List<ScheduledWorkout>;
      final logSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final List<WorkoutLog> workoutLogs = List<WorkoutLog>.from(
        logSnapshot.docs.map((doc) {
          try {
            return WorkoutLog.fromMap({'id': doc.id, ...doc.data()});
          } catch (e) {
            print("Error parsing WorkoutLog ${doc.id}: $e");
            return null;
          }
        }).whereNotNull(), // whereNotNull is crucial before List.from
      );

      print(
        "Notifier: Fetched ${scheduledWorkouts.length} scheduled workouts.",
      );
      print("Notifier: Fetched ${workoutLogs.length} workout logs.");

      final List<PlannerItem> combinedItems = [];
      for (final sw in scheduledWorkouts) {
        combinedItems.add(PlannedWorkoutItem(sw));
      }
      for (final log in workoutLogs) {
        combinedItems.add(LoggedWorkoutItem(log));
      }
      combinedItems.sort((a, b) => a.itemDate.compareTo(b.itemDate));

      print(
        "Notifier: Combined list has ${combinedItems.length} items. Scheduling state update.",
      );

      // --- Delay state update using microtask ---
      if (mounted) {
        Future.microtask(() {
          if (mounted) {
            // Check mounted again inside microtask
            print("Notifier: Microtask executing. Setting state to data.");
            state = AsyncValue.data(combinedItems);
          }
        });
      }
      // --- End Delay ---
    } catch (e, stackTrace) {
      print("Notifier: Error fetching planner items: $e\n$stackTrace");
      if (mounted) {
        // Update error state immediately or also microtask? Let's do immediate for errors.
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  // Ensure _ensureAndGetActivePlanId is present and correct
  Future<String?> _ensureAndGetActivePlanId() async {
    WorkoutPlan? activePlan = await _planningRepository.getActiveWorkoutPlan(
      _userId,
    );
    if (activePlan == null) {
      print("No active plan found. Creating a default plan for user: $_userId");
      try {
        final now = DateTime.now();
        final defaultEndDate = DateTime(now.year + 10, now.month, now.day);
        activePlan = await _planningRepository.createWorkoutPlan(
          _userId,
          "My Schedule",
          now,
          defaultEndDate,
          description: "Default schedule for workouts.",
        );
        print("Default plan created with ID: ${activePlan.id}");
      } catch (e) {
        print("Error creating default workout plan: $e");
        return null;
      }
    }
    return activePlan.id;
  }

  // scheduleWorkout method remains unchanged from last correct version
  Future<ScheduledWorkout> scheduleWorkout(
    String workoutId,
    DateTime scheduledDate, {
    TimeOfDay? preferredTime,
  }) async {
    final String? planId = await _ensureAndGetActivePlanId();
    if (planId == null) {
      print(
        "Error: Could not find or create a workout plan ID to schedule workout.",
      );
      throw Exception("Failed to get or create a plan for scheduling.");
    }
    try {
      final scheduledWorkout = await _planningRepository.scheduleWorkout(
        planId,
        workoutId,
        _userId,
        scheduledDate,
        preferredTime: preferredTime,
      );
      print("Notifier: Workout scheduled successfully: ${scheduledWorkout.id}");

      // --- Optimistic Local State Update ---
      // Only update if current state is data and within the fetched range
      if (state is AsyncData<List<PlannerItem>> &&
          _fetchedRangeStart != null &&
          _fetchedRangeEnd != null &&
          !scheduledDate.isBefore(_fetchedRangeStart!) &&
          scheduledDate.isBefore(
            _fetchedRangeEnd!.add(const Duration(days: 1)),
          )) {
        final currentItems = List<PlannerItem>.from(state.value!);
        // Avoid duplicates if already present (unlikely but safe)
        if (!currentItems.any((item) => item.id == scheduledWorkout.id)) {
          currentItems.add(PlannedWorkoutItem(scheduledWorkout));
          currentItems.sort((a, b) => a.itemDate.compareTo(b.itemDate));
          if (mounted) {
            state = AsyncValue.data(currentItems);
            print(
              "Notifier: Optimistically added scheduled item ${scheduledWorkout.id} to local state.",
            );
          }
        }
      }
      return scheduledWorkout;
    } catch (e, stackTrace) {
      print("Error in scheduleWorkout repository call: $e\n$stackTrace");
      throw Exception("Failed to schedule workout: $e");
    }
  }

  Future<void> markScheduledItemComplete(
    ScheduledWorkout scheduledWorkout,
  ) async {
    if (scheduledWorkout.isCompleted) {
      print(
        "Notifier: Workout ${scheduledWorkout.id} is already marked complete.",
      );
      return;
    }

    Workout? workout = await _fetchWorkoutDetailsIfNeededInternal(
      scheduledWorkout,
    );

    if (workout == null || workout.exercises.isEmpty) {
      print(
        "Notifier: Fetching full workout details for ${scheduledWorkout.workoutId} before marking complete.",
      );
      try {
        workout = await _workoutService.getWorkoutById(
          scheduledWorkout.workoutId,
        );
        if (workout == null) {
          throw Exception(
            "Could not find details for workout ID: ${scheduledWorkout.workoutId}. Cannot complete.",
          );
        }
        print("Notifier: Fetched full workout details: ${workout.title}");
      } catch (e) {
        print("Notifier: Error fetching full workout details: $e");
        throw Exception("Error fetching workout details: $e");
      }
    }

    try {
      final now = DateTime.now();
      final completedAt = DateTime(
        scheduledWorkout.scheduledDate.year,
        scheduledWorkout.scheduledDate.month,
        scheduledWorkout.scheduledDate.day,
        now.hour,
        now.minute,
        now.second,
      );
      final durationMinutes = workout.durationMinutes;
      final startedAt = completedAt.subtract(
        Duration(minutes: durationMinutes),
      );

      final newLog = WorkoutLog(
        id: const Uuid().v4(),
        userId: _userId,
        workoutId: workout.id,
        startedAt: startedAt,
        completedAt: completedAt,
        durationMinutes: durationMinutes,
        caloriesBurned: workout.estimatedCaloriesBurn,
        exercisesCompleted: const [],
        userFeedback: const UserFeedback(rating: 3),
        isShared: false,
        privacy: 'private',
        isOfflineCreated: false,
        syncStatus: 'synced',
        workoutCategory: workout.category.name,
        workoutName: workout.title,
        targetAreas: workout.tags,
      );

      await _workoutService.logCompletedWorkout(newLog);
      await _statsService.updateStatsFromWorkoutLog(
        newLog,
      ); // Use injected service

      final String? planId = await _ensureAndGetActivePlanId();
      if (planId == null) {
        throw Exception("Could not find active plan to mark workout complete.");
      }
      await _planningRepository.markWorkoutCompleted(
        planId,
        scheduledWorkout.id,
        completedAt: completedAt,
      );

      print(
        "Notifier: Successfully marked item ${scheduledWorkout.id} complete and updated stats.",
      );

      print("Notifier: Invalidating stats providers after marking complete...");
      _ref.invalidate(workoutStatsProvider(_userId)); // For Home Screen Card
      _ref.invalidate(userWorkoutStatsProvider(_userId)); // Detailed stats
      _ref.invalidate(userWorkoutStreakProvider(_userId)); // Streak
      // Optionally invalidate frequency/progress if they might be affected
      // _ref.invalidate(workoutFrequencyDataProvider((userId: _userId, days: 90)));
      print("Notifier: Stats providers invalidated.");

      if (state is AsyncData<List<PlannerItem>>) {
        final currentItems = List<PlannerItem>.from(state.value!);
        final itemIndex = currentItems.indexWhere(
          (item) =>
              item is PlannedWorkoutItem && item.id == scheduledWorkout.id,
        );
        if (itemIndex != -1) {
          currentItems[itemIndex] = PlannedWorkoutItem(
            scheduledWorkout.copyWith(
              isCompleted: true,
              completedAt: completedAt,
            ),
          );
          currentItems.sort((a, b) => a.itemDate.compareTo(b.itemDate));
          if (mounted) {
            state = AsyncValue.data(currentItems);
            print(
              "Notifier: Optimistically updated item ${scheduledWorkout.id} to completed in local state.",
            );
          }
        } else {
          print(
            "Notifier: Warning - Could not find item ${scheduledWorkout.id} in local state for optimistic update after completion.",
          );
          // Optionally add just the log if the scheduled item wasn't found
          if (!currentItems.any(
            (i) => i is LoggedWorkoutItem && i.id == newLog.id,
          )) {
            currentItems.add(LoggedWorkoutItem(newLog));
            currentItems.sort((a, b) => a.itemDate.compareTo(b.itemDate));
            if (mounted) {
              state = AsyncValue.data(currentItems);
            }
          }
        }
      }
    } catch (e) {
      print(
        "Notifier: Error during mark complete process for ${scheduledWorkout.id}: $e",
      );
      throw Exception("Failed to mark workout complete: $e");
    }
  }

  Future<void> deletePlannerItem(PlannerItem itemToDelete) async {
    // Store current items before backend call
    List<PlannerItem>? previousItems;
    if (state is AsyncData<List<PlannerItem>>) {
      previousItems = List.from(state.value!);
    }

    // --- Optimistic UI removal (optional but improves UX) ---
    if (previousItems != null) {
      final itemIndex = previousItems.indexWhere(
        (item) => item.id == itemToDelete.id,
      );
      if (itemIndex != -1) {
        previousItems.removeAt(itemIndex);
        if (mounted) {
          state = AsyncValue.data(
            List.from(previousItems),
          ); // Show removed state immediately
          print(
            "Notifier: Optimistically removed item ${itemToDelete.id} from local state.",
          );
        }
      }
    }
    // --- End Optimistic Removal ---

    // Perform actual backend deletion
    if (itemToDelete is PlannedWorkoutItem) {
      final String? planId = await _ensureAndGetActivePlanId();
      if (planId == null) {
        throw Exception("Failed to find plan context...");
      }
      try {
        await _planningRepository.deleteScheduledWorkout(
          planId,
          itemToDelete.scheduledWorkout.id,
        );
        print(
          "Notifier: Deleted PlannedWorkoutItem ${itemToDelete.id} from backend.",
        );
        // No need to manually update state again if optimistic removal was done
      } catch (e) {
        print("Notifier: Error deleting planned item ${itemToDelete.id}: $e");
        // --- Revert Optimistic Removal on Error ---
        if (previousItems != null && mounted) {
          // If deletion failed, restore the previous state
          state = AsyncValue.data(previousItems);
          print(
            "Notifier: Reverted optimistic removal for ${itemToDelete.id} due to error.",
          );
        }
        // --- End Revert ---
        throw e;
      }
    } else {
      // Revert state if optimistic removal was done for an unsupported type
      if (previousItems != null && mounted) {
        state = AsyncValue.data(previousItems);
      }
      throw UnimplementedError("Deleting logged workouts is not supported.");
    }
  }

  Future<Workout?> _fetchWorkoutDetailsIfNeededInternal(
    ScheduledWorkout scheduledWorkout,
  ) async {
    Workout? workout = scheduledWorkout.workout;
    if (workout == null || workout.exercises.isEmpty) {
      try {
        workout = await _workoutService.getWorkoutById(
          scheduledWorkout.workoutId,
        );
      } catch (e) {
        print("Notifier internal fetch error: $e");
        return null;
      }
    }
    return workout;
  }
}

final plannerItemsNotifierProvider = StateNotifierProvider.family<
  PlannerItemsNotifier,
  AsyncValue<List<PlannerItem>>,
  String
>((ref, userId) {
  final planningRepository = ref.watch(workoutPlanningRepositoryProvider);
  final workoutService = ref.watch(workoutServiceProvider);
  final statsService = ref.watch(workoutStatsServiceProvider);
  // Pass the ref itself to the notifier so it can invalidate other providers
  return PlannerItemsNotifier(
    planningRepository,
    workoutService,
    statsService,
    userId,
    ref,
  );
});
