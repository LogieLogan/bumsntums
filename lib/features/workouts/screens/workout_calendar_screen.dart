// lib/features/workouts/screens/workout_calendar_screen.dart
import 'dart:math';

import 'package:bums_n_tums/features/workouts/screens/workout_plan_editor_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_scheduling_screen.dart';
import 'package:bums_n_tums/features/workouts/widgets/calendar/recurring_workout_dialog.dart';
import 'package:bums_n_tums/features/workouts/widgets/calendar/workout_event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_log.dart';
import '../models/workout_plan.dart';
import '../providers/workout_calendar_provider.dart';
import '../providers/workout_planning_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/providers/analytics_provider.dart';
import 'workout_detail_screen.dart';
import 'workout_analytics_screen.dart';
import '../models/plan_color.dart';
import '../widgets/plan_badge.dart';
import '../services/smart_plan_detector.dart';
import '../widgets/smart_plan_suggestion_card.dart';

class WorkoutCalendarScreen extends ConsumerStatefulWidget {
  final String userId;

  const WorkoutCalendarScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  ConsumerState<WorkoutCalendarScreen> createState() =>
      _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends ConsumerState<WorkoutCalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late TabController _tabController;
  bool _hasLoggedInitialBuild = false;
  List<PatternSuggestion> _patternSuggestions = [];
  bool _showPatternSuggestions = true;

