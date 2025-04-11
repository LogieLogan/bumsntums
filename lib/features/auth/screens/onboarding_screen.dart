// lib/features/auth/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/onboarding/profile_setup_coordinator.dart'; // Updated import
import '../../../shared/constants/app_constants.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView(screenName: 'onboarding_screen');
  }

  void _onProfileSetupComplete(UserProfile profile) async {
    print("Profile setup complete, navigating to home");

    try {
      // Force a refresh of the userProfileProvider
      final _ = ref.refresh(userProfileProvider.future);

      // Explicitly fetch the profile to ensure data is updated
      final userService = ref.read(userProfileServiceProvider);
      final updatedProfile = await userService.getUserProfile(profile.userId);
      print("Fetched updated profile data:");
      print("Goals: ${updatedProfile?.goals}");
      print("Body Focus Areas: ${updatedProfile?.bodyFocusAreas}");
      print("Dietary Preferences: ${updatedProfile?.dietaryPreferences}");
      print("Allergies: ${updatedProfile?.allergies}");
      print("Health Conditions: ${updatedProfile?.healthConditions}");
      print("Motivations: ${updatedProfile?.motivations}");

      // Add a short delay to ensure the state is updated
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate to home
      if (mounted) {
        GoRouter.of(context).go(AppConstants.homeRoute);
      }
    } catch (e) {
      print("Error refreshing profile data: $e");
      if (mounted) {
        GoRouter.of(context).go(AppConstants.homeRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Setup Profile"), // Or dynamic title
        actions: [
          TextButton(
            onPressed: () async {
              // Optional: Show Confirmation Dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text("Sign Out?"),
                      content: Text(
                        "Are you sure you want to sign out and use a different account? Your progress on this screen will be lost.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text("Sign Out"),
                        ),
                      ],
                    ),
              );

              if (confirmed == true) {
                try {
                  // Call sign out using the service provider
                  await ref.read(authServiceProvider).signOut();

                  // Navigate back to login screen (use your specific router logic)
                  // Example using GoRouter assuming '/' is login or initial auth gate
                  if (context.mounted) {
                    // Check if widget is still in the tree
                    context.go('/');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error signing out: $e")),
                    );
                  }
                }
              }
            },
            child: Text(
              "Sign Out",
              style: TextStyle(color: Colors.white), // Adjust style as needed
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true, // Important for keyboard handling
      body: Container(
        color: AppColors.pink,
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative elements
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.popYellow.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.popTurquoise.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: authState.when(
                  data: (user) {
                    if (user == null) {
                      return const Center(
                        child: Text(
                          'You need to be logged in to access this page',
                        ),
                      );
                    }

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // App logo and title
                            const Icon(
                              Icons.fitness_center,
                              size: 48,
                              color: AppColors.pink,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create Your Profile',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                color: AppColors.pink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Profile setup form
                            Expanded(
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final userProfileAsync = ref.watch(
                                    userProfileProvider,
                                  );

                                  return userProfileAsync.when(
                                    data: (profile) {
                                      final userProfile =
                                          profile ??
                                          UserProfile.empty(user.uid);

                                      return ProfileSetupForm(
                                        initialProfile: userProfile,
                                        onComplete: _onProfileSetupComplete,
                                      );
                                    },
                                    loading:
                                        () => const LoadingIndicator(
                                          message: 'Loading your profile...',
                                        ),
                                    error:
                                        (error, stackTrace) => Center(
                                          child: Text(
                                            'Error loading profile: ${error.toString()}',
                                            style: TextStyle(
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading:
                      () => const Center(
                        child: LoadingIndicator(message: 'Loading...'),
                      ),
                  error:
                      (error, stackTrace) => Center(
                        child: Text(
                          'Error: ${error.toString()}',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
