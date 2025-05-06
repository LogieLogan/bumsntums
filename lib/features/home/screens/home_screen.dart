// lib/features/home/screens/home_screen.dart
import 'package:bums_n_tums/features/auth/models/user_profile.dart';
import 'package:bums_n_tums/features/nutrition/screens/nutrition_screen.dart';
import 'package:bums_n_tums/features/workout_planning/screens/weekly_planning_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_browse_screen.dart';
import '../../workout_planning/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bums_n_tums/features/auth/providers/user_provider.dart';
import 'package:bums_n_tums/shared/analytics/firebase_analytics_service.dart';
import 'package:bums_n_tums/shared/components/indicators/loading_indicator.dart';
import 'package:bums_n_tums/shared/theme/app_colors.dart';
import 'home_tab.dart';
import 'profile_tab.dart';

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
    _analyticsService.logScreenView(screenName: 'home_screen_container');
  }

  void _onTabTapped(int index) async {
    setState(() {
      _currentIndex = index;
    });

    String tabName = _getTabName(index);
    _analyticsService.logEvent(
      name: 'tab_viewed',
      parameters: {'tab_name': tabName},
    );

    if (index == 4) {
      try {
        ref.invalidate(userProfileProvider);
      } catch (e) {
        print("Error invalidating profile data: $e");
      }
    }
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Workouts';
      case 2:
        return 'Nutrition';
      case 3:
        return 'Plan';
      case 4:
        return 'Profile';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text(
                'Error: User profile not found. Please try logging in again.',
                style: TextStyle(color: AppColors.error),
              ),
            );
          }
          return _buildContent(profile);
        },
        loading:
            () => const Center(
              child: LoadingIndicator(message: 'Loading your space...'),
            ),
        error:
            (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load profile',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There was an issue retrieving your profile data. Please check your connection and try restarting the app.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error details: ${error.toString()}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.salmon,
        unselectedItemColor: AppColors.mediumGrey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Plan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildContent(UserProfile profile) {
    switch (_currentIndex) {
      case 0:
        return HomeTab(profile: profile, onTabChange: _onTabTapped);
      case 1:
        return const WorkoutBrowseScreen();
      case 2:
        return const NutritionScreen();
      case 3:
        return WeeklyPlanningScreen(userId: profile.userId);
      case 4:
        return ProfileTab(profile: profile);
      default:
        return HomeTab(profile: profile, onTabChange: _onTabTapped);
    }
  }
}
