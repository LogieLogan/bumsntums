// lib/features/ai/screens/workout_creation/widgets/equipment_selection_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../../../shared/components/buttons/primary_button.dart';
import '../../../../../shared/components/buttons/secondary_button.dart';
import '../../../../../features/auth/providers/user_provider.dart';

class EquipmentSelectionStep extends ConsumerWidget {
  final List<String> selectedEquipment;
  final Function(List<String>) onEquipmentUpdated;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  EquipmentSelectionStep({
    Key? key,
    required this.selectedEquipment,
    required this.onEquipmentUpdated,
    required this.onContinue,
    required this.onBack,
  }) : super(key: key);

  final TextEditingController _customEquipmentController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get equipment from profile
    final userProfile = ref.watch(userProfileProvider).asData?.value;
    final profileEquipment = userProfile?.availableEquipment ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What equipment will you use for this workout?',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 8),
        Text(
          'Select from your available equipment or add new items',
          style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
        ),
        const SizedBox(height: 16),

        // Show equipment from profile with indicator
        if (profileEquipment.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.salmon.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.salmon.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.mediumGrey),
                    const SizedBox(width: 4),
                    Text(
                      'From your profile',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.mediumGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profileEquipment.map((item) {
                    final isSelected = selectedEquipment.contains(item);
                    return FilterChip(
                      label: Text(item),
                      selected: isSelected,
                      onSelected: (selected) {
                        final updatedEquipment = List<String>.from(selectedEquipment);
                        if (selected) {
                          if (!updatedEquipment.contains(item)) {
                            updatedEquipment.add(item);
                          }
                          updatedEquipment.remove('None');
                        } else {
                          updatedEquipment.remove(item);
                        }
                        onEquipmentUpdated(updatedEquipment);
                      },
                      backgroundColor: AppColors.paleGrey,
                      selectedColor: AppColors.salmon.withOpacity(0.2),
                      checkmarkColor: AppColors.salmon,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Common equipment options
        Text(
          'Common Equipment',
          style: AppTextStyles.small.copyWith(
            color: AppColors.mediumGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Dumbbells',
            'Resistance Bands',
            'Yoga Mat',
            'Kettlebell',
            'Exercise Ball',
            'None',
          ].map((item) {
            final isSelected = selectedEquipment.contains(item);
            return FilterChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (selected) {
                final updatedEquipment = List<String>.from(selectedEquipment);
                if (selected) {
                  if (!updatedEquipment.contains(item)) {
                    updatedEquipment.add(item);
                  }
                  // If "None" is selected, clear all other selections
                  if (item == 'None') {
                    updatedEquipment.clear();
                    updatedEquipment.add('None');
                  } else {
                    // If another item is selected, remove "None" if present
                    updatedEquipment.remove('None');
                  }
                } else {
                  updatedEquipment.remove(item);
                }
                onEquipmentUpdated(updatedEquipment);
              },
              backgroundColor: AppColors.paleGrey,
              selectedColor: AppColors.salmon.withOpacity(0.2),
              checkmarkColor: AppColors.salmon,
            );
          }).toList(),
        ),

        // Add custom equipment option
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customEquipmentController,
                decoration: InputDecoration(
                  hintText: 'Add custom equipment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final text = _customEquipmentController.text.trim();
                if (text.isNotEmpty) {
                  final updatedEquipment = List<String>.from(selectedEquipment);
                  if (!updatedEquipment.contains(text)) {
                    updatedEquipment.add(text);
                    updatedEquipment.remove('None'); // Remove "None" if present
                  }
                  onEquipmentUpdated(updatedEquipment);
                  _customEquipmentController.clear();
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.salmon,
                foregroundColor: Colors.white,
              ),
            ),
          ],
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
                text: 'Continue',
                onPressed: onContinue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}