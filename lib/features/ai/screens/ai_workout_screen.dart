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
  customRequest,
  generating,
  result,
  refining,
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
  final TextEditingController _customRequestController = TextEditingController();
  final TextEditingController _refinementController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      _currentStep = ConversationStep.customRequest;
    });
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

    final customRequest = _customRequestController.text.trim().isNotEmpty
        ? _customRequestController.text.trim()
        : null;

    // Set parameters then generate
    final notifier = ref.read(workoutGenerationProvider.notifier);
    notifier.setParameters(
      workoutCategory: _selectedCategory.name,
      durationMinutes: _selectedDuration,
      focusAreas: _getFocusAreasForCategory(_selectedCategory),
      specialRequest: customRequest,
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

  // Start the refinement process
  void _startRefinement() {
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
                
                // Custom request
                if (_currentStep == ConversationStep.customRequest)
                  _buildCustomRequestStep(),
                
                // Generating state
                if (_currentStep == ConversationStep.generating)
                  _buildGeneratingStep(),
                
                // Result state
                if (_currentStep == ConversationStep.result && recommendationState.workoutData != null)
                  _buildWorkoutResult(recommendationState.workoutData!),
                
                // Refinement state
                if (_currentStep == ConversationStep.refining && recommendationState.workoutData != null)
                  _buildRefinementStep(recommendationState.workoutData!),
                
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

  Widget _buildCategorySelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you like to focus on today?',
          style: AppTextStyles.h3,
        ),
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
      onTap: () => _selectCategory(category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 0.9 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 32,
            ),
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
        Text(
          'Select workout duration in minutes:',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [10, 15, 20, 30, 45, 60].map((duration) {
            final isSelected = _selectedDuration == duration;
            return InkWell(
              onTap: () => _selectDuration(duration),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.salmon : Colors.grey.withOpacity(0.1),
                  border: Border.all(
                    color: isSelected ? AppColors.salmon : Colors.grey.withOpacity(0.3),
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
          'For example: "Include resistance bands" or "Focus on stretching"',
          style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _customRequestController,
          decoration: InputDecoration(
            hintText: 'Enter any special requests (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
          children: [
            'No jumping',
            'Low impact',
            'Include resistance bands',
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
              _buildSummaryRow('Focus', _getCategoryDisplayName(_selectedCategory)),
              _buildSummaryRow('Duration', '$_selectedDuration minutes'),
              if (_customRequestController.text.isNotEmpty)
                _buildSummaryRow('Special Request', _customRequestController.text),
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
                    _currentStep = ConversationStep.durationSelection;
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
        final currentText = _customRequestController.text;
        if (currentText.isEmpty) {
          _customRequestController.text = text;
        } else if (!currentText.toLowerCase().contains(text.toLowerCase())) {
          _customRequestController.text = '$currentText, $text';
        }
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
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body,
            ),
          ),
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
                        return Transform.rotate(
                          angle: value,
                          child: child,
                        );
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
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
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

  Widget _buildWorkoutResult(Map<String, dynamic> workoutData) {
    // Extract workout details
    final title = workoutData['title'] ?? 'Custom Workout';
    final description = workoutData['description'] ?? 'A personalized workout just for you.';
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
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    _buildStatColumn(Icons.local_fire_department, '$calories cal'),
                    _buildStatColumn(Icons.fitness_center, _capitalizeFirst(difficulty)),
                  ],
                ),
                const SizedBox(height: 16),

                // Equipment list if present
                if (equipment is List && equipment.isNotEmpty) ...[
                  Text('Equipment:', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(equipment.length, (index) {
                      return Chip(
                        label: Text(equipment[index].toString()),
                        backgroundColor: AppColors.popTurquoise.withOpacity(0.1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],

                // Exercise list header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Exercises (${exercises.length})', 
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                    Text('Sets × Reps', 
                        style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey)),
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
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              isRepBased ? '$sets × $reps' : '$sets × ${exercise['durationSeconds']}s',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How was this workout suggestion?', 
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thanks for your feedback!')),
        );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you like to change about this workout?',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _refinementController,
          decoration: InputDecoration(
            hintText: 'E.g., "Make it harder" or "Add more core exercises"',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        // Suggestion chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Make it easier',
            'Make it harder',
            'More core work',
            'Less cardio',
            'Add stretching',
            'Different equipment',
          ].map((suggestion) => _buildSuggestionChip(suggestion)).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'Cancel',
                onPressed: () {
                  setState(() {
                    _refinementController.clear();
                    _currentStep = ConversationStep.result;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'Refine Workout',
                onPressed: () {
                  // In a full implementation, this would send the refinement request
                  // For now, just return to result step
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refinement feature coming soon!')),
                  );
                  setState(() {
                    _currentStep = ConversationStep.result;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
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
Text(
            error,
            style: TextStyle(color: AppColors.error),
          ),
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
    final exercises = exercisesList.map((e) {
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
      description: data['description'] ?? 'A personalized workout created just for you.',
      imageUrl: 'assets/images/placeholder_workout.jpg',
      category: _getCategoryFromName(data['category']),
      difficulty: _getDifficultyFromName(data['difficulty']),
      durationMinutes: data['durationMinutes'] ?? 30,
      estimatedCaloriesBurn: data['estimatedCaloriesBurn'] ?? 150,
      isAiGenerated: true,
      createdAt: DateTime.now(),
      createdBy: 'ai',
      exercises: exercises,
      equipment: data['equipment'] != null ? List<String>.from(data['equipment']) : [],
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