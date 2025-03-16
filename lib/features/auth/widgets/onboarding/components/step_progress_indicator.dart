// lib/features/auth/widgets/onboarding/components/step_progress_indicator.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linear progress bar
        LinearProgressIndicator(
          value: (currentStep + 1) / totalSteps,
          backgroundColor: AppColors.paleGrey,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.salmon),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Step ${currentStep + 1} of $totalSteps',
            style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
          ),
        ),
      ],
    );
  }
}