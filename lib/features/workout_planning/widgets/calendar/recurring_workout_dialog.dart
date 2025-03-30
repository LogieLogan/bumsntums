// lib/features/workouts/widgets/calendar/recurring_workout_dialog.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/theme/text_styles.dart';

enum RecurrencePattern {
  daily,
  weekly,
  monthly,
}

class RecurringWorkoutSettings {
  final RecurrencePattern pattern;
  final int occurrences;
  final List<int>? daysOfWeek; // For weekly pattern (1-7 for Monday-Sunday)
  
  RecurringWorkoutSettings({
    required this.pattern,
    required this.occurrences,
    this.daysOfWeek,
  });
  
  String get patternName {
    switch (pattern) {
      case RecurrencePattern.daily:
        return 'daily';
      case RecurrencePattern.weekly:
        return 'weekly';
      case RecurrencePattern.monthly:
        return 'monthly';
    }
  }
}

class RecurringWorkoutDialog extends StatefulWidget {
  final String workoutTitle;
  final DateTime initialDate;
  
  const RecurringWorkoutDialog({
    Key? key,
    required this.workoutTitle,
    required this.initialDate,
  }) : super(key: key);

  @override
  State<RecurringWorkoutDialog> createState() => _RecurringWorkoutDialogState();
}

class _RecurringWorkoutDialogState extends State<RecurringWorkoutDialog> {
  RecurrencePattern _selectedPattern = RecurrencePattern.weekly;
  int _occurrences = 4;
  List<int> _selectedDaysOfWeek = [];
  
  @override
  void initState() {
    super.initState();
    // Initialize selected day of week based on initial date
    _selectedDaysOfWeek = [widget.initialDate.weekday];
  }
  
  List<DateTime> _getPreviewDates() {
    final List<DateTime> dates = [];
    final startDate = widget.initialDate;
    
    switch (_selectedPattern) {
      case RecurrencePattern.daily:
        for (int i = 0; i < _occurrences; i++) {
          dates.add(startDate.add(Duration(days: i)));
        }
        break;
        
      case RecurrencePattern.weekly:
        // For weekly recurrence, we need to handle multiple days of week
        if (_selectedDaysOfWeek.isEmpty) {
          _selectedDaysOfWeek = [startDate.weekday];
        }
        
        // Calculate dates for each selected day of week
        for (int week = 0; week < _occurrences; week++) {
          for (final dayOfWeek in _selectedDaysOfWeek) {
            // Calculate days to add to get to this day of week
            final daysToAdd = (dayOfWeek - startDate.weekday) % 7;
            dates.add(startDate.add(Duration(days: daysToAdd + (week * 7))));
          }
        }
        
        // Sort dates
        dates.sort();
        break;
        
      case RecurrencePattern.monthly:
        for (int i = 0; i < _occurrences; i++) {
          // Simple approach - might need to handle edge cases like month end
          final newDate = DateTime(
            startDate.year,
            startDate.month + i,
            startDate.day,
          );
          dates.add(newDate);
        }
        break;
    }
    
    return dates;
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  Widget _buildPatternSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repeat Pattern', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<RecurrencePattern>(
          segments: const [
            ButtonSegment<RecurrencePattern>(
              value: RecurrencePattern.daily,
              label: Text('Daily'),
            ),
            ButtonSegment<RecurrencePattern>(
              value: RecurrencePattern.weekly,
              label: Text('Weekly'),
            ),
            ButtonSegment<RecurrencePattern>(
              value: RecurrencePattern.monthly,
              label: Text('Monthly'),
            ),
          ],
          selected: {_selectedPattern},
          onSelectionChanged: (Set<RecurrencePattern> selected) {
            setState(() {
              _selectedPattern = selected.first;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildOccurrencesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Occurrences', 
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _occurrences.toDouble(),
                min: 2,
                max: 12,
                divisions: 10,
                label: _occurrences.toString(),
                onChanged: (value) {
                  setState(() {
                    _occurrences = value.toInt();
                  });
                },
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '$_occurrences',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDaysOfWeekSelector() {
    if (_selectedPattern != RecurrencePattern.weekly) {
      return const SizedBox.shrink();
    }
    
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Days of Week', 
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final dayIndex = index + 1; // 1-7 for Monday-Sunday
            final isSelected = _selectedDaysOfWeek.contains(dayIndex);
            
            return FilterChip(
              label: Text(days[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDaysOfWeek.add(dayIndex);
                  } else {
                    _selectedDaysOfWeek.remove(dayIndex);
                    // Ensure at least one day is selected
                    if (_selectedDaysOfWeek.isEmpty) {
                      _selectedDaysOfWeek = [widget.initialDate.weekday];
                    }
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }
  
  Widget _buildDatePreview() {
    final dates = _getPreviewDates().take(10).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: dates.isNotEmpty
              ? SingleChildScrollView(
                  child: Column(
                    children: dates.map((date) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(_formatDate(date)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              : Center(
                  child: Text(
                    'No dates generated',
                    style: AppTextStyles.body.copyWith(color: Colors.grey),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Make "${widget.workoutTitle}" Recurring',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            Text(
              'Starting from ${_formatDate(widget.initialDate)}',
              style: AppTextStyles.small.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatternSelector(),
                    const SizedBox(height: 24),
                    _buildOccurrencesSelector(),
                    const SizedBox(height: 16),
                    _buildDaysOfWeekSelector(),
                    const SizedBox(height: 24),
                    _buildDatePreview(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      RecurringWorkoutSettings(
                        pattern: _selectedPattern,
                        occurrences: _occurrences,
                        daysOfWeek: _selectedPattern == RecurrencePattern.weekly 
                            ? _selectedDaysOfWeek 
                            : null,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}