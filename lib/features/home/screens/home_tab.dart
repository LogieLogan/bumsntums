// lib/features/home/screens/home_tab.dart
import 'package:bums_n_tums/features/workouts/models/workout.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_detail_screen.dart';
import 'package:bums_n_tums/shared/providers/environment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bums_n_tums/features/ai/screens/ai_chat_screen.dart';
import 'package:bums_n_tums/features/auth/models/user_profile.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_browse_screen.dart';
import 'package:bums_n_tums/features/ai/screens/workout_creation/ai_workout_screen.dart';
import 'package:bums_n_tums/shared/theme/color_palette.dart';
import 'package:bums_n_tums/shared/theme/text_styles.dart';
import '../widgets/welcome_card.dart';
import '../widgets/stats_card.dart';
import '../providers/recommended_workout_provider.dart';

class HomeTab extends ConsumerStatefulWidget {
  final UserProfile profile;
  final Function(int) onTabChange;

  const HomeTab({Key? key, required this.profile, required this.onTabChange})
    : super(key: key);

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card with user info
              WelcomeCard(profile: widget.profile),

              const SizedBox(height: 24),

              // Highlighted AI Workout Creator - Featured at the top
              _buildAIWorkoutFeature(),

              const SizedBox(height: 32),

              // Quick Actions Section
              _buildSectionHeader("Quick Actions", Icons.flash_on),
              const SizedBox(height: 12),
              _buildQuickActionsGrid(context),

              const SizedBox(height: 32),

              // Today's Recommendation
              _buildSectionHeader("Today's Suggestion", Icons.recommend),
              const SizedBox(height: 12),
              _buildRecommendedWorkout(),

              const SizedBox(height: 32),

              // Your stats section
              _buildSectionHeader("Your Progress", Icons.trending_up),
              const SizedBox(height: 12),
              StatsCard(userId: widget.profile.userId),

              const SizedBox(height: 32),

              // // Calendar and Analytics
              // _buildSectionHeader("Calendar & Analytics", Icons.upcoming),
              // const SizedBox(height: 12),
              // _buildProgressTrackingFeatures(),

              // const SizedBox(height: 32),

              // Coming Soon Features (Challenges & Progress Tracking)
              _buildSectionHeader("Coming Soon", Icons.upcoming),
              const SizedBox(height: 12),
              _buildComingSoonFeatures(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.salmon, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAIWorkoutFeature() {
    return GestureDetector(
      onTap: () {
        // Show loading indicator while checking if environment service is ready
        final loadingDialog = showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(
                child: CircularProgressIndicator(color: AppColors.salmon),
              ),
        );

        // Check if environment service is initialized
        ref
            .read(environmentServiceInitProvider.future)
            .then(
              (service) {
                // Close loading dialog
                Navigator.of(context).pop();

                // Navigate to AI Workout screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AIWorkoutScreen(),
                  ),
                );
              },
              onError: (error) {
                // Close loading dialog
                Navigator.of(context).pop();

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unable to load AI Workout Creator. Please try again later.',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );

                print('Error initializing environment service: $error');
              },
            );
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.salmon, AppColors.popCoral],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.salmon.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.fitness_center,
                  size: 150,
                  color: Colors.white,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "AI Workout Creator",
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Create personalized workouts tailored to your goals, fitness level, and available equipment",
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Create Workout",
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.salmon,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          color: AppColors.salmon,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionItem(
                    "Start Workout",
                    Icons.play_circle_filled,
                    AppColors.salmon,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const WorkoutBrowseScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionItem(
                    "Scan Food",
                    Icons.camera_alt,
                    AppColors.popTurquoise,
                    () {
                      widget.onTabChange(2); // Switch to scanner tab
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionItem(
                    "Fitness Assistant",
                    Icons.chat_bubble_outline,
                    AppColors.popBlue,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AIChatScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionItem(
                    "Plan",
                    Icons.calendar_month,
                    AppColors.popGreen,
                    () {
                      widget.onTabChange(3); // Switch to profile tab
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.small.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedWorkout() {
    return Consumer(
      builder: (context, ref, child) {
        final recommendedWorkoutAsync = ref.watch(
          recommendedWorkoutProvider(widget.profile),
        );

        return recommendedWorkoutAsync.when(
          data: (workout) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.popBlue.withOpacity(0.7),
                          AppColors.popBlue,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: Opacity(
                            opacity: 0.2,
                            child: Icon(
                              Icons.directions_run,
                              size: 100,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Suggested Workout for Today",
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                workout.title,
                                style: AppTextStyles.h3.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${workout.durationMinutes} minutes • ${_getDifficultyText(workout.difficulty)}",
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.description,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to this specific workout
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => WorkoutDetailScreen(
                                      workoutId: workout.id,
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.salmon,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Start Workout",
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (_, __) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text("Could not load recommendation"),
                ),
              ),
        );
      },
    );
  }

  String _getDifficultyText(WorkoutDifficulty difficulty) {
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        return "Beginner friendly";
      case WorkoutDifficulty.intermediate:
        return "Intermediate";
      case WorkoutDifficulty.advanced:
        return "Advanced";
    }
  }

  Widget _buildComingSoonFeatures() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenges preview
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.popBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: AppColors.popBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Fitness Challenges",
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.popBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Coming Soon",
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Compete with yourself and others",
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // Progress tracking preview
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.popGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: AppColors.popGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Advanced Progress Tracking",
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.popGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Coming Soon",
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Visualize your fitness journey and celebrate achievements",
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
