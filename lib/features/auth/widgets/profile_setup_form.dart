// lib/features/auth/widgets/profile_setup_form.dart (continued)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/user_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';

class ProfileSetupForm extends ConsumerStatefulWidget {
  final UserProfile initialProfile;
  final Function(UserProfile) onComplete;
  
  const ProfileSetupForm({
    super.key,
    required this.initialProfile,
    required this.onComplete,
  });

  @override
  ConsumerState<ProfileSetupForm> createState() => _ProfileSetupFormState();
}

class _ProfileSetupFormState extends ConsumerState<ProfileSetupForm> {
  late UserProfile _profile;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _nameController.text = _profile.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveBasicInfo() {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _profile = _profile.copyWith(
        displayName: _nameController.text.trim(),
      );
      _currentStep++;
    });
  }

  void _saveMeasurements(int? age, double? height, double? weight) {
    setState(() {
      _profile = _profile.copyWith(
        age: age,
        heightCm: height,
        weightKg: weight,
      );
      _currentStep++;
    });
  }

  void _saveGoals(List<FitnessGoal> goals) {
    setState(() {
      _profile = _profile.copyWith(
        goals: goals,
      );
      _currentStep++;
    });
  }

  void _saveFitnessLevel(FitnessLevel level) {
    setState(() {
      _profile = _profile.copyWith(
        fitnessLevel: level,
      );
      _currentStep++;
    });
  }

  void _saveBodyFocusAreas(List<String> areas) {
    setState(() {
      _profile = _profile.copyWith(
        bodyFocusAreas: areas,
      );
      _currentStep++;
    });
  }

  void _saveDietaryPreferences(List<String> preferences) {
    setState(() {
      _profile = _profile.copyWith(
        dietaryPreferences: preferences,
      );
      // Mark onboarding as completed
      _profile = _profile.copyWith(
        onboardingCompleted: true,
      );
      _submitProfile();
    });
  }

  Future<void> _submitProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update profile in Firestore
      await ref.read(userProfileNotifierProvider.notifier).updateProfile(_profile);
      
      // Call completion callback
      widget.onComplete(_profile);
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: () {
        // Handle continue based on current step
        switch (_currentStep) {
          case 0: // Basic info
            _saveBasicInfo();
            break;
          case 1: // Measurements - handled by form
            break;
          case 2: // Goals - handled by form
            break;
          case 3: // Fitness level - handled by form
            break;
          case 4: // Body focus - handled by form
            break;
          case 5: // Dietary - handled by form
            break;
        }
      },
      onStepCancel: () {
        if (_currentStep > 0) {
          setState(() {
            _currentStep--;
          });
        }
      },
      steps: [
        // Step 1: Basic Info
        Step(
          title: const Text('Basic Info'),
          content: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    helperText: 'This will be visible to other users',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a display name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Continue',
                  onPressed: _saveBasicInfo,
                ),
              ],
            ),
          ),
          isActive: _currentStep >= 0,
        ),
        
        // Step 2: Measurements
        Step(
          title: const Text('Your Measurements'),
          content: _MeasurementsForm(
            onSave: _saveMeasurements,
            initialAge: _profile.age,
            initialHeight: _profile.heightCm,
            initialWeight: _profile.weightKg,
          ),
          isActive: _currentStep >= 1,
        ),
        
        // Step 3: Fitness Goals
        Step(
          title: const Text('Your Goals'),
          content: _GoalsSelectionForm(
            onSave: _saveGoals,
            initialGoals: _profile.goals,
          ),
          isActive: _currentStep >= 2,
        ),
        
        // Step 4: Fitness Level
        Step(
          title: const Text('Your Fitness Level'),
          content: _FitnessLevelForm(
            onSave: _saveFitnessLevel,
            initialLevel: _profile.fitnessLevel,
          ),
          isActive: _currentStep >= 3,
        ),
        
        // Step 5: Body Focus Areas
        Step(
          title: const Text('Body Focus Areas'),
          content: _BodyFocusForm(
            onSave: _saveBodyFocusAreas,
            initialAreas: _profile.bodyFocusAreas,
          ),
          isActive: _currentStep >= 4,
        ),
        
        // Step 6: Dietary Preferences
        Step(
          title: const Text('Dietary Preferences'),
          content: _DietaryPreferencesForm(
            onSave: _saveDietaryPreferences,
            initialPreferences: _profile.dietaryPreferences,
            isLoading: _isLoading,
          ),
          isActive: _currentStep >= 5,
        ),
      ],
      controlsBuilder: (context, details) {
        // Hide controls for forms that handle their own submission
        if (_currentStep > 0) {
          return const SizedBox.shrink();
        }
        
        return Row(
          children: [
            if (_currentStep > 0)
              TextButton(
                onPressed: details.onStepCancel,
                child: const Text('Back'),
              ),
            const SizedBox(width: 12),
          ],
        );
      },
    );
  }
}

