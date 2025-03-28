// lib/features/workouts/widgets/calendar/plans_tab_view.dart
import 'package:bums_n_tums/features/workouts/widgets/calendar/plan_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workout_plan.dart';
import '../../providers/workout_calendar_provider.dart';
import '../../../../shared/components/indicators/loading_indicator.dart';

class PlansTabView extends ConsumerWidget {
  final String userId;
  final VoidCallback onCreateNewPlan;
  final Function(WorkoutPlan) onEditPlan;

  const PlansTabView({
    Key? key,
    required this.userId,
    required this.onCreateNewPlan,
    required this.onEditPlan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch active workout plan
    final activePlanAsync = ref.watch(activeWorkoutPlanProvider(userId));

    return activePlanAsync.when(
      data: (plan) => PlanView(
        plan: plan,
        onCreateNewPlan: onCreateNewPlan,
        onEditPlan: onEditPlan,
      ),
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Error loading workout plan: $error')),
    );
  }
}