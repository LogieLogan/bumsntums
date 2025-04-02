// lib/features/ai/screens/workout_creation/widgets/refinement_step.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/buttons/secondary_button.dart';

class RefinementStep extends StatefulWidget {
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
  State<RefinementStep> createState() => _RefinementStepState();
}

class _RefinementStepState extends State<RefinementStep> {
  // Track selected chips to show visual feedback
  final Set<String> _selectedSuggestions = {};
  
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

        const SizedBox(height: 16),
        
        // Current refinement text with clear button
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: 'Describe what changes you want...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
          onChanged: (value) {
            // Force refresh to show/hide clear button
            setState(() {});
          },
        ),
        
        // Selected suggestions display
        if (_selectedSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _selectedSuggestions.map((suggestion) {
                return Chip(
                  label: Text(suggestion),
                  backgroundColor: AppColors.salmon,
                  labelStyle: const TextStyle(color: Colors.white),
                  deleteIconColor: Colors.white,
                  onDeleted: () {
                    setState(() {
                      _selectedSuggestions.remove(suggestion);
                      _updateControllerText();
                    });
                    HapticFeedback.lightImpact();
                  },
                );
              }).toList(),
            ),
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
            if (widget.refinementHistoryExists)
              Expanded(
                child: SecondaryButton(
                  text: 'Undo Changes',
                  iconData: Icons.undo,
                  onPressed: widget.isRefining ? null : widget.onUndoChanges,
                ),
              ),
            if (widget.refinementHistoryExists)
              const SizedBox(width: 8),
            Expanded(
              child: SecondaryButton(
                text: 'Cancel',
                onPressed: widget.isRefining ? null : widget.onCancel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PrimaryButton(
                text: 'Apply Changes',
                isLoading: widget.isRefining,
                onPressed: widget.isRefining 
                    ? null 
                    : widget.controller.text.trim().isEmpty
                        ? null  // Disable if text is empty
                        : widget.onApplyChanges,
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
    final isSelected = _selectedSuggestions.contains(text);
    
    return ActionChip(
      label: Text(text),
      backgroundColor: isSelected 
          ? AppColors.salmon 
          : AppColors.salmon.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.salmon,
      ),
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedSuggestions.remove(text);
          } else {
            _selectedSuggestions.add(text);
          }
          _updateControllerText();
        });
      },
    );
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
    } else {
      final lastSuggestion = suggestions.removeLast();
      widget.controller.text = '${suggestions.join(", ")} and $lastSuggestion';
    }
    
    // Set cursor at the end of the text
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );
  }
}