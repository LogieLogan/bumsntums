// lib/features/workouts/widgets/plan_color_picker.dart
import 'package:flutter/material.dart';
import '../../models/plan_color.dart';
import '../../../../shared/theme/text_styles.dart';

class PlanColorPicker extends StatefulWidget {
  final String? initialColorName;
  final Function(String) onColorSelected;

  const PlanColorPicker({
    Key? key,
    this.initialColorName,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  State<PlanColorPicker> createState() => _PlanColorPickerState();
}

class _PlanColorPickerState extends State<PlanColorPicker> {
  late String? _selectedColorName;

  @override
  void initState() {
    super.initState();
    _selectedColorName = widget.initialColorName;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Plan Color', style: AppTextStyles.body),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...PlanColor.predefinedColors.map((planColor) {
              final isSelected = _selectedColorName == planColor.name;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColorName = planColor.name;
                  });
                  widget.onColorSelected(planColor.name);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: planColor.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: planColor.color.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      planColor.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}