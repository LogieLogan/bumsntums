// lib/features/workouts/widgets/calendar/calendar_tab_view.dart
import 'package:bums_n_tums/features/workouts/widgets/calendar/calendar_view.dart';
import 'package:bums_n_tums/features/workouts/widgets/calendar/day_events_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/workout_plan.dart';
import '../../providers/workout_calendar_provider.dart';
import '../../services/smart_plan_detector.dart';
import '../../../../shared/components/indicators/loading_indicator.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/theme/text_styles.dart';
import '../smart_plan_suggestion_card.dart';

class CalendarTabView extends ConsumerWidget {
  final String userId;
  final DateTime selectedDay;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;
  final Function(ScheduledWorkout, DateTime) onRescheduleWorkout;
  final VoidCallback onAddWorkout;
  final Function(String) onNavigateToWorkoutDetail;
  final Function(ScheduledWorkout) onMarkWorkoutAsCompleted;
  final Function(ScheduledWorkout) onMakeWorkoutRecurring;
  final List<PatternSuggestion> patternSuggestions;
  final Function(PatternSuggestion) onCreatePlanFromSuggestion;
  final Function(PatternSuggestion) onDismissSuggestion;

  const CalendarTabView({
    Key? key,
    required this.userId,
    required this.selectedDay,
    required this.focusedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    required this.onRescheduleWorkout,
    required this.onAddWorkout,
    required this.onNavigateToWorkoutDetail,
    required this.onMarkWorkoutAsCompleted,
    required this.onMakeWorkoutRecurring,
    required this.patternSuggestions,
    required this.onCreatePlanFromSuggestion,
    required this.onDismissSuggestion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 1, 1);
    final endDate = DateTime(now.year, now.month + 2, 0);

    // Fetch calendar data
    final calendarEventsAsync = ref.watch(
      combinedCalendarEventsProvider((
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    // Fetch rest day recommendations
    final restDaysAsync = ref.watch(
      restDayRecommendationsProvider(userId),
    );

    return calendarEventsAsync.when(
      data: (events) {
        // Store events in provider for drag-and-drop operations
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(calendarStateProvider.notifier).updateEvents(events);
          
          // Update rest days in state
          restDaysAsync.whenData((restDays) {
            ref.read(calendarStateProvider.notifier).updateHighlightedDates(restDays);
          });
        });

        // Create a combined events map that includes rest days
        final Map<DateTime, List<dynamic>> combinedEvents = Map.from(events);
        
        // Add rest day indicators to the events map
        restDaysAsync.whenData((restDays) {
          for (final restDay in restDays) {
            final key = DateTime(
              restDay.year,
              restDay.month,
              restDay.day,
            );
            if (!combinedEvents.containsKey(key)) {
              combinedEvents[key] = [];
            }
            // We'll use a string marker to indicate a rest day
            combinedEvents[key]!.add('REST_DAY');
          }
        });

        return _buildCalendarTabContent(
          context, 
          combinedEvents,
          restDaysAsync,
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Could not load your workout calendar',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Refresh data
                  final _ = ref.refresh(
                    combinedCalendarEventsProvider((
                      userId: userId,
                      startDate: DateTime(
                        DateTime.now().year,
                        DateTime.now().month - 1,
                        1,
                      ),
                      endDate: DateTime(
                        DateTime.now().year,
                        DateTime.now().month + 2,
                        0,
                      ),
                    )),
                  );
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarTabContent(
    BuildContext context,
    Map<DateTime, List<dynamic>> events,
    AsyncValue<List<DateTime>> restDaysAsync,
  ) {
    return Stack(
      children: [
        // Main Calendar UI
        SingleChildScrollView(
          child: Column(
            children: [
              // Calendar Component
              CalendarView(
                events: events,
                selectedDay: selectedDay,
                focusedDay: focusedDay,
                calendarFormat: calendarFormat,
                onDaySelected: onDaySelected,
                onFormatChanged: onFormatChanged,
                onPageChanged: onPageChanged,
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'View your scheduled workouts and track completed sessions',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  onPressed: onAddWorkout,
                  icon: const Icon(Icons.add),
                  label: const Text('Schedule Workout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Day Events Section
              DayEventsSection(
                events: events[DateTime(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day,
                )] ?? [],
                selectedDay: selectedDay,
                onNavigateToWorkoutDetail: onNavigateToWorkoutDetail,
                onMarkWorkoutAsCompleted: onMarkWorkoutAsCompleted,
                onMakeWorkoutRecurring: onMakeWorkoutRecurring,
                onRescheduleWorkout: onRescheduleWorkout,
                onAddWorkout: onAddWorkout,
              ),
            ],
          ),
        ),

        // Show pattern suggestion if available
        if (patternSuggestions.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: SmartPlanSuggestionCard(
              suggestion: patternSuggestions.first,
              onCreatePlan: () => onCreatePlanFromSuggestion(patternSuggestions.first),
              onDismiss: () => onDismissSuggestion(patternSuggestions.first),
            ),
          ),

        // Drag Target Overlay (only visible when dragging)
        DragTarget<ScheduledWorkout>(
          builder: (context, candidateData, rejectedData) {
            // This will show when dragging a workout
            return Visibility(
              visible: candidateData.isNotEmpty, // Only show when dragging
              child: Container(
                color: Colors.black.withOpacity(0.1),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Drop to reschedule',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'To: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          onAccept: (workout) {
            // Handle the rescheduling here
            onRescheduleWorkout(workout, selectedDay);
          },
        ),
      ],
    );
  }
}