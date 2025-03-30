// lib/features/workout_planning/screens/ai_plan_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/ai_planning_provider.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/buttons/secondary_button.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class AIPlanCreationScreen extends ConsumerStatefulWidget {
  final String userId;

  const AIPlanCreationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  ConsumerState<AIPlanCreationScreen> createState() => _AIPlanCreationScreenState();
}

class _AIPlanCreationScreenState extends ConsumerState<AIPlanCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final _analytics = AnalyticsService();
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 28));
  int _daysPerWeek = 3;
  String _fitnessLevel = 'beginner';
  final List<String> _selectedFocusAreas = ['Bums', 'Tums'];
  
  final List<String> _availableFocusAreas = [
    'Bums',
    'Tums',
    'Full Body',
    'Cardio',
    'Arms',
    'Legs',
    'Core',
  ];
  
  final Map<String, String> _fitnessLevels = {
    'beginner': 'Beginner',
    'intermediate': 'Intermediate',
    'advanced': 'Advanced',
  };

  @override
  void initState() {
    super.initState();
    _planNameController.text = 'My AI Workout Plan';
    _analytics.logScreenView(screenName: 'ai_plan_creation_screen');
  }

  @override
  void dispose() {
    _planNameController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        
        // Ensure end date is always after start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 28));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _toggleFocusArea(String area) {
    setState(() {
      if (_selectedFocusAreas.contains(area)) {
        if (_selectedFocusAreas.length > 1) {
          _selectedFocusAreas.remove(area);
        }
      } else {
        _selectedFocusAreas.add(area);
      }
    });
    
    _analytics.logEvent(
      name: 'ai_plan_focus_area_toggled',
      parameters: {'area': area, 'selected': _selectedFocusAreas.contains(area)},
    );
  }

  void _generatePlan() {
    if (_formKey.currentState!.validate()) {
      _analytics.logEvent(
        name: 'ai_plan_generate_tapped',
        parameters: {
          'days_per_week': _daysPerWeek,
          'focus_areas': _selectedFocusAreas.join(','),
          'duration_days': _endDate.difference(_startDate).inDays + 1,
        },
      );
      
      ref.read(aiPlanNotifierProvider.notifier).generatePlan(
        userId: widget.userId,
        startDate: _startDate,
        endDate: _endDate,
        daysPerWeek: _daysPerWeek,
        focusAreas: _selectedFocusAreas,
        fitnessLevel: _fitnessLevel,
        planName: _planNameController.text,
      ).then((success) {
        if (success && mounted) {
          Navigator.pop(context, true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(aiPlanNotifierProvider);
    final isGenerating = generationState.isLoading;
    final hasError = generationState.error != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create AI Workout Plan'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Name
              TextFormField(
                controller: _planNameController,
                decoration: const InputDecoration(
                  labelText: 'Plan Name',
                  hintText: 'Enter a name for your plan',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for your plan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Date Range
              Text(
                'Plan Duration',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectStartDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start Date',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.yMMMd().format(_startDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectEndDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'End Date',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.yMMMd().format(_endDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Days per week
              Text(
                'Workouts per Week',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Slider(
                value: _daysPerWeek.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: _daysPerWeek.toString(),
                onChanged: (value) {
                  setState(() {
                    _daysPerWeek = value.toInt();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('1 day'),
                  Text('$_daysPerWeek days'),
                  const Text('7 days'),
                ],
              ),
              const SizedBox(height: 24),
              
              // Fitness Level
              Text(
                'Fitness Level',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: _fitnessLevels.entries.map((entry) {
                  final isSelected = _fitnessLevel == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _fitnessLevel = entry.key;
                        });
                        
                        _analytics.logEvent(
                          name: 'ai_plan_fitness_level_changed',
                          parameters: {'level': entry.key},
                        );
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppColors.pink.withOpacity(0.7),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Focus Areas
              Text(
                'Focus Areas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableFocusAreas.map((area) {
                  final isSelected = _selectedFocusAreas.contains(area);
                  return FilterChip(
                    label: Text(area),
                    selected: isSelected,
                    onSelected: (_) => _toggleFocusArea(area),
                    backgroundColor: Colors.grey[200],
                    selectedColor: AppColors.pink.withOpacity(0.7),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Plan Duration visualization
              Text(
                'Plan Overview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Duration',
                        '${_endDate.difference(_startDate).inDays + 1} days',
                        Icons.calendar_today,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Workouts',
                        '${_daysPerWeek * ((_endDate.difference(_startDate).inDays ~/ 7) + 1)} workouts',
                        Icons.fitness_center,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Focus',
                        _selectedFocusAreas.join(', '),
                        Icons.track_changes,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Rest Days',
                        '${7 - _daysPerWeek} days/week',
                        Icons.hotel,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error message if there is one
              if (hasError)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error: ${generationState.error}',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                
              const SizedBox(height: 32),
              
              // Generate button
              if (isGenerating)
                const LoadingIndicator(message: 'Creating your personalized workout plan...')
              else
                Column(
                  children: [
                    PrimaryButton(
                      text: 'Generate Plan',
                      onPressed: _generatePlan,
                      isLoading: isGenerating,
                    ),
                    const SizedBox(height: 16),
                    SecondaryButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.pink),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}