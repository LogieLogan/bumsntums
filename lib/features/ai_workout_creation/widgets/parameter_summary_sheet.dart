// lib/features/ai_workout_creation/screens/workout_creation/widgets/parameter_summary_sheet.dart
import 'package:bums_n_tums/features/workouts/models/workout_category_extensions.dart';
import 'package:flutter/material.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/buttons/secondary_button.dart';
import '../../workouts/models/workout.dart';

class ParameterSummarySheet extends StatelessWidget {
  final WorkoutCategory? selectedCategory;
  final int? selectedDuration;
  final List<String> selectedEquipment;
  final String? specialRequest;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  final bool showBackButton;
  final bool showContinueButton;
  final String continueButtonText;

  const ParameterSummarySheet({
    Key? key,
    this.selectedCategory,
    this.selectedDuration,
    this.selectedEquipment = const [],
    this.specialRequest,
    this.onBack,
    this.onContinue,
    this.showBackButton = true,
    this.showContinueButton = true,
    this.continueButtonText = 'Continue',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle for sheet
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.only(bottom: 16),
          ),

          // Parameter summary
          if (selectedCategory != null ||
              selectedDuration != null ||
              selectedEquipment.isNotEmpty ||
              specialRequest != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.salmon.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.salmon.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workout Parameters',
                    style: AppTextStyles.small.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.salmon,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Category
                  if (selectedCategory != null)
                    _buildParameter(
                      'Type',
                      selectedCategory!.displayName,
                      Icons.fitness_center,
                    ),

                  // Duration
                  if (selectedDuration != null)
                    _buildParameter(
                      'Duration',
                      '$selectedDuration minutes',
                      Icons.timer,
                    ),

                  // Equipment
                  if (selectedEquipment.isNotEmpty)
                    _buildParameter(
                      'Equipment',
                      selectedEquipment.length == 1 &&
                              selectedEquipment.first == 'None'
                          ? 'No equipment'
                          : selectedEquipment.join(', '),
                      Icons.fitness_center,
                    ),

                  // Special request
                  if (specialRequest != null && specialRequest!.isNotEmpty)
                    _buildParameter(
                      'Special Request',
                      specialRequest!,
                      Icons.lightbulb_outline,
                    ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              if (showBackButton)
                Expanded(
                  child: SecondaryButton(text: 'Back', onPressed: onBack),
                ),
              if (showBackButton && showContinueButton)
                const SizedBox(width: 16),
              if (showContinueButton)
                Expanded(
                  child: PrimaryButton(
                    text: continueButtonText,
                    onPressed: onContinue,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParameter(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.salmon.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mediumGrey,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.small,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
