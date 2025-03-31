// lib/features/ai/screens/ai_workout_screen.dart
import 'package:bums_n_tums/features/workouts/models/exercise.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/components/buttons/secondary_button.dart';
import '../../../features/auth/providers/user_provider.dart';
import '../../../features/workouts/models/workout.dart';
import '../providers/workout_generation_provider.dart';
import '../../../features/workouts/screens/pre_workout_setup_screen.dart';
import '../../../features/workouts/repositories/custom_workout_repository.dart';

enum ConversationStep {
  welcome,
  categorySelection,
  durationSelection,
  equipmentSelection,
  customRequest,
  generating,
  result,
  refining,
  refinementResult,
}

class AIWorkoutScreen extends ConsumerStatefulWidget {
  const AIWorkoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIWorkoutScreen> createState() => _AIWorkoutScreenState();
}

class _AIWorkoutScreenState extends ConsumerState<AIWorkoutScreen> {
  // Track the current conversation step

  ConversationStep _currentStep = ConversationStep.welcome;
  WorkoutCategory _selectedCategory = WorkoutCategory.fullBody;
  int _selectedDuration = 30;
  final TextEditingController _customRequestController =
      TextEditingController();
  final TextEditingController _refinementController = TextEditingController();
  List<String> _selectedEquipment = [];
  final TextEditingController _customEquipmentController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default values
    _selectedCategory = WorkoutCategory.fullBody;
    _selectedDuration = 30;
    _selectedEquipment = [];

