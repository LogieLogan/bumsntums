// lib/features/ai/screens/workout_creation/widgets/custom_request_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../shared/components/buttons/primary_button.dart';
import '../../../../../shared/components/buttons/secondary_button.dart';
import '../../../../../features/workouts/models/workout.dart';

class CustomRequestStep extends StatelessWidget {
  final TextEditingController controller;
  final WorkoutCategory selectedCategory;
  final int selectedDuration;
  final List<String> selectedEquipment;
  final VoidCallback onBack;
  final VoidCallback onGenerate;

  const CustomRequestStep({
    Key? key,
    required this.controller,
    required this.selectedCategory,
    required this.selectedDuration,
    required this.selectedEquipment,
    required this.onBack,
    required this.onGenerate,
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
          'Almost there! Any special requests for your workout?',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 12),
        Text(
          'For example: "Add stretching" or "Focus on upper body"',
          style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter any special requests (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.1),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        // Quick suggestion chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'No jumping',
            'Low impact',
            'Include stretching',
            'Extra core work',
            'Stretch focus',
          ].map((suggestion) => _buildSuggestionChip(context, suggestion)).toList(),
        ),
        const SizedBox(height: 32),
        // Workout summary before generation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.salmon.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout Summary',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Focus',
                _getCategoryDisplayName(selectedCategory),
              ),
              _buildSummaryRow('Duration', '$selectedDuration minutes'),
              // Add equipment summary
              _buildSummaryRow(
                'Equipment',
                selectedEquipment.isEmpty || selectedEquipment.contains('None')
                    ? 'None (bodyweight only)'
                    : selectedEquipment.join(', '),
              ),
              if (controller.text.isNotEmpty)
                _buildSummaryRow(
                  'Special Request',
                  controller.text,
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'Back',
                onPressed: onBack,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'Create Workout',
                onPressed: onGenerate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: AppColors.salmon.withOpacity(0.1),
      labelStyle: TextStyle(color: AppColors.salmon),
      onPressed: () {
        // Get current text from controller
        final currentText = controller.text;

        // Handle empty or placeholder text
        if (currentText.isEmpty ||
            currentText == 'Enter any special requests (optional)') {
          controller.text = text;
        }
        // Check if text is already in the input
        else if (!currentText.toLowerCase().contains(text.toLowerCase())) {
          // If the existing text ends with punctuation, add a space
          if (currentText.endsWith('.') ||
              currentText.endsWith(',') ||
              currentText.endsWith(':') ||
              currentText.endsWith(';')) {
            controller.text = '$currentText $text';
          }
          // If existing text doesn't end with space, add a comma and space
          else if (!currentText.endsWith(' ')) {
            controller.text = '$currentText, $text';
          }
          // Otherwise just append with a space
          else {
            controller.text = '$currentText$text';
          }
        }

        // Set cursor at the end of the text
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );

        // Focus on the text field after selecting a chip
        FocusScope.of(context).requestFocus(FocusNode());
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}