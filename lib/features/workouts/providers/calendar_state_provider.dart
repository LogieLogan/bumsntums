// lib/features/workouts/providers/calendar_state_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/workout_planning_service.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/providers/analytics_provider.dart';
import 'workout_planning_provider.dart';

// State for calendar interactions (selected day, view mode, etc.)
class CalendarState {
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final String viewMode;
  final bool isEditing;
  final Map<DateTime, List<dynamic>> cachedEvents;
  final List<DateTime> highlightedDates;

  CalendarState({
    DateTime? selectedDate,
    DateTime? focusedMonth,
    this.viewMode = 'month',
    this.isEditing = false,
    this.cachedEvents = const {},
    this.highlightedDates = const [],
  }) : selectedDate = selectedDate ?? DateTime.now(),
       focusedMonth = focusedMonth ?? DateTime.now();

  CalendarState copyWith({
    DateTime? selectedDate,
    DateTime? focusedMonth,
    String? viewMode,
    bool? isEditing,
    Map<DateTime, List<dynamic>>? cachedEvents,
    List<DateTime>? highlightedDates,
  }) {
    return CalendarState(
      selectedDate: selectedDate ?? this.selectedDate,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      viewMode: viewMode ?? this.viewMode,
      isEditing: isEditing ?? this.isEditing,
      cachedEvents: cachedEvents ?? this.cachedEvents,
      highlightedDates: highlightedDates ?? this.highlightedDates,
    );
  }
}

// Notifier for calendar interactions
class CalendarStateNotifier extends StateNotifier<CalendarState> {
  final WorkoutPlanningService _planningService;
  final AnalyticsService _analytics;

  CalendarStateNotifier(this._planningService, this._analytics)
    : super(CalendarState());

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    _analytics.logEvent(
      name: 'calendar_date_selected',
      parameters: {'date': date.toIso8601String()},
    );
  }

  void changeViewMode(String mode) {
    if (['month', 'week', 'day'].contains(mode)) {
      state = state.copyWith(viewMode: mode);
      _analytics.logEvent(
        name: 'calendar_view_changed',
        parameters: {'mode': mode},
      );
    }
  }

  void changeFocusedMonth(DateTime month) {
    state = state.copyWith(focusedMonth: DateTime(month.year, month.month, 1));
  }

  void toggleEditMode() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  void updateEvents(Map<DateTime, List<dynamic>> events) {
    state = state.copyWith(cachedEvents: events);
  }

  void updateHighlightedDates(List<DateTime> dates) {
    state = state.copyWith(highlightedDates: dates);
  }
}

// Provider for calendar state
final calendarStateProvider =
    StateNotifierProvider<CalendarStateNotifier, CalendarState>((ref) {
      final planningService = ref.watch(workoutPlanningServiceProvider);
      final analytics = ref.watch(analyticsServiceProvider);
      return CalendarStateNotifier(planningService, analytics);
    });