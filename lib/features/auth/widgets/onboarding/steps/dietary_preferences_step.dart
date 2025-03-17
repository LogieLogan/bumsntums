// lib/features/auth/widgets/onboarding/steps/dietary_preferences_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';

class DietaryPreferencesStep extends StatefulWidget {
  final List<String> initialAllergies;
  final List<String> initialDietaryPreferences;
  final Function(List<String>, List<String>) onNext;
  final Function(List<String>)? onAllergiesChanged;
  final Function(List<String>)? onDietaryPreferencesChanged;

  const DietaryPreferencesStep({
    super.key,
    required this.initialAllergies,
    required this.initialDietaryPreferences,
    required this.onNext,
    this.onAllergiesChanged,
    this.onDietaryPreferencesChanged,
  });

  @override
  State<DietaryPreferencesStep> createState() => _DietaryPreferencesStepState();
}

class _DietaryPreferencesStepState extends State<DietaryPreferencesStep> {
  late List<String> _selectedAllergies;
  late List<String> _selectedDietaryPreferences;
  final _customAllergyController = TextEditingController();
  final _customDietaryController = TextEditingController();
  bool _isAddingAllergy = false;
  bool _isAddingDietary = false;

  final List<String> _commonExclusions = [
    'None',
    'Peanuts',
    'Tree Nuts',
    'Dairy',
    'Egg',
    'Wheat',
    'Gluten',
    'Soy',
    'Fish',
    'Shellfish',
  ];

  final List<String> _commonDietaryPreferences = [
    'Free style (anything)',
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
  ];

  @override
  void initState() {
    super.initState();
    _selectedAllergies = List.from(widget.initialAllergies);
    _selectedDietaryPreferences = List.from(widget.initialDietaryPreferences);
    
    // Set default "None" option if nothing is selected
    if (_selectedAllergies.isEmpty) {
      _selectedAllergies = ['None'];
    }
    
    if (_selectedDietaryPreferences.isEmpty) {
      _selectedDietaryPreferences = ['Free style (anything)'];
    }
  }

  @override
  void dispose() {
    _customAllergyController.dispose();
    _customDietaryController.dispose();
    super.dispose();
  }

  bool _isCustomAllergy(String allergy) {
    return !_commonExclusions.contains(allergy);
  }

  bool _isCustomDietaryPreference(String preference) {
    return !_commonDietaryPreferences.contains(preference);
  }

  void _removeCustomAllergy(String allergy) {
    setState(() {
      _selectedAllergies.remove(allergy);
      if (_selectedAllergies.isEmpty) {
        _selectedAllergies = ['None'];
      }
      
      if (widget.onAllergiesChanged != null) {
        widget.onAllergiesChanged!(_selectedAllergies);
      }
    });
  }

  void _removeCustomDietaryPreference(String preference) {
    setState(() {
      _selectedDietaryPreferences.remove(preference);
      if (_selectedDietaryPreferences.isEmpty) {
        _selectedDietaryPreferences = ['None'];
      }
      
      if (widget.onDietaryPreferencesChanged != null) {
        widget.onDietaryPreferencesChanged!(_selectedDietaryPreferences);
      }
    });
  }

  void _toggleAllergy(String allergy) {
    setState(() {
      if (_selectedAllergies.contains(allergy)) {
        _selectedAllergies.remove(allergy);
        if (_selectedAllergies.isEmpty) {
          _selectedAllergies = ['None'];
        }
      } else {
        if (allergy == 'None') {
          _selectedAllergies = ['None'];
        } else {
          _selectedAllergies.remove('None');
          _selectedAllergies.add(allergy);
        }
      }

      if (widget.onAllergiesChanged != null) {
        widget.onAllergiesChanged!(_selectedAllergies);
      }
    });
  }

  void _toggleDietaryPreference(String preference) {
    setState(() {
      if (_selectedDietaryPreferences.contains(preference)) {
        _selectedDietaryPreferences.remove(preference);
        if (_selectedDietaryPreferences.isEmpty) {
          _selectedDietaryPreferences = ['Free style (anything)'];
        }
      } else {
        if (preference == 'Free style (anything)') {
          _selectedDietaryPreferences = ['Free style (anything)'];
        } else {
          _selectedDietaryPreferences.remove('Free style (anything)');
          _selectedDietaryPreferences.add(preference);
        }
      }

      if (widget.onDietaryPreferencesChanged != null) {
        widget.onDietaryPreferencesChanged!(_selectedDietaryPreferences);
      }
    });
  }

