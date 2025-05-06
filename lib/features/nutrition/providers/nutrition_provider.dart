// lib/features/nutrition/providers/nutrition_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/food_log_entry.dart';
import '../repositories/nutrition_repository.dart';
import '../models/estimated_goals.dart'; // Import goal model
import '../services/nutrition_goal_service.dart'; // Import goal service
import '../../auth/providers/user_provider.dart'; // Import user profile provider
import '../../auth/models/user_profile.dart'; // Import UserProfile model

// --- State Class (already updated) ---
class NutritionDiaryState {
  final DateTime selectedDate;
  final AsyncValue<List<FoodLogEntry>> logEntriesState;
  final AsyncValue<EstimatedGoals> estimatedGoalsState;

  const NutritionDiaryState({
    required this.selectedDate,
    this.logEntriesState = const AsyncValue.loading(),
    this.estimatedGoalsState = const AsyncValue.loading(),
  });

  NutritionDiaryState copyWith({
    DateTime? selectedDate,
    AsyncValue<List<FoodLogEntry>>? logEntriesState,
    AsyncValue<EstimatedGoals>? estimatedGoalsState,
  }) {
    return NutritionDiaryState(
      selectedDate: selectedDate ?? this.selectedDate,
      logEntriesState: logEntriesState ?? this.logEntriesState,
      estimatedGoalsState: estimatedGoalsState ?? this.estimatedGoalsState,
    );
  }
}


// --- Updated StateNotifier ---
class NutritionDiaryNotifier extends StateNotifier<NutritionDiaryState> {
  final String _userId;
  final NutritionRepository _repository;
  final NutritionGoalService _goalService; // Add goal service
  final Ref _ref; // Keep ref to watch other providers

