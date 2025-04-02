// lib/features/ai_workout_planning/widgets/steps/parameters_summary_sheet.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';

class ParametersSummarySheet extends StatelessWidget {
  final int durationDays;
  final int daysPerWeek;
  final List<String> focusAreas;
  final String variationType;
  final String? specialRequest;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  final bool showBackButton;
  final bool showContinueButton;
  final String continueButtonText;

  const ParametersSummarySheet({
    Key? key,
    required this.durationDays,
    required this.daysPerWeek,
    required this.focusAreas,
    required this.variationType,
    this.specialRequest,
    this.onBack,
    this.onContinue,
    this.showBackButton = true,
    this.showContinueButton = true,
    this.continueButtonText = 'CONTINUE',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String variationTypeText = getVariationTypeText();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Parameters summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                context,
                'Duration',
                '$durationDays days',
                Icons.calendar_today,
              ),
              _buildSummaryItem(
                context,
                'Frequency',
                '$daysPerWeek/week',
                Icons.repeat,
              ),
              _buildSummaryItem(
                context,
                'Focus',
                focusAreas.length > 1 ? 'Multiple' : focusAreas.first,
                Icons.fitness_center,
              ),
              _buildSummaryItem(
                context,
                'Type',
                variationTypeText,
                Icons.category,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Buttons
          if (showBackButton || showContinueButton)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showBackButton)
                  OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('BACK'),
                  )
                else
                  const SizedBox.shrink(),
                
                if (showContinueButton)
                  ElevatedButton(
                    onPressed: onContinue,
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
                    child: Text(continueButtonText),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.pink),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mediumGrey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String getVariationTypeText() {
    switch (variationType) {
      case 'balanced':
        return 'Balanced';
      case 'progressive':
        return 'Progressive';
      case 'alternating':
        return 'Alternating';
      case 'focused':
        return 'Targeted';
      default:
        return 'Balanced';
    }
  }
}