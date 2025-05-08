// Update to lib/features/ai/screens/workout_creation/ai_workout_screen.dart

import 'package:bums_n_tums/features/auth/providers/user_provider.dart';
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../provider/workout_generation_provider.dart';
import '../widgets/category_selection_step.dart';
import '../widgets/custom_request_step.dart';
import '../widgets/duration_selection_step.dart';
import '../widgets/equipment_selection_step.dart';
import '../widgets/generating_step.dart';
import '../widgets/refinement_step.dart';
import '../widgets/welcome_step.dart';
import '../widgets/workout_result.dart';
import '../widgets/refinement_result.dart';
import '../widgets/parameter_summary_sheet.dart'; // Add this import
import '../models/creation_step.dart';

class AIWorkoutScreen extends ConsumerStatefulWidget {
  const AIWorkoutScreen({super.key});

  @override
  ConsumerState<AIWorkoutScreen> createState() => _AIWorkoutScreenState();
}

class _AIWorkoutScreenState extends ConsumerState<AIWorkoutScreen>
    with SingleTickerProviderStateMixin {
  CreationStep _currentStep = CreationStep.welcome;
  WorkoutCategory _selectedCategory = WorkoutCategory.fullBody;
  int _selectedDuration = 30;
  final TextEditingController _customRequestController =
      TextEditingController();
  final TextEditingController _refinementController = TextEditingController();
  List<String> selectedEquipment = [];
  final AnalyticsService _analytics = AnalyticsService();

  // Add animation controller for transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Initialize default values
    _selectedCategory = WorkoutCategory.fullBody;
    _selectedDuration = 30;
    selectedEquipment = [];
    _scrollController = ScrollController();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    _analytics.logScreenView(screenName: 'ai_workout_screen');

    // Start with a short delay to allow for smooth animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _currentStep = CreationStep.categorySelection;
        });
      }
    });
  }

  @override
  void dispose() {
    _customRequestController.dispose();
    _refinementController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    // Animate out current step
    _animationController.reverse().then((_) {
      setState(() {
        _currentStep =
            CreationStep.values[(_currentStep.index + 1) %
                CreationStep.values.length];
      });

      // Scroll to top and animate in new step
      _scrollToTop();
      _animationController.forward();
    });
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

  void _selectCategory(WorkoutCategory category) {
    // Add haptic feedback
    HapticFeedback.selectionClick();

    // Animate transition
    _animationController.reverse().then((_) {
      setState(() {
        _selectedCategory = category;
        _currentStep = CreationStep.durationSelection;
      });

      _scrollToTop();
      _animationController.forward();
    });

    _analytics.logEvent(
      name: 'workout_category_selected',
      parameters: {'category': category.name},
    );
  }

  void _selectDuration(int duration) {
    // Add haptic feedback
    HapticFeedback.selectionClick();

    // Animate transition
    _animationController.reverse().then((_) {
      setState(() {
        _selectedDuration = duration;
        _currentStep = CreationStep.equipmentSelection;
      });

      _scrollToTop();
      _animationController.forward();
    });

    _analytics.logEvent(
      name: 'workout_duration_selected',
      parameters: {'duration': duration},
    );
  }

  void _updateEquipment(List<String> equipment) {
    setState(() {
      selectedEquipment = equipment;
    });
  }

  void _startGeneration() {
    debugPrint("AIWorkoutScreen: _startGeneration called.");
    // Add haptic feedback
    HapticFeedback.mediumImpact();

    _animationController.reverse().then((_) {
      setState(() {
        _currentStep = CreationStep.generating;
      });

      _scrollToTop();
      _animationController.forward();
      debugPrint("AIWorkoutScreen: Calling _generateWorkout...");
      _generateWorkout();
    });

    _analytics.logEvent(name: 'workout_generation_started_ui');
  }

  Future<void> _generateWorkout() async {
    debugPrint("AIWorkoutScreen: _generateWorkout method entered.");
    try {
      final userProfile = await ref.read(userProfileProvider.future);
      if (userProfile == null) {
        debugPrint(
          "AIWorkoutScreen: Cannot generate workout - User profile is null.",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to load user profile')),
          );
          setState(() {
            _currentStep = CreationStep.categorySelection;
          });
        }
        return;
      }

      // Get focus areas based on category
      final focusAreas = _getFocusAreasForCategory(_selectedCategory);

      // Prepare equipment list
      final equipment =
          selectedEquipment.contains('None')
              ? <String>[]
              : selectedEquipment.toList();

      // Extract user profile data
      final userProfileData = {
        'fitnessLevel': userProfile.fitnessLevel.name,
        'age': userProfile.age,
        'goals': userProfile.goals.map((g) => g.name).toList(),
        'preferredLocation': userProfile.preferredLocation?.name,
        'healthConditions': userProfile.healthConditions,
      };

      // Set parameters then generate
      final notifier = ref.read(workoutGenerationProvider.notifier);

      // Reset any previous parameters
      notifier.reset();
      debugPrint("AIWorkoutScreen: Setting parameters in notifier...");

      // Set new parameters
      notifier.setParameters(
        workoutCategory: _selectedCategory.name,
        durationMinutes: _selectedDuration,
        focusAreas: focusAreas,
        specialRequest:
            _customRequestController.text.trim().isNotEmpty
                ? _customRequestController.text.trim()
                : null,
        equipment: equipment,
      );
      debugPrint("AIWorkoutScreen: Calling notifier.generateWorkout...");
      await notifier.generateWorkout(
        userId: userProfile.userId,
        userProfileData: userProfileData, // Pass the profile data
      );
      debugPrint("AIWorkoutScreen: notifier.generateWorkout completed.");
      if (mounted) {
        debugPrint(
          "AIWorkoutScreen: Workout generation successful, moving to result step.",
        );
        _animationController.reverse().then((_) {
          setState(() {
            _currentStep = CreationStep.result;
          });
          _scrollToTop();
          _animationController.forward();
        });
      }
    } catch (e) {
      debugPrint("AIWorkoutScreen: Error caught in _generateWorkout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating workout: ${e.toString()}')),
        );
        setState(() {
          _currentStep = CreationStep.customRequest;
        });
      }
    }
  }

  void _startRefinement() {
    // Reset any previous changes summary
    ref.read(workoutGenerationProvider.notifier).state = ref
        .read(workoutGenerationProvider.notifier)
        .state
        .copyWith(changesSummary: null);

    // Clear the refinement controller instead of prefilling it
    _refinementController.clear();

    _animationController.reverse().then((_) {
      setState(() {
        _currentStep = CreationStep.refining;
      });
      _scrollToTop();
      _animationController.forward();
    });

    _analytics.logEvent(name: 'workout_refinement_started');
  }

  Future<void> _applyRefinement() async {
    final refinementRequest = _refinementController.text.trim();
    if (refinementRequest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your refinement request')),
      );
      return;
    }

    try {
      _animationController.reverse().then((_) {
        setState(() {
          _currentStep = CreationStep.generating;
        });
        _scrollToTop();
        _animationController.forward();
      });

      final userProfile = await ref.read(userProfileProvider.future);
      if (userProfile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to load user profile')),
          );
          setState(() {
            _currentStep = CreationStep.refining;
          });
        }
        return;
      }

      // Apply the refinement
      await ref
          .read(workoutGenerationProvider.notifier)
          .refineWorkout(
            userId: userProfile.userId,
            refinementRequest: refinementRequest,
          );

      if (mounted) {
        _animationController.reverse().then((_) {
          setState(() {
            _currentStep = CreationStep.refinementResult;
          });
          _scrollToTop();
          _animationController.forward();
        });

        _analytics.logEvent(
          name: 'workout_refinement_applied',
          parameters: {'request_length': refinementRequest.length},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refining workout: ${e.toString()}')),
        );
        setState(() {
          _currentStep = CreationStep.refining;
        });
      }
    }
  }

  void _startOver() {
    ref.read(workoutGenerationProvider.notifier).reset();

    _animationController.reverse().then((_) {
      setState(() {
        _customRequestController.clear();
        _refinementController.clear();
        _currentStep = CreationStep.categorySelection;
      });
      _scrollToTop();
      _animationController.forward();
    });

    _analytics.logEvent(name: 'workout_creation_restarted');
  }

  List<String> _getFocusAreasForCategory(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return ['Glutes', 'Lower Body'];
      case WorkoutCategory.tums:
        return ['Core', 'Abs'];
      case WorkoutCategory.arms:
        return ['Arms'];
      case WorkoutCategory.fullBody:
        return ['Full Body'];
      case WorkoutCategory.cardio:
        return ['Cardio', 'Endurance'];
      case WorkoutCategory.quickWorkout:
        return ['Full Body', 'Quick'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Workout Creator'),
        actions: [
          if (_currentStep == CreationStep.result ||
              _currentStep == CreationStep.refinementResult)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startOver,
              tooltip: 'Create new workout',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content area with fade animation
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
            ),

            // Parameter summary sheet (only shown for certain steps)
            if (_shouldShowBottomSheet()) _buildBottomSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    final recommendationState = ref.watch(workoutGenerationProvider);

    switch (_currentStep) {
      case CreationStep.welcome:
        return WelcomeStep(onGetStarted: _goToNextStep);

      case CreationStep.categorySelection:
        return CategorySelectionStep(
          selectedCategory: _selectedCategory,
          onCategorySelected: _selectCategory,
        );

      case CreationStep.durationSelection:
        return DurationSelectionStep(
          selectedDuration: _selectedDuration,
          selectedCategory: _selectedCategory,
          onDurationSelected: _selectDuration,
          onBack: () {
            _animationController.reverse().then((_) {
              setState(() {
                _currentStep = CreationStep.categorySelection;
              });
              _scrollToTop();
              _animationController.forward();
            });
          },
        );

      case CreationStep.equipmentSelection:
        return EquipmentSelectionStep(
          selectedEquipment: selectedEquipment,
          onEquipmentUpdated: _updateEquipment,
          onContinue: () {
            _animationController.reverse().then((_) {
              setState(() {
                _currentStep = CreationStep.customRequest;
              });
              _scrollToTop();
              _animationController.forward();
            });
          },
          onBack: () {
            _animationController.reverse().then((_) {
              setState(() {
                _currentStep = CreationStep.durationSelection;
              });
              _scrollToTop();
              _animationController.forward();
            });
          },
        );

      case CreationStep.customRequest:
        return CustomRequestStep(
          controller: _customRequestController,
          selectedCategory: _selectedCategory,
          selectedDuration: _selectedDuration,
          selectedEquipment: selectedEquipment,
          onBack: () {
            _animationController.reverse().then((_) {
              setState(() {
                _currentStep = CreationStep.equipmentSelection;
              });
              _scrollToTop();
              _animationController.forward();
            });
          },
          onGenerate: _startGeneration,
        );

      case CreationStep.generating:
        return GeneratingStep(selectedCategory: _selectedCategory);

      case CreationStep.result:
        if (recommendationState.workoutData != null) {
          return WorkoutResult(
            workoutData: recommendationState.workoutData!,
            onStartRefinement: _startRefinement,
          );
        }
        return const Center(child: Text("No workout data available"));

      case CreationStep.refining:
        if (recommendationState.workoutData != null) {
          return RefinementStep(
            workoutData: recommendationState.workoutData!,
            controller: _refinementController,
            isRefining: recommendationState.isLoading,
            refinementHistoryExists:
                recommendationState.refinementHistory.isNotEmpty,
            onCancel: () {
              _animationController.reverse().then((_) {
                setState(() {
                  _currentStep = CreationStep.result;
                });
                _scrollToTop();
                _animationController.forward();
              });
            },
            onUndoChanges: () {
              ref.read(workoutGenerationProvider.notifier).undoRefinement();
              _animationController.reverse().then((_) {
                setState(() {
                  _currentStep = CreationStep.refinementResult;
                });
                _scrollToTop();
                _animationController.forward();
              });
            },
            onApplyChanges: _applyRefinement,
          );
        }
        return const Center(child: Text("No workout data available"));

      case CreationStep.refinementResult:
        if (recommendationState.workoutData != null) {
          return RefinementResult(
            workoutData: recommendationState.workoutData!,
            changesSummary: recommendationState.changesSummary,
            onUseWorkout: () {
              _animationController.reverse().then((_) {
                setState(() {
                  _currentStep = CreationStep.result;
                });
                _scrollToTop();
                _animationController.forward();
              });
            },
            onUndoChanges: () {
              ref.read(workoutGenerationProvider.notifier).undoRefinement();
              _animationController.reverse().then((_) {
                setState(() {
                  _currentStep = CreationStep.result;
                });
                _scrollToTop();
                _animationController.forward();
              });
            },
            onRefineAgain: () {
              _animationController.reverse().then((_) {
                setState(() {
                  _refinementController.clear();
                  _currentStep = CreationStep.refining;
                });
                _scrollToTop();
                _animationController.forward();
              });
            },
          );
        }
        return const Center(child: Text("No workout data available"));
    }
  }

  bool _shouldShowBottomSheet() {
    // Don't show for welcome, generating, result or refinement result steps
    return !([
      CreationStep.welcome,
      CreationStep.generating,
      CreationStep.result,
      CreationStep.refinementResult,
    ].contains(_currentStep));
  }

  Widget _buildBottomSheet() {
    // Only add back button for steps after category selection
    final showBackButton =
        _currentStep.index > CreationStep.categorySelection.index;

    // Only add continue button for certain steps
    final showContinueButton = [
      CreationStep.categorySelection,
      CreationStep.durationSelection,
      CreationStep.equipmentSelection,
      CreationStep.customRequest,
    ].contains(_currentStep);

    // Configure button text based on step
    String continueText = 'Continue';
    if (_currentStep == CreationStep.customRequest) {
      continueText = 'Generate Workout';
    } else if (_currentStep == CreationStep.refining) {
      continueText = 'Apply Changes';
    }

    // Configure actions based on step
    VoidCallback? onBack;
    VoidCallback? onContinue;

    switch (_currentStep) {
      case CreationStep.categorySelection:
        onContinue = _goToNextStep;
        break;
      case CreationStep.durationSelection:
        onBack = () {
          _animationController.reverse().then((_) {
            setState(() {
              _currentStep = CreationStep.categorySelection;
            });
            _scrollToTop();
            _animationController.forward();
          });
        };
        break;
      case CreationStep.equipmentSelection:
        onBack = () {
          _animationController.reverse().then((_) {
            setState(() {
              _currentStep = CreationStep.durationSelection;
            });
            _scrollToTop();
            _animationController.forward();
          });
        };
        onContinue = () {
          _animationController.reverse().then((_) {
            setState(() {
              _currentStep = CreationStep.customRequest;
            });
            _scrollToTop();
            _animationController.forward();
          });
        };
        break;
      case CreationStep.customRequest:
        onBack = () {
          _animationController.reverse().then((_) {
            setState(() {
              _currentStep = CreationStep.equipmentSelection;
            });
            _scrollToTop();
            _animationController.forward();
          });
        };
        onContinue = _startGeneration;
        break;
      case CreationStep.refining:
        onBack = () {
          _animationController.reverse().then((_) {
            setState(() {
              _currentStep = CreationStep.result;
            });
            _scrollToTop();
            _animationController.forward();
          });
        };
        onContinue = _applyRefinement;
        break;
      default:
        break;
    }

    return ParameterSummarySheet(
      selectedCategory: _selectedCategory,
      selectedDuration: _selectedDuration,
      selectedEquipment: selectedEquipment,
      specialRequest:
          _customRequestController.text.trim().isNotEmpty
              ? _customRequestController.text.trim()
              : null,
      onBack: onBack,
      onContinue: onContinue,
      showBackButton: showBackButton,
      showContinueButton: showContinueButton,
      continueButtonText: continueText,
    );
  }

  // Widget _buildErrorState(String error) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     margin: const EdgeInsets.symmetric(vertical: 16),
  //     decoration: BoxDecoration(
  //       color: Colors.red.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.red),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: const [
  //             Icon(Icons.error_outline, color: Colors.red),
  //             SizedBox(width: 8),
  //             Text(
  //               'Error Creating Workout',
  //               style: TextStyle(
  //                 color: Colors.red,
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 16,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Text(error),
  //         const SizedBox(height: 16),
  //         SizedBox(
  //           width: double.infinity,
  //           child: ElevatedButton(
  //             onPressed: _startOver,
  //             child: const Text('Try Again'),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
