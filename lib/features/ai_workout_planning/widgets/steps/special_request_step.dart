// lib/features/ai_workout_planning/widgets/steps/special_request_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';

class SpecialRequestStep extends StatelessWidget {
  final TextEditingController controller;
  final List<String> selectedFocusAreas;
  final int selectedDuration;
  final int selectedFrequency;
  final String selectedVariationType;
  final VoidCallback onGenerate;
  final VoidCallback onBack;

  const SpecialRequestStep({
    Key? key,
    required this.controller,
    required this.selectedFocusAreas,
    required this.selectedDuration,
    required this.selectedFrequency,
    required this.selectedVariationType,
    required this.onGenerate,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Any Special Requests?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add any specific requirements or preferences for your plan.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.mediumGrey,
          ),
        ),
        const SizedBox(height: 24),
        
        // Request input
        TextField(
          controller: controller,
          maxLength: 500,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'E.g., "I prefer morning workouts" or "I have knee issues"',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Example requests
        Text(
          'Suggested requests:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildExampleRequestChips(context),
        const SizedBox(height: 24),
        
        // Review card
        _buildReviewCard(context),
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
              onPressed: onGenerate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: AppColors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('GENERATE PLAN'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExampleRequestChips(BuildContext context) {
    final examples = [
      "I prefer morning workouts",
      "Include more stretching",
      "I have limited time on weekends",
      "I need lower impact exercises",
      "I want to focus on strength",
      "Include yoga or recovery days",
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: examples.map((example) {
        return ActionChip(
          label: Text(example),
          backgroundColor: AppColors.offWhite,
          onPressed: () {
            if (controller.text.isEmpty) {
              controller.text = example;
            } else {
              controller.text += ". $example";
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildReviewCard(BuildContext context) {
    String getDurationText() {
      if (selectedDuration <= 7) {
        return '$selectedDuration days';
      } else {
        return '${selectedDuration ~/ 7} weeks';
      }
    }

    String getVariationText() {
      switch (selectedVariationType) {
        case 'balanced':
          return 'Balanced mix';
        case 'progressive':
          return 'Progressive intensity';
        case 'alternating':
          return 'Alternating intensity';
        case 'focused':
          return 'Targeted focus';
        default:
          return 'Balanced mix';
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              context,
              'Duration',
              getDurationText(),
              Icons.calendar_today,
            ),
            const Divider(height: 16),
            _buildSummaryRow(
              context,
              'Frequency',
              '$selectedFrequency workouts/week',
              Icons.repeat,
            ),
            const Divider(height: 16),
            _buildSummaryRow(
              context,
              'Focus',
              selectedFocusAreas.join(', '),
              Icons.fitness_center,
            ),
            const Divider(height: 16),
            _buildSummaryRow(
              context,
              'Structure',
              getVariationText(),
              Icons.category,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.pink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: AppColors.mediumGrey),
          ),
        ],
      ),
    );
  }
}