// lib/features/auth/widgets/onboarding/steps/health_and_diet_step.dart
import 'package:flutter/material.dart';
import '../../../../../shared/theme/color_palette.dart';
import '../../../../../shared/theme/text_styles.dart';

class HealthAndDietStep extends StatefulWidget {
  final List<String> initialConditions;
  final List<String> initialAllergies;
  final List<String> initialDietaryPreferences;
  final Function(List<String>, List<String>, List<String>) onNext;
  final Function(List<String>)? onConditionsChanged; // Add these
  final Function(List<String>)? onAllergiesChanged;
  final Function(List<String>)? onDietaryPreferencesChanged;

  const HealthAndDietStep({
    super.key,
    required this.initialConditions,
    required this.initialAllergies,
    required this.initialDietaryPreferences,
    required this.onNext,
    this.onConditionsChanged,
    this.onAllergiesChanged,
    this.onDietaryPreferencesChanged,
  });

  @override
  State<HealthAndDietStep> createState() => _HealthAndDietStepState();
}

class _HealthAndDietStepState extends State<HealthAndDietStep> {
  late List<String> _selectedConditions;
  late List<String> _selectedAllergies;
  late List<String> _selectedDietaryPreferences;
  final _customConditionController = TextEditingController();
  final _customAllergyController = TextEditingController();
  final _customDietaryController = TextEditingController();
  bool _isAddingCondition = false;
  bool _isAddingAllergy = false;
  bool _isAddingDietary = false;
  bool _hasAcceptedDisclaimer = false;

  final List<String> _commonConditions = [
    'Pregnancy',
    'Back Pain',
    'Knee Issues',
    'Shoulder Pain',
    'Heart Condition',
    'Asthma',
    'Diabetes',
    'High Blood Pressure',
    'None',
  ];

  final List<String> _commonAllergies = [
    'Peanuts',
    'Tree Nuts',
    'Dairy',
    'Egg',
    'Wheat',
    'Soy',
    'Seafood',
    'None',
  ];

  final List<String> _commonDietaryPreferences = [
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
    _selectedConditions = List.from(widget.initialConditions);
    _selectedAllergies = List.from(widget.initialAllergies);
    _selectedDietaryPreferences = List.from(widget.initialDietaryPreferences);
  }

  @override
  void dispose() {
    _customConditionController.dispose();
    _customAllergyController.dispose();
    _customDietaryController.dispose();
    super.dispose();
  }

  bool _isCustomCondition(String condition) {
    return !_commonConditions.contains(condition);
  }

  bool _isCustomAllergy(String allergy) {
    return !_commonAllergies.contains(allergy);
  }

  bool _isCustomDietaryPreference(String preference) {
    return !_commonDietaryPreferences.contains(preference);
  }

  void _removeCustomCondition(String condition) {
    setState(() {
      _selectedConditions.remove(condition);
    });
  }

  void _removeCustomAllergy(String allergy) {
    setState(() {
      _selectedAllergies.remove(allergy);
    });
  }

  void _removeCustomDietaryPreference(String preference) {
    setState(() {
      _selectedDietaryPreferences.remove(preference);
    });
  }

  void _toggleCondition(String condition) {
    setState(() {
      if (_selectedConditions.contains(condition)) {
        _selectedConditions.remove(condition);
      } else {
        if (condition == 'None') {
          _selectedConditions = ['None'];
        } else {
          _selectedConditions.remove('None');
          _selectedConditions.add(condition);
        }
      }

      // Call onConditionsChanged if available
      if (widget.onConditionsChanged != null) {
        widget.onConditionsChanged!(_selectedConditions);
      }
    });
  }

  void _toggleAllergy(String allergy) {
    setState(() {
      if (_selectedAllergies.contains(allergy)) {
        _selectedAllergies.remove(allergy);
      } else {
        if (allergy == 'None') {
          _selectedAllergies = ['None'];
        } else {
          _selectedAllergies.remove('None');
          _selectedAllergies.add(allergy);
        }
      }

      print("Selected allergies: $_selectedAllergies");

      // Call onAllergiesChanged if available
      if (widget.onAllergiesChanged != null) {
        widget.onAllergiesChanged!(_selectedAllergies);
      }
    });
  }

  void _toggleDietaryPreference(String preference) {
    setState(() {
      if (_selectedDietaryPreferences.contains(preference)) {
        _selectedDietaryPreferences.remove(preference);
      } else {
        if (preference == 'No Restrictions') {
          _selectedDietaryPreferences = ['No Restrictions'];
        } else {
          _selectedDietaryPreferences.remove('No Restrictions');
          _selectedDietaryPreferences.add(preference);
        }
      }

      print("Selected dietary preferences: $_selectedDietaryPreferences");

      // Call onDietaryPreferencesChanged if available
      if (widget.onDietaryPreferencesChanged != null) {
        widget.onDietaryPreferencesChanged!(_selectedDietaryPreferences);
      }
    });
  }

