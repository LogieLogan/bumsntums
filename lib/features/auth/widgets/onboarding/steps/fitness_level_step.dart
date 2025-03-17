import 'package:bums_n_tums/features/auth/models/user_profile.dart';
import 'package:bums_n_tums/shared/theme/color_palette.dart';
import 'package:bums_n_tums/shared/theme/text_styles.dart';
import 'package:flutter/material.dart';

class FitnessLevelStep extends StatefulWidget {
  final Function(FitnessLevel) onNext;
  final FitnessLevel initialLevel;
  final Function(FitnessLevel)? onChanged;

  const FitnessLevelStep({
    super.key,
    required this.onNext,
    required this.initialLevel,
    this.onChanged,
  });

  @override
  State<FitnessLevelStep> createState() => FitnessLevelStepState();
}

class FitnessLevelStepState extends State<FitnessLevelStep> {
  late FitnessLevel _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel;
  }

  @override
  void didUpdateWidget(FitnessLevelStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLevel != widget.initialLevel) {
      _selectedLevel = widget.initialLevel;
    }
  }

  void _selectLevel(FitnessLevel level) {
    setState(() {
      _selectedLevel = level;

      // Notify parent of the change
      if (widget.onChanged != null) {
        widget.onChanged!(level);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('What\'s your fitness level?', style: AppTextStyles.body),
        const SizedBox(height: 16),

        // Fitness level options
        for (final level in FitnessLevel.values)
          _LevelOption(
            level: level,
            isSelected: _selectedLevel == level,
            onSelect: () => _selectLevel(level),
          ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _LevelOption extends StatelessWidget {
  final FitnessLevel level;
  final bool isSelected;
  final VoidCallback onSelect;

  const _LevelOption({
    required this.level,
    required this.isSelected,
    required this.onSelect,
  });

  String get _levelName {
    switch (level) {
      case FitnessLevel.beginner:
        return 'Beginner';
      case FitnessLevel.intermediate:
        return 'Intermediate';
      case FitnessLevel.advanced:
        return 'Advanced';
    }
  }

  String get _levelDescription {
    switch (level) {
      case FitnessLevel.beginner:
        return 'New to fitness or returning after a break';
      case FitnessLevel.intermediate:
        return 'Regular exerciser with some experience';
      case FitnessLevel.advanced:
        return 'Experienced with challenging workouts';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? AppColors.salmon.withOpacity(0.1) : null,
      elevation: isSelected ? 2 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side:
            isSelected
                ? const BorderSide(color: AppColors.salmon, width: 2)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _levelName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.salmon : null,
                    ),
                  ),
                  const Spacer(),
                  Radio<bool>(
                    value: true,
                    groupValue: isSelected,
                    onChanged: (_) => onSelect(),
                    activeColor: AppColors.salmon,
                  ),
                ],
              ),
              Text(_levelDescription, style: AppTextStyles.small),
            ],
          ),
        ),
      ),
    );
  }
}
