// lib/features/auth/widgets/onboarding/steps/body_focus_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_text_styles.dart';

class BodyFocusStep extends StatefulWidget {
  final Function(List<String>) onNext;
  final List<String> initialAreas;
  final Function(List<String>)? onChanged; // Add this

  const BodyFocusStep({
    super.key,
    required this.onNext,
    required this.initialAreas,
    this.onChanged,
  });

  @override
  State<BodyFocusStep> createState() => BodyFocusStepState();
}

class BodyFocusStepState extends State<BodyFocusStep> {
  late List<String> _selectedAreas;
  final _customAreaController = TextEditingController();
  bool _isAddingCustom = false;

  final List<String> _availableAreas = [
    'Abs (Tum)',
    'Glutes (Bum)',
    'Thighs',
    'Arms',
    'Back',
    'Chest',
    'Shoulders',
    'Calves',
    'Full Body',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAreas = List.from(widget.initialAreas);
  }

  @override
  void dispose() {
    _customAreaController.dispose();
    super.dispose();
  }

  void _toggleArea(String area) {
    setState(() {
      if (_selectedAreas.contains(area)) {
        _selectedAreas.remove(area);
      } else {
        _selectedAreas.add(area);
      }

      // Call onChanged if available
      if (widget.onChanged != null) {
        widget.onChanged!(_selectedAreas);
      }
    });
  }

  bool _isCustomArea(String area) {
    return !_availableAreas.contains(area);
  }

  void _addCustomArea() {
    final area = _customAreaController.text.trim();
    if (area.isNotEmpty) {
      setState(() {
        _selectedAreas.add(area);
        _customAreaController.clear();
        _isAddingCustom = false;

        // Call onChanged if available
        if (widget.onChanged != null) {
          widget.onChanged!(_selectedAreas);
        }
      });
    }
  }

  void _removeCustomArea(String area) {
    setState(() {
      _selectedAreas.remove(area);

      // Call onChanged if available
      if (widget.onChanged != null) {
        widget.onChanged!(_selectedAreas);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Which areas would you like to focus on?',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 8),
        Text('Select all that apply', style: AppTextStyles.small),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._availableAreas.map((area) {
              final isSelected = _selectedAreas.contains(area);
              return FilterChip(
                label: Text(area),
                selected: isSelected,
                onSelected: (_) => _toggleArea(area),
                backgroundColor: AppColors.offWhite,
                selectedColor: AppColors.salmon.withOpacity(0.2),
                checkmarkColor: AppColors.salmon,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.salmon : AppColors.darkGrey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.salmon : Colors.transparent,
                ),
              );
            }),

            // Display custom areas with delete option
            ..._selectedAreas.where(_isCustomArea).map((area) {
              return Chip(
                label: Text(area),
                backgroundColor: AppColors.salmon.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: AppColors.salmon,
                  fontWeight: FontWeight.bold,
                ),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeCustomArea(area),
                deleteIconColor: AppColors.salmon,
              );
            }),
          ],
        ),

        // Custom area input
        if (_isAddingCustom)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customAreaController,
                    decoration: const InputDecoration(
                      hintText: 'Enter body area',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.salmon),
                  onPressed: _addCustomArea,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _customAreaController.clear();
                      _isAddingCustom = false;
                    });
                  },
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add custom area'),
              onPressed: () {
                setState(() {
                  _isAddingCustom = true;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.salmon,
              ),
            ),
          ),
      ],
    );
  }
}
