// lib/features/workouts/screens/workout_scheduling_screen.dart
import 'package:bums_n_tums/features/workouts/screens/custom_workouts_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../widgets/workout_card.dart';
import '../providers/workout_provider.dart';
import '../providers/workout_calendar_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/providers/analytics_provider.dart';
import 'workout_browse_screen.dart';
import '../../ai/screens/ai_workout_screen.dart';
import '../models/workout_plan.dart';
import '../models/plan_color.dart';

// State provider for selected workouts
final selectedWorkoutsProvider = StateProvider<List<SelectedWorkoutItem>>(
  (ref) => [],
);

// Enum for time slots
enum TimeSlot { morning, lunch, evening }

// Class to hold workout with time slot
class SelectedWorkoutItem {
  final Workout workout;
  TimeSlot timeSlot;

  SelectedWorkoutItem({
    required this.workout,
    this.timeSlot = TimeSlot.morning,
  });
}

class WorkoutSchedulingScreen extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final String userId;
  final String planId;
  final WorkoutPlan? plan;

  const WorkoutSchedulingScreen({
    Key? key,
    required this.selectedDate,
    required this.userId,
    required this.planId,
    this.plan,
  }) : super(key: key);

  @override
  ConsumerState<WorkoutSchedulingScreen> createState() =>
      _WorkoutSchedulingScreenState();
}