  void _addCustomCondition() {
    final condition = _customConditionController.text.trim();
    if (condition.isNotEmpty) {
      setState(() {
        _selectedConditions.remove('None');
        _selectedConditions.add(condition);
        _customConditionController.clear();
        _isAddingCondition = false;
      });
    }
  }

  void _addCustomAllergy() {
    final allergy = _customAllergyController.text.trim();
    if (allergy.isNotEmpty) {
      setState(() {
        _selectedAllergies.remove('None');
        _selectedAllergies.add(allergy);
        _customAllergyController.clear();
        _isAddingAllergy = false;
      });
    }
  }

  void _addCustomDietaryPreference() {
    final preference = _customDietaryController.text.trim();
    if (preference.isNotEmpty) {
      setState(() {
        _selectedDietaryPreferences.remove('No Restrictions');
        _selectedDietaryPreferences.add(preference);
        _customDietaryController.clear();
        _isAddingDietary = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Privacy Disclaimer
            Container(
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.popBlue.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.popBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Privacy Information',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.popBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bums \'n\' Tums uses AI to provide personalized workouts and nutrition advice. '
                    'The information you provide here helps us tailor recommendations to your needs. '
                    'Your health data is stored securely and never shared with third parties or external AI systems.',
                    style: AppTextStyles.small,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _hasAcceptedDisclaimer,
                        onChanged: (value) {
                          setState(() {
                            _hasAcceptedDisclaimer = value ?? false;
                          });
                        },
                        activeColor: AppColors.popBlue,
                      ),
                      Expanded(
                        child: Text(
                          'I understand how my data will be used to personalize my experience',
                          style: AppTextStyles.small,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Health conditions section
            Text('Health Considerations', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Do you have any health conditions we should know about?',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 4),
            Text(
              'This helps us tailor workouts for your safety',
              style: AppTextStyles.small,
            ),
            const SizedBox(height: 16),

            // Health conditions selection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._commonConditions.map((condition) {
                  final isSelected = _selectedConditions.contains(condition);
                  return FilterChip(
                    label: Text(condition),
                    selected: isSelected,
                    onSelected: (_) => _toggleCondition(condition),
                    backgroundColor: AppColors.offWhite,
                    selectedColor: AppColors.salmon.withOpacity(0.2),
                    checkmarkColor: AppColors.salmon,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.salmon : AppColors.darkGrey,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.salmon : Colors.transparent,
                    ),
                  );
                }),

                // Custom conditions with delete option
                ..._selectedConditions.where(_isCustomCondition).map((
                  condition,
                ) {
                  return Chip(
                    label: Text(condition),
                    backgroundColor: AppColors.salmon.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: AppColors.salmon,
                      fontWeight: FontWeight.bold,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeCustomCondition(condition),
                    deleteIconColor: AppColors.salmon,
                  );
                }),
              ],
            ),
            // Custom condition input
            if (_isAddingCondition)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customConditionController,
                        decoration: const InputDecoration(
                          hintText: 'Enter health condition',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.salmon),
                      onPressed: _addCustomCondition,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _customConditionController.clear();
                          _isAddingCondition = false;
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
                  label: const Text('Add custom condition'),
                  onPressed: () {
                    setState(() {
                      _isAddingCondition = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.salmon,
                  ),
                ),
              ),

            const Divider(height: 32),

            // Allergies section
            Text('Food Allergies', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Do you have any food allergies or intolerances?',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),

            // Allergies selection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._commonAllergies.map((allergy) {
                  final isSelected = _selectedAllergies.contains(allergy);
                  return FilterChip(
                    label: Text(allergy),
                    selected: isSelected,
                    onSelected: (_) => _toggleAllergy(allergy),
                    backgroundColor: AppColors.offWhite,
                    selectedColor: AppColors.popGreen.withOpacity(0.2),
                    checkmarkColor: AppColors.popGreen,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? AppColors.popGreen : AppColors.darkGrey,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color:
                          isSelected ? AppColors.popGreen : Colors.transparent,
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

            // Custom allergy input
            if (_isAddingAllergy)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customAllergyController,
                        decoration: const InputDecoration(
                          hintText: 'Enter food allergy',
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
                  label: const Text('Add custom allergy'),
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
            Text('Dietary Preferences', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'What eating patterns do you follow?',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),

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
                      color:
                          isSelected
                              ? AppColors.popTurquoise
                              : AppColors.darkGrey,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color:
                          isSelected
                              ? AppColors.popTurquoise
                              : Colors.transparent,
                    ),
                  );
                }),

                // Custom dietary preferences with delete option
                ..._selectedDietaryPreferences
                    .where(_isCustomDietaryPreference)
                    .map((pref) {
                      return Chip(
                        label: Text(pref),
                        backgroundColor: AppColors.popTurquoise.withOpacity(
                          0.2,
                        ),
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
                      icon: const Icon(
                        Icons.check,
                        color: AppColors.popTurquoise,
                      ),
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
