// lib/features/ai/screens/workout_creation/widgets/refinement_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../shared/components/buttons/primary_button.dart';
import '../../../../../shared/components/buttons/secondary_button.dart';

class RefinementStep extends StatelessWidget {
  final Map<String, dynamic> workoutData;
  final TextEditingController controller;
  final bool isRefining;
  final bool refinementHistoryExists;
  final VoidCallback onCancel;
  final VoidCallback onUndoChanges;
  final VoidCallback onApplyChanges;

  const RefinementStep({
    Key? key,
    required this.workoutData,
    required this.controller,
    required this.isRefining,
    required this.refinementHistoryExists,
    required this.onCancel,
    required this.onUndoChanges,
    required this.onApplyChanges,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create categorized refinement suggestions
    final intensitySuggestions = [
      'Make it easier',
      'Make it harder',
      'More rest time',
      'Less rest time',
    ];

    final bodyFocusSuggestions = [
      'More core work',
      'More leg exercises',
      'More upper body',
      'Focus on strength',
    ];

    final equipmentSuggestions = [
      'Use different equipment',
      'Add resistance bands',
      'No equipment needed',
      'Use dumbbells only',
    ];

    final modificationSuggestions = [
      'No jumping',
      'Low impact only',
      'Add stretching',
      'Add warm-up',
      'Increase length',
      'Decrease length',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you like to change about this workout?',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 8),

        // Add guidance for effective refinement
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.salmon.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.salmon.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips for effective refinement:',
                style: AppTextStyles.small.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Be specific about what to add, remove, or change\n'
                '• For example: "Add 2 core exercises" or "Replace jumping with low-impact"\n'
                '• Mention specific exercises if possible\n'
                '• Include equipment preferences if relevant',
                style: AppTextStyles.small,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'E.g., "Add core exercises" or "Remove jumping exercises"',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Display suggestion categories with labels
        _buildSuggestionCategory(context, 'Intensity', intensitySuggestions),
        const SizedBox(height: 8),
        _buildSuggestionCategory(context, 'Body Focus', bodyFocusSuggestions),
        const SizedBox(height: 8),
        _buildSuggestionCategory(context, 'Equipment', equipmentSuggestions),
        const SizedBox(height: 8),
        _buildSuggestionCategory(context, 'Modifications', modificationSuggestions),

        const SizedBox(height: 24),

        // Bottom buttons, with proper constraints
        Row(
          children: [
            if (refinementHistoryExists)
              Expanded(
                child: SecondaryButton(
                  text: 'Undo Changes',
                  iconData: Icons.undo,
                  onPressed: isRefining ? null : onUndoChanges,
                ),
              ),
            if (refinementHistoryExists)
              const SizedBox(width: 8),
            Expanded(
              child: SecondaryButton(
                text: 'Cancel',
                onPressed: isRefining ? null : onCancel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PrimaryButton(
                text: 'Apply Changes',
                isLoading: isRefining,
                onPressed: isRefining ? null : onApplyChanges,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionCategory(BuildContext context, String title, List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.small.copyWith(
            color: AppColors.mediumGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: suggestions
                .map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildSuggestionChip(context, suggestion),
                  ),
                )
                .toList(),
          ),
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
        final currentText = controller.text;

        // Handle empty or placeholder text
        if (currentText.isEmpty ||
            currentText == 'Modify this workout by adding...') {
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
}