  void _addCustomAllergy() {
    final allergy = _customAllergyController.text.trim();
    if (allergy.isNotEmpty) {
      setState(() {
        _selectedAllergies.remove('None');
        _selectedAllergies.add(allergy);
        _customAllergyController.clear();
        _isAddingAllergy = false;
        
        if (widget.onAllergiesChanged != null) {
          widget.onAllergiesChanged!(_selectedAllergies);
        }
      });
    }
  }

  void _addCustomDietaryPreference() {
    final preference = _customDietaryController.text.trim();
    if (preference.isNotEmpty) {
      setState(() {
        _selectedDietaryPreferences.remove('None');
        _selectedDietaryPreferences.add(preference);
        _customDietaryController.clear();
        _isAddingDietary = false;
        
        if (widget.onDietaryPreferencesChanged != null) {
          widget.onDietaryPreferencesChanged!(_selectedDietaryPreferences);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Dietary Preferences', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'This helps us tailor your nutrition advice and recommendations.',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 24),

            // Food Exclusions section
            Text('Do you have any food exclusions?', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Including allergies, intolerances or foods you avoid',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 12),

            // Food exclusions selection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._commonExclusions.map((allergy) {
                  final isSelected = _selectedAllergies.contains(allergy);
                  return FilterChip(
                    label: Text(allergy),
                    selected: isSelected,
                    onSelected: (_) => _toggleAllergy(allergy),
                    backgroundColor: AppColors.offWhite,
                    selectedColor: AppColors.popGreen.withOpacity(0.2),
                    checkmarkColor: AppColors.popGreen,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.popGreen : AppColors.darkGrey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.popGreen : Colors.transparent,
                    ),
                  );
                }),

                // Custom allergies with delete option
                ..._selectedAllergies.where(_isCustomAllergy).map((allergy) {
                  return Chip(
                    label: Text(allergy),
                    backgroundColor: AppColors.popGreen.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: AppColors.popGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeCustomAllergy(allergy),
                    deleteIconColor: AppColors.popGreen,
                  );
                }),
              ],
            ),

            // Custom exclusion input
            if (_isAddingAllergy)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customAllergyController,
                        decoration: const InputDecoration(
                          hintText: 'Enter food exclusion',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.popGreen),
                      onPressed: _addCustomAllergy,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _customAllergyController.clear();
                          _isAddingAllergy = false;
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
                  label: const Text('Add custom exclusion'),
                  onPressed: () {
                    setState(() {
                      _isAddingAllergy = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.popGreen,
                  ),
                ),
              ),

            const Divider(height: 32),

            // Dietary Preferences section
            Text('What eating style do you follow?', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Dietary preferences selection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._commonDietaryPreferences.map((pref) {
                  final isSelected = _selectedDietaryPreferences.contains(pref);
                  return FilterChip(
                    label: Text(pref),
                    selected: isSelected,
                    onSelected: (_) => _toggleDietaryPreference(pref),
                    backgroundColor: AppColors.offWhite,
                    selectedColor: AppColors.popTurquoise.withOpacity(0.2),
                    checkmarkColor: AppColors.popTurquoise,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.popTurquoise : AppColors.darkGrey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.popTurquoise : Colors.transparent,
                    ),
                  );
                }),

                // Custom dietary preferences with delete option
                ..._selectedDietaryPreferences
                    .where(_isCustomDietaryPreference)
                    .map((pref) {
                      return Chip(
                        label: Text(pref),
                        backgroundColor: AppColors.popTurquoise.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: AppColors.popTurquoise,
                          fontWeight: FontWeight.bold,
                        ),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeCustomDietaryPreference(pref),
                        deleteIconColor: AppColors.popTurquoise,
                      );
                    }),
              ],
            ),

            // Custom dietary preference input
            if (_isAddingDietary)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customDietaryController,
                        decoration: const InputDecoration(
                          hintText: 'Enter dietary preference',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.popTurquoise),
                      onPressed: _addCustomDietaryPreference,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _customDietaryController.clear();
                          _isAddingDietary = false;
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
                  label: const Text('Add custom preference'),
                  onPressed: () {
                    setState(() {
                      _isAddingDietary = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.popTurquoise,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}