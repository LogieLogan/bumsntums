// lib/features/ai_workout_planning/widgets/visualization/plan_preview.dart
import 'package:bums_n_tums/features/ai_workout_planning/providers/ai_workout_plan_provider.dart'; // Import the plan provider
import 'package:bums_n_tums/features/ai_workout_planning/providers/plan_generation_provider.dart';
import 'package:bums_n_tums/features/ai_workout_planning/screens/saved_plans_screen.dart';
import 'package:bums_n_tums/features/auth/providers/auth_provider.dart'; // Import auth provider for user ID
import 'package:bums_n_tums/features/nutrition/providers/food_scanner_provider.dart';
import 'package:bums_n_tums/shared/providers/analytics_provider.dart'; // Import analytics provider
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart'; // Not used directly, can be removed if PlanCalendarView doesn't need it implicitly
import '../../../../../shared/theme/color_palette.dart';
import 'plan_calendar_view.dart';
import 'workout_distribution_chart.dart';

// Change StatefulWidget to ConsumerStatefulWidget
class PlanPreview extends ConsumerStatefulWidget {
  final Map<String, dynamic> planData;
  final VoidCallback onRefine;

  const PlanPreview({Key? key, required this.planData, required this.onRefine})
      : super(key: key);

  @override
  // Change State to ConsumerState
  ConsumerState<PlanPreview> createState() => _PlanPreviewState();
}

// Change State<PlanPreview> to ConsumerState<PlanPreview>
class _PlanPreviewState extends ConsumerState<PlanPreview>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access planData via widget.planData
    final planName =
        widget.planData['planName'] as String? ?? 'Your Workout Plan';
    final planDescription = widget.planData['planDescription'] as String? ?? '';
    final successTips = widget.planData['successTips'] as List<dynamic>? ?? [];
    final scheduledWorkouts =
        widget.planData['scheduledWorkouts'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success animation and header
        Center(
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                'Plan Created!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your personalized workout plan is ready',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.mediumGrey),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Plan name and description
        Text(
          planName,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(planDescription, style: Theme.of(context).textTheme.bodyMedium),

        const SizedBox(height: 24),

        // Tab bar for different views
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Calendar View'), Tab(text: 'Statistics')],
          labelColor: AppColors.pink,
          unselectedLabelColor: AppColors.mediumGrey,
          indicatorColor: AppColors.pink,
        ),

        const SizedBox(height: 16),

        // Tab content
        SizedBox(
          height: 300, // Fixed height for tab content
          child: TabBarView(
            controller: _tabController,
            children: [
              // Calendar view tab
              PlanCalendarView(scheduledWorkouts: scheduledWorkouts),

              // Statistics tab
              WorkoutDistributionChart(planData: widget.planData),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Success tips
        if (successTips.isNotEmpty) ...[
          Text(
            'Tips for Success',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...successTips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.tips_and_updates,
                    color: AppColors.popYellow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip.toString())),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onRefine,
                icon: const Icon(Icons.edit),
                label: const Text('Refine Plan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  // Consider adding foregroundColor for consistency if needed
                  // foregroundColor: Theme.of(context).colorScheme.primary,
                  // side: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                // No need to pass context or ref here anymore
                onPressed: _savePlan,
                icon: const Icon(Icons.save),
                label: const Text('Save Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.popBlue,
                  foregroundColor: Colors.white, // Ensure text is visible
                  padding: const EdgeInsets.symmetric(vertical: 12), // Match padding
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Remove WidgetRef from parameters, use instance member 'ref'
  Future<void> _savePlan() async {
    // Add haptic feedback
    HapticFeedback.mediumImpact();

    // Access analytics service via ref
    final analyticsService = ref.read(analyticsServiceProvider);
    analyticsService.logEvent(
      name: 'save_generated_plan_button_tapped',
      // Access planData via widget.planData
      parameters: {'plan_name': widget.planData['planName'] ?? 'Unknown'},
    );

    try {
      // Get the user ID from the auth provider
      final userId = ref.read(authProvider).currentUser?.uid; // Use read for one-time access in callback
      if (userId == null) {
         // Handle case where user is not logged in (should ideally not happen here)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not logged in. Cannot save plan.'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Exit if no user ID
      }

      // Get plan generation parameters from the provider state
      // Use 'read' as we likely don't need to react to changes *during* save
      final parameters = ref.read(planGenerationProvider).parameters;

      // Save the plan using the notifier provider
      // Pass the correct userId
      // Access planData via widget.planData
      await ref.read(aiWorkoutPlanNotifierProvider(userId).notifier)
          .saveGeneratedPlan(
            planData: widget.planData,
            parameters: parameters,
          );

      // Show success message
      // Check mounted state before accessing context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Access planData via widget.planData
            content: Text(
                'Plan "${widget.planData['planName'] ?? 'New Plan'}" saved successfully'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View Plans',
              onPressed: () {
                // Check mounted state again before navigation
                if (mounted) {
                  // Navigate to saved plans screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SavedPlansScreen(userId: userId),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e, stackTrace) { // Catch stack trace for better debugging
       // Log the error using analytics or crash reporting
      final crashReportingService = ref.read(crashReportingServiceProvider);
      crashReportingService.recordError(e, stackTrace, reason: 'Failed to save AI workout plan');
      analyticsService.logEvent(name: 'save_plan_failed', parameters: {'error': e.toString()});

      // Show error message
      // Check mounted state before accessing context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save plan: ${e.toString()}'), // Show concise error
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Remove the currentUserIdProvider as it's no longer needed here.
// We fetch the userId directly from the auth provider when saving.
/*
final currentUserIdProvider = Provider<String?>((ref) {
  // This logic was problematic, relying on potentially stale state
  // final planData = ref.watch(planGenerationProvider).planData;
  // if (planData == null) return null;
  // return planData['userId'] as String?;

  // Better approach: Get directly from auth state when needed
  return ref.watch(authProvider).currentUser?.uid;
});
*/