// lib/features/ai_workout_planning/widgets/steps/duration_frequency_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';

class DurationFrequencyStep extends StatelessWidget {
  final int selectedDuration;
  final int selectedFrequency;
  final Function(int) onDurationSelected;
  final Function(int) onFrequencySelected;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const DurationFrequencyStep({
    Key? key,
    required this.selectedDuration,
    required this.selectedFrequency,
    required this.onDurationSelected,
    required this.onFrequencySelected,
    required this.onContinue,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan Duration & Frequency',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose how many days your plan will cover and how many workouts per week.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.mediumGrey,
          ),
        ),
        const SizedBox(height: 32),
        
        // Duration selection
        Text(
          'Plan Duration',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildDurationSelector(context),
        const SizedBox(height: 32),
        
        // Frequency selection
        Text(
          'Workouts Per Week',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildFrequencySelector(context),
        const SizedBox(height: 32),
        
        // Navigation buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('BACK'),
            ),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('CONTINUE'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSelector(BuildContext context) {
    final durations = [3, 5, 7, 14];
    final labels = ['3 Days', '5 Days', '1 Week', '2 Weeks'];
    
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: durations.length,
        itemBuilder: (context, index) {
          final isSelected = selectedDuration == durations[index];
          
          return GestureDetector(
            onTap: () => onDurationSelected(durations[index]),
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.pink : AppColors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: isSelected ? Colors.white : AppColors.pink,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.darkGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrequencySelector(BuildContext context) {
    // Create a row of selectors for 2-7 days per week
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(6, (index) {
        final days = index + 2; // 2-7 days
        final isSelected = selectedFrequency == days;
        
        return GestureDetector(
          onTap: () => onFrequencySelected(days),
          child: Container(
            width: 45,
            height: 45,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.pink : AppColors.offWhite,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.lightGrey,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$days',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.darkGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}