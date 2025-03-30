// lib/features/workouts/widgets/plan_badge.dart
import 'package:flutter/material.dart';
import '../../workout_planning/models/workout_plan.dart';
import '../../workout_planning/models/plan_color.dart';
import '../../../shared/theme/text_styles.dart';

class PlanBadge extends StatelessWidget {
  final WorkoutPlan plan;
  final bool isCompact;
  final VoidCallback? onTap;

  const PlanBadge({
    Key? key,
    required this.plan,
    this.isCompact = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the plan color - either from colorName or generate from name
    final planColor = plan.colorName != null
        ? PlanColor.predefinedColors.firstWhere(
            (color) => color.name == plan.colorName,
            orElse: () => PlanColor.generateFromName(plan.name),
          )
        : PlanColor.generateFromName(plan.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: planColor.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: planColor.color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isCompact ? 10 : 12,
              height: isCompact ? 10 : 12,
              decoration: BoxDecoration(
                color: planColor.color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isCompact ? 4 : 8),
            Flexible(
              child: Text(
                plan.name,
                style: (isCompact ? AppTextStyles.small : AppTextStyles.body).copyWith(
                  color: planColor.color,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (plan.isActive && !isCompact) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: planColor.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Active',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}