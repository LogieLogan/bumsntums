// lib/features/workout_planning/screens/ai_plan_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _planRequestController = TextEditingController(); 
  final _analytics = AnalyticsService();
  
  int _numberOfDays = 3; // Default to 3 days
  String _fitnessLevel = 'beginner';
  final List<String> _selectedFocusAreas = ['Bums', 'Tums'];
  bool _useSimpleMode = true; // Default to simple text input mode
  
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
    _planNameController.text = '';
    _analytics.logScreenView(screenName: 'ai_plan_creation_screen');
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _planRequestController.dispose();
    super.dispose();
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

  void _toggleInputMode() {
    setState(() {
      _useSimpleMode = !_useSimpleMode;
    });
    
    _analytics.logEvent(
      name: 'ai_plan_toggle_input_mode',
      parameters: {'simple_mode': _useSimpleMode},
    );
  }

  void _generatePlan() {
    if (_formKey.currentState!.validate()) {
      _analytics.logEvent(
        name: 'ai_plan_generate_tapped',
        parameters: {
          'days': _numberOfDays,
          'focus_areas': _selectedFocusAreas.join(','),
          'simple_mode': _useSimpleMode,
        },
      );
      
      // Calculate dates based on today and number of days
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: _numberOfDays - 1));

      // When using simple mode, we'll send the text as extra context
      final Map<String, dynamic> additionalParams = _useSimpleMode 
          ? {'textRequest': _planRequestController.text}
          : {};
      
      ref.read(aiPlanNotifierProvider.notifier).generatePlan(
        userId: widget.userId,
        startDate: startDate,
        endDate: endDate,
        daysPerWeek: _numberOfDays, // In simple mode, days = workouts
        focusAreas: _useSimpleMode ? _selectedFocusAreas : _selectedFocusAreas,
        fitnessLevel: _fitnessLevel,
        planName: _planNameController.text,
        additionalParams: additionalParams,
      ).then((success) {
        if (success && mounted) {
          // Navigate back to the planning screen
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
        actions: [
          TextButton.icon(
            icon: Icon(
              _useSimpleMode ? Icons.tune : Icons.chat_bubble_outline, 
              color: Colors.white
            ),
            label: Text(
              _useSimpleMode ? 'Advanced' : 'Simple',
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: _toggleInputMode,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Name - required for both modes
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
              const SizedBox(height: 24),

              // Simple mode vs Advanced mode UI
              if (_useSimpleMode) _buildSimpleModeUI() else _buildAdvancedModeUI(),
              
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

  // Simple mode UI with just text input and days selector
  Widget _buildSimpleModeUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell me what you want:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _planRequestController,
          maxLength: 200,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g., "Create a 5-day plan focused on legs and cardio for a beginner"',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        
        Text(
          'Number of Days',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final dayCount = index + 1;
            final isSelected = _numberOfDays == dayCount;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _numberOfDays = dayCount;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.pink : Colors.grey.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    '$dayCount',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        
        // Preview card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppColors.pink),
                    const SizedBox(width: 8),
                    Text('$_numberOfDays days'),
                  ],
                ),
                if (_planRequestController.text.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    'Your request:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.mediumGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_planRequestController.text),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Advanced mode UI with detailed options
  Widget _buildAdvancedModeUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number of Days
        Text(
          'Number of Days',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final dayCount = index + 1;
            final isSelected = _numberOfDays == dayCount;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _numberOfDays = dayCount;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.pink : Colors.grey.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    '$dayCount',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
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
        
        // Plan overview card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Duration',
                  '$_numberOfDays days',
                  Icons.calendar_today,
                ),
                const Divider(),
                _buildInfoRow(
                  'Focus',
                  _selectedFocusAreas.join(', '),
                  Icons.track_changes,
                ),
                const Divider(),
                _buildInfoRow(
                  'Level',
                  _fitnessLevels[_fitnessLevel] ?? 'Beginner',
                  Icons.fitness_center,
                ),
              ],
            ),
          ),
        ),
      ],
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