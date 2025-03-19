// lib/features/ai/screens/ai_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../features/auth/providers/user_provider.dart';
import '../../../features/workouts/models/workout.dart';
import '../../../features/workouts/models/exercise.dart';
import '../providers/workout_recommendation_provider.dart';
import '../../../features/workouts/screens/workout_execution_screen.dart';
import '../../workouts/providers/workout_execution_provider.dart';

class AIWorkoutScreen extends ConsumerStatefulWidget {
  const AIWorkoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AIWorkoutScreen> createState() => _AIWorkoutScreenState();
}

class _AIWorkoutScreenState extends ConsumerState<AIWorkoutScreen> {
  WorkoutCategory _selectedCategory = WorkoutCategory.fullBody;
  int _selectedDuration = 30;
  final TextEditingController _customRequestController =
      TextEditingController();
      
        ProviderListenable? get analyticsProvider => null;

  @override
  void dispose() {
    _customRequestController.dispose();
    super.dispose();
  }

  Future<void> _generateWorkout() async {
    final userProfile = await ref.read(userProfileProvider.future);
    if (userProfile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load user profile')),
        );
      }
      return;
    }

    final customRequest =
        _customRequestController.text.trim().isNotEmpty
            ? _customRequestController.text.trim()
            : null;

    // Use userId instead of userProfile
    await ref
        .read(workoutRecommendationProvider.notifier)
        .generateWorkout(
          userId: userProfile.userId,
          category: _selectedCategory,
          maxMinutes: _selectedDuration,
          specificRequest: customRequest,
        );
  }

  @override
  Widget build(BuildContext context) {
    final recommendationState = ref.watch(workoutRecommendationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Workout Creator')),
      body:
          recommendationState.workoutData != null
              ? _buildWorkoutResult(recommendationState.workoutData!)
              : _buildWorkoutForm(recommendationState),
    );
  }

  Widget _buildWorkoutForm(WorkoutRecommendationState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Create Your Perfect Workout', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Our AI will generate a personalized workout based on your profile and preferences.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 24),

          // Category selection
          Text('Focus Area', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryOption(WorkoutCategory.bums, 'Bums'),
              _buildCategoryOption(WorkoutCategory.tums, 'Tums'),
              _buildCategoryOption(WorkoutCategory.fullBody, 'Full Body'),
              _buildCategoryOption(WorkoutCategory.cardio, 'Cardio'),
              _buildCategoryOption(WorkoutCategory.quickWorkout, 'Quick'),
            ],
          ),

          const SizedBox(height: 24),

          // Duration slider
          Text('Duration: $_selectedDuration minutes', style: AppTextStyles.h3),
          Slider(
            value: _selectedDuration.toDouble(),
            min: 10,
            max: 60,
            divisions: 10,
            label: '$_selectedDuration min',
            activeColor: AppColors.salmon,
            onChanged: (value) {
              setState(() {
                _selectedDuration = value.round();
              });
            },
          ),

          const SizedBox(height: 24),

          // Custom request
          Text('Special Requests (Optional)', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          TextField(
            controller: _customRequestController,
            decoration: InputDecoration(
              hintText:
                  'E.g., "Include resistance bands" or "Focus on stretching"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 32),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _generateWorkout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  state.isLoading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Create My Workout'),
            ),
          ),

          // Error message
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.error!.contains('Rate limit')
                                ? 'Rate Limit Reached'
                                : 'Error Creating Workout',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.error!.contains('Rate limit')
                          ? state.error!
                          : 'Something went wrong. Please try again later.',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryOption(WorkoutCategory category, String label) {
    final isSelected = _selectedCategory == category;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.salmon : AppColors.salmon.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.salmon,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutResult(Map<String, dynamic> workoutData) {
    // Convert raw AI-generated data to a Workout object
    final exercises =
        (workoutData['exercises'] as List)
            .map(
              (e) => Exercise(
                id: e['name'].hashCode.toString(),
                name: e['name'],
                description: e['description'],
                imageUrl: 'assets/images/placeholder_exercise.jpg',
                sets: e['sets'],
                reps: e['reps'],
                durationSeconds: e['durationSeconds'],
                restBetweenSeconds: e['restBetweenSeconds'],
                targetArea: e['targetArea'],
              ),
            )
            .toList();

    final workout = Workout(
      id: workoutData['id'],
      title: workoutData['title'],
      description: workoutData['description'],
      imageUrl: 'assets/images/placeholder_workout.jpg',
      category: WorkoutCategory.values.firstWhere(
        (c) => c.name == workoutData['category'],
        orElse: () => WorkoutCategory.fullBody,
      ),
      difficulty: WorkoutDifficulty.values.firstWhere(
        (d) => d.name == workoutData['difficulty'],
        orElse: () => WorkoutDifficulty.beginner,
      ),
      durationMinutes: workoutData['durationMinutes'],
      estimatedCaloriesBurn: workoutData['estimatedCaloriesBurn'],
      isAiGenerated: true,
      createdAt: DateTime.parse(workoutData['createdAt']),
      createdBy: 'ai',
      exercises: exercises,
      equipment: List<String>.from(workoutData['equipment']),
      tags: ['ai-generated'],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(workoutRecommendationProvider.notifier).reset();
                },
              ),
              Expanded(
                child: Text(
                  'Your AI Workout',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // For balance
            ],
          ),

          const SizedBox(height: 16),

          // Workout info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout.title, style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(workout.description, style: AppTextStyles.body),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildWorkoutStat(
                        Icons.timer,
                        '${workout.durationMinutes} min',
                      ),
                      _buildWorkoutStat(
                        Icons.local_fire_department,
                        '${workout.estimatedCaloriesBurn} cal',
                      ),
                      _buildWorkoutStat(
                        Icons.fitness_center,
                        workout.difficulty.name,
                      ),
                    ],
                  ),

                  // Equipment list
                  if (workout.equipment.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Equipment Needed:',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children:
                          workout.equipment.map((item) {
                            return Chip(
                              label: Text(item),
                              backgroundColor: AppColors.popTurquoise
                                  .withOpacity(0.1),
                              labelStyle: TextStyle(
                                color: AppColors.popTurquoise,
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Exercises list
          Text('Exercises', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: workout.exercises.length,
            itemBuilder: (context, index) {
              final exercise = workout.exercises[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.salmon.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: AppTextStyles.h2.copyWith(
                                  color: AppColors.salmon,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Target: ${exercise.targetArea}',
                                  style: AppTextStyles.small.copyWith(
                                    color: AppColors.mediumGrey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildExerciseStat(
                                      'Sets',
                                      exercise.sets.toString(),
                                    ),
                                    const SizedBox(width: 16),
                                    _buildExerciseStat(
                                      'Reps',
                                      exercise.reps.toString(),
                                    ),
                                    const SizedBox(width: 16),
                                    _buildExerciseStat(
                                      'Rest',
                                      '${exercise.restBetweenSeconds}s',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Exercise description
                      Text(exercise.description, style: AppTextStyles.small),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Feedback section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paleGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How was this workout?', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(
                  'Your feedback helps us improve our workout recommendations.',
                  style: AppTextStyles.small,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeedbackOption(
                      icon: Icons.thumb_down,
                      label: 'Too Easy',
                      onTap: () => _submitWorkoutFeedback('too_easy'),
                    ),
                    _buildFeedbackOption(
                      icon: Icons.thumb_up,
                      label: 'Just Right',
                      onTap: () => _submitWorkoutFeedback('just_right'),
                    ),
                    _buildFeedbackOption(
                      icon: Icons.fitness_center,
                      label: 'Too Hard',
                      onTap: () => _submitWorkoutFeedback('too_hard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(workoutRecommendationProvider.notifier).reset();
                  },
                  child: const Text('Start Over'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Initialize the workout using the correct method name
                    ref
                        .read(workoutExecutionProvider.notifier)
                        .startWorkout(workout);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const WorkoutExecutionScreen(),
                      ),
                    );
                  },
                  child: const Text('Start Workout'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: AppColors.salmon),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.small.copyWith(color: AppColors.darkGrey),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to submit feedback
  void _submitWorkoutFeedback(String feedbackType) {
    // Get the workout ID
    final workoutData = ref.read(workoutRecommendationProvider).workoutData;
    if (workoutData == null) return;

    final workoutId = workoutData['id'];

    // Analytics event
    ref
        .read(analyticsProvider!)
        .logEvent(
          name: 'ai_workout_feedback',
          parameters: {'workout_id': workoutId, 'feedback_type': feedbackType},
        );

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thanks for your feedback!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _buildWorkoutStat(IconData icon, String text) {
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

  Widget _buildExerciseStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.mediumGrey),
        ),
        Text(
          value,
          style: AppTextStyles.small.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