class _WorkoutSchedulingScreenState
    extends ConsumerState<WorkoutSchedulingScreen> {
  @override
  void initState() {
    super.initState();
    // Clear any previously selected workouts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedWorkoutsProvider.notifier).state = [];

      // Track screen view
      ref
          .read(analyticsServiceProvider)
          .logScreenView(screenName: 'workout_scheduling');
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedWorkouts = ref.watch(selectedWorkoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Workouts', style: AppTextStyles.h2),
        backgroundColor: AppColors.pink,
        actions: [
          // Help icon
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.paleGrey,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.pink),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                      style: AppTextStyles.h3,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.plan != null) ...[
                  // Show plan badge
                  Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.plan!.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.plan!.color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: widget.plan!.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Adding to ${widget.plan!.name}',
                          style: AppTextStyles.small.copyWith(
                            color: widget.plan!.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Text(
                  'Select workouts to schedule for this day',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                ),
              ],
            ),
          ),

          // Tabs for browse, custom and AI
          Expanded(
            child: DefaultTabController(
              length: 2, // Changed from 3 to 2
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'Browse Workouts'),
                      Tab(text: 'My Workouts'),
                    ],
                    labelColor: AppColors.pink,
                    unselectedLabelColor: AppColors.mediumGrey,
                    indicatorColor: AppColors.pink,
                  ),
                  Expanded(
                    child: TabBarView(
                      physics: const ClampingScrollPhysics(),
                      children: [
                        // Browse Workouts Tab
                        _buildBrowseWorkoutsTab(),

                        // My Workouts Tab (Updated)
                        _buildMyWorkoutsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selected workouts list (only visible when there are selected workouts)
                  if (selectedWorkouts.isNotEmpty) ...[
                    Container(
                      constraints: BoxConstraints(maxHeight: 120),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.paleGrey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: selectedWorkouts.length,
                        separatorBuilder:
                            (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = selectedWorkouts[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                // Small workout image or icon
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.popCoral.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center,
                                    size: 16,
                                    color: AppColors.popCoral,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Workout title
                                Expanded(
                                  child: Text(
                                    item.workout.title,
                                    style: AppTextStyles.small.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Time slot dropdown
                                DropdownButton<TimeSlot>(
                                  value: item.timeSlot,
                                  isDense: true,
                                  underline: Container(height: 0),
                                  onChanged: (newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        final currentItems =
                                            List<SelectedWorkoutItem>.from(
                                              ref.read(
                                                selectedWorkoutsProvider,
                                              ),
                                            );
                                        currentItems[index].timeSlot = newValue;
                                        ref
                                            .read(
                                              selectedWorkoutsProvider.notifier,
                                            )
                                            .state = currentItems;
                                      });
                                    }
                                  },
                                  items: [
                                    DropdownMenuItem(
                                      value: TimeSlot.morning,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.wb_sunny,
                                            size: 12,
                                            color: AppColors.popYellow,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'AM',
                                            style: AppTextStyles.small,
                                          ),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: TimeSlot.lunch,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.restaurant,
                                            size: 12,
                                            color: AppColors.popBlue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Lunch',
                                            style: AppTextStyles.small,
                                          ),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: TimeSlot.evening,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.nightlight_round,
                                            size: 12,
                                            color: AppColors.darkGrey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'PM',
                                            style: AppTextStyles.small,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // Remove button
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    final currentItems =
                                        List<SelectedWorkoutItem>.from(
                                          ref.read(selectedWorkoutsProvider),
                                        );
                                    currentItems.removeAt(index);
                                    ref
                                        .read(selectedWorkoutsProvider.notifier)
                                        .state = currentItems;
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Schedule button
                  PrimaryButton(
                    text:
                        selectedWorkouts.isEmpty
                            ? 'SELECT WORKOUTS TO SCHEDULE'
                            : 'SCHEDULE ${selectedWorkouts.length} WORKOUT${selectedWorkouts.length != 1 ? 'S' : ''}',
                    onPressed:
                        selectedWorkouts.isEmpty
                            ? null
                            : _scheduleSelectedWorkouts,
                    isEnabled: selectedWorkouts.isNotEmpty,
                  ),

                  // Help text
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      selectedWorkouts.isEmpty
                          ? 'Tap workouts below to add them to your schedule'
                          : 'You can specify morning, lunch, or evening for each workout',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedWorkoutItem(SelectedWorkoutItem item, int index) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.paleGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Stack(
              children: [
                Image.network(
                  item.workout.imageUrl.isNotEmpty
                      ? item.workout.imageUrl
                      : 'https://placehold.co/140x70?text=Workout',
                  height: 70,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 70,
                      width: double.infinity,
                      color: AppColors.lightGrey,
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () {
                      final currentItems = List<SelectedWorkoutItem>.from(
                        ref.read(selectedWorkoutsProvider),
                      );
                      currentItems.removeAt(index);
                      ref.read(selectedWorkoutsProvider.notifier).state =
                          currentItems;
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Workout title
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Text(
              item.workout.title,
              style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Time slot dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: DropdownButton<TimeSlot>(
              value: item.timeSlot,
              isDense: true,
              isExpanded: true,
              underline: Container(height: 1, color: AppColors.lightGrey),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    final currentItems = List<SelectedWorkoutItem>.from(
                      ref.read(selectedWorkoutsProvider),
                    );
                    currentItems[index].timeSlot = newValue;
                    ref.read(selectedWorkoutsProvider.notifier).state =
                        currentItems;
                  });
                }
              },
              items: [
                DropdownMenuItem(
                  value: TimeSlot.morning,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wb_sunny,
                        size: 12,
                        color: AppColors.popYellow,
                      ),
                      const SizedBox(width: 4),
                      Text('Morning', style: AppTextStyles.small),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: TimeSlot.lunch,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.restaurant,
                        size: 12,
                        color: AppColors.popBlue,
                      ),
                      const SizedBox(width: 4),
                      Text('Lunch', style: AppTextStyles.small),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: TimeSlot.evening,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.nightlight_round,
                        size: 12,
                        color: AppColors.darkGrey,
                      ),
                      const SizedBox(width: 4),
                      Text('Evening', style: AppTextStyles.small),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseWorkoutsTab() {
    // Featured workouts section
    final featuredWorkoutsAsync = ref.watch(featuredWorkoutsProvider);

    // Use SingleChildScrollView to prevent overflow
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Featured Workouts', style: AppTextStyles.h3),
          ),

          featuredWorkoutsAsync.when(
            data: (workouts) {
              if (workouts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No featured workouts available.')),
                );
              }

              return ListView.builder(
                shrinkWrap: true, // Important
                physics:
                    const NeverScrollableScrollPhysics(), // Disable scrolling on this ListView
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return _buildSelectableWorkoutCard(workout);
                },
              );
            },
            loading: () => const Center(child: LoadingIndicator()),
            error:
                (error, stack) =>
                    Center(child: Text('Error loading workouts: $error')),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Quick Workouts', style: AppTextStyles.h3),
          ),

          // Quick workouts section
          SizedBox(
            height: 160,
            child: ref
                .watch(workoutsByCategoryProvider(WorkoutCategory.quickWorkout))
                .when(
                  data: (workouts) {
                    if (workouts.isEmpty) {
                      return const Center(
                        child: Text('No quick workouts available.'),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: workouts.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 280,
                          child: _buildSelectableWorkoutCard(
                            workouts[index],
                            isCompact: true,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: LoadingIndicator()),
                  error:
                      (error, stack) =>
                          Center(child: Text('Error loading workouts: $error')),
                ),
          ),

          const SizedBox(height: 24),

          // Browse all categories button
          Center(
            child: OutlinedButton.icon(
              onPressed: _browseAllWorkouts,
              icon: const Icon(Icons.search),
              label: const Text('Browse All Categories'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.pink,
                side: const BorderSide(color: AppColors.pink),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMyWorkoutsTab() {
    // Use the existing custom workouts provider to get user's workouts
    final customWorkoutsAsync = ref.watch(
      customWorkoutsStreamProvider(widget.userId),
    );

    return customWorkoutsAsync.when(
      data: (workouts) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Creation options at the top
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Create custom workout
                    Expanded(
                      child: _buildCreationOption(
                        icon: Icons.add_circle_outline,
                        title: 'Custom Workout',
                        subtitle: 'Build from scratch',
                        onTap: _createCustomWorkout,
                        color: AppColors.popTurquoise,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Create with AI
                    Expanded(
                      child: _buildCreationOption(
                        icon: Icons.smart_toy,
                        title: 'AI Workout',
                        subtitle: 'Let AI create for you',
                        onTap: _createAIWorkout,
                        color: AppColors.popCoral,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Saved workouts section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Your Saved Workouts', style: AppTextStyles.h3),
              ),

              // Display custom workouts or empty state
              workouts.isEmpty
                  ? _buildEmptyWorkoutsState()
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      return _buildWorkoutListItem(workout);
                    },
                  ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error:
          (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to load your workouts'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed:
                      () => ref.refresh(
                        customWorkoutsStreamProvider(widget.userId),
                      ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyWorkoutsState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.fitness_center,
              size: 48,
              color: AppColors.lightGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No saved workouts yet',
              style: AppTextStyles.body.copyWith(
                color: AppColors.mediumGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create custom workouts or generate with AI',
              style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutListItem(Workout workout) {
    final isSelected = ref
        .read(selectedWorkoutsProvider)
        .any((item) => item.workout.id == workout.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _toggleWorkoutSelection(workout),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Selection indicator
              isSelected
                  ? Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.pink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                  : Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.paleGrey,
                      shape: BoxShape.circle,
                    ),
                  ),
              const SizedBox(width: 12),

              // Workout icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      workout.isAiGenerated
                          ? AppColors.popCoral.withOpacity(0.2)
                          : AppColors.popTurquoise.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  workout.isAiGenerated
                      ? Icons.smart_toy
                      : Icons.fitness_center,
                  color:
                      workout.isAiGenerated
                          ? AppColors.popCoral
                          : AppColors.popTurquoise,
                ),
              ),
              const SizedBox(width: 12),

              // Workout details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 12,
                          color: AppColors.mediumGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${workout.durationMinutes} min',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.fitness_center,
                          size: 12,
                          color: AppColors.mediumGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${workout.exercises.length} exercises',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Type indicator
              if (workout.isAiGenerated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.popCoral.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.smart_toy,
                        size: 12,
                        color: AppColors.popCoral,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.popCoral,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build creation options
  Widget _buildCreationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Method to handle custom workout creation
  void _createCustomWorkout() {
    // Navigate to workout editor screen
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const WorkoutEditorScreen()),
        )
        .then((_) {
          // Refresh the custom workouts list
          ref.refresh(customWorkoutsStreamProvider(widget.userId));
        });
  }

  // Updated AI workout creation method
  void _createAIWorkout() {
    // Navigate to AI workout generation screen with flag
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AIWorkoutScreen(),
            // Pass argument to indicate we're in scheduling mode
            settings: const RouteSettings(arguments: true),
          ),
        )
        .then((workout) {
          if (workout != null && workout is Workout) {
            _toggleWorkoutSelection(workout);
          }
          // Refresh the custom workouts list either way
          ref.refresh(customWorkoutsStreamProvider(widget.userId));
        });
  }

  Widget _buildSelectableWorkoutCard(
    Workout workout, {
    bool isCompact = false,
  }) {
    // Check if this workout is already selected
    final selectedWorkouts = ref.read(selectedWorkoutsProvider);
    final isSelected = selectedWorkouts.any(
      (item) => item.workout.id == workout.id,
    );

    return Stack(
      children: [
        WorkoutCard(
          workout: workout,
          isCompact: isCompact,
          onTap: () {
            _toggleWorkoutSelection(workout);
          },
        ),
        if (isSelected)
          Positioned(
            top: 16,
            right: isCompact ? 12 : 24,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.pink,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.check, size: 16, color: Colors.white),
            ),
          ),
      ],
    );
  }

  void _toggleWorkoutSelection(Workout workout) {
    final currentItems = List<SelectedWorkoutItem>.from(
      ref.read(selectedWorkoutsProvider),
    );

    // Check if workout is already selected
    final existingIndex = currentItems.indexWhere(
      (item) => item.workout.id == workout.id,
    );

    if (existingIndex >= 0) {
      // Remove if already selected
      currentItems.removeAt(existingIndex);
    } else {
      // Add if not selected
      currentItems.add(SelectedWorkoutItem(workout: workout));
    }

    // Update state
    ref.read(selectedWorkoutsProvider.notifier).state = currentItems;

    // Give feedback
    if (existingIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${workout.title} added to selection'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.popGreen,
        ),
      );
    }
  }

  void _browseAllWorkouts() async {
    // Flag to indicate we're in selection mode
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkoutBrowseScreen(),
        // Pass arguments to indicate selection mode
        settings: const RouteSettings(arguments: {'selectionMode': true}),
      ),
    ).then((result) {
      // Check if result is a workout and add it to selections
      if (result != null && result is Workout) {
        _toggleWorkoutSelection(result);
      }
    });
  }

  void _scheduleSelectedWorkouts() async {
    final selectedWorkouts = ref.read(selectedWorkoutsProvider);

    if (selectedWorkouts.isEmpty) {
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingIndicator(),
                SizedBox(height: 16),
                Text('Scheduling workouts...'),
              ],
            ),
          ),
    );

    try {
      print(
        '🏋️ Scheduling ${selectedWorkouts.length} workouts for ${widget.selectedDate}',
      );
      print('🏋️ Using plan ID: ${widget.planId} for user: ${widget.userId}');

      // Schedule each workout
      bool allSuccessful = true;

      for (final item in selectedWorkouts) {
        // Calculate time based on time slot
        final DateTime scheduledTime;
        switch (item.timeSlot) {
          case TimeSlot.morning:
            scheduledTime = DateTime(
              widget.selectedDate.year,
              widget.selectedDate.month,
              widget.selectedDate.day,
              8, // 8 AM
              0,
            );
            break;
          case TimeSlot.lunch:
            scheduledTime = DateTime(
              widget.selectedDate.year,
              widget.selectedDate.month,
              widget.selectedDate.day,
              12, // 12 PM
              0,
            );
            break;
          case TimeSlot.evening:
            scheduledTime = DateTime(
              widget.selectedDate.year,
              widget.selectedDate.month,
              widget.selectedDate.day,
              18, // 6 PM
              0,
            );
            break;
        }

        print(
          '🏋️ Scheduling workout: ${item.workout.title} for time: $scheduledTime',
        );

        // Use the calendar provider to schedule the workout
        final success = await ref
            .read(calendarStateProvider.notifier)
            .scheduleWorkout(
              userId: widget.userId,
              planId: widget.planId,
              workout: item.workout,
              date: scheduledTime,
              reminderEnabled: true,
              reminderTime: scheduledTime.subtract(const Duration(minutes: 30)),
            );

        print(
          '🏋️ Scheduling ${item.workout.title} ${success ? "succeeded" : "failed"}',
        );

        if (!success) {
          allSuccessful = false;
        }
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (allSuccessful) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${selectedWorkouts.length} workout${selectedWorkouts.length != 1 ? 's' : ''} scheduled successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Return success to calling screen
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Some workouts could not be scheduled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stack) {
      print('❌ Error scheduling workouts: $e');
      print('❌ Stack trace: $stack');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling workouts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Scheduling Workouts'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to schedule workouts:',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('1. Browse or search for workouts'),
                const Text('2. Tap workouts to add to your selection'),
                const Text('3. Set morning, lunch, or evening time for each'),
                const Text('4. Tap Schedule to add to your calendar'),
                const SizedBox(height: 16),
                Text(
                  'Tips:',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('• You can schedule multiple workouts at once'),
                const Text('• Create custom or AI workouts from the tabs'),
                const Text('• Use time slots to organize your day'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }
}
