// lib/features/ai/screens/workout_creation/widgets/welcome_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../shared/components/buttons/primary_button.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onGetStarted;

  const WelcomeStep({
    Key? key,
    required this.onGetStarted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(
          Icons.fitness_center,
          size: 64,
          color: AppColors.salmon.withOpacity(0.7),
        ),
        const SizedBox(height: 24),
        Text(
          'Let\'s Create Your Perfect Workout',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'I\'ll help you build a personalized workout that matches your goals and preferences.',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Get Started',
          onPressed: onGetStarted,
        ),
      ],
    );
  }
}