  void _checkForPatterns() {
    final activePlanAsync = ref.read(activeWorkoutPlanProvider(widget.userId));

    activePlanAsync.whenData((plan) {
      if (plan != null && _showPatternSuggestions) {
        final detector = SmartPlanDetector();
        final newSuggestions = detector.detectPatterns(plan.scheduledWorkouts);

        if (newSuggestions.isNotEmpty) {
          setState(() {
            _patternSuggestions = newSuggestions;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Log screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(analyticsServiceProvider)
          .logScreenView(screenName: 'workout_calendar');

      // Update calendar state with initial values
      ref.read(calendarStateProvider.notifier).selectDate(_selectedDay);
      ref.read(calendarStateProvider.notifier).changeFocusedMonth(_focusedDay);

      // Check for patterns after loading
      _checkForPatterns();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 1, 1);
    final endDate = DateTime(now.year, now.month + 2, 0);

    // Fetch calendar data
    final calendarEventsAsync = ref.watch(
      combinedCalendarEventsProvider((
        userId: widget.userId,
        startDate: startDate,
        endDate: endDate,
      )),
    );

    // Fetch rest day recommendations
    final restDaysAsync = ref.watch(
      restDayRecommendationsProvider(widget.userId),
    );

    // Fetch active workout plan
    final activePlanAsync = ref.watch(activeWorkoutPlanProvider(widget.userId));

    // Watch calendar state
    final calendarState = ref.watch(calendarStateProvider);

    if (!_hasLoggedInitialBuild) {
      print('Building calendar with selected day: ${_selectedDay.toString()}');
      _hasLoggedInitialBuild = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout Calendar', style: AppTextStyles.h2),
        centerTitle: true,
        backgroundColor: AppColors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          WorkoutAnalyticsScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Calendar'), Tab(text: 'Plans')],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Calendar Tab - For viewing and managing individual workout sessions
          calendarEventsAsync.when(
            data: (events) {
              // Store events in provider for drag-and-drop operations
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(calendarStateProvider.notifier).updateEvents(events);

                // Check for workout patterns after loading events
                if (_showPatternSuggestions) {
                  activePlanAsync.whenData((plan) {
                    if (plan != null) {
                      final detector = SmartPlanDetector();
                      final newSuggestions = detector.detectPatterns(
                        plan.scheduledWorkouts,
                      );

                      if (newSuggestions.isNotEmpty && mounted) {
                        setState(() {
                          _patternSuggestions = newSuggestions;
                        });
                      }
                    }
                  });
                }
              });

              return Builder(
                builder: (context) {
                  // Combine the rest day recommendations with events for display
                  final Map<DateTime, List<dynamic>> combinedEvents = {
                    ...events,
                  };

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
                      // This will be handled differently in the event builder
                      combinedEvents[key]!.add('REST_DAY');
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref
                          .read(calendarStateProvider.notifier)
                          .updateHighlightedDates(restDays);
                    });
                  });

                  return Stack(
                    children: [
                      _buildCalendarTab(combinedEvents, calendarState),

                      // Show pattern suggestion if available
                      if (_patternSuggestions.isNotEmpty)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: SmartPlanSuggestionCard(
                            suggestion: _patternSuggestions.first,
                            onCreatePlan:
                                () => _createPlanFromSuggestion(
                                  _patternSuggestions.first,
                                ),
                            onDismiss: () {
                              setState(() {
                                _patternSuggestions.removeAt(0);
                                if (_patternSuggestions.isEmpty) {
                                  _showPatternSuggestions = false;
                                }
                              });
                            },
                          ),
                        ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: LoadingIndicator()),
            error: (error, stackTrace) {
              print('Error loading calendar data: $error');
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
                        final _ =  ref.refresh(
                          combinedCalendarEventsProvider((
                            userId: widget.userId,
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
          ),

          // Plans Tab - For creating and managing workout plans spanning multiple days
          activePlanAsync.when(
            data:
                (plan) => SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Workout Plans', style: AppTextStyles.h3),
                        const SizedBox(height: 8),
                        Text(
                          'Create structured workout programs that span multiple days or weeks',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                        ),
                        const SizedBox(height: 24),

                        plan != null
                            ?
                            // If there's a plan, use the existing method but make it more compact
                            _buildCompactPlanView(plan)
                            :
                            // If no plan, show the empty state
                            _buildNoPlanView(),

                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          onPressed: _createNewWorkoutPlan,
                          icon: const Icon(Icons.add),
                          label: Text(
                            plan != null
                                ? 'Create New Plan'
                                : 'Create Your First Plan',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.pink,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            loading: () => const Center(child: LoadingIndicator()),
            error:
                (error, stackTrace) =>
                    Center(child: Text('Error loading workout plan: $error')),
          ),
        ],
      ),
    );
  }

  void _createPlanFromSuggestion(PatternSuggestion suggestion) async {
    // Get relevant data from suggestion
    final workouts = suggestion.matchedWorkouts;
    if (workouts.isEmpty) return;

    // Generate a plan name based on pattern type
    String planName = 'My Workout Plan';
    String planDescription = '';

    if (suggestion.patternType == 'weekly') {
      final daysOfWeek = workouts.map((w) => w.scheduledDate.weekday).toSet();
      final dayNames = daysOfWeek.map((day) => _getDayName(day)).join(', ');
      planName = '$dayNames Workout Plan';
      planDescription = 'Workouts on $dayNames';
    } else if (suggestion.patternType == 'daily') {
      planName = 'Daily Workout Plan';
      planDescription = 'Workouts every day';
    } else if (suggestion.patternType == 'category-based') {
      // Get the common category if all workouts have the same category
      final categories =
          workouts
              .map((w) => w.workoutCategory)
              .where((c) => c != null)
              .toSet();

      if (categories.length == 1 && categories.first != null) {
        final categoryName = _getCategoryName(categories.first!);
        planName = '$categoryName Workout Plan';
        planDescription = 'Focus on $categoryName';
      }
    }

    // Show plan creation dialog with pre-filled info
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create Workout Plan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create a new plan based on your workout pattern:'),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: planName,
                  decoration: const InputDecoration(labelText: 'Plan Name'),
                  onChanged: (value) {
                    planName = value;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: planDescription,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                  onChanged: (value) {
                    planDescription = value;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create Plan'),
              ),
            ],
          ),
    );

    if (result == true) {
      // Create the new plan
      _createNewPlanWithWorkouts(planName, planDescription, workouts);
    }

    // Remove the suggestion
    setState(() {
      _patternSuggestions.remove(suggestion);
    });
  }

  Future<void> _createNewPlanWithWorkouts(
    String planName,
    String description,
    List<ScheduledWorkout> workouts,
  ) async {
    final uuid = const Uuid().v4();
    final now = DateTime.now();

    // Create start date based on earliest workout
    final earliestDate = workouts
        .map((w) => w.scheduledDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);

    // Create the plan
    final plan = WorkoutPlan(
      id: uuid,
      userId: widget.userId,
      name: planName,
      description: description,
      startDate: earliestDate,
      goal: 'Custom workout plan',
      scheduledWorkouts: workouts,
      createdAt: now,
      updatedAt: now,
      isActive: true,
      colorName:
          PlanColor
              .predefinedColors[now.millisecondsSinceEpoch %
                  PlanColor.predefinedColors.length]
              .name,
    );

    // Save the plan
    final success = await ref
        .read(workoutPlanActionsProvider.notifier)
        .savePlan(plan);

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout plan created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh data
      _refreshCalendarData();

      // Switch to the plan tab
      _tabController.animateTo(1);
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create workout plan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  String _getCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'bums':
        return 'Bums';
      case 'tums':
        return 'Tums';
      case 'fullbody':
        return 'Full Body';
      case 'cardio':
        return 'Cardio';
      case 'quickworkout':
        return 'Quick Workout';
      default:
        return category;
    }
  }

  Widget _buildCalendarTab(
    Map<DateTime, List<dynamic>> events,
    CalendarState calendarState,
  ) {
    return Stack(
      children: [
        // Main Calendar UI
        SingleChildScrollView(
          child: Column(
            children: [
              _buildCalendar(events, calendarState),
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
                  onPressed: _addWorkoutToSelectedDay,
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
              _buildDayEventsSection(
                events[DateTime(
                      _selectedDay.year,
                      _selectedDay.month,
                      _selectedDay.day,
                    )] ??
                    [],
              ),
            ],
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
                          'To: ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
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
            _rescheduleWorkout(workout, _selectedDay);
          },
        ),
      ],
    );
  }

  Widget _buildCalendar(
    Map<DateTime, List<dynamic>> events,
    CalendarState calendarState,
  ) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
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
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        ref.read(calendarStateProvider.notifier).selectDate(selectedDay);
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
        ref
            .read(calendarStateProvider.notifier)
            .changeViewMode(
              format == CalendarFormat.month
                  ? 'month'
                  : format == CalendarFormat.week
                  ? 'week'
                  : 'twoWeeks',
            );
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
        ref.read(calendarStateProvider.notifier).changeFocusedMonth(focusedDay);
      },
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
        min(workouts.length, 3), // Limit to 3 indicators
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
    return min(workouts.length + 1, 5);
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

  Widget _buildDayEventsSection(List<dynamic> events) {
    final filteredEvents = events.where((e) => e != 'REST_DAY').toList();

    // Check if this day is a recommended rest day
    final isRestDay = events.any((e) => e == 'REST_DAY');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with improved styling
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Workouts for ${_selectedDay.day}/${_selectedDay.month}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (filteredEvents.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filteredEvents.length} workout${filteredEvents.length != 1 ? 's' : ''}',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (isRestDay) _buildRestDayCard(),

          if (filteredEvents.isEmpty && !isRestDay)
            _buildEmptyDayCard()
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  return _buildEnhancedWorkoutCard(event);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedWorkoutCard(dynamic event) {
    if (event is WorkoutLog) {
      // Enhanced completed workout card
      return WorkoutEventCard(
        workout: event,
        isDraggable: false,
        showIntensity: true,
        showTargetAreas: true,
        onTap: () => _navigateToWorkoutDetail(event.workoutId),
      );
    } else if (event is ScheduledWorkout) {
      // Enhanced scheduled workout card
      return WorkoutEventCard(
        workout: event,
        showIntensity: true,
        showTargetAreas: true,
        onTap: () => _navigateToWorkoutDetail(event.workoutId),
        onComplete:
            event.isCompleted ? null : () => _markWorkoutAsCompleted(event),
        onMakeRecurring:
            event.isRecurring ? null : () => _makeWorkoutRecurring(event),
        onReschedule: (newDate) => _rescheduleWorkout(event, newDate),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRestDayCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.paleGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bedtime_outlined, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rest Day Recommended',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Recovery helps improve results and prevent injury',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Show recovery activities dialog
                _showRecoveryActivitiesDialog();
              },
              icon: const Icon(Icons.healing),
              label: const Text('View Recovery Activities'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecoveryActivitiesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recovery Activities', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                'Try these activities to enhance your recovery',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.mediumGrey,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecoveryActivity(
                'Light stretching',
                '10-15 minutes of gentle stretches',
                Icons.self_improvement,
              ),
              _buildRecoveryActivity(
                'Hydration',
                'Drink plenty of water throughout the day',
                Icons.water_drop,
              ),
              _buildRecoveryActivity(
                'Sleep',
                'Aim for 7-9 hours of quality sleep',
                Icons.bedtime,
              ),
              _buildRecoveryActivity(
                'Walking',
                '20-30 minutes of easy walking',
                Icons.directions_walk,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecoveryActivity(
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(description, style: AppTextStyles.small),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayCard() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No workouts scheduled',
              style: AppTextStyles.body.copyWith(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addWorkoutToSelectedDay,
              icon: const Icon(Icons.add),
              label: const Text('Schedule Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToWorkoutDetail(String workoutId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailScreen(workoutId: workoutId),
      ),
    );
  }

  void _markWorkoutAsCompleted(ScheduledWorkout scheduled) {
    // Get the active plan ID from the provider
    final activePlanAsync = ref.read(activeWorkoutPlanProvider(widget.userId));

    activePlanAsync.whenData((plan) {
      if (plan != null) {
        // Use the workout planning provider to mark as completed
        ref
            .read(workoutPlanActionsProvider.notifier)
            .markWorkoutCompleted(
              widget.userId,
              plan.id,
              scheduled.workoutId,
              DateTime.now(),
            )
            .then((success) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Workout marked as completed'),
                    backgroundColor: Colors.green,
                  ),
                );

                // Refresh the data
                _refreshCalendarData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to mark workout as completed'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
      }
    });
  }

  void _makeWorkoutRecurring(ScheduledWorkout scheduled) {
    showDialog(
      context: context,
      builder:
          (context) => RecurringWorkoutDialog(
            workoutTitle: scheduled.title,
            initialDate: scheduled.scheduledDate,
          ),
    ).then((settings) {
      if (settings != null && settings is RecurringWorkoutSettings) {
        // Get the active plan ID
        final activePlanAsync = ref.read(
          activeWorkoutPlanProvider(widget.userId),
        );

        activePlanAsync.whenData((plan) {
          if (plan != null) {
            // Use the new calendar provider
            ref
                .read(calendarStateProvider.notifier)
                .setRecurringWorkout(
                  userId: widget.userId,
                  planId: plan.id,
                  workoutId: scheduled.workoutId,
                  startDate: scheduled.scheduledDate,
                  recurrencePattern: settings.patternName,
                  occurrences: settings.occurrences,
                )
                .then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Workout set to repeat ${settings.patternName} for ${settings.occurrences} occurrences',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Refresh the data
                    _refreshCalendarData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to set recurring workout'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
          }
        });
      }
    });
  }

  void _rescheduleWorkout(ScheduledWorkout workout, DateTime newDate) {
    // Get the active plan ID
    final activePlanAsync = ref.read(activeWorkoutPlanProvider(widget.userId));

    activePlanAsync.whenData((plan) {
      if (plan != null) {
        // Show confirmation dialog for recurring workouts
        if (workout.isRecurring) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Reschedule Workout'),
                  content: const Text(
                    'This is a recurring workout. Do you want to reschedule just this occurrence or all future occurrences?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop('single'),
                      child: const Text('Just This One'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop('all'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pink,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('All Future Occurrences'),
                    ),
                  ],
                ),
          ).then((result) {
            if (result != null) {
              final applyToSeries = result == 'all';

              // Use the new calendar provider function
              ref
                  .read(calendarStateProvider.notifier)
                  .rescheduleWorkout(
                    userId: widget.userId,
                    planId: plan.id,
                    workoutId: workout.workoutId,
                    oldDate: workout.scheduledDate,
                    newDate: newDate,
                    applyToSeries: applyToSeries,
                  )
                  .then((success) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Workout rescheduled to ${newDate.day}/${newDate.month}/${newDate.year}',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Refresh the data
                      _refreshCalendarData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to reschedule workout'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  });
            }
          });
        } else {
          // For non-recurring workouts, just reschedule
          ref
              .read(calendarStateProvider.notifier)
              .rescheduleWorkout(
                userId: widget.userId,
                planId: plan.id,
                workoutId: workout.workoutId,
                oldDate: workout.scheduledDate,
                newDate: newDate,
                applyToSeries: false,
              )
              .then((success) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Workout rescheduled to ${newDate.day}/${newDate.month}/${newDate.year}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh the data
                  _refreshCalendarData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to reschedule workout'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
        }
      }
    });
  }

  void _refreshCalendarData() {
    final now = DateTime.now();
    final _ =  ref.refresh(
      combinedCalendarEventsProvider((
        userId: widget.userId,
        startDate: DateTime(now.year, now.month - 1, 1),
        endDate: DateTime(now.year, now.month + 2, 0),
      )),
    );
    final _ =  ref.refresh(activeWorkoutPlanProvider(widget.userId));
    final _ =  ref.refresh(restDayRecommendationsProvider(widget.userId));
  }

  Future<String?> _createDefaultPlan() async {
    final now = DateTime.now();
    final planId = const Uuid().v4();

    // Create a plan with a more descriptive name than "My Workout Plan"
    final plan = WorkoutPlan(
      id: planId,
      userId: widget.userId,
      name: '${_getMonthName(now.month)} Training Plan',
      description: 'Automatically created workout plan',
      startDate: now,
      goal: 'Stay fit and healthy',
      scheduledWorkouts: [],
      createdAt: now,
      updatedAt: now,
      colorName:
          PlanColor
              .predefinedColors[now.millisecondsSinceEpoch %
                  PlanColor.predefinedColors.length]
              .name,
    );

    final success = await ref
        .read(workoutPlanActionsProvider.notifier)
        .createWorkoutPlan(plan);

    return success;
  }

  // Helper to get month name
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  void _addWorkoutToSelectedDay() async {
    // Log analytics
    ref
        .read(analyticsServiceProvider)
        .logEvent(
          name: 'schedule_workout_initiated',
          parameters: {'date': _selectedDay.toIso8601String()},
        );

    // Check for active plan
    final activePlanAsync = await ref.read(
      activeWorkoutPlanProvider(widget.userId).future,
    );

    if (activePlanAsync == null) {
      // Create a default plan automatically if none exists
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Create Workout Plan'),
              content: const Text(
                'You need a workout plan to schedule workouts. Would you like to create one now?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final planId = await _createDefaultPlan();
                    if (planId != null) {
                      // Refresh the data
                      _refreshCalendarData();

                      // Navigate to workout scheduling
                      _navigateToWorkoutSelection(planId);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Plan'),
                ),
              ],
            ),
      );
    } else {
      // Use the existing active plan
      _navigateToWorkoutSelection(activePlanAsync.id);
    }
  }

  void _navigateToWorkoutSelection(String planId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WorkoutSchedulingScreen(
              selectedDate: _selectedDay,
              userId: widget.userId,
              planId: planId,
            ),
      ),
    );

    // If workouts were scheduled, refresh the calendar
    if (result == true) {
      _refreshCalendarData();
    }
  }

  Widget _buildCompactPlanView(WorkoutPlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: plan.color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Plan badge with color
                PlanBadge(plan: plan),
                const Spacer(),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editWorkoutPlan(plan),
                  tooltip: 'Edit Plan',
                ),
              ],
            ),

            if (plan.description != null && plan.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                plan.description!,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.mediumGrey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Plan details
            Row(
              children: [
                _buildPlanStat(
                  icon: Icons.calendar_today,
                  label: 'Start Date',
                  value: '${plan.startDate.day}/${plan.startDate.month}',
                  color: plan.color,
                ),
                const SizedBox(width: 16),
                _buildPlanStat(
                  icon: Icons.fitness_center,
                  label: 'Workouts',
                  value: plan.scheduledWorkouts.length.toString(),
                  color: plan.color,
                ),
                const SizedBox(width: 16),
                _buildPlanStat(
                  icon: Icons.flag,
                  label: 'Goal',
                  value: plan.goal.split(' ').first,
                  color: plan.color,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Body focus distribution
            _buildBodyFocusDistribution(plan),

            const SizedBox(height: 16),

            // View workouts button
            OutlinedButton.icon(
              onPressed: () {
                // Show scheduled workouts in a dialog
                _showPlanWorkoutsDialog(context, plan);
              },
              icon: const Icon(Icons.visibility),
              label: const Text('View Scheduled Workouts'),
              style: OutlinedButton.styleFrom(
                foregroundColor: plan.color,
                side: BorderSide(color: plan.color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyFocusDistribution(WorkoutPlan plan) {
    // Extract distribution from plan or calculate if not available
    Map<String, int> distribution = Map<String, int>.from(
      plan.bodyFocusDistribution,
    );

    if (distribution.isEmpty) {
      // Calculate distribution if not available in plan
      distribution = _calculateBodyFocusDistribution(plan);
    }

    // If still empty, return nothing
    if (distribution.isEmpty) return const SizedBox.shrink();

    // Calculate total workouts
    final totalWorkouts = plan.scheduledWorkouts.length;
    if (totalWorkouts == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Body Focus',
          style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Focus areas bars
        if (distribution.containsKey('bums'))
          _buildFocusBar(
            'Bums',
            distribution['bums']! / totalWorkouts,
            AppColors.salmon,
          ),
        if (distribution.containsKey('tums'))
          _buildFocusBar(
            'Tums',
            distribution['tums']! / totalWorkouts,
            AppColors.popCoral,
          ),
        if (distribution.containsKey('fullBody'))
          _buildFocusBar(
            'Full Body',
            distribution['fullBody']! / totalWorkouts,
            AppColors.popBlue,
          ),
        if (distribution.containsKey('cardio'))
          _buildFocusBar(
            'Cardio',
            distribution['cardio']! / totalWorkouts,
            AppColors.popGreen,
          ),
        if (distribution.containsKey('quickWorkout'))
          _buildFocusBar(
            'Quick',
            distribution['quickWorkout']! / totalWorkouts,
            AppColors.popYellow,
          ),
      ],
    );
  }

  Map<String, int> _calculateBodyFocusDistribution(WorkoutPlan plan) {
    Map<String, int> distribution = {};

    for (final workout in plan.scheduledWorkouts) {
      final category = workout.workoutCategory;
      if (category != null) {
        distribution[category] = (distribution[category] ?? 0) + 1;
      }
    }

    return distribution;
  }

  Widget _buildFocusBar(String label, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(percentage * 100).round()}%',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: percentage,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.mediumGrey),
          ),
        ],
      ),
    );
  }

  void _showPlanWorkoutsDialog(BuildContext context, WorkoutPlan plan) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${plan.name} Workouts', style: AppTextStyles.h3),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  plan.scheduledWorkouts.isEmpty
                      ? const Center(child: Text('No workouts scheduled yet'))
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: plan.scheduledWorkouts.length,
                        itemBuilder: (context, index) {
                          final workout = plan.scheduledWorkouts[index];
                          final date = workout.scheduledDate;

                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: plan.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                color: plan.color,
                              ),
                            ),
                            title: Text(workout.title),
                            subtitle: Text(
                              '${date.day}/${date.month} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                              style: AppTextStyles.small,
                            ),
                            trailing:
                                workout.isCompleted
                                    ? Icon(
                                      Icons.check_circle,
                                      color: AppColors.popGreen,
                                    )
                                    : null,
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildNoPlanView() {
    // Use your existing implementation
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No active workout plan',
            style: AppTextStyles.h3.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a workout plan',
            style: AppTextStyles.body.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _createNewWorkoutPlan() {
    // Use your existing implementation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutPlanEditorScreen(userId: widget.userId),
      ),
    ).then((_) {
      // Refresh the data when returning from the editor
      _refreshCalendarData();
    });
  }

  void _editWorkoutPlan(WorkoutPlan plan) {
    // Use your existing implementation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => WorkoutPlanEditorScreen(
              userId: widget.userId,
              existingPlan: plan,
            ),
      ),
    ).then((_) {
      // Refresh the data when returning from the editor
      _refreshCalendarData();
    });
  }
}
