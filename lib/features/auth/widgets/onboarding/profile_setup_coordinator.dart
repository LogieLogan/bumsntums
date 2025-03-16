// lib/features/auth/widgets/onboarding/profile_setup_coordinator.dart
import 'package:bums_n_tums/shared/theme/color_palette.dart';
import 'package:bums_n_tums/shared/theme/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';
import '../../../../shared/analytics/firebase_analytics_service.dart';
import 'steps/basic_info_step.dart';
import 'steps/measurements_step.dart';
import 'steps/goals_step.dart';
import 'steps/fitness_level_step.dart';
import 'steps/body_focus_step.dart';
import 'steps/workout_environment_step.dart';
import 'steps/health_and_diet_step.dart';
import 'steps/motivation_step.dart';
import 'components/step_progress_indicator.dart';

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
  final _scrollController = ScrollController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Create the controller
  final _basicInfoController = BasicInfoStepController();
  final _workoutEnvironmentController = WorkoutEnvironmentStepController();

  String? _validationError;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _basicInfoController.dispose();
    super.dispose();
  }

  void _clearValidationError() {
    if (_validationError != null) {
      setState(() {
        _validationError = null;
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _clearValidationError();

      // We don't need to extract data from widgets here
      // The data will be properly preserved if we collect it
      // at each forward step

      setState(() {
        _currentStep--;
      });
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _updateBasicInfo(String displayName) async {
    final userService = ref.read(userProfileServiceProvider);
    await userService.updateDisplayName(_profile.userId, displayName.trim());

    setState(() {
      _currentStep++;
    });
    _scrollToTop();
  }

  void _updateMeasurements(
    DateTime? dateOfBirth,
    double? height,
    double? weight,
  ) {
    print("Updating measurements:");
    print("Date of Birth: $dateOfBirth");
    print("Height: $height cm");
    print("Weight: $weight kg");

    setState(() {
      _profile = _profile.copyWith(
        dateOfBirth: dateOfBirth,
        heightCm: height,
        weightKg: weight,
      );

      print("Updated profile measurements:");
      print("Date of Birth: ${_profile.dateOfBirth}");
      print("Height: ${_profile.heightCm} cm");
      print("Weight: ${_profile.weightKg} kg");

      _currentStep++;
    });
    _scrollToTop();
  }

  void _updateGoals(List<FitnessGoal> goals) {
    print("Updating goals: ${goals.map((g) => g.name).join(', ')}");
    setState(() {
      _profile = _profile.copyWith(goals: goals);
      print(
        "Updated profile goals: ${_profile.goals.map((g) => g.name).join(', ')}",
      );
      _currentStep++;
    });
    _scrollToTop();
  }

  void _updateFitnessLevel(FitnessLevel level) {
    setState(() {
      _profile = _profile.copyWith(fitnessLevel: level);
      _currentStep++;
    });
    _scrollToTop();
  }

  void _updateBodyFocus(List<String> areas) {
    print("Updating body focus areas: ${areas.join(', ')}");
    setState(() {
      _profile = _profile.copyWith(bodyFocusAreas: areas);
      print(
        "Updated profile body focus areas: ${_profile.bodyFocusAreas.join(', ')}",
      );
      _currentStep++;
    });
    _scrollToTop();
  }

  void _updateWorkoutEnvironment(
    WorkoutLocation? location,
    List<String> equipment,
    int? weeklyDays,
    int? duration,
  ) {
    print("Updating workout environment:");
    print("Location: $location");
    print("Equipment: $equipment");
    print("Weekly Days: $weeklyDays");
    print("Duration: $duration");

    // Ensure we have proper lists with data
    final equipmentList = equipment.isEmpty ? ['No Equipment'] : equipment;

    setState(() {
      _profile = _profile.copyWith(
        preferredLocation: location,
        availableEquipment: List<String>.from(equipmentList),
        weeklyWorkoutDays: weeklyDays,
        workoutDurationMinutes: duration,
      );
      _currentStep++;
    });

    // Print updated profile to verify
    print("Updated profile:");
    print("Preferred Location: ${_profile.preferredLocation}");
    print("Equipment: ${_profile.availableEquipment}");
    print("Weekly Days: ${_profile.weeklyWorkoutDays}");
    print("Duration: ${_profile.workoutDurationMinutes}");

    _scrollToTop();
  }

  void _updateHealthAndDiet(
    List<String> conditions,
    List<String> allergies,
    List<String> dietaryPreferences,
  ) {
    print("Updating health and diet:");
    print("Conditions: ${conditions.join(', ')}");
    print("Allergies: ${allergies.join(', ')}");
    print("Dietary Preferences: ${dietaryPreferences.join(', ')}");

    // Filter out "None" values
    List<String> filteredConditions =
        conditions.contains('None') ? [] : List<String>.from(conditions);
    List<String> filteredAllergies =
        allergies.contains('None') ? [] : List<String>.from(allergies);
    List<String> filteredDietaryPreferences =
        dietaryPreferences.contains('No Restrictions')
            ? []
            : List<String>.from(dietaryPreferences);

    setState(() {
      _profile = _profile.copyWith(
        healthConditions: filteredConditions,
        allergies: filteredAllergies,
        dietaryPreferences: filteredDietaryPreferences,
        hasAcceptedPrivacyPolicy: true,
      );

      print("Updated profile:");
      print("Health Conditions: ${_profile.healthConditions.join(', ')}");
      print("Allergies: ${_profile.allergies.join(', ')}");
      print("Dietary Preferences: ${_profile.dietaryPreferences.join(', ')}");

      _currentStep++;
    });
    _scrollToTop();
  }

  void _updateMotivation(
    List<MotivationType> motivations,
    String? customMotivation,
  ) {
    print("Updating motivations: ${motivations.map((m) => m.name).join(', ')}");
    print("Custom motivation: $customMotivation");

    setState(() {
      _profile = _profile.copyWith(
        motivations: List<MotivationType>.from(motivations),
        customMotivation: customMotivation,
        onboardingCompleted: true,
      );

      print(
        "Updated profile motivations: ${_profile.motivations.map((m) => m.name).join(', ')}",
      );
      print("Updated profile custom motivation: ${_profile.customMotivation}");

      _submitProfile();
    });
  }

  Future<void> _submitProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("FINAL PROFILE DATA BEFORE SUBMISSION:");
      print("User ID: ${_profile.userId}");
      print("Goals Count: ${_profile.goals.length}");
      print("Goals: ${_profile.goals.map((g) => g.name).join(', ')}");
      print("Body Focus Areas Count: ${_profile.bodyFocusAreas.length}");
      print("Body Focus Areas: ${_profile.bodyFocusAreas.join(', ')}");
      print("Dietary Preferences Count: ${_profile.dietaryPreferences.length}");
      print("Dietary Preferences: ${_profile.dietaryPreferences.join(', ')}");
      print("Allergies Count: ${_profile.allergies.length}");
      print("Allergies: ${_profile.allergies.join(', ')}");
      print("Health Conditions Count: ${_profile.healthConditions.length}");
      print("Health Conditions: ${_profile.healthConditions.join(', ')}");
      print("Motivations Count: ${_profile.motivations.length}");
      print(
        "Motivations: ${_profile.motivations.map((m) => m.name).join(', ')}",
      );
      print("Custom Motivation: ${_profile.customMotivation}");
      print("Onboarding Completed: ${_profile.onboardingCompleted}");

      final userProfileNotifier = ref.read(
        userProfileNotifierProvider.notifier,
      );

      if (mounted) {
        await userProfileNotifier.updateProfile(_profile);

        // Track completion in analytics
        final analyticsService = AnalyticsService();
        analyticsService.logEvent(
          name: 'profile_setup_completed',
          parameters: {
            'has_weight': _profile.weightKg != null ? 'yes' : 'no',
            'has_height': _profile.heightCm != null ? 'yes' : 'no',
            'has_dob': _profile.dateOfBirth != null ? 'yes' : 'no',
            'fitness_level': _profile.fitnessLevel.name,
            'goals_count': _profile.goals.length,
            'has_health_conditions':
                _profile.healthConditions.isNotEmpty ? 'yes' : 'no',
            'has_allergies': _profile.allergies.isNotEmpty ? 'yes' : 'no',
            'has_motivations': _profile.motivations.isNotEmpty ? 'yes' : 'no',
            'has_accepted_privacy':
                _profile.hasAcceptedPrivacyPolicy ? 'yes' : 'no',
          },
        );

        // Call the onComplete callback to navigate away
        print("Profile setup completed, calling navigation callback");
        widget.onComplete(_profile);
      }
    } catch (e) {
      print('Profile setup error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    final totalSteps = 8;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: StepProgressIndicator(
                currentStep: _currentStep,
                totalSteps: totalSteps,
              ),
            ),

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildCurrentStep(),
              ),
            ),

            // Validation error messages
            if (_validationError != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),

      // Fixed bottom navigation area
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Actions for current step
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button or skip option
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: _goToPreviousStep,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                    )
                  else
                    const SizedBox(width: 80),

                  // Continue button
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                _currentStep == 7 ? 'Complete' : 'Continue',
                              ),
                    ),
                  ),
                ],
              ),
            ),

            // Skip option
            if (_currentStep < 7) // Don't show skip on last step
              TextButton(
                onPressed: _isLoading ? null : () => _handleSkip(),
                child: Text(
                  'Skip this step',
                  style: AppTextStyles.small.copyWith(
                    color: _isLoading ? AppColors.lightGrey : AppColors.popBlue,
                  ),
                ),
              ),
            const SizedBox(height: 8), // Bottom padding
          ],
        ),
      ),
    );
  }

  void _handleContinue() {
    _clearValidationError();

    switch (_currentStep) {
      case 0:
        if (_basicInfoController.canSubmit) {
          _basicInfoController.submitForm();
        } else {
          setState(() {
            _validationError = 'Please enter your name to continue';
          });
        }
        break;

      case 1:
        // For measurements step, we'll use current values (if any)
        _updateMeasurements(
          _profile.dateOfBirth,
          _profile.heightCm,
          _profile.weightKg,
        );
        break;
      case 2:
        // For goals step, use current selections
        _updateGoals(_profile.goals);
        break;
      case 3:
        // For fitness level step, use current level
        _updateFitnessLevel(_profile.fitnessLevel);
        break;
      case 4:
        // For body focus step, use current selections
        _updateBodyFocus(_profile.bodyFocusAreas);
        break;

      case 5:
        if (_workoutEnvironmentController.isValid) {
          // Use primary location for backward compatibility
          _updateWorkoutEnvironment(
            _workoutEnvironmentController.primaryLocation,
            _workoutEnvironmentController.selectedEquipment,
            _workoutEnvironmentController.weeklyWorkoutDays,
            _workoutEnvironmentController.workoutDurationMinutes,
          );
        } else {
          setState(() {
            _validationError = _workoutEnvironmentController.validationMessage;
          });
        }
        break;
      case 6:
        // For health and diet step, use current selections
        _updateHealthAndDiet(
          _profile.healthConditions,
          _profile.allergies,
          _profile.dietaryPreferences,
        );
        break;
      case 7:
        // For motivation step, use current selections
        _updateMotivation(_profile.motivations, _profile.customMotivation);
        break;
      default:
        // For other steps, use the default behavior
        _handleDefaultContinue();
        break;
    }
  }

  void _handleDefaultContinue() {
    switch (_currentStep) {
      case 1:
        _updateMeasurements(
          _profile.dateOfBirth,
          _profile.heightCm,
          _profile.weightKg,
        );
        break;
      case 2:
        _updateGoals(_profile.goals);
        break;
      case 3:
        _updateFitnessLevel(_profile.fitnessLevel);
        break;
      case 4:
        _updateBodyFocus(_profile.bodyFocusAreas);
        break;
      case 6:
        _updateHealthAndDiet(
          _profile.healthConditions,
          _profile.allergies,
          _profile.dietaryPreferences,
        );
        break;
      case 7:
        _updateMotivation(_profile.motivations, _profile.customMotivation);
        break;
    }
  }

  void _handleSkip() {
    _clearValidationError();
    print("Skipping step: $_currentStep");
    switch (_currentStep) {
      case 0:
        // Can't skip basic info step
        break;
      case 1:
        // Skip measurements step (leave values as null)
        _updateMeasurements(null, null, null);
        break;
      case 2:
        // Skip goals step (empty list)
        print("Skipping goals step, setting empty goals list");
        _updateGoals([]);
        break;
      case 3:
        // Skip fitness level step (use beginner as default)
        _updateFitnessLevel(FitnessLevel.beginner);
        break;
      case 4:
        // Skip body focus step (empty list)
        print("Skipping body focus step, setting empty body focus list");
        _updateBodyFocus([]);
        break;
      case 5:
        // Skip workout environment step (use defaults)
        _updateWorkoutEnvironment(
          WorkoutLocation.anywhere, // Default location
          ['No Equipment'], // Default equipment
          3, // Default 3 days per week
          30, // Default 30 minutes
        );
        break;
      case 6:
        // Skip health and diet step (empty lists)
        print("Skipping health and diet step, setting empty lists");
        _updateHealthAndDiet([], [], []);
        break;
      case 7:
        // Skip motivation step (empty list)
        print("Skipping motivation step, setting empty motivation list");
        _updateMotivation([], null);
        break;
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return BasicInfoStep(
          userId: _profile.userId,
          onNext: _updateBasicInfo,
          controller: _basicInfoController,
        );
      case 1:
        return MeasurementsStep(
          initialDateOfBirth: _profile.dateOfBirth,
          initialHeight: _profile.heightCm,
          initialWeight: _profile.weightKg,
          onNext: _updateMeasurements,
          onChanged: (dateOfBirth, height, weight) {
            // Update profile immediately when measurements change
            setState(() {
              _profile = _profile.copyWith(
                dateOfBirth: dateOfBirth,
                heightCm: height,
                weightKg: weight,
              );
            });
          },
        );
      case 2:
        return GoalsStep(
          initialGoals: _profile.goals,
          onNext: _updateGoals,
          onChanged: (goals) {
            // Update _profile directly when goals change
            setState(() {
              _profile = _profile.copyWith(goals: goals);
            });
          },
        );
      case 3:
        return FitnessLevelStep(
          initialLevel: _profile.fitnessLevel,
          onNext: _updateFitnessLevel,
        );
      case 4:
        return BodyFocusStep(
          initialAreas: _profile.bodyFocusAreas,
          onNext: _updateBodyFocus,
          onChanged: (areas) {
            // Update _profile directly when body focus areas change
            setState(() {
              _profile = _profile.copyWith(bodyFocusAreas: areas);
            });
          },
        );
      case 5:
        return WorkoutEnvironmentStep(
          initialLocation: _profile.preferredLocation,
          initialEquipment: _profile.availableEquipment,
          initialWeeklyDays: _profile.weeklyWorkoutDays,
          initialDuration: _profile.workoutDurationMinutes,
          onNext: _updateWorkoutEnvironment,
          controller: _workoutEnvironmentController,
        );
      case 6:
        return HealthAndDietStep(
          initialConditions: _profile.healthConditions,
          initialAllergies: _profile.allergies,
          initialDietaryPreferences: _profile.dietaryPreferences,
          onNext: _updateHealthAndDiet,
          onConditionsChanged: (conditions) {
            setState(() {
              _profile = _profile.copyWith(healthConditions: conditions);
            });
          },
          onAllergiesChanged: (allergies) {
            setState(() {
              _profile = _profile.copyWith(allergies: allergies);
            });
          },
          onDietaryPreferencesChanged: (preferences) {
            setState(() {
              _profile = _profile.copyWith(dietaryPreferences: preferences);
            });
          },
        );
      case 7:
        return MotivationStep(
          initialMotivations: _profile.motivations,
          initialCustomMotivation: _profile.customMotivation,
          onNext: _updateMotivation,
          onChanged: (motivations, customMotivation) {
            setState(() {
              _profile = _profile.copyWith(
                motivations: motivations,
                customMotivation: customMotivation,
              );
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
