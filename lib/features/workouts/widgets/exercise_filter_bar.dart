// lib/features/workouts/widgets/exercise_filter_bar.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';

class ExerciseFilterBar extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final Function(String) onSelected;

  const ExerciseFilterBar({
    super.key,
    required this.title,
    required this.options,
    this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox(); // Return empty widget if no options
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.mediumGrey,
            ),
          ),
        ),
        Wrap(
          spacing: 8.0,
          children:
              options.map((option) {
                final isSelected = option == selectedOption;
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (_) => onSelected(option),
                  backgroundColor: AppColors.offWhite,
                  selectedColor: AppColors.pink.withOpacity(0.2),
                  checkmarkColor: AppColors.pink,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.pink : AppColors.darkGrey,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
