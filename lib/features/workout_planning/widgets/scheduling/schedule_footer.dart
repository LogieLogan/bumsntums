// lib/features/workouts/widgets/scheduling/schedule_footer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_scheduling_provider.dart';
import 'scheduled_workout_item.dart';
import '../../../../shared/theme/text_styles.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/components/buttons/primary_button.dart';

class ScheduleFooter extends ConsumerWidget {
  final Function() onSchedule;
  
  const ScheduleFooter({Key? key, required this.onSchedule}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedWorkouts = ref.watch(workoutSchedulingProvider);
    
    return Container(
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
                constraints: const BoxConstraints(maxHeight: 120),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.paleGrey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: selectedWorkouts.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ScheduledWorkoutItemWidget(index: index);
                  },
                ),
              ),
            ],

            // Schedule button
            PrimaryButton(
              text: selectedWorkouts.isEmpty
                  ? 'SELECT WORKOUTS TO SCHEDULE'
                  : 'SCHEDULE ${selectedWorkouts.length} WORKOUT${selectedWorkouts.length != 1 ? 'S' : ''}',
              onPressed: selectedWorkouts.isEmpty ? null : onSchedule,
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
    );
  }
}