  NutritionDiaryNotifier(
    this._userId,
    this._repository,
    this._goalService, // Inject goal service
    this._ref,        // Inject ref
  ) : super(NutritionDiaryState(selectedDate: _getToday())) {
    // Initial fetch for logs and goals
    _initialize();

     // Listen for changes in the user profile to recalculate goals
     _ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (previous, next) {
       if (kDebugMode) { print(">>> NutritionDiaryNotifier: UserProfile changed, recalculating goals..."); }
       _calculateEstimatedGoals(); // Recalculate when profile changes
     });
  }

  // Initialization method called from constructor
  void _initialize() {
     _fetchLogEntries(state.selectedDate);
     _calculateEstimatedGoals();
  }

  // Helper to calculate goals using the service
  Future<void> _calculateEstimatedGoals() async {
    // Set goals state to loading
    state = state.copyWith(estimatedGoalsState: const AsyncValue.loading());
    try {
      // Read the latest user profile state
      // Note: Watching inside a method is generally discouraged, but here it's
      // for a one-time read triggered by init or profile change listener.
      // If this becomes complex, consider passing profile data differently.
      final userProfile = await _ref.read(userProfileProvider.future);

      // Estimate goals using the service
      final goals = _goalService.estimateDailyGoals(userProfile);

      if (mounted) {
        state = state.copyWith(estimatedGoalsState: AsyncValue.data(goals));
        if (kDebugMode) { print(">>> NutritionDiaryNotifier: Estimated goals updated. Met requirements: ${goals.areMet}"); }
      }
    } catch (e, stack) {
       if (kDebugMode) { print(">>> NutritionDiaryNotifier: Error estimating goals: $e"); }
       if (mounted) {
         state = state.copyWith(estimatedGoalsState: AsyncValue.error(e, stack));
       }
    }
  }

  // --- _fetchLogEntries, changeDate, addLogEntry, deleteLogEntry remain the same ---
  static DateTime _getToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _fetchLogEntries(DateTime date) async {
    if (kDebugMode) { print(">>> _fetchLogEntries START for $date. Current state status: ${state.logEntriesState.runtimeType}"); }
    state = state.copyWith(logEntriesState: const AsyncValue.loading());
     if (kDebugMode) { print(">>> _fetchLogEntries SET LOADING for $date."); }
    try {
      final entries = await _repository.getFoodLogEntriesForDay(_userId, date);
      if (kDebugMode) { print(">>> _fetchLogEntries SUCCESS for $date. Fetched ${entries.length} entries."); }
      if (mounted) {
        if (state.selectedDate == date) {
          state = state.copyWith(logEntriesState: AsyncValue.data(entries));
           if (kDebugMode) { print(">>> _fetchLogEntries SET DATA for $date."); }
        } else {
           if (kDebugMode) { print(">>> _fetchLogEntries IGNORED data for $date (selected date is now ${state.selectedDate})."); }
        }
      } else {
           if (kDebugMode) { print(">>> _fetchLogEntries Notifier disposed before data could be set for $date."); }
      }
    } catch (e, stack) {
      if (kDebugMode) { print(">>> _fetchLogEntries ERROR for $date: $e"); }
      if (mounted) {
         if (state.selectedDate == date) {
             state = state.copyWith(logEntriesState: AsyncValue.error(e, stack));
             if (kDebugMode) { print(">>> _fetchLogEntries SET ERROR for $date."); }
         } else {
             if (kDebugMode) { print(">>> _fetchLogEntries IGNORED error for $date (selected date is now ${state.selectedDate})."); }
         }
      } else {
           if (kDebugMode) { print(">>> _fetchLogEntries Notifier disposed before error could be set for $date."); }
      }
    }
  }

  Future<void> changeDate(DateTime newDate) async {
    final normalizedDate = DateTime(newDate.year, newDate.month, newDate.day);
    if (normalizedDate == state.selectedDate) return;
    if (kDebugMode) { print(">>> changeDate START: Changing date to $normalizedDate"); }
    state = state.copyWith(selectedDate: normalizedDate);
    await _fetchLogEntries(normalizedDate); // Fetch logs for new date
     if (kDebugMode) { print(">>> changeDate END: Fetch triggered for $normalizedDate"); }
  }

   Future<void> addLogEntry(FoodLogEntry entry) async {
    final entryDate = DateTime(entry.loggedAt.year, entry.loggedAt.month, entry.loggedAt.day);
    bool belongsToCurrentDate = entryDate == state.selectedDate;
    List<FoodLogEntry>? previousEntries;
    if (belongsToCurrentDate && state.logEntriesState is AsyncData<List<FoodLogEntry>>) {
      previousEntries = List.from(state.logEntriesState.value!);
      final updatedEntries = List<FoodLogEntry>.from(previousEntries)..add(entry);
      updatedEntries.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
      state = state.copyWith(logEntriesState: AsyncValue.data(updatedEntries));
      if (kDebugMode) { print(">>> addLogEntry: Optimistically added entry ${entry.id}"); }
    }
    try {
       await _repository.addFoodLogEntry(entry);
       if (kDebugMode) { print(">>> addLogEntry: Backend add success for entry ${entry.id}"); }
    } catch (e) {
        if (kDebugMode) { print(">>> addLogEntry: Error adding log entry to backend: $e"); }
       if (belongsToCurrentDate && previousEntries != null && mounted) {
          state = state.copyWith(logEntriesState: AsyncValue.data(previousEntries));
          if (kDebugMode) { print(">>> addLogEntry: Reverted optimistic add for entry ${entry.id}"); }
       }
       rethrow;
    }
  }

   Future<void> deleteLogEntry(String entryId) async {
     List<FoodLogEntry>? previousEntries;
     bool belongsToCurrentDate = false;
     if (state.logEntriesState is AsyncData<List<FoodLogEntry>>) {
        previousEntries = List.from(state.logEntriesState.value!);
        final entryIndex = previousEntries.indexWhere((e) => e.id == entryId);
        if (entryIndex != -1) {
           final entryDate = DateTime(previousEntries[entryIndex].loggedAt.year, previousEntries[entryIndex].loggedAt.month, previousEntries[entryIndex].loggedAt.day);
           belongsToCurrentDate = entryDate == state.selectedDate;
           if (belongsToCurrentDate) {
              previousEntries.removeAt(entryIndex);
              state = state.copyWith(logEntriesState: AsyncValue.data(List.from(previousEntries)));
               if (kDebugMode) { print(">>> deleteLogEntry: Optimistically removed entry $entryId"); }
           } else {
               previousEntries = null;
               if (kDebugMode) { print(">>> deleteLogEntry: Deleting entry $entryId which is not on the current date ${state.selectedDate}"); }
           }
        } else {
           previousEntries = null;
            if (kDebugMode) { print(">>> deleteLogEntry: Entry $entryId not found in current state for optimistic delete."); }
        }
     }
     try {
        await _repository.deleteFoodLogEntry(_userId, entryId);
        if (kDebugMode) { print(">>> deleteLogEntry: Backend delete success for entry $entryId"); }
     } catch (e) {
         if (kDebugMode) { print(">>> deleteLogEntry: Error deleting log entry from backend: $e"); }
        if (belongsToCurrentDate && previousEntries != null && mounted) {
           state = state.copyWith(logEntriesState: AsyncValue.data(previousEntries));
           if (kDebugMode) { print(">>> deleteLogEntry: Reverted optimistic delete for entry $entryId"); }
        }
        rethrow;
     }
   }
}


// --- Updated Provider ---
final nutritionDiaryProvider = StateNotifierProvider.autoDispose
    .family<NutritionDiaryNotifier, NutritionDiaryState, String>((ref, userId) {
  // Get dependencies
  final repository = ref.watch(nutritionRepositoryProvider);
  final goalService = ref.watch(nutritionGoalServiceProvider); // Get goal service

  // Create and return the notifier, passing ref
  return NutritionDiaryNotifier(userId, repository, goalService, ref);
});
// --- End Updated Provider ---