// Form for Step 2: Measurements
class _MeasurementsForm extends StatefulWidget {
  final Function(int?, double?, double?) onSave;
  final int? initialAge;
  final double? initialHeight;
  final double? initialWeight;
  
  const _MeasurementsForm({
    required this.onSave,
    this.initialAge,
    this.initialHeight,
    this.initialWeight,
  });

  @override
  State<_MeasurementsForm> createState() => _MeasurementsFormState();
}

class _MeasurementsFormState extends State<_MeasurementsForm> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ageController.text = widget.initialAge?.toString() ?? '';
    _heightController.text = widget.initialHeight?.toString() ?? '';
    _weightController.text = widget.initialWeight?.toString() ?? '';
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    final age = _ageController.text.isNotEmpty 
        ? int.tryParse(_ageController.text) 
        : null;
    final height = _heightController.text.isNotEmpty 
        ? double.tryParse(_heightController.text) 
        : null;
    final weight = _weightController.text.isNotEmpty 
        ? double.tryParse(_weightController.text) 
        : null;
    
    widget.onSave(age, height, weight);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'These measurements help us personalize your experience',
            style: AppTextStyles.small,
          ),
          const SizedBox(height: 16),
          
          // Age
          TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(
              labelText: 'Age',
              helperText: 'Optional',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final age = int.tryParse(value);
                if (age == null || age < 13 || age > 100) {
                  return 'Please enter a valid age between 13-100';
                }
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Height
          TextFormField(
            controller: _heightController,
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              helperText: 'Optional',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final height = double.tryParse(value);
                if (height == null || height < 120 || height > 220) {
                  return 'Please enter a valid height';
                }
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Weight
          TextFormField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              helperText: 'Optional',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final weight = double.tryParse(value);
                if (weight == null || weight < 30 || weight > 250) {
                  return 'Please enter a valid weight';
                }
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          PrimaryButton(
            text: 'Continue',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// Form for Step 3: Goals
class _GoalsSelectionForm extends StatefulWidget {
  final Function(List<FitnessGoal>) onSave;
  final List<FitnessGoal> initialGoals;
  
  const _GoalsSelectionForm({
    required this.onSave,
    required this.initialGoals,
  });

  @override
  State<_GoalsSelectionForm> createState() => _GoalsSelectionFormState();
}

class _GoalsSelectionFormState extends State<_GoalsSelectionForm> {
  late List<FitnessGoal> _selectedGoals;

  @override
  void initState() {
    super.initState();
    _selectedGoals = List.from(widget.initialGoals);
  }

  void _toggleGoal(FitnessGoal goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
      } else {
        _selectedGoals.add(goal);
      }
    });
  }

  void _submit() {
    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one goal'),
        ),
      );
      return;
    }
    
    widget.onSave(_selectedGoals);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What are your fitness goals?',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 8),
        Text(
          'Select all that apply',
          style: AppTextStyles.small,
        ),
        const SizedBox(height: 16),
        
        // Goal options
        for (final goal in FitnessGoal.values)
          _GoalOption(
            goal: goal,
            isSelected: _selectedGoals.contains(goal),
            onToggle: () => _toggleGoal(goal),
          ),
        
        const SizedBox(height: 24),
        
        PrimaryButton(
          text: 'Continue',
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _GoalOption extends StatelessWidget {
  final FitnessGoal goal;
  final bool isSelected;
  final VoidCallback onToggle;
  
  const _GoalOption({
    required this.goal,
    required this.isSelected,
    required this.onToggle,
  });

  String get _goalName {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.toning:
        return 'Toning';
      case FitnessGoal.strength:
        return 'Strength';
      case FitnessGoal.endurance:
        return 'Endurance';
      case FitnessGoal.flexibility:
        return 'Flexibility';
    }
  }

  IconData get _goalIcon {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return Icons.fitness_center;
      case FitnessGoal.toning:
        return Icons.accessibility_new;
      case FitnessGoal.strength:
        return Icons.sports_gymnastics;
      case FitnessGoal.endurance:
        return Icons.directions_run;
      case FitnessGoal.flexibility:
        return Icons.self_improvement;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? AppColors.salmon.withOpacity(0.1) : null,
      elevation: isSelected ? 2 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? const BorderSide(color: AppColors.salmon, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _goalIcon,
                color: isSelected ? AppColors.salmon : AppColors.darkGrey,
              ),
              const SizedBox(width: 16),
              Text(
                _goalName,
                style: AppTextStyles.body.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : null,
                  color: isSelected ? AppColors.salmon : null,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.salmon,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Form for Step 4: Fitness Level
class _FitnessLevelForm extends StatefulWidget {
  final Function(FitnessLevel) onSave;
  final FitnessLevel initialLevel;
  
  const _FitnessLevelForm({
    required this.onSave,
    required this.initialLevel,
  });

  @override
  State<_FitnessLevelForm> createState() => _FitnessLevelFormState();
}

class _FitnessLevelFormState extends State<_FitnessLevelForm> {
  late FitnessLevel _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel;
  }

  void _selectLevel(FitnessLevel level) {
    setState(() {
      _selectedLevel = level;
    });
  }

  void _submit() {
    widget.onSave(_selectedLevel);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'What\'s your fitness level?',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 16),
        
        // Fitness level options
        for (final level in FitnessLevel.values)
          _LevelOption(
            level: level,
            isSelected: _selectedLevel == level,
            onSelect: () => _selectLevel(level),
          ),
        
        const SizedBox(height: 24),
        
        PrimaryButton(
          text: 'Continue',
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _LevelOption extends StatelessWidget {
  final FitnessLevel level;
  final bool isSelected;
  final VoidCallback onSelect;
  
  const _LevelOption({
    required this.level,
    required this.isSelected,
    required this.onSelect,
  });

  String get _levelName {
    switch (level) {
      case FitnessLevel.beginner:
        return 'Beginner';
      case FitnessLevel.intermediate:
        return 'Intermediate';
      case FitnessLevel.advanced:
        return 'Advanced';
    }
  }

  String get _levelDescription {
    switch (level) {
      case FitnessLevel.beginner:
        return 'New to fitness or returning after a break';
      case FitnessLevel.intermediate:
        return 'Regular exerciser with some experience';
      case FitnessLevel.advanced:
        return 'Experienced with challenging workouts';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? AppColors.salmon.withOpacity(0.1) : null,
      elevation: isSelected ? 2 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? const BorderSide(color: AppColors.salmon, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _levelName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.salmon : null,
                    ),
                  ),
                  const Spacer(),
                  Radio<bool>(
                    value: true,
                    groupValue: isSelected,
                    onChanged: (_) => onSelect(),
                    activeColor: AppColors.salmon,
                  ),
                ],
              ),
              Text(
                _levelDescription,
                style: AppTextStyles.small,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Form for Step 5: Body Focus Areas
class _BodyFocusForm extends StatefulWidget {
  final Function(List<String>) onSave;
  final List<String> initialAreas;
  
  const _BodyFocusForm({
    required this.onSave,
    required this.initialAreas,
  });

  @override
  State<_BodyFocusForm> createState() => _BodyFocusFormState();
}

class _BodyFocusFormState extends State<_BodyFocusForm> {
  late List<String> _selectedAreas;

  final List<String> _availableAreas = [
    'Abs',
    'Glutes',
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

  void _toggleArea(String area) {
    setState(() {
      if (_selectedAreas.contains(area)) {
        _selectedAreas.remove(area);
      } else {
        _selectedAreas.add(area);
      }
    });
  }

  void _submit() {
    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one area'),
        ),
      );
      return;
    }
    
    widget.onSave(_selectedAreas);
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
        Text(
          'Select all that apply',
          style: AppTextStyles.small,
        ),
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableAreas.map((area) {
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
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        
        PrimaryButton(
          text: 'Continue',
          onPressed: _submit,
        ),
      ],
    );
  }
}

// Form for Step 6: Dietary Preferences
class _DietaryPreferencesForm extends StatefulWidget {
  final Function(List<String>) onSave;
  final List<String> initialPreferences;
  final bool isLoading;
  
  const _DietaryPreferencesForm({
    required this.onSave,
    required this.initialPreferences,
    required this.isLoading,
  });

  @override
  State<_DietaryPreferencesForm> createState() => _DietaryPreferencesFormState();
}

class _DietaryPreferencesFormState extends State<_DietaryPreferencesForm> {
  late List<String> _selectedPreferences;

  final List<String> _availablePreferences = [
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Gluten-Free',
    'Dairy-Free',
    'Keto',
    'Paleo',
    'Low-Carb',
    'Low-Fat',
    'High-Protein',
    'No Restrictions',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPreferences = List.from(widget.initialPreferences);
  }

  void _togglePreference(String preference) {
    setState(() {
      if (_selectedPreferences.contains(preference)) {
        _selectedPreferences.remove(preference);
      } else {
        _selectedPreferences.add(preference);
      }
    });
  }

  void _submit() {
    widget.onSave(_selectedPreferences);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Do you have any dietary preferences?',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 8),
        Text(
          'Select all that apply (optional)',
          style: AppTextStyles.small,
        ),
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availablePreferences.map((pref) {
            final isSelected = _selectedPreferences.contains(pref);
            return FilterChip(
              label: Text(pref),
              selected: isSelected,
              onSelected: (_) => _togglePreference(pref),
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
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        
        PrimaryButton(
          text: 'Complete Setup',
          onPressed: _submit,
          isLoading: widget.isLoading,
        ),
      ],
    );
  }
}