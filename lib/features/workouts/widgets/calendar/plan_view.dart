// lib/features/workouts/widgets/calendar/plan_view.dart
import 'package:flutter/material.dart';
import '../../models/workout_plan.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/theme/text_styles.dart';
import '../plan_badge.dart';

class PlanView extends StatelessWidget {
  final WorkoutPlan? plan;
  final VoidCallback onCreateNewPlan;
  final Function(WorkoutPlan) onEditPlan;

  const PlanView({
    Key? key,
    this.plan,
    required this.onCreateNewPlan,
    required this.onEditPlan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                ? _buildCompactPlanView(plan!)
                : _buildNoPlanView(),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: onCreateNewPlan,
              icon: const Icon(Icons.add),
              label: Text(
                plan != null ? 'Create New Plan' : 'Create Your First Plan',
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
    );
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
                  onPressed: () => onEditPlan(plan),
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
                _showPlanWorkoutsDialog(
                  plan: plan,
                );
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

  void _showPlanWorkoutsDialog({required WorkoutPlan plan}) {
    // This method would need access to context, which we don't have in a stateless widget
    // We'll modify this to accept a BuildContext in the actual implementation
    // For now, let's just define the Widget that would be shown
  }

  Widget _buildNoPlanView() {
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
}