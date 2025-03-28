// lib/features/workouts/widgets/smart_plan_suggestion_card.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../services/smart_plan_detector.dart';

class SmartPlanSuggestionCard extends StatelessWidget {
  final PatternSuggestion suggestion;
  final VoidCallback onCreatePlan;
  final VoidCallback onDismiss;
  
  const SmartPlanSuggestionCard({
    Key? key,
    required this.suggestion,
    required this.onCreatePlan,
    required this.onDismiss,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                    color: AppColors.popBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.popBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pattern Detected',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        suggestion.description,
                        style: AppTextStyles.small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getWorkoutSummary(),
              style: AppTextStyles.small.copyWith(
                color: AppColors.mediumGrey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onCreatePlan,
                  icon: const Icon(Icons.repeat),
                  label: const Text('Create Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.popBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getWorkoutSummary() {
    if (suggestion.matchedWorkouts.isEmpty) return '';
    
    final totalWorkouts = suggestion.matchedWorkouts.length;
    final firstWorkout = suggestion.matchedWorkouts.first;
    
    // If all workouts are the same type, show that
    final workoutTypes = suggestion.matchedWorkouts
        .map((w) => w.workoutCategory)
        .where((type) => type != null)
        .toSet();
    
    if (workoutTypes.length == 1 && workoutTypes.first != null) {
      return '$totalWorkouts ${workoutTypes.first} workouts detected';
    }
    
    // Default summary
    return '$totalWorkouts workouts including "${firstWorkout.title}"';
  }
}