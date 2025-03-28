// lib/features/workouts/screens/workout_scheduling_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_plan.dart';
import '../providers/workout_scheduling_provider.dart';
import '../providers/workout_actions_provider.dart';
import '../widgets/scheduling/browse_workouts_tab.dart';
import '../widgets/scheduling/my_workouts_tab.dart';
import '../widgets/scheduling/schedule_footer.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/providers/analytics_provider.dart';

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
    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(analyticsServiceProvider)
          .logScreenView(screenName: 'workout_scheduling');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // lib/features/workouts/screens/workout_scheduling_screen.dart (continued)
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
          _buildDateHeader(),

          // Tabs for browse and my workouts
          Expanded(
            child: DefaultTabController(
              length: 2,
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
                        const BrowseWorkoutsTab(),

                        // My Workouts Tab
                        MyWorkoutsTab(userId: widget.userId),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Schedule footer
          ScheduleFooter(onSchedule: _scheduleSelectedWorkouts),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.plan!.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.plan!.color.withOpacity(0.3)),
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
            style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleSelectedWorkouts() async {
    final selectedWorkouts = ref.read(workoutSchedulingProvider);

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
            .read(workoutActionsProvider.notifier)
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
