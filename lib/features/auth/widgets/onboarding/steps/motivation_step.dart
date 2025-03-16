// Updated motivation_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';
import '../../../models/user_profile.dart';

class MotivationStep extends StatefulWidget {
  final List<MotivationType> initialMotivations;
  final String? initialCustomMotivation;
  final Function(List<MotivationType>, String?) onNext;
  final Function(List<MotivationType>, String?)? onChanged;

  const MotivationStep({
    super.key,
    this.initialMotivations = const [],
    this.initialCustomMotivation,
    required this.onNext,
    this.onChanged,
  });

  @override
  State<MotivationStep> createState() => _MotivationStepState();
}

class _MotivationStepState extends State<MotivationStep> {
  late List<MotivationType> _selectedMotivations;
  final _customMotivationController = TextEditingController();
  bool _hasCustomMotivation = false;

  @override
  void initState() {
    super.initState();
    _selectedMotivations = List.from(widget.initialMotivations);
    _customMotivationController.text = widget.initialCustomMotivation ?? '';
    _hasCustomMotivation = _selectedMotivations.contains(MotivationType.other);
  }

  @override
  void dispose() {
    _customMotivationController.dispose();
    super.dispose();
  }

  void _toggleMotivation(MotivationType motivation) {
    setState(() {
      if (_selectedMotivations.contains(motivation)) {
        _selectedMotivations.remove(motivation);
        if (motivation == MotivationType.other) {
          _hasCustomMotivation = false;
        }
      } else {
        _selectedMotivations.add(motivation);
        if (motivation == MotivationType.other) {
          _hasCustomMotivation = true;
        }
      }

      // Call onChanged if available
      if (widget.onChanged != null) {
        String? customMotivation =
            _hasCustomMotivation
                ? _customMotivationController.text.trim()
                : null;
        widget.onChanged!(_selectedMotivations, customMotivation);
      }
    });
  }

  String _getMotivationTitle(MotivationType type) {
    switch (type) {
      case MotivationType.appearance:
        return 'Look Better';
      case MotivationType.health:
        return 'Health'; // Shortened
      case MotivationType.energy:
        return 'Energy'; // Shortened
      case MotivationType.stress:
        return 'Less Stress'; // Shortened
      case MotivationType.confidence:
        return 'Confidence'; // Shortened
      case MotivationType.other:
        return 'Other'; // Shortened
    }
  }

  IconData _getMotivationIcon(MotivationType type) {
    switch (type) {
      case MotivationType.appearance:
        return Icons.face;
      case MotivationType.health:
        return Icons.favorite;
      case MotivationType.energy:
        return Icons.bolt;
      case MotivationType.stress:
        return Icons.spa;
      case MotivationType.confidence:
        return Icons.emoji_emotions;
      case MotivationType.other:
        return Icons.add_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What motivates you?', style: AppTextStyles.h3),
        const SizedBox(height: 4),
        Text(
          'Select all the reasons why you want to get fit',
          style: AppTextStyles.small,
        ),
        const SizedBox(height: 12),

        // GridView for motivation options
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children:
              MotivationType.values.map((type) {
                final isSelected = _selectedMotivations.contains(type);
                return Card(
                  elevation: isSelected ? 4 : 1,
                  margin: const EdgeInsets.all(2), // smaller margin
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // smaller radius
                    side: BorderSide(
                      color: isSelected ? AppColors.pink : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  color: isSelected ? AppColors.pink.withOpacity(0.1) : null,
                  child: InkWell(
                    onTap: () => _toggleMotivation(type),
                    borderRadius: BorderRadius.circular(8), // smaller radius
                    child: Padding(
                      padding: const EdgeInsets.all(6.0), // smaller padding
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getMotivationIcon(type),
                            color:
                                isSelected
                                    ? AppColors.pink
                                    : AppColors.mediumGrey,
                            size: 24, // smaller icon
                          ),
                          const SizedBox(height: 4), // less spacing
                          Text(
                            _getMotivationTitle(type),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.small.copyWith(
                              fontSize: 12, // smaller text
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? AppColors.pink
                                      : AppColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),

        // Custom motivation text field (shown only when "Other" is selected)
        if (_hasCustomMotivation) ...[
          const SizedBox(height: 8), // reduced spacing
          TextField(
            controller: _customMotivationController,
            decoration: const InputDecoration(
              labelText: 'Tell us your motivation',
              hintText: 'What drives you to exercise?',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            maxLines: 2,
            onChanged: (value) {
              // Call onChanged when text changes
              if (widget.onChanged != null &&
                  _selectedMotivations.contains(MotivationType.other)) {
                widget.onChanged!(_selectedMotivations, value.trim());
              }
            },
          ),
        ],
      ],
    );
  }
}
