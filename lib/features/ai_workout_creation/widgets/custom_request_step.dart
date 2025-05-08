// Updated lib/features/ai/screens/workout_creation/widgets/custom_request_step.dart
import 'package:bums_n_tums/features/workouts/models/workout_category_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../workouts/models/workout.dart';

class CustomRequestStep extends StatefulWidget {
  final TextEditingController controller;
  final WorkoutCategory selectedCategory;
  final int selectedDuration;
  final List<String> selectedEquipment;
  final VoidCallback onBack;
  final VoidCallback onGenerate;

  const CustomRequestStep({
    super.key,
    required this.controller,
    required this.selectedCategory,
    required this.selectedDuration,
    required this.selectedEquipment,
    required this.onBack,
    required this.onGenerate,
  });

  @override
  State<CustomRequestStep> createState() => _CustomRequestStepState();
}

class _CustomRequestStepState extends State<CustomRequestStep> {
  final Set<String> _selectedSuggestions = {};
  
  @override
  void initState() {
    super.initState();
    // Initialize selected suggestions based on current text
    if (widget.controller.text.isNotEmpty) {
      _parseExistingSuggestions();
    }
  }
  
  void _parseExistingSuggestions() {
    // This is a simplified approach - in a real app you might want
    // a more sophisticated parsing for exact matches
    final text = widget.controller.text.toLowerCase();
    for (var suggestion in _suggestions) {
      if (text.contains(suggestion.toLowerCase())) {
        _selectedSuggestions.add(suggestion);
      }
    }
  }

  // Organized suggestions by category for better usability
  final Map<String, List<String>> _suggestionCategories = {
    'Intensity': [
      'Low impact',
      'High intensity',
      'Moderate intensity',
      'Gentle workout',
      'Advanced challenge',
    ],
    'Modifications': [
      'No jumping',
      'Knee-friendly',
      'Back-friendly',
      'Wrist-friendly',
      'Longer rest periods',
      'Shorter rest periods',
      'No floor exercises',
      'Chair-based exercises',
    ],
    'Focus Areas': [
      'Extra core work',
      'Upper body focus',
      'Lower body focus',
      'Glute activation',
      'Posture improvement',
      'Balance training',
    ],
    'Style': [
      'Include stretching',
      'Add warm-up',
      'Add cool-down',
      'Mobility work',
      'Breathwork and relaxation',
      'Energy-boosting',
      'Stress-relief',
    ],
  };
  
  // All suggestions flattened for searching and reference
  late final List<String> _suggestions = _suggestionCategories.values
      .expand((element) => element)
      .toList();

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
          'Customize your workout by adding specific requests or modifications',
          style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
        ),
        const SizedBox(height: 20),
        
        // Input field with clear button
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: 'Enter any special requests (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.salmon, width: 2),
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        widget.controller.clear();
                        _selectedSuggestions.clear();
                      });
                    },
                  )
                : null,
          ),
          maxLines: 3,
          onChanged: (_) {
            // Force refresh to update UI for clear button
            setState(() {});
          },
        ),
        
        // Selected suggestions display
        if (_selectedSuggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSuggestions.map((suggestion) {
              return Chip(
                label: Text(suggestion),
                backgroundColor: AppColors.salmon,
                labelStyle: const TextStyle(color: Colors.white),
                deleteIconColor: Colors.white,
                onDeleted: () {
                  _removeSuggestion(suggestion);
                },
              );
            }).toList(),
          ),
        ],
        
        const SizedBox(height: 24),
        
        // Quick suggestion categories
        for (final category in _suggestionCategories.keys) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
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
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestionCategories[category]!
                .map((suggestion) => _buildSuggestionChip(suggestion))
                .toList(),
          ),
        ],
        
        const SizedBox(height: 32),
        
        // Workout summary before generation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.salmon.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 18,
                    color: AppColors.salmon,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Workout Summary',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.salmon,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                'Focus',
                widget.selectedCategory.displayName,
                Icons.center_focus_strong,
              ),
              _buildSummaryRow(
                'Duration',
                '${widget.selectedDuration} minutes',
                Icons.timer,
              ),
              _buildSummaryRow(
                'Equipment',
                widget.selectedEquipment.isEmpty || 
                        widget.selectedEquipment.contains('None')
                    ? 'None (bodyweight only)'
                    : widget.selectedEquipment.join(', '),
                Icons.fitness_center,
              ),
              if (widget.controller.text.isNotEmpty)
                _buildSummaryRow(
                  'Special Request',
                  widget.controller.text,
                  Icons.lightbulb_outline,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    final isSelected = _selectedSuggestions.contains(text);
    
    return FilterChip(
      label: Text(text),
      selected: isSelected,
      onSelected: (selected) {
        HapticFeedback.selectionClick();
        setState(() {
          if (selected) {
            _addSuggestion(text);
          } else {
            _removeSuggestion(text);
          }
        });
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.salmon.withOpacity(0.7),
          ),
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
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Intensity':
        return Icons.speed;
      case 'Modifications':
        return Icons.tune;
      case 'Focus Areas':
        return Icons.center_focus_strong;
      case 'Style':
        return Icons.style;
      default:
        return Icons.category;
    }
  }
  
  void _addSuggestion(String suggestion) {
    setState(() {
      _selectedSuggestions.add(suggestion);
      _updateControllerText();
    });
  }
  
  void _removeSuggestion(String suggestion) {
    setState(() {
      _selectedSuggestions.remove(suggestion);
      _updateControllerText();
    });
  }
  
  void _updateControllerText() {
    if (_selectedSuggestions.isEmpty) {
      widget.controller.clear();
      return;
    }
    
    // Combine all selected suggestions into a coherent sentence
    final suggestions = _selectedSuggestions.toList();
    if (suggestions.length == 1) {
      widget.controller.text = suggestions[0];
    } else if (suggestions.length == 2) {
      widget.controller.text = '${suggestions[0]} and ${suggestions[1]}';
    } else {
      final lastSuggestion = suggestions.removeLast();
      widget.controller.text = '${suggestions.join(", ")}, and $lastSuggestion';
    }
    
    // Set cursor at the end of the text
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );
  }
}