    // Start with a short delay to allow for smooth animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _currentStep = ConversationStep.categorySelection;
        });
      }
    });
  }

  @override
  void dispose() {
    _customRequestController.dispose();
    _refinementController.dispose();
    _customEquipmentController.dispose();
    super.dispose();
  }

  // Handle category selection
  void _selectCategory(WorkoutCategory category) {
    setState(() {
      _selectedCategory = category;
      _currentStep = ConversationStep.durationSelection;
    });
  }

  // Handle duration selection
  void _selectDuration(int duration) {
    setState(() {
      _selectedDuration = duration;
    });

    // Pre-populate equipment from profile
    final userProfile = ref.read(userProfileProvider).asData?.value;
    if (userProfile != null && userProfile.availableEquipment.isNotEmpty) {
      setState(() {
        _selectedEquipment.clear();
        _selectedEquipment.addAll(userProfile.availableEquipment);
      });
    }
  }

  // Move to generating step
  void _startGeneration() {
    setState(() {
      _currentStep = ConversationStep.generating;
    });
    _generateWorkout();
  }

  // Generate the workout
  Future<void> _generateWorkout() async {
    final userProfile = await ref.read(userProfileProvider.future);
    if (userProfile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load user profile')),
        );
        setState(() {
          _currentStep = ConversationStep.categorySelection;
        });
      }
      return;
    }

    final customRequest =
        _customRequestController.text.trim().isNotEmpty
            ? _customRequestController.text.trim()
            : null;

    // Prepare equipment list, excluding "None"
    final equipment =
        _selectedEquipment.contains('None')
            ? <String>[]
            : _selectedEquipment.toList();

    // Get focus areas based on category
    final focusAreas = _getFocusAreasForCategory(_selectedCategory);

    debugPrint('Generating workout with:');
    debugPrint('Category: ${_selectedCategory.name}');
    debugPrint('Duration: $_selectedDuration minutes');
    debugPrint('Equipment: ${equipment.join(', ')}');
    debugPrint('Special Request: $customRequest');
    debugPrint('Focus Areas: ${focusAreas.join(', ')}');

    // Set parameters then generate
    final notifier = ref.read(workoutGenerationProvider.notifier);

    // First reset any previous parameters
    notifier.reset();

    // Then set new parameters
    notifier.setParameters(
      workoutCategory: _selectedCategory.name,
      durationMinutes: _selectedDuration,
      focusAreas: focusAreas,
      specialRequest: customRequest,
      equipment: equipment,
    );

    await notifier.generateWorkout(userId: userProfile.userId);

    if (mounted) {
      setState(() {
        _currentStep = ConversationStep.result;
      });
    }
  }

  // Get focus areas based on category
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

  void _startRefinement() {
    // Reset any previous changes summary
    ref.read(workoutGenerationProvider.notifier).state = ref
        .read(workoutGenerationProvider.notifier)
        .state
        .copyWith(changesSummary: null);

    // Get the original request from state
    final originalRequest =
        ref.read(workoutGenerationProvider).originalRequest ??
        '${_selectedCategory.name} workout for ${_selectedDuration} minutes';

    // Prefill the refinement controller with a template
    _refinementController.text = 'Modify this workout by adding...';

    setState(() {
      _currentStep = ConversationStep.refining;
    });
  }

  // Start a new workout creation
  void _startOver() {
    ref.read(workoutGenerationProvider.notifier).reset();
    setState(() {
      _customRequestController.clear();
      _refinementController.clear();
      _currentStep = ConversationStep.categorySelection;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recommendationState = ref.watch(workoutGenerationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Workout Creator'),
        actions: [
          if (_currentStep == ConversationStep.result)
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
                // Conversational welcome
                if (_currentStep == ConversationStep.welcome)
                  _buildWelcomeStep(),

                // Category selection
                if (_currentStep == ConversationStep.categorySelection)
                  _buildCategorySelectionStep(),

                // Duration selection
                if (_currentStep == ConversationStep.durationSelection)
                  _buildDurationSelectionStep(),

                if (_currentStep == ConversationStep.equipmentSelection)
                  _buildEquipmentSelectionStep(),

                // Custom request
                if (_currentStep == ConversationStep.customRequest)
                  _buildCustomRequestStep(),

                // Generating state
                if (_currentStep == ConversationStep.generating)
                  _buildGeneratingStep(),

                // Result state
                if (_currentStep == ConversationStep.result &&
                    recommendationState.workoutData != null)
                  _buildWorkoutResult(recommendationState.workoutData!),

                // Refinement state
                if (_currentStep == ConversationStep.refining &&
                    recommendationState.workoutData != null)
                  _buildRefinementStep(recommendationState.workoutData!),

                if (_currentStep == ConversationStep.refinementResult &&
                    recommendationState.workoutData != null)
                  _buildRefinementResultStep(recommendationState.workoutData!),

                // Error state
                if (recommendationState.error != null)
                  _buildErrorState(recommendationState.error!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(
          Icons.fitness_center,
          size: 64,
          color: AppColors.salmon.withOpacity(0.7),
        ),
        const SizedBox(height: 24),
        Text(
          'Let\'s Create Your Perfect Workout',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'I\'ll help you build a personalized workout that matches your goals and preferences.',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Get Started',
          onPressed: () {
            setState(() {
              _currentStep = ConversationStep.categorySelection;
            });
          },
        ),
      ],
    );
  }

  // Add a Continue button to category selection step
  Widget _buildCategorySelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What would you like to focus on today?', style: AppTextStyles.h3),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildCategoryCard(
              title: 'Bums',
              icon: Icons.fitness_center,
              color: AppColors.salmon,
              category: WorkoutCategory.bums,
            ),
            _buildCategoryCard(
              title: 'Tums',
              icon: Icons.accessibility_new,
              color: AppColors.popCoral,
              category: WorkoutCategory.tums,
            ),
            _buildCategoryCard(
              title: 'Full Body',
              icon: Icons.sports_gymnastics,
              color: AppColors.popBlue,
              category: WorkoutCategory.fullBody,
            ),
            _buildCategoryCard(
              title: 'Cardio',
              icon: Icons.directions_run,
              color: AppColors.popTurquoise,
              category: WorkoutCategory.cardio,
            ),
            _buildCategoryCard(
              title: 'Quick',
              icon: Icons.timer,
              color: AppColors.popGreen,
              category: WorkoutCategory.quickWorkout,
            ),
          ],
        ),
        // Add Continue button
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Continue',
          onPressed: () {
            setState(() {
              _currentStep = ConversationStep.durationSelection;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required WorkoutCategory category,
  }) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category; // Simply update the selection
          // Don't change steps here - let the continue button handle that
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 0.9 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Great choice! How long should your ${_getCategoryDisplayName(_selectedCategory)} workout be?',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 20),
        Text('Select workout duration in minutes:', style: AppTextStyles.body),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children:
              [10, 15, 20, 30, 45, 60].map((duration) {
                final isSelected = _selectedDuration == duration;
                return InkWell(
                  onTap: () => _selectDuration(duration),
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isSelected
                              ? AppColors.salmon
                              : Colors.grey.withOpacity(0.1),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.salmon
                                : Colors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$duration',
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.darkGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'Back',
                onPressed: () {
                  setState(() {
                    _currentStep = ConversationStep.categorySelection;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  setState(() {
                    _currentStep = ConversationStep.equipmentSelection;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEquipmentSelectionStep() {
    // Get equipment from profile
    final userProfile = ref.watch(userProfileProvider).asData?.value;
    final profileEquipment = userProfile?.availableEquipment ?? [];

    // State for selected equipment
    final selectedEquipment = _selectedEquipment.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What equipment will you use for this workout?',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 8),
        Text(
          'Select from your available equipment or add new items',
          style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
        ),
        const SizedBox(height: 16),

        // Show equipment from profile with indicator
        if (profileEquipment.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.salmon.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.salmon.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.mediumGrey),
                    const SizedBox(width: 4),
                    Text(
                      'From your profile',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.mediumGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      profileEquipment.map((item) {
                        final isSelected = selectedEquipment.contains(item);
                        return FilterChip(
                          label: Text(item),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (!selectedEquipment.contains(item)) {
                                  _selectedEquipment.add(item);
                                }
                              } else {
                                _selectedEquipment.remove(item);
                              }
                            });
                          },
                          backgroundColor: AppColors.paleGrey,
                          selectedColor: AppColors.salmon.withOpacity(0.2),
                          checkmarkColor: AppColors.salmon,
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Common equipment options
        Text(
          'Common Equipment',
          style: AppTextStyles.small.copyWith(
            color: AppColors.mediumGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                'Dumbbells',
                'Resistance Bands',
                'Yoga Mat',
                'Kettlebell',
                'Exercise Ball',
                'None',
              ].map((item) {
                final isSelected = selectedEquipment.contains(item);
                return FilterChip(
                  label: Text(item),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (!selectedEquipment.contains(item)) {
                          _selectedEquipment.add(item);
                        }
                        // If "None" is selected, clear all other selections
                        if (item == 'None') {
                          _selectedEquipment.clear();
                          _selectedEquipment.add('None');
                        } else {
                          // If another item is selected, remove "None" if present
                          _selectedEquipment.remove('None');
                        }
                      } else {
                        _selectedEquipment.remove(item);
                      }
                    });
                  },
                  backgroundColor: AppColors.paleGrey,
                  selectedColor: AppColors.salmon.withOpacity(0.2),
                  checkmarkColor: AppColors.salmon,
                );
              }).toList(),
        ),

        // Add custom equipment option
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customEquipmentController,
                decoration: InputDecoration(
                  hintText: 'Add custom equipment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final text = _customEquipmentController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    if (!_selectedEquipment.contains(text)) {
                      _selectedEquipment.add(text);
                      _selectedEquipment.remove(
                        'None',
                      ); // Remove "None" if present
                    }
                    _customEquipmentController.clear();
                  });
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.salmon,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'Back',
                onPressed: () {
                  setState(() {
                    _currentStep = ConversationStep.durationSelection;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  setState(() {
                    _currentStep = ConversationStep.customRequest;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomRequestStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Almost there! Any special requests for your workout?',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 12),
        Text(
          'For example: "Add stretching" or "Focus on upper body"',
          style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _customRequestController,
          decoration: InputDecoration(
            hintText: 'Enter any special requests (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.1),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        // Quick suggestion chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                'No jumping',
                'Low impact',
                'Include stretching',
                'Extra core work',
                'Stretch focus',
              ].map((suggestion) => _buildSuggestionChip(suggestion)).toList(),
        ),
        const SizedBox(height: 32),
        // Workout summary before generation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.salmon.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout Summary',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Focus',
                _getCategoryDisplayName(_selectedCategory),
              ),
              _buildSummaryRow('Duration', '$_selectedDuration minutes'),
              // Add equipment summary
              _buildSummaryRow(
                'Equipment',
                _selectedEquipment.isEmpty ||
                        _selectedEquipment.contains('None')
                    ? 'None (bodyweight only)'
                    : _selectedEquipment.join(', '),
              ),
              if (_customRequestController.text.isNotEmpty)
                _buildSummaryRow(
                  'Special Request',
                  _customRequestController.text,
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'Back',
                onPressed: () {
                  setState(() {
                    _currentStep =
                        ConversationStep
                            .equipmentSelection; // Changed from durationSelection
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'Create Workout',
                onPressed: _startGeneration,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: AppColors.salmon.withOpacity(0.1),
      labelStyle: TextStyle(color: AppColors.salmon),
      onPressed: () {
        // Determine which text controller to use based on current step
        final controller =
            _currentStep == ConversationStep.refining
                ? _refinementController
                : _customRequestController;

        // Get current text from controller
        final currentText = controller.text;

        // Handle empty or placeholder text
        if (currentText.isEmpty ||
            currentText == 'Modify this workout by adding...' ||
            currentText == 'Enter any special requests (optional)') {
          controller.text = text;
        }
        // Check if text is already in the input
        else if (!currentText.toLowerCase().contains(text.toLowerCase())) {
          // If the existing text ends with punctuation, add a space
          if (currentText.endsWith('.') ||
              currentText.endsWith(',') ||
              currentText.endsWith(':') ||
              currentText.endsWith(';')) {
            controller.text = '$currentText $text';
          }
          // If existing text doesn't end with space, add a comma and space
          else if (!currentText.endsWith(' ')) {
            controller.text = '$currentText, $text';
          }
          // Otherwise just append with a space
          else {
            controller.text = '$currentText$text';
          }
        }

        // Set cursor at the end of the text
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );

        // Focus on the text field after selecting a chip
        FocusScope.of(context).requestFocus(FocusNode());
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  Widget _buildGeneratingStep() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom animation for workout generation
              SizedBox(
                height: 100,
                width: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer rotating circle
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 2 * 3.14159),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.rotate(angle: value, child: child);
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.salmon.withOpacity(0.3),
                            width: 8,
                          ),
                        ),
                      ),
                    ),
                    // Inner pulsing circle
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.2),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Icon(
                        Icons.fitness_center,
                        color: AppColors.salmon,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Creating Your Personalized Workout',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Designing the perfect ${_getCategoryDisplayName(_selectedCategory)} workout just for you...',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutResult(
    Map<String, dynamic> workoutData, {
    bool showFeedbackSection = true,
  }) {
    // Extract workout details
    final title = workoutData['title'] ?? 'Custom Workout';
    final description =
        workoutData['description'] ?? 'A personalized workout just for you.';
    final difficulty = workoutData['difficulty'] ?? 'beginner';
    final duration = workoutData['durationMinutes'] ?? _selectedDuration;
    final calories = workoutData['estimatedCaloriesBurn'] ?? 150;
    final equipment = workoutData['equipment'] ?? [];
    final exercises = workoutData['exercises'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your personalized workout is ready!',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on your preferences, I\'ve created a ${_getCategoryDisplayName(_selectedCategory)} workout for you.',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Workout details card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and description
                Text(title, style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text(description, style: AppTextStyles.body),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(Icons.timer, '$duration min'),
                    _buildStatColumn(
                      Icons.local_fire_department,
                      '$calories cal',
                    ),
                    _buildStatColumn(
                      Icons.fitness_center,
                      _capitalizeFirst(difficulty),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Equipment list if present
                if (equipment is List && equipment.isNotEmpty) ...[
                  Text(
                    'Equipment:',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(equipment.length, (index) {
                      return Chip(
                        label: Text(equipment[index].toString()),
                        backgroundColor: AppColors.popTurquoise.withOpacity(
                          0.1,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],

                // Exercise list header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercises (${exercises.length})',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Sets × Reps',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ],
                ),
                const Divider(),

                // Exercise list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exercises.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final name = exercise['name'] ?? 'Exercise ${index + 1}';
                    final description = exercise['description'] ?? '';
                    final sets = exercise['sets'] ?? 3;
                    final reps = exercise['reps'] ?? 10;
                    final isRepBased = (exercise['durationSeconds'] == null);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              isRepBased
                                  ? '$sets × $reps'
                                  : '$sets × ${exercise['durationSeconds']}s',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.mediumGrey,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Refine'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _startRefinement,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.salmon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => _startWorkout(workoutData),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save to My Workouts'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => _saveWorkout(workoutData),
          ),
        ),
        const SizedBox(height: 32),

        // Feedback section
        if (showFeedbackSection) ...[
          const SizedBox(height: 32),

          // Feedback section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How was this workout suggestion?',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeedbackButton(Icons.thumb_down, 'Too Easy'),
                    _buildFeedbackButton(Icons.check_circle, 'Just Right'),
                    _buildFeedbackButton(Icons.fitness_center, 'Too Hard'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatColumn(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppColors.salmon),
        const SizedBox(height: 4),
        Text(
          text,
          style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFeedbackButton(IconData icon, String label) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Thanks for your feedback!')));
      },
      child: Column(
        children: [
          Icon(icon, color: AppColors.darkGrey),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.small),
        ],
      ),
    );
  }

  Widget _buildRefinementStep(Map<String, dynamic> currentWorkout) {
    final isRefining = ref.watch(workoutGenerationProvider).isLoading;

    // Create categorized refinement suggestions
    final intensitySuggestions = [
      'Make it easier',
      'Make it harder',
      'More rest time',
      'Less rest time',
    ];

    final bodyFocusSuggestions = [
      'More core work',
      'More leg exercises',
      'More upper body',
      'Focus on strength',
    ];

    final equipmentSuggestions = [
      'Use different equipment',
      'Add resistance bands',
      'No equipment needed',
      'Use dumbbells only',
    ];

    final modificationSuggestions = [
      'No jumping',
      'Low impact only',
      'Add stretching',
      'Add warm-up',
      'Increase length',
      'Decrease length',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you like to change about this workout?',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 8),

        // Add guidance for effective refinement
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.salmon.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.salmon.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips for effective refinement:',
                style: AppTextStyles.small.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Be specific about what to add, remove, or change\n'
                '• For example: "Add 2 core exercises" or "Replace jumping with low-impact"\n'
                '• Mention specific exercises if possible\n'
                '• Include equipment preferences if relevant',
                style: AppTextStyles.small,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        TextField(
          controller: _refinementController,
          decoration: InputDecoration(
            hintText:
                'E.g., "Add core exercises" or "Remove jumping exercises"',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Display suggestion categories with labels
        _buildSuggestionCategory('Intensity', intensitySuggestions),
        const SizedBox(height: 8),
        _buildSuggestionCategory('Body Focus', bodyFocusSuggestions),
        const SizedBox(height: 8),
        _buildSuggestionCategory('Equipment', equipmentSuggestions),
        const SizedBox(height: 8),
        _buildSuggestionCategory('Modifications', modificationSuggestions),

        const SizedBox(height: 24),

        // Bottom buttons, with proper constraints
        Row(
          children: [
            if (ref
                .watch(workoutGenerationProvider)
                .refinementHistory
                .isNotEmpty)
              Expanded(
                child: SecondaryButton(
                  text: 'Undo Changes',
                  iconData: Icons.undo,
                  onPressed:
                      isRefining
                          ? null
                          : () {
                            ref
                                .read(workoutGenerationProvider.notifier)
                                .undoRefinement();
                            setState(() {
                              _refinementController.clear();
                              _currentStep = ConversationStep.refinementResult;
                            });
                          },
                ),
              ),
            if (ref
                .watch(workoutGenerationProvider)
                .refinementHistory
                .isNotEmpty)
              const SizedBox(width: 8),
            Expanded(
              child: SecondaryButton(
                text: 'Cancel',
                onPressed:
                    isRefining
                        ? null
                        : () {
                          setState(() {
                            _refinementController.clear();
                            _currentStep = ConversationStep.result;
                          });
                        },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PrimaryButton(
                text: 'Apply Changes',
                isLoading: isRefining,
                onPressed: isRefining ? null : () => _applyRefinement(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionCategory(String title, List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.small.copyWith(
            color: AppColors.mediumGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children:
                suggestions
                    .map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildSuggestionChip(suggestion),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRefinementResultStep(Map<String, dynamic> refinedWorkout) {
    final changesSummary = ref.watch(workoutGenerationProvider).changesSummary;
    final exercises = refinedWorkout['exercises'] as List? ?? [];
    final originalExercisesPreserved =
        changesSummary?.contains('Original exercises preserved') ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Changes summary section with better visibility
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                originalExercisesPreserved
                    ? AppColors.warning.withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  originalExercisesPreserved
                      ? AppColors.warning.withOpacity(0.3)
                      : AppColors.success.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    originalExercisesPreserved
                        ? Icons.info_outline
                        : Icons.check_circle,
                    color:
                        originalExercisesPreserved
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    originalExercisesPreserved
                        ? 'Workout Updated'
                        : 'Changes Applied',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          originalExercisesPreserved
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                changesSummary ?? 'Workout refined based on your feedback.',
                style: AppTextStyles.body,
              ),
              if (originalExercisesPreserved) ...[
                const SizedBox(height: 8),
                Text(
                  'For more specific exercise changes, try mentioning specific exercises or exercise types.',
                  style: AppTextStyles.small.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Workout details card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and description
                Text(
                  refinedWorkout['title'] ?? 'Custom Workout',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 8),
                Text(
                  refinedWorkout['description'] ??
                      'A personalized workout just for you.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      Icons.timer,
                      '${refinedWorkout['durationMinutes'] ?? 30} min',
                    ),
                    _buildStatColumn(
                      Icons.local_fire_department,
                      '${refinedWorkout['estimatedCaloriesBurn'] ?? 150} cal',
                    ),
                    _buildStatColumn(
                      Icons.fitness_center,
                      _capitalizeFirst(
                        refinedWorkout['difficulty'] ?? 'beginner',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Exercise list header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercises (${exercises.length})',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Sets × Reps',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ],
                ),
                const Divider(),

                // Exercise list
                if (exercises.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: exercises.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      final name = exercise['name'] ?? 'Exercise ${index + 1}';
                      final description = exercise['description'] ?? '';
                      final sets = exercise['sets'] ?? 3;
                      final reps = exercise['reps'] ?? 10;
                      final isRepBased = (exercise['durationSeconds'] == null);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                isRepBased
                                    ? '$sets × $reps'
                                    : '$sets × ${exercise['durationSeconds']}s',
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.mediumGrey,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'No exercises found',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Action buttons - cleaned up layout
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Undo changes button
            Expanded(
              child: SecondaryButton(
                text: 'Undo Changes',
                iconData: Icons.undo,
                onPressed: () {
                  ref.read(workoutGenerationProvider.notifier).undoRefinement();
                  setState(() {
                    _currentStep = ConversationStep.result;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            // Use workout button
            Expanded(
              child: PrimaryButton(
                text: 'Use Workout',
                onPressed: () {
                  setState(() {
                    _currentStep = ConversationStep.result;
                  });
                },
              ),
            ),
          ],
        ),

        // Refine again button as a full-width option
        const SizedBox(height: 16),
        SecondaryButton(
          text: 'Refine Again',
          iconData: Icons.edit,
          onPressed: () {
            setState(() {
              _refinementController.clear();
              _currentStep = ConversationStep.refining;
            });
          },
        ),
      ],
    );
  }

  Future<void> _applyRefinement() async {
    final refinementRequest = _refinementController.text.trim();
    if (refinementRequest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your refinement request')),
      );
      return;
    }

    final userProfile = await ref.read(userProfileProvider.future);
    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load user profile')),
      );
      return;
    }

    // Apply the refinement
    await ref
        .read(workoutGenerationProvider.notifier)
        .refineWorkout(
          userId: userProfile.userId,
          refinementRequest: refinementRequest,
        );

    // If successful, show the refined result
    if (mounted) {
      final error = ref.read(workoutGenerationProvider).error;
      if (error == null) {
        setState(() {
          _currentStep = ConversationStep.refinementResult;
        });
      }
    }
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Error Creating Workout',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(color: AppColors.error)),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Try Again',
            onPressed: () {
              setState(() {
                _currentStep = ConversationStep.categorySelection;
              });
            },
          ),
        ],
      ),
    );
  }

  void _saveWorkout(Map<String, dynamic> workoutData) async {
    try {
      // Get the user ID
      final userProfile = await ref.read(userProfileProvider.future);
      if (userProfile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to load user profile')),
          );
        }
        return;
      }

      // Create a workout model from the data
      final workout = _createWorkoutFromData(workoutData);

      // Save to repository
      final repository = CustomWorkoutRepository();
      await repository.saveCustomWorkout(userProfile.userId, workout);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Workout _createWorkoutFromData(Map<String, dynamic> data) {
    // Extract exercises
    final exercisesList = data['exercises'] as List<dynamic>? ?? [];
    final exercises =
        exercisesList.map((e) {
          return Exercise(
            id: (e['name'] ?? 'exercise').hashCode.toString(),
            name: e['name'] ?? 'Unnamed Exercise',
            description: e['description'] ?? 'No description available',
            imageUrl: 'assets/images/placeholder_exercise.jpg',
            sets: e['sets'] ?? 3,
            reps: e['reps'] ?? 10,
            durationSeconds: e['durationSeconds'],
            restBetweenSeconds: e['restBetweenSeconds'] ?? 30,
            targetArea: e['targetArea'] ?? 'Core',
          );
        }).toList();

    // Create the workout model
    return Workout(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] ?? 'Custom Workout',
      description:
          data['description'] ?? 'A personalized workout created just for you.',
      imageUrl: 'assets/images/placeholder_workout.jpg',
      category: _getCategoryFromName(data['category']),
      difficulty: _getDifficultyFromName(data['difficulty']),
      durationMinutes: data['durationMinutes'] ?? 30,
      estimatedCaloriesBurn: data['estimatedCaloriesBurn'] ?? 150,
      isAiGenerated: true,
      createdAt: DateTime.now(),
      createdBy: 'ai',
      exercises: exercises,
      equipment:
          data['equipment'] != null ? List<String>.from(data['equipment']) : [],
      tags: ['ai-generated'],
      featured: false,
    );
  }

  void _startWorkout(Map<String, dynamic> workoutData) {
    // Create a workout model from the data
    final workout = _createWorkoutFromData(workoutData);

    // Navigate to pre-workout setup screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PreWorkoutSetupScreen(workout: workout),
      ),
    );
  }

  // Helper methods
  String _getCategoryDisplayName(WorkoutCategory category) {
    switch (category) {
      case WorkoutCategory.bums:
        return 'Bums';
      case WorkoutCategory.tums:
        return 'Tums';
      case WorkoutCategory.fullBody:
        return 'Full Body';
      case WorkoutCategory.cardio:
        return 'Cardio';
      case WorkoutCategory.quickWorkout:
        return 'Quick';
    }
  }

  WorkoutCategory _getCategoryFromName(String? name) {
    if (name == null) return WorkoutCategory.fullBody;

    switch (name.toLowerCase()) {
      case 'bums':
        return WorkoutCategory.bums;
      case 'tums':
        return WorkoutCategory.tums;
      case 'fullbody':
        return WorkoutCategory.fullBody;
      case 'cardio':
        return WorkoutCategory.cardio;
      case 'quick':
      case 'quickworkout':
        return WorkoutCategory.quickWorkout;
      default:
        return WorkoutCategory.fullBody;
    }
  }

  WorkoutDifficulty _getDifficultyFromName(String? name) {
    if (name == null) return WorkoutDifficulty.beginner;

    switch (name.toLowerCase()) {
      case 'beginner':
        return WorkoutDifficulty.beginner;
      case 'intermediate':
        return WorkoutDifficulty.intermediate;
      case 'advanced':
        return WorkoutDifficulty.advanced;
      default:
        return WorkoutDifficulty.beginner;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
