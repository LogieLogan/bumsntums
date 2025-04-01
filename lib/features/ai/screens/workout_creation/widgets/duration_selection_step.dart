// Updated lib/features/ai/screens/workout_creation/widgets/duration_selection_step.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../features/workouts/models/workout.dart';

class DurationSelectionStep extends StatelessWidget {
  final int selectedDuration;
  final WorkoutCategory selectedCategory;
  final Function(int) onDurationSelected;
  final VoidCallback onBack;

  const DurationSelectionStep({
    Key? key,
    required this.selectedDuration,
    required this.selectedCategory,
    required this.onDurationSelected,
    required this.onBack,
  }) : super(key: key);

  String _getCategoryDisplayName(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return 'Bums';
      case WorkoutCategory.tums:
        return 'Tums';
      case WorkoutCategory.fullBody:
        return 'Full Body';
      case WorkoutCategory.cardio:
        return 'Cardio';
      case WorkoutCategory.quickWorkout:
        return 'Quick';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Great choice! How long should your ${_getCategoryDisplayName(selectedCategory)} workout be?',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 12),
        Text(
          'Choose a duration that fits your schedule. Longer workouts provide more time for warm-up, cool-down, and variety.',
          style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
        ),
        const SizedBox(height: 36),
        
        // Duration options
        Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [10, 15, 20].map((duration) => 
                  _buildDurationOption(duration)
                ).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [30, 45, 60].map((duration) => 
                  _buildDurationOption(duration)
                ).toList(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Information card about workout duration
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.popBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.popBlue.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.popBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Workout Duration Guide',
                    style: AppTextStyles.small.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.popBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDurationGuideItem(
                '10-15 min',
                'Quick workouts, ideal for busy days',
                Icons.bolt,
              ),
              _buildDurationGuideItem(
                '20-30 min',
                'Balanced workouts with good intensity',
                Icons.fitness_center,
              ),
              _buildDurationGuideItem(
                '45-60 min',
                'Complete workouts with warm-up and cool-down',
                Icons.star,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationOption(int duration) {
    final isSelected = selectedDuration == duration;
    
    // Determine size based on duration value
    double size = 80;
    if (duration >= 30) {
      size = 90;  // Larger circles for longer durations
    } else if (duration <= 15) {
      size = 75;  // Smaller circles for shorter durations
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onDurationSelected(duration);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.salmon.withOpacity(0.7),
                      AppColors.salmon,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? AppColors.salmon.withOpacity(0.3) 
                    : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: isSelected 
                  ? Colors.transparent 
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$duration',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.darkGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Text(
                'min',
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.9) 
                      : AppColors.mediumGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationGuideItem(String duration, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.popBlue.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  duration,
                  style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(color: AppColors.mediumGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}