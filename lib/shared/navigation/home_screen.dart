// lib/features/workouts/screens/home_screen.dart
import 'package:bums_n_tums/features/nutrition/screens/scanner_screen.dart';
import 'package:bums_n_tums/features/settings/screens/gdpr_settings_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_browse_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/user_provider.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../constants/app_constants.dart';
import '../components/indicators/loading_indicator.dart';
import '../analytics/firebase_analytics_service.dart';
import '../../features/auth/models/user_profile.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/components/feedback/feedback_button.dart';
import '../../shared/providers/feedback_provider.dart';

Future<String?> getDisplayName(String userId) async {
  try {
    final doc =
        await FirebaseFirestore.instance
            .collection('users_personal_info')
            .doc(userId)
            .get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['displayName'];
    }
    return null;
  } catch (e) {
    print('Error fetching display name: $e');
    return null;
  }
}

// And update the provider to use this function:
final displayNameProvider = FutureProvider.family<String, String>((
  ref,
  userId,
) async {
  final displayName = await getDisplayName(userId);
  return displayName ?? 'Fitness Friend';
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _analyticsService = AnalyticsService();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView(screenName: 'home_screen');
  }

  void _onTabTapped(int index) async {
    setState(() {
      _currentIndex = index;
    });

    // If switching to profile tab, refresh the user profile data
    if (index == 3) {
      // Profile tab index
      try {
        await ref.refresh(userProfileProvider.future);
        print("Refreshed user profile data for profile tab");
      } catch (e) {
        print("Error refreshing profile data: $e");
      }
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

  Future<void> _signOut() async {
    try {
      await ref.read(authStateNotifierProvider.notifier).signOut();
      if (mounted) {
        GoRouter.of(context).go(AppConstants.loginRoute);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bums \'n\' Tums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: _signOut,
          ), // This should be the AI chat function
        ],
      ),
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Error loading profile'));
          }

          return _buildContent(profile);
        },
        loading:
            () => const LoadingIndicator(message: 'Loading your profile...'),
        error:
            (error, stackTrace) => Center(
              child: Text(
                'Error: ${error.toString()}',
                style: TextStyle(color: AppColors.error),
              ),
            ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.salmon,
        unselectedItemColor: AppColors.mediumGrey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildContent(UserProfile profile) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(profile);
      case 1:
        return _buildWorkoutsTab();
      case 2:
        return _buildScannerTab();
      case 3:
        return _buildProfileTab(profile);
      default:
        return _buildHomeTab(profile);
    }
  }

  Widget _buildHomeTab(UserProfile profile) {
    return SingleChildScrollView(
      // Add this SingleChildScrollView wrapper
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.salmon,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer(
                                builder: (context, ref, child) {
                                  final displayNameAsync = ref.watch(
                                    displayNameProvider(profile.userId),
                                  );
                                  return displayNameAsync.when(
                                    data:
                                        (name) => Text(
                                          'Welcome, $name!',
                                          style: AppTextStyles.h3,
                                        ),
                                    loading:
                                        () => Text(
                                          'Welcome, Fitness Friend!',
                                          style: AppTextStyles.h3,
                                        ),
                                    error:
                                        (_, __) => Text(
                                          'Welcome, Fitness Friend!',
                                          style: AppTextStyles.h3,
                                        ),
                                  );
                                },
                              ),
                              Text(
                                'Let\'s get moving today.',
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats section
            Text('Your Stats', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Workouts', '0', Icons.fitness_center),
                    _buildStatItem(
                      'Calories',
                      '0',
                      Icons.local_fire_department,
                    ),
                    _buildStatItem('Minutes', '0', Icons.timer),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick actions
            Text('Quick Actions', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Start Workout',
                    Icons.play_circle_fill,
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
                  child: _buildQuickActionCard(
                    'Scan Food',
                    Icons.camera_alt,
                    AppColors.popTurquoise,
                    () {
                      setState(() {
                        _currentIndex = 2; // Switch to scanner tab
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Featured workout
            Text('Featured Workout', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 120,
                    color: AppColors.salmon.withOpacity(0.2),
                    child: const Center(
                      child: Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: AppColors.salmon,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Beginner Bums \'n\' Tums',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '20 minutes • 8 exercises',
                          style: AppTextStyles.small,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to workout detail for a featured workout
                            // For now, we can use a mock workout ID until we have real data
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => const WorkoutDetailScreen(
                                      workoutId: 'bums-001',
                                    ),
                              ),
                            );
                          },
                          child: const Text('Start Workout'),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.salmon, size: 32),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.h2),
        Text(label, style: AppTextStyles.small),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutsTab() {
    // Replace the placeholder with the actual WorkoutBrowseScreen
    return const WorkoutBrowseScreen();
  }

  Widget _buildScannerTab() {
    // Replace the placeholder with the actual ScannerScreen
    return const ScannerScreen();
  }

  Widget _buildProfileTab(UserProfile profile) {
    print('Building profile tab with data:');
    print('User ID: ${profile.userId}');
    print('Goals: ${profile.goals}');
    print('Body Focus Areas: ${profile.bodyFocusAreas}');
    print('Dietary Preferences: ${profile.dietaryPreferences}');
    print('Allergies: ${profile.allergies}');
    print('Health Conditions: ${profile.healthConditions}');
    print('Motivations: ${profile.motivations}');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.salmon,
                    child: Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final displayNameAsync = ref.watch(
                              displayNameProvider(profile.userId),
                            );
                            return displayNameAsync.when(
                              data:
                                  (name) => Text(name, style: AppTextStyles.h2),
                              loading:
                                  () => Text(
                                    'Fitness Friend',
                                    style: AppTextStyles.h2,
                                  ),
                              error:
                                  (_, __) => Text(
                                    'Fitness Friend',
                                    style: AppTextStyles.h2,
                                  ),
                            );
                          },
                        ),
                        if (profile.age != null)
                          Text(
                            'Age: ${profile.age}',
                            style: AppTextStyles.body,
                          ),
                        if (profile.heightCm != null &&
                            profile.weightKg != null)
                          Text(
                            'Height: ${profile.heightCm}cm • Weight: ${profile.weightKg}kg',
                            style: AppTextStyles.body,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Fitness goals
          Text('Your Fitness Goals', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  profile.goals.isEmpty
                      ? const Text('No goals set yet')
                      : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            profile.goals.map((goal) {
                              return Chip(
                                label: Text(goal.name),
                                backgroundColor: AppColors.salmon.withOpacity(
                                  0.1,
                                ),
                                labelStyle: TextStyle(color: AppColors.salmon),
                              );
                            }).toList(),
                      ),
            ),
          ),

          const SizedBox(height: 16),

          // Body focus areas
          Text('Body Focus Areas', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  profile.bodyFocusAreas.isEmpty
                      ? const Text('No focus areas set yet')
                      : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            profile.bodyFocusAreas.map((area) {
                              return Chip(
                                label: Text(area),
                                backgroundColor: AppColors.popTurquoise
                                    .withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: AppColors.popTurquoise,
                                ),
                              );
                            }).toList(),
                      ),
            ),
          ),

          const SizedBox(height: 16),

          // Dietary preferences
          Text('Dietary Preferences', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  profile.dietaryPreferences.isEmpty
                      ? const Text('No dietary preferences set')
                      : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            profile.dietaryPreferences.map((pref) {
                              return Chip(
                                label: Text(pref),
                                backgroundColor: AppColors.popGreen.withOpacity(
                                  0.1,
                                ),
                                labelStyle: TextStyle(
                                  color: AppColors.popGreen,
                                ),
                              );
                            }).toList(),
                      ),
            ),
          ),

          // After the Dietary preferences section in _buildProfileTab
          const SizedBox(height: 16),

          // Allergies section
          Text('Allergies', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  profile.allergies.isEmpty
                      ? const Text('No allergies set')
                      : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            profile.allergies.map((allergy) {
                              return Chip(
                                label: Text(allergy),
                                backgroundColor: AppColors.salmon.withOpacity(
                                  0.1,
                                ),
                                labelStyle: TextStyle(color: AppColors.salmon),
                              );
                            }).toList(),
                      ),
            ),
          ),

          const SizedBox(height: 16),

          // Health conditions section
          Text('Health Conditions', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  profile.healthConditions.isEmpty
                      ? const Text('No health conditions set')
                      : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            profile.healthConditions.map((condition) {
                              return Chip(
                                label: Text(condition),
                                backgroundColor: AppColors.popBlue.withOpacity(
                                  0.1,
                                ),
                                labelStyle: TextStyle(color: AppColors.popBlue),
                              );
                            }).toList(),
                      ),
            ),
          ),

          const SizedBox(height: 16),

          // Motivations section
          Text('Motivations', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child:
                  profile.motivations.isEmpty
                      ? const Text('No motivations set')
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                profile.motivations.map((motivation) {
                                  return Chip(
                                    label: Text(
                                      _getMotivationTitle(motivation),
                                    ),
                                    backgroundColor: AppColors.popYellow
                                        .withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color: AppColors.popYellow,
                                    ),
                                  );
                                }).toList(),
                          ),
                          if (profile.customMotivation != null &&
                              profile.customMotivation!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Custom motivation: ${profile.customMotivation}',
                                style: AppTextStyles.small,
                              ),
                            ),
                        ],
                      ),
            ),
          ),

          const SizedBox(height: 24),

          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to edit profile screen
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
          ),

          const SizedBox(height: 16),

          // Feedback button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Show feedback dialog
                final userId =
                    FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
                showDialog(
                  context: context,
                  builder:
                      (context) => FeedbackDialog(
                        userId: userId,
                        currentScreen: 'Profile',
                      ),
                );
              },
              icon: const Icon(Icons.feedback_outlined),
              label: const Text('Send Feedback'),
            ),
          ),

          const SizedBox(height: 16),

          // Privacy & GDPR settings button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GdprSettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.privacy_tip_outlined),
              label: const Text('Privacy & Data Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
