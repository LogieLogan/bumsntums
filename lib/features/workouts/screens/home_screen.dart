// lib/features/workouts/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/providers/user_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import '../../../features/auth/models/user_profile.dart';

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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authStateNotifierProvider.notifier).signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
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
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Error loading profile'),
            );
          }
          
          return _buildContent(profile);
        },
        loading: () => const LoadingIndicator(
          message: 'Loading your profile...',
        ),
        error: (error, stackTrace) => Center(
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
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
    return Padding(
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
                            Text(
                              'Welcome, ${profile.displayName ?? 'Fitness Friend'}!',
                              style: AppTextStyles.h3,
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
          Text(
            'Your Stats',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Workouts', '0', Icons.fitness_center),
                  _buildStatItem('Calories', '0', Icons.local_fire_department),
                  _buildStatItem('Minutes', '0', Icons.timer),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick actions
          Text(
            'Quick Actions',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Start Workout',
                  Icons.play_circle_fill,
                  AppColors.salmon,
                  () {
                    setState(() {
                      _currentIndex = 1; // Switch to workouts tab
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  'Scan Food',
                  Icons.camera_alt,
                  AppColors.teal,
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
          Text(
            'Featured Workout',
            style: AppTextStyles.h3,
          ),
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
                          // TODO: Navigate to workout detail
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
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.salmon,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.h2,
        ),
        Text(
          label,
          style: AppTextStyles.small,
        ),
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
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutsTab() {
    // Placeholder for workouts tab
    return const Center(
      child: Text('Workouts Coming Soon'),
    );
  }

  Widget _buildScannerTab() {
    // Placeholder for scanner tab
    return const Center(
      child: Text('Food Scanner Coming Soon'),
    );
  }

  Widget _buildProfileTab(UserProfile profile) {
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
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName ?? 'Fitness Friend',
                          style: AppTextStyles.h2,
                        ),
                        if (profile.age != null)
                          Text(
                            'Age: ${profile.age}',
                            style: AppTextStyles.body,
                          ),
                        if (profile.heightCm != null && profile.weightKg != null)
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
          Text(
            'Your Fitness Goals',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: profile.goals.isEmpty
                  ? const Text('No goals set yet')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.goals.map((goal) {
                        return Chip(
                          label: Text(goal.name),
                          backgroundColor: AppColors.salmon.withOpacity(0.1),
                          labelStyle: TextStyle(color: AppColors.salmon),
                        );
                      }).toList(),
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Body focus areas
          Text(
            'Body Focus Areas',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: profile.bodyFocusAreas.isEmpty
                  ? const Text('No focus areas set yet')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.bodyFocusAreas.map((area) {
                        return Chip(
                          label: Text(area),
                          backgroundColor: AppColors.teal.withOpacity(0.1),
                          labelStyle: TextStyle(color: AppColors.teal),
                        );
                      }).toList(),
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Dietary preferences
          Text(
            'Dietary Preferences',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: profile.dietaryPreferences.isEmpty
                  ? const Text('No dietary preferences set')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.dietaryPreferences.map((pref) {
                        return Chip(
                          label: Text(pref),
                          backgroundColor: AppColors.popGreen.withOpacity(0.1),
                          labelStyle: TextStyle(color: AppColors.popGreen),
                        );
                      }).toList(),
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
        ],
      ),
    );
  }
}