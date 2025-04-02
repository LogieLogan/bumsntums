// Updated lib/features/ai/screens/workout_creation/widgets/equipment_selection_step.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/buttons/secondary_button.dart';
import '../../auth/providers/user_provider.dart';

class EquipmentSelectionStep extends ConsumerStatefulWidget {
  final List<String> selectedEquipment;
  final Function(List<String>) onEquipmentUpdated;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const EquipmentSelectionStep({
    Key? key,
    required this.selectedEquipment,
    required this.onEquipmentUpdated,
    required this.onContinue,
    required this.onBack,
  }) : super(key: key);

  @override
  ConsumerState<EquipmentSelectionStep> createState() => _EquipmentSelectionStepState();
}

class _EquipmentSelectionStepState extends ConsumerState<EquipmentSelectionStep> {
  final TextEditingController _customEquipmentController = TextEditingController();
  final FocusNode _customEquipmentFocus = FocusNode();
  bool _showCustomError = false;

  @override
  void dispose() {
    _customEquipmentController.dispose();
    _customEquipmentFocus.dispose();
    super.dispose();
  }

  void _addCustomEquipment() {
    final text = _customEquipmentController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _showCustomError = true;
      });
      return;
    }

    setState(() {
      _showCustomError = false;
    });

    final updatedEquipment = List<String>.from(widget.selectedEquipment);
    if (!updatedEquipment.contains(text)) {
      updatedEquipment.add(text);
      updatedEquipment.remove('None'); // Remove "None" if present
      widget.onEquipmentUpdated(updatedEquipment);
      _customEquipmentController.clear();
      
      // Give feedback
      HapticFeedback.mediumImpact();
      
      // Show temporary confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "$text" to your equipment'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          width: 300,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get equipment from profile
    final userProfile = ref.watch(userProfileProvider).asData?.value;
    final profileEquipment = userProfile?.availableEquipment ?? [];

    // Organize common equipment into categories for better organization
    final equipmentCategories = {
      'Basic Home Equipment': [
        'None',
        'Dumbbells',
        'Resistance Bands',
        'Yoga Mat',
        'Jump Rope',
        'Foam Roller',
      ],
      'Gym Equipment': [
        'Barbell & Weight Plates',
        'Kettlebell',
        'Pull-Up Bar',
        'Adjustable Bench',
        'Smith Machine',
        'Cables & Pulleys',
        'Leg Press Machine',
      ],
      'Cardio Equipment': [
        'Treadmill',
        'Stationary Bike',
        'Rowing Machine',
        'Elliptical Machine',
        'Spin Bike',
        'Skipping Rope',
      ],
      'Specialized Equipment': [
        'Medicine Ball',
        'Exercise Ball',
        'TRX Suspension Trainer',
        'Battle Ropes',
        'Ankle Weights',
        'Weighted Vest',
        'Ab Roller',
        'Sliders/Core Gliders',
      ],
    };

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

        // Selected equipment display with remove option
        if (widget.selectedEquipment.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.salmon.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.salmon.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center, 
                      size: 16, 
                      color: AppColors.salmon
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selected Equipment',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.salmon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.selectedEquipment.map((item) {
                    return Chip(
                      label: Text(item),
                      backgroundColor: AppColors.salmon.withOpacity(0.1),
                      labelStyle: TextStyle(color: AppColors.salmon),
                      deleteIconColor: AppColors.salmon,
                      onDeleted: () {
                        final updatedEquipment = List<String>.from(
                          widget.selectedEquipment,
                        )..remove(item);
                        
                        // If all equipment is removed, add "None"
                        if (updatedEquipment.isEmpty) {
                          updatedEquipment.add('None');
                        }
                        
                        widget.onEquipmentUpdated(updatedEquipment);
                        HapticFeedback.selectionClick();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Show equipment from profile with indicator
        if (profileEquipment.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.popBlue),
                    const SizedBox(width: 8),
                    Text(
                      'From your profile',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.popBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: profileEquipment.map((item) {
                    final isSelected = widget.selectedEquipment.contains(item);
                    return _buildSelectionChip(
                      label: item,
                      isSelected: isSelected,
                      onToggle: (selected) {
                        final updatedEquipment = List<String>.from(
                          widget.selectedEquipment,
                        );
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
                          // If all equipment is removed, add "None"
                          if (updatedEquipment.isEmpty) {
                            updatedEquipment.add('None');
                          }
                        }
                        widget.onEquipmentUpdated(updatedEquipment);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Common equipment categories
        for (final category in equipmentCategories.keys) ...[
          Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                size: 16,
                color: AppColors.mediumGrey,
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.mediumGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: equipmentCategories[category]!.map((item) {
              final isSelected = widget.selectedEquipment.contains(item);
              return _buildSelectionChip(
                label: item,
                isSelected: isSelected,
                onToggle: (selected) {
                  final updatedEquipment = List<String>.from(
                    widget.selectedEquipment,
                  );
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
                    // If all equipment is removed, add "None"
                    if (updatedEquipment.isEmpty) {
                      updatedEquipment.add('None');
                    }
                  }
                  widget.onEquipmentUpdated(updatedEquipment);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Add custom equipment option
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _showCustomError ? Colors.red : AppColors.lightGrey,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Custom Equipment',
                style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customEquipmentController,
                      focusNode: _customEquipmentFocus,
                      decoration: InputDecoration(
                        hintText: 'Enter equipment name...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        errorText: _showCustomError 
                            ? 'Please enter equipment name' 
                            : null,
                      ),
                      onSubmitted: (_) => _addCustomEquipment(),
                      onChanged: (_) {
                        if (_showCustomError) {
                          setState(() {
                            _showCustomError = false;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addCustomEquipment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.salmon,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: SecondaryButton(text: 'Back', onPressed: widget.onBack)),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(text: 'Continue', onPressed: widget.onContinue),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionChip({
    required String label,
    required bool isSelected,
    required Function(bool) onToggle,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onToggle(selected);
        HapticFeedback.selectionClick();
      },
      backgroundColor: AppColors.paleGrey,
      selectedColor: AppColors.salmon.withOpacity(0.2),
      checkmarkColor: AppColors.salmon,
      avatar: isSelected 
          ? Icon(
              Icons.check_circle, 
              color: AppColors.salmon, 
              size: 16,
            ) 
          : null,
      showCheckmark: false,
      elevation: isSelected ? 2 : 0,
      shadowColor: isSelected ? AppColors.salmon.withOpacity(0.3) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.salmon : Colors.transparent,
          width: isSelected ? 1 : 0,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.salmon : AppColors.darkGrey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Basic Home Equipment':
        return Icons.home;
      case 'Gym Equipment':
        return Icons.fitness_center;
      case 'Cardio Equipment':
        return Icons.directions_run;
      case 'Specialized Equipment':
        return Icons.sports_gymnastics;
      default:
        return Icons.category;
    }
  }
}