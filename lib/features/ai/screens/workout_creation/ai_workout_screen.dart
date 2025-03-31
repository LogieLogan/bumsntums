// lib/features/ai/screens/workout_creation/ai_workout_screen.dart
import 'package:bums_n_tums/features/auth/providers/user_provider.dart';
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/indicators/loading_indicator.dart';
import '../../../../shared/analytics/firebase_analytics_service.dart';
import '../../providers/workout_generation_provider.dart';
import 'widgets/category_selection_step.dart';
import 'widgets/custom_request_step.dart';
import 'widgets/duration_selection_step.dart';
import 'widgets/equipment_selection_step.dart';
import 'widgets/generating_step.dart';
import 'widgets/refinement_step.dart';
import 'widgets/welcome_step.dart';
import 'widgets/workout_result.dart';
import 'widgets/refinement_result.dart';
import 'models/creation_step.dart';

class AIWorkoutScreen extends ConsumerStatefulWidget {
  const AIWorkoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIWorkoutScreen> createState() => _AIWorkoutScreenState();
}

class _AIWorkoutScreenState extends ConsumerState<AIWorkoutScreen> {
  CreationStep _currentStep = CreationStep.welcome;
  WorkoutCategory _selectedCategory = WorkoutCategory.fullBody;
  int _selectedDuration = 30;
  final TextEditingController _customRequestController = TextEditingController();
  final TextEditingController _refinementController = TextEditingController();
  List<String> _selectedEquipment = [];
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    // Initialize default values
    _selectedCategory = WorkoutCategory.fullBody;
    _selectedDuration = 30;
    _selectedEquipment = [];
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
    super.dispose();
  }

  void _goToNextStep() {
    setState(() {
      _currentStep = CreationStep.values[
        (_currentStep.index + 1) % CreationStep.values.length
      ];
    });
  }

  void _goToPreviousStep() {
    setState(() {
      _currentStep = CreationStep.values[
        (_currentStep.index - 1) % CreationStep.values.length
      ];
    });
  }

  void _selectCategory(WorkoutCategory category) {
    setState(() {
      _selectedCategory = category;
      _currentStep = CreationStep.durationSelection;
    });
    _analytics.logEvent(
      name: 'workout_category_selected',
      parameters: {'category': category.name},
    );
  }

  void _selectDuration(int duration) {
    setState(() {
      _selectedDuration = duration;
      _currentStep = CreationStep.equipmentSelection;
    });
    _analytics.logEvent(
      name: 'workout_duration_selected',
      parameters: {'duration': duration},
    );
  }

  void _updateEquipment(List<String> equipment) {
    setState(() {
      _selectedEquipment = equipment;
    });
  }

  void _startGeneration() {
    setState(() {
      _currentStep = CreationStep.generating;
    });
    _generateWorkout();
    _analytics.logEvent(name: 'workout_generation_started');
  }

  Future<void> _generateWorkout() async {
    try {
      final userProfile = await ref.read(userProfileProvider.future);
      if (userProfile == null) {
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
      final equipment = _selectedEquipment.contains('None') 
          ? <String>[] 
          : _selectedEquipment.toList();

      // Set parameters then generate
      final notifier = ref.read(workoutGenerationProvider.notifier);
      
      // Reset any previous parameters
      notifier.reset();

      // Set new parameters
      notifier.setParameters(
        workoutCategory: _selectedCategory.name,
        durationMinutes: _selectedDuration,
        focusAreas: focusAreas,
        specialRequest: _customRequestController.text.trim().isNotEmpty 
            ? _customRequestController.text.trim() 
            : null,
        equipment: equipment,
      );

      await notifier.generateWorkout(userId: userProfile.userId);

      if (mounted) {
        setState(() {
          _currentStep = CreationStep.result;
        });
      }
    } catch (e) {
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

    // Prefill the refinement controller with a template
    _refinementController.text = 'Modify this workout by adding...';

    setState(() {
      _currentStep = CreationStep.refining;
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
      setState(() {
        _currentStep = CreationStep.generating;
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
      await ref.read(workoutGenerationProvider.notifier).refineWorkout(
        userId: userProfile.userId,
        refinementRequest: refinementRequest,
      );

      if (mounted) {
        setState(() {
          _currentStep = CreationStep.refinementResult;
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
    setState(() {
      _customRequestController.clear();
      _refinementController.clear();
      _currentStep = CreationStep.categorySelection;
    });
    _analytics.logEvent(name: 'workout_creation_restarted');
  }

  List<String> _getFocusAreasForCategory(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return ['Glutes', 'Lower Body'];
      case WorkoutCategory.tums:
        return ['Core', 'Abs'];
      case WorkoutCategory.fullBody:
        return ['Full Body'];
      case WorkoutCategory.cardio:
        return ['Cardio', 'Endurance'];
      case WorkoutCategory.quickWorkout:
        return ['Full Body', 'Quick'];
      default:
        return ['Full Body'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendationState = ref.watch(workoutGenerationProvider);

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentStep == CreationStep.welcome)
                  WelcomeStep(onGetStarted: _goToNextStep),
                
                if (_currentStep == CreationStep.categorySelection)
                  CategorySelectionStep(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: _selectCategory,
                  ),
                
                if (_currentStep == CreationStep.durationSelection)
                  DurationSelectionStep(
                    selectedDuration: _selectedDuration,
                    selectedCategory: _selectedCategory,
                    onDurationSelected: _selectDuration,
                    onBack: () => setState(() {
                      _currentStep = CreationStep.categorySelection;
                    }),
                  ),

                if (_currentStep == CreationStep.equipmentSelection)
                  EquipmentSelectionStep(
                    selectedEquipment: _selectedEquipment,
                    onEquipmentUpdated: _updateEquipment,
                    onContinue: () => setState(() {
                      _currentStep = CreationStep.customRequest;
                    }),
                    onBack: () => setState(() {
                      _currentStep = CreationStep.durationSelection;
                    }),
                  ),

                if (_currentStep == CreationStep.customRequest)
                  CustomRequestStep(
                    controller: _customRequestController,
                    selectedCategory: _selectedCategory,
                    selectedDuration: _selectedDuration,
                    selectedEquipment: _selectedEquipment,
                    onBack: () => setState(() {
                      _currentStep = CreationStep.equipmentSelection;
                    }),
                    onGenerate: _startGeneration,
                  ),

                if (_currentStep == CreationStep.generating)
                  GeneratingStep(selectedCategory: _selectedCategory),

                if (_currentStep == CreationStep.result && 
                    recommendationState.workoutData != null)
                  WorkoutResult(
                    workoutData: recommendationState.workoutData!,
                    onStartRefinement: _startRefinement,
                  ),

                if (_currentStep == CreationStep.refining && 
                    recommendationState.workoutData != null)
                  RefinementStep(
                    workoutData: recommendationState.workoutData!,
                    controller: _refinementController,
                    isRefining: recommendationState.isLoading,
                    refinementHistoryExists: recommendationState.refinementHistory.isNotEmpty,
                    onCancel: () => setState(() {
                      _currentStep = CreationStep.result;
                    }),
                    onUndoChanges: () {
                      ref.read(workoutGenerationProvider.notifier).undoRefinement();
                      setState(() {
                        _currentStep = CreationStep.refinementResult;
                      });
                    },
                    onApplyChanges: _applyRefinement,
                  ),

                if (_currentStep == CreationStep.refinementResult && 
                    recommendationState.workoutData != null)
                  RefinementResult(
                    workoutData: recommendationState.workoutData!,
                    changesSummary: recommendationState.changesSummary,
                    onUseWorkout: () => setState(() {
                      _currentStep = CreationStep.result;
                    }),
                    onUndoChanges: () {
                      ref.read(workoutGenerationProvider.notifier).undoRefinement();
                      setState(() {
                        _currentStep = CreationStep.result;
                      });
                    },
                    onRefineAgain: () => setState(() {
                      _refinementController.clear();
                      _currentStep = CreationStep.refining;
                    }),
                  ),

                if (recommendationState.error != null)
                  _buildErrorState(recommendationState.error!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Error Creating Workout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(error),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startOver,
              child: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }
}