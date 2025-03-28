// lib/features/auth/screens/edit_profile_screen.dart
import 'package:bums_n_tums/features/auth/widgets/onboarding/steps/capability_questionnaire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../models/user_profile.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/buttons/secondary_button.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _analyticsService = AnalyticsService();

  // Form controllers
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _dateOfBirth;

  // Multi-select values
  List<FitnessGoal> _selectedGoals = [];
  List<String> _selectedBodyFocusAreas = [];
  List<String> _selectedDietaryPreferences = [];
  List<String> _selectedAllergies = [];
  List<String> _selectedHealthConditions = [];
  List<MotivationType> _selectedMotivations = [];
  String? _customMotivation;

  // Dropdown values
  FitnessLevel _selectedFitnessLevel = FitnessLevel.beginner;
  WorkoutLocation? _selectedWorkoutLocation;
  int? _weeklyWorkoutDays;
  int? _workoutDurationMinutes;

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView(screenName: 'edit_profile_screen');

    // Load user data when screen initializes
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    final userProfile = await ref.read(userProfileProvider.future);

    if (userProfile == null) {
      return;
    }

    print("Loaded health conditions: ${userProfile.healthConditions}");

    // Get display name from Firestore
    String displayName = 'Fitness Friend';
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users_personal_info')
              .doc(userProfile.userId)
              .get();
      if (doc.exists && doc.data() != null) {
        displayName = doc.data()!['displayName'] ?? 'Fitness Friend';
      }
    } catch (e) {
      print('Error fetching display name: $e');
    }

    setState(() {
      _nameController.text = displayName;
      _heightController.text = userProfile.heightCm?.toString() ?? '';
      _weightController.text = userProfile.weightKg?.toString() ?? '';
      _dateOfBirth = userProfile.dateOfBirth;

      _selectedGoals = List.from(userProfile.goals);
      _selectedBodyFocusAreas = List.from(userProfile.bodyFocusAreas);
      _selectedDietaryPreferences = List.from(userProfile.dietaryPreferences);
      _selectedAllergies = List.from(userProfile.allergies);
      _selectedHealthConditions = List.from(userProfile.healthConditions);
      _selectedMotivations = List.from(userProfile.motivations);
      _customMotivation = userProfile.customMotivation;

      _selectedFitnessLevel = userProfile.fitnessLevel;
      _selectedWorkoutLocation = userProfile.preferredLocation;
      _weeklyWorkoutDays = userProfile.weeklyWorkoutDays;
      _workoutDurationMinutes = userProfile.workoutDurationMinutes;
    });
  }

  void _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print("Starting profile update process");

      // First get the current profile
      final currentProfile = await ref.read(userProfileProvider.future);
      if (currentProfile == null) {
        throw Exception('Failed to load user profile');
      }

      print("Current profile loaded, user ID: ${currentProfile.userId}");
      print("Creating updated profile with new values");

      // Parse values safely
      double? heightCm;
      if (_heightController.text.isNotEmpty) {
        try {
          heightCm = double.parse(_heightController.text);
          print("Parsed height: $heightCm");
        } catch (e) {
          print("Error parsing height: ${_heightController.text}");
        }
      }

      double? weightKg;
      if (_weightController.text.isNotEmpty) {
        try {
          weightKg = double.parse(_weightController.text);
          print("Parsed weight: $weightKg");
        } catch (e) {
          print("Error parsing weight: ${_weightController.text}");
        }
      }

      print("Health conditions being saved: $_selectedHealthConditions");

      // Create updated profile with explicit values
      final updatedProfile = currentProfile.copyWith(
        dateOfBirth: _dateOfBirth,
        heightCm: heightCm,
        weightKg: weightKg,
        goals: _selectedGoals,
        fitnessLevel: _selectedFitnessLevel,
        dietaryPreferences: _selectedDietaryPreferences,
        bodyFocusAreas: _selectedBodyFocusAreas,
        preferredLocation: _selectedWorkoutLocation,
        weeklyWorkoutDays: _weeklyWorkoutDays,
        workoutDurationMinutes: _workoutDurationMinutes,
        healthConditions: _selectedHealthConditions,
        allergies: _selectedAllergies,
        motivations: _selectedMotivations,
        customMotivation: _customMotivation,
      );

      print("Calling updateProfile on userProfileNotifier");

      // Update profile in Firestore via notifier
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateProfile(updatedProfile);

      print("Profile updated successfully in Firestore");

      // Update display name in Firestore - personal info
      if (_nameController.text.trim().isNotEmpty) {
        print("Updating display name: ${_nameController.text.trim()}");

        try {
          final userService = ref.read(userProfileServiceProvider);
          await userService.updateDisplayName(
            currentProfile.userId,
            _nameController.text.trim(),
          );
          print("Display name updated successfully");
        } catch (e) {
          print("Error updating display name: $e");
          // Continue even if display name update fails
        }
      }

      // Log analytics event
      try {
        print("Logging analytics event");
        await _analyticsService.logEvent(
          name: 'profile_updated',
          parameters: {'user_id': currentProfile.userId},
        );
        print("Analytics event logged");
      } catch (e) {
        print("Error logging analytics event: $e");
        // Continue even if analytics fails
      }

      // Refresh the user profile provider to make sure the UI updates
      print("Refreshing user profile provider");
      final _ =  ref.refresh(userProfileProvider);

      // Show success message and navigate back
      if (mounted) {
        print("Showing success message and returning to profile");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("ERROR in _updateProfile: $e");
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_hasChanges) return true;

        // Show confirmation dialog
        final result = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Discard Changes?'),
                content: const Text(
                  'You have unsaved changes. Are you sure you want to discard them?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Discard'),
                  ),
                ],
              ),
        );

        return result ?? false;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: Form(
          key: _formKey,
          onChanged: () {
            if (!_hasChanges) {
              setState(() {
                _hasChanges = true;
              });
            }
          },
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBasicInfoSection(),
                        const SizedBox(height: 24),
                        _buildGoalsSection(),
                        const SizedBox(height: 24),
                        _buildBodyFocusSection(),
                        const SizedBox(height: 24),
                        _buildDietarySection(),
                        const SizedBox(height: 24),
                        _buildHealthSection(),
                        const SizedBox(height: 24),
                        _buildWorkoutSettingsSection(),
                        const SizedBox(height: 24),
                        _buildMotivationSection(),
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  // Build methods for each section...
  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Your preferred name',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date of Birth',
              hintText: 'Select your date of birth',
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _dateOfBirth == null
                  ? 'Select your date of birth'
                  : DateFormat('MMM d, yyyy').format(_dateOfBirth!),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  hintText: 'Your height in cm',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final height = double.tryParse(value);
                    if (height == null || height <= 0) {
                      return 'Please enter a valid height';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: 'Your weight in kg',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0) {
                      return 'Please enter a valid weight';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fitness Goals', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              FitnessGoal.values.map((goal) {
                final isSelected = _selectedGoals.contains(goal);
                return ChoiceChip(
                  label: Text(goal.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGoals.add(goal);
                      } else {
                        _selectedGoals.remove(goal);
                      }
                    });
                  },
                  backgroundColor: AppColors.offWhite,
                  selectedColor: AppColors.salmon.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.salmon : AppColors.darkGrey,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<FitnessLevel>(
          decoration: const InputDecoration(labelText: 'Fitness Level'),
          value: _selectedFitnessLevel,
          items:
              FitnessLevel.values.map((level) {
                return DropdownMenuItem(value: level, child: Text(level.name));
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFitnessLevel = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildBodyFocusSection() {
    // Predefined body focus areas
    final bodyFocusOptions = [
      'Bums',
      'Tums',
      'Arms',
      'Legs',
      'Back',
      'Chest',
      'Full Body',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Body Focus Areas', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              bodyFocusOptions.map((area) {
                final isSelected = _selectedBodyFocusAreas.contains(area);
                return ChoiceChip(
                  label: Text(area),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedBodyFocusAreas.add(area);
                      } else {
                        _selectedBodyFocusAreas.remove(area);
                      }
                    });
                  },
                  backgroundColor: AppColors.offWhite,
                  selectedColor: AppColors.popTurquoise.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? AppColors.popTurquoise
                            : AppColors.darkGrey,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildDietarySection() {
    // Predefined dietary preferences
    final dietaryOptions = [
      'Vegetarian',
      'Vegan',
      'Pescatarian',
      'Gluten-Free',
      'Dairy-Free',
      'Keto',
      'Paleo',
      'Low-Carb',
      'High-Protein',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dietary Preferences', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              dietaryOptions.map((pref) {
                final isSelected = _selectedDietaryPreferences.contains(pref);
                return ChoiceChip(
                  label: Text(pref),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDietaryPreferences.add(pref);
                      } else {
                        _selectedDietaryPreferences.remove(pref);
                      }
                      _hasChanges = true;
                    });
                  },
                  backgroundColor: AppColors.offWhite,
                  selectedColor: AppColors.popGreen.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.popGreen : AppColors.darkGrey,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Other Dietary Preferences',
            hintText: 'Add any other dietary preferences separated by commas',
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              final additionalPrefs =
                  value
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
              setState(() {
                // Add new preferences but keep the predefined ones that are selected
                _selectedDietaryPreferences = [
                  ..._selectedDietaryPreferences.where(
                    (pref) => dietaryOptions.contains(pref),
                  ),
                  ...additionalPrefs,
                ];
                _hasChanges = true;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildHealthSection() {
    // Common allergens
    final allergyOptions = [
      'Nuts',
      'Dairy',
      'Eggs',
      'Soy',
      'Wheat',
      'Fish',
      'Shellfish',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Health Information', style: AppTextStyles.h3),
        const SizedBox(height: 16),

        // Allergies section
        Text(
          'Allergies',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              allergyOptions.map((allergy) {
                final isSelected = _selectedAllergies.contains(allergy);
                return ChoiceChip(
                  label: Text(allergy),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAllergies.add(allergy);
                      } else {
                        _selectedAllergies.remove(allergy);
                      }
                      _hasChanges = true;
                    });
                  },
                  backgroundColor: AppColors.offWhite,
                  selectedColor: AppColors.salmon.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.salmon : AppColors.darkGrey,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Other Allergies',
            hintText: 'Add any other allergies separated by commas',
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              final additionalAllergies =
                  value
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
              setState(() {
                _selectedAllergies = [
                  ..._selectedAllergies.where(
                    (allergy) => allergyOptions.contains(allergy),
                  ),
                  ...additionalAllergies,
                ];
                _hasChanges = true;
              });
            }
          },
        ),

        const SizedBox(height: 24),

        // Fitness capabilities section
        if (_selectedHealthConditions.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fitness Capabilities',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Display saved capability answers as a list
              ...List.generate(_selectedHealthConditions.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '• ${_selectedHealthConditions[index]}',
                    style: AppTextStyles.small,
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),

        // Button to update capability questionnaire
        OutlinedButton.icon(
          onPressed: () {
            _showCapabilityQuestionnaire();
          },
          icon: const Icon(Icons.fitness_center),
          label: const Text('Update Fitness Capabilities'),
        ),
      ],
    );
  }

  void _showCapabilityQuestionnaire() async {
    // Create list of capability questions
    List<CapabilityQuestion> questions = [
      CapabilityQuestion(
        question: 'Can you touch your toes without bending your knees?',
        options: [
          'Easily',
          'With some effort',
          'Not even close',
          'I prefer not to answer',
        ],
      ),
      CapabilityQuestion(
        question: 'How long could you jog or run without stopping?',
        options: [
          'I don\'t run',
          '5-10 minutes',
          '10-30 minutes',
          '30-60 minutes',
          '60+ minutes',
          'I prefer not to answer',
        ],
      ),
      CapabilityQuestion(
        question: 'How many push-ups can you do in one go?',
        options: [
          'None',
          '1-5',
          '6-10',
          '11-20',
          '20+',
          'I prefer not to answer',
        ],
      ),
      CapabilityQuestion(
        question:
            'Could you climb a few flights of stairs without getting winded?',
        options: [
          'Yes, easily',
          'Yes, but I\'d be a bit winded',
          'I\'d need to take breaks',
          'I avoid stairs',
          'I prefer not to answer',
        ],
      ),
      CapabilityQuestion(
        question:
            'How is your balance? Could you stand on one leg for 30 seconds?',
        options: [
          'Yes, with no problem',
          'Yes, but it\'s wobbly',
          'No, I\'d topple over',
          'I prefer not to answer',
        ],
      ),
      CapabilityQuestion(
        question: 'When you carry groceries or heavy items, how does it feel?',
        options: [
          'Easy, no problem',
          'Manageable but tiring',
          'Difficult, I avoid it',
          'I prefer not to answer',
        ],
      ),
      CapabilityQuestion(
        question:
            'If you needed to do 20 jumping jacks right now, how would that go?',
        options: [
          'Piece of cake!',
          'I\'d get through it',
          'I\'d struggle',
          'Not happening',
          'I prefer not to answer',
        ],
      ),
    ];

    // Pre-populate answers from existing health conditions
    for (String condition in _selectedHealthConditions) {
      if (condition.contains(": ")) {
        final parts = condition.split(": ");
        if (parts.length >= 2) {
          final questionText = parts[0];
          final answerText = parts.sublist(1).join(": ");

          for (int i = 0; i < questions.length; i++) {
            if (questions[i].question == questionText) {
              questions[i] = questions[i].copyWith(selectedOption: answerText);
              break;
            }
          }
        }
      }
    }

    final result = await showModalBottomSheet<List<Map<String, String?>>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Fitness Capabilities', style: AppTextStyles.h3),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            'Update your fitness capabilities to help us personalize your workouts.',
                            style: AppTextStyles.body,
                          ),
                          const SizedBox(height: 16),

                          // Display questions as cards
                          ...questions.map((question) {
                            return _buildQuestionCard(question, setState, (
                              newValue,
                            ) {
                              final index = questions.indexOf(question);
                              questions[index] = questions[index].copyWith(
                                selectedOption: newValue,
                              );
                            });
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Update Capabilities',
                    onPressed: () {
                      // Get data from the questionnaire
                      final answers =
                          questions
                              .where(
                                (q) =>
                                    q.selectedOption != null &&
                                    q.selectedOption !=
                                        'I prefer not to answer',
                              )
                              .map(
                                (q) => {
                                  'question': q.question,
                                  'answer': q.selectedOption,
                                },
                              )
                              .toList();
                      Navigator.pop(context, answers);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      // Convert answers to format for storage
      final formattedAnswers =
          result
              .where(
                (answer) =>
                    answer['question'] != null && answer['answer'] != null,
              )
              .map((answer) => "${answer['question']}: ${answer['answer']}")
              .toList();

      setState(() {
        _selectedHealthConditions = formattedAnswers;
        _hasChanges = true; // This is important to enable the save button
      });

      // Add explicit debug print
      print("Updated health conditions: $_selectedHealthConditions");
      print("Has changes set to true, save button should be enabled");
    }
  }

  Widget _buildQuestionCard(
    CapabilityQuestion question,
    StateSetter setState,
    Function(String) onSelect,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...question.options.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: question.selectedOption,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      onSelect(value);
                    });
                  }
                },
                activeColor: AppColors.popTurquoise,
                dense: true,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutSettingsSection() {
    // Define standard workout durations
    final standardDurations = [15, 20, 30, 45, 60];

    // Check if current duration is a standard one or custom
    final isCustomDuration =
        _workoutDurationMinutes != null &&
        !standardDurations.contains(_workoutDurationMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Workout Settings', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        DropdownButtonFormField<WorkoutLocation?>(
          decoration: const InputDecoration(
            labelText: 'Preferred Workout Location',
          ),
          value: _selectedWorkoutLocation,
          items: [
            const DropdownMenuItem<WorkoutLocation?>(
              value: null,
              child: Text('No preference'),
            ),
            ...WorkoutLocation.values.map((location) {
              return DropdownMenuItem(
                value: location,
                child: Text(location.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedWorkoutLocation = value;
              _hasChanges = true;
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          decoration: const InputDecoration(labelText: 'Weekly Workout Days'),
          value: _weeklyWorkoutDays,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Not specified'),
            ),
            ...[1, 2, 3, 4, 5, 6, 7].map((days) {
              return DropdownMenuItem(
                value: days,
                child: Text('$days ${days == 1 ? 'day' : 'days'} per week'),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _weeklyWorkoutDays = value;
              _hasChanges = true;
            });
          },
        ),
        const SizedBox(height: 16),

        // Handle custom workout duration properly
        isCustomDuration
            ? TextFormField(
              initialValue: _workoutDurationMinutes?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Workout Duration (minutes)',
                hintText: 'Enter custom duration',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _workoutDurationMinutes = int.tryParse(value);
                    _hasChanges = true;
                  });
                } else {
                  setState(() {
                    _workoutDurationMinutes = null;
                    _hasChanges = true;
                  });
                }
              },
            )
            : DropdownButtonFormField<int?>(
              decoration: const InputDecoration(
                labelText: 'Preferred Workout Duration',
              ),
              value: _workoutDurationMinutes,
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Not specified'),
                ),
                ...standardDurations.map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text('$minutes minutes'),
                  );
                }),
                const DropdownMenuItem<int?>(
                  value: -1, // Special value for "Custom"
                  child: Text('Custom duration'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == -1) {
                    // Switch to text input for custom duration
                    _workoutDurationMinutes = null;
                  } else {
                    _workoutDurationMinutes = value;
                  }
                  _hasChanges = true;
                });
              },
            ),
      ],
    );
  }

  Widget _buildMotivationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What Motivates You?', style: AppTextStyles.h3),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              MotivationType.values.map((motivation) {
                final isSelected = _selectedMotivations.contains(motivation);
                final motivationTitle = _getMotivationTitle(motivation);

                return ChoiceChip(
                  label: Text(motivationTitle),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedMotivations.add(motivation);
                      } else {
                        _selectedMotivations.remove(motivation);
                      }
                      _hasChanges = true;
                    });
                  },
                  backgroundColor: AppColors.offWhite,
                  selectedColor: AppColors.popYellow.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color:
                        isSelected ? AppColors.popYellow : AppColors.darkGrey,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
        if (_selectedMotivations.contains(MotivationType.other))
          TextFormField(
            initialValue: _customMotivation,
            decoration: const InputDecoration(
              labelText: 'Custom Motivation',
              hintText: 'Tell us what motivates you',
            ),
            onChanged: (value) {
              setState(() {
                _customMotivation = value;
                _hasChanges = true;
              });
            },
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            text: 'Save Changes',
            onPressed: _hasChanges ? _updateProfile : null,
            isLoading: _isLoading,
            isEnabled: _hasChanges,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: SecondaryButton(
            text: 'Cancel',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }

  // Helper methods
  Future<void> _selectDate(BuildContext context) async {
    final initialDate =
        _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18));
    final firstDate = DateTime(1900);
    final lastDate = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        _dateOfBirth = pickedDate;
        _hasChanges = true;
      });
    }
  }

  String _getMotivationTitle(MotivationType type) {
    switch (type) {
      case MotivationType.appearance:
        return 'Look Better';
      case MotivationType.health:
        return 'Health';
      case MotivationType.energy:
        return 'Energy';
      case MotivationType.stress:
        return 'Less Stress';
      case MotivationType.confidence:
        return 'Confidence';
      case MotivationType.other:
        return 'Other';
    }
  }
}
