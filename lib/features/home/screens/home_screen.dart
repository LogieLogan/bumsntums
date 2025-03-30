// lib/features/home/screens/home_screen.dart
import 'package:bums_n_tums/features/ai/screens/ai_chat_screen.dart';
import 'package:bums_n_tums/features/nutrition/screens/scanner_screen.dart';
import 'package:bums_n_tums/features/workout_planning/screens/weekly_planning_screen.dart';
import 'package:bums_n_tums/features/workouts/screens/workout_browse_screen.dart';
import '../../workout_planning/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bums_n_tums/features/auth/providers/user_provider.dart';
import 'package:bums_n_tums/shared/analytics/firebase_analytics_service.dart';
import 'package:bums_n_tums/shared/components/indicators/loading_indicator.dart';
import 'package:bums_n_tums/shared/theme/color_palette.dart';
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
        final _ =  ref.refresh(userProfileProvider.future);
      } catch (e) {
        print("Error refreshing profile data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bums & Tums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AIChatScreen()),
              );
            },
          ),
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
        type: BottomNavigationBarType.fixed, // Add this line for 5 items
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Scan'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Plan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildContent(profile) {
    switch (_currentIndex) {
      case 0:
        return HomeTab(profile: profile, onTabChange: _onTabTapped);
      case 1:
        return const WorkoutBrowseScreen();
      case 2:
        return const ScannerScreen();
      case 3:
        return WeeklyPlanningScreen(userId: profile.userId);
      case 4:
        return ProfileTab(profile: profile);
      default:
        return HomeTab(profile: profile, onTabChange: _onTabTapped);
    }
  }
}
