// lib/features/workouts/screens/workout_completion_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../models/workout.dart';
import '../models/workout_log.dart';
import '../providers/workout_provider.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../shared/components/buttons/primary_button.dart';
import '../../../shared/theme/color_palette.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/providers/feedback_provider.dart';

class WorkoutCompletionScreen extends ConsumerStatefulWidget {
  final Workout workout;
  final int elapsedTimeSeconds;

  const WorkoutCompletionScreen({
    super.key,
    required this.workout,
    required this.elapsedTimeSeconds,
  });

  @override
  ConsumerState<WorkoutCompletionScreen> createState() =>
      _WorkoutCompletionScreenState();
}

class _WorkoutCompletionScreenState
    extends ConsumerState<WorkoutCompletionScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  late ConfettiController _confettiController;
  int _rating = 4; // Default rating
  bool _feltEasy = false;
  bool _feltTooHard = false;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isAnimationScheduled = false;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView(
      screenName: 'workout_completion',
      screenClass: 'WorkoutCompletionScreen',
    );

    // Log workout completed
    _analytics.logWorkoutCompleted(
      workoutId: widget.workout.id,
      workoutName: widget.workout.title,
      durationSeconds: widget.elapsedTimeSeconds,
    );

    // Initialize confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Play celebration animation with safety check
    _isAnimationScheduled = true;
    _animationTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _isAnimationScheduled) {
        try {
          _confettiController.play();
        } catch (e) {
          print("Error playing confetti animation: $e");
        }
      }
    });
  }

  @override
  void dispose() {
    _isAnimationScheduled = false;
    _animationTimer?.cancel();
    _confettiController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caloriesBurned = _calculateCaloriesBurned();

    return Scaffold(
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              // App bar with confetti
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Background gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.salmon, AppColors.popCoral],
                          ),
                        ),
                      ),

                      // Confetti
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirection:
                              -pi / 2, // Straight up (using dart:math pi)
                          emissionFrequency: 0.05,
                          numberOfParticles: 20,
                          maxBlastForce: 20,
                          minBlastForce: 5,
                          gravity: 0.1,
                        ),
                      ),

                      // Title text
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Workout Complete!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Great job finishing ${widget.workout.title}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Workout summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      // Stats cards
                      Row(
                        children: [
                          _buildStatCard(
                            'Duration',
                            _formatTime(widget.elapsedTimeSeconds),
                            Icons.timer,
                            AppColors.popBlue,
                          ),
                          _buildStatCard(
                            'Calories',
                            '$caloriesBurned',
                            Icons.local_fire_department,
                            AppColors.popCoral,
                          ),
                          _buildStatCard(
                            'Exercises',
                            '${widget.workout.exercises.length}',
                            Icons.fitness_center,
                            AppColors.popGreen,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Rate your workout
                      Text(
                        'How was your workout?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      // Star rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color:
                                  index < _rating
                                      ? AppColors.popYellow
                                      : Colors.grey,
                              size: 36,
                            ),
                            onPressed: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                          );
                        }),
                      ),

                      const SizedBox(height: 16),

                      // Difficulty feedback
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeedbackChip('Too Easy', _feltEasy, () {
                            setState(() {
                              _feltEasy = !_feltEasy;
                              if (_feltEasy) _feltTooHard = false;
                            });
                          }),
                          const SizedBox(width: 16),
                          _buildFeedbackChip('Too Hard', _feltTooHard, () {
                            setState(() {
                              _feltTooHard = !_feltTooHard;
                              if (_feltTooHard) _feltEasy = false;
                            });
                          }),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Comments
                      Text(
                        'Additional Comments (Optional)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _feedbackController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Tell us more about your experience...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // What's next section
                      Text(
                        'What\'s Next?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      // Suggested actions
                      _buildActionCard(
                        'Share Your Achievement',
                        'Let your friends know about your workout progress',
                        Icons.share,
                        AppColors.popBlue,
                        () {
                          // TODO: Implement sharing functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sharing coming soon!'),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildActionCard(
                        'Explore Similar Workouts',
                        'Find more workouts like this one',
                        Icons.fitness_center,
                        AppColors.salmon,
                        () {
                          // TODO: Navigate to similar workouts
                          Navigator.pop(context);
                        },
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Save feedback button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: PrimaryButton(
              text: 'Save & Continue',
              onPressed: _saveWorkoutFeedback,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.salmon.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.salmon : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.salmon : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.salmon : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _saveWorkoutFeedback() async {
    // Get the current user ID
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save feedback')),
      );
      return;
    }

    // Create user feedback for workout service
    final feedback = UserFeedback(
      rating: _rating,
      feltEasy: _feltEasy,
      feltTooHard: _feltTooHard,
      comments:
          _feedbackController.text.isNotEmpty ? _feedbackController.text : null,
    );

    // Complete the workout using the provider
    ref
        .read(workoutServiceProvider)
        .updateWorkoutFeedback(userId, widget.workout.id, feedback);

    // Also log the feedback through our feedback service for analytics
    final feedbackService = ref.read(feedbackServiceProvider);
    feedbackService.submitSatisfactionRating(
      userId: userId,
      rating: _rating,
      comment: _feedbackController.text,
      featureName: 'Workout - ${widget.workout.title}',
    );

    // Navigate back to the main screen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  int _calculateCaloriesBurned() {
    // A simple calculation based on workout estimated burn rate and actual time
    final estimatedPerMinute =
        widget.workout.estimatedCaloriesBurn / widget.workout.durationMinutes;
    final actualMinutes = widget.elapsedTimeSeconds / 60;
    return (estimatedPerMinute * actualMinutes).round();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
