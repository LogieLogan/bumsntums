import 'package:bums_n_tums/features/auth/models/user_profile.dart';
import 'package:bums_n_tums/shared/theme/color_palette.dart';
import 'package:bums_n_tums/shared/theme/text_styles.dart';
import 'package:flutter/material.dart';

class GoalsStep extends StatefulWidget {
  final Function(List<FitnessGoal>) onNext;
  final List<FitnessGoal> initialGoals;
  final Function(List<FitnessGoal>)? onChanged; // Add this

  const GoalsStep({
    required this.onNext,
    required this.initialGoals,
    this.onChanged,
  });

  @override
  State<GoalsStep> createState() => GoalsStepState();
}

class GoalsStepState extends State<GoalsStep> {
  late List<FitnessGoal> _selectedGoals;

  @override
  void initState() {
    super.initState();
    _selectedGoals = List.from(widget.initialGoals);
  }

  void _toggleGoal(FitnessGoal goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
      } else {
        _selectedGoals.add(goal);
      }

      // Call onChanged if available
      if (widget.onChanged != null) {
        widget.onChanged!(_selectedGoals);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('What are your fitness goals?', style: AppTextStyles.body),
        const SizedBox(height: 8),
        Text('Select all that apply', style: AppTextStyles.small),
        const SizedBox(height: 16),

        // Goal options
        for (final goal in FitnessGoal.values)
          _GoalOption(
            goal: goal,
            isSelected: _selectedGoals.contains(goal),
            onToggle: () => _toggleGoal(goal),
          ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _GoalOption extends StatelessWidget {
  final FitnessGoal goal;
  final bool isSelected;
  final VoidCallback onToggle;

  const _GoalOption({
    required this.goal,
    required this.isSelected,
    required this.onToggle,
  });

  String get _goalName {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.toning:
        return 'Toning';
      case FitnessGoal.strength:
        return 'Strength';
      case FitnessGoal.endurance:
        return 'Endurance';
      case FitnessGoal.flexibility:
        return 'Flexibility';
    }
  }

  IconData get _goalIcon {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return Icons.fitness_center;
      case FitnessGoal.toning:
        return Icons.accessibility_new;
      case FitnessGoal.strength:
        return Icons.sports_gymnastics;
      case FitnessGoal.endurance:
        return Icons.directions_run;
      case FitnessGoal.flexibility:
        return Icons.self_improvement;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? AppColors.salmon.withOpacity(0.1) : null,
      elevation: isSelected ? 2 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side:
            isSelected
                ? const BorderSide(color: AppColors.salmon, width: 2)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _goalIcon,
                color: isSelected ? AppColors.salmon : AppColors.darkGrey,
              ),
              const SizedBox(width: 16),
              Text(
                _goalName,
                style: AppTextStyles.body.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : null,
                  color: isSelected ? AppColors.salmon : null,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.salmon),
            ],
          ),
        ),
      ),
    );
  }
}
