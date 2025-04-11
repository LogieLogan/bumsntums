// lib/features/home/screens/profile_tab.dart
import 'package:bums_n_tums/features/workouts/screens/workout_history_screen.dart';
import 'package:bums_n_tums/shared/services/unit_conversion_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bums_n_tums/features/auth/models/user_profile.dart';
import 'package:bums_n_tums/features/auth/screens/edit_profile_screen.dart';
import 'package:bums_n_tums/features/settings/screens/gdpr_settings_screen.dart';
import 'package:bums_n_tums/shared/components/feedback/feedback_button.dart';
import 'package:bums_n_tums/shared/theme/app_colors.dart';
import 'package:bums_n_tums/shared/theme/app_text_styles.dart';
import '../providers/display_name_provider.dart';

class ProfileTab extends ConsumerWidget {
  final UserProfile profile;

  const ProfileTab({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          _buildProfileHeader(context, ref),

          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.history, color: AppColors.popBlue),
            title: const Text('Workout History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WorkoutHistoryScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Fitness goals
          Text('Your Fitness Goals', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          _buildChipCard(
            profile.goals.isEmpty
                ? const Text('No goals set yet')
                : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      profile.goals.map((goal) {
                        return Chip(
                          label: Text(goal.name),
                          backgroundColor: AppColors.salmon.withOpacity(0.1),
                          labelStyle: TextStyle(color: AppColors.salmon),
                        );
                      }).toList(),
                ),
          ),

          const SizedBox(height: 16),

          // Body focus areas
          Text('Body Focus Areas', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          _buildChipCard(
            profile.bodyFocusAreas.isEmpty
                ? const Text('No focus areas set yet')
                : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      profile.bodyFocusAreas.map((area) {
                        return Chip(
                          label: Text(area),
                          backgroundColor: AppColors.popTurquoise.withOpacity(
                            0.1,
                          ),
                          labelStyle: TextStyle(color: AppColors.popTurquoise),
                        );
                      }).toList(),
                ),
          ),

          const SizedBox(height: 16),

          // Dietary preferences
          Text('Dietary Preferences', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          _buildChipCard(
            profile.dietaryPreferences.isEmpty
                ? const Text('No dietary preferences set')
                : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      profile.dietaryPreferences.map((pref) {
                        return Chip(
                          label: Text(pref),
                          backgroundColor: AppColors.popGreen.withOpacity(0.1),
                          labelStyle: TextStyle(color: AppColors.popGreen),
                        );
                      }).toList(),
                ),
          ),

          const SizedBox(height: 16),

          // Allergies section
          Text('Allergies', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          _buildChipCard(
            profile.allergies.isEmpty
                ? const Text('No allergies set')
                : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      profile.allergies.map((allergy) {
                        return Chip(
                          label: Text(allergy),
                          backgroundColor: AppColors.salmon.withOpacity(0.1),
                          labelStyle: TextStyle(color: AppColors.salmon),
                        );
                      }).toList(),
                ),
          ),

          const SizedBox(height: 16),

          // Health conditions section
          Text('Health Conditions', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          _buildChipCard(
            profile.healthConditions.isEmpty
                ? const Text('No health conditions set')
                : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      profile.healthConditions.map((condition) {
                        return Chip(
                          label: Text(condition),
                          backgroundColor: AppColors.popBlue.withOpacity(0.1),
                          labelStyle: TextStyle(color: AppColors.popBlue),
                        );
                      }).toList(),
                ),
          ),

          const SizedBox(height: 16),

          // Motivations section
          Text('Motivations', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          _buildChipCard(
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
                              label: Text(_getMotivationTitle(motivation)),
                              backgroundColor: AppColors.popYellow.withOpacity(
                                0.1,
                              ),
                              labelStyle: TextStyle(color: AppColors.popYellow),
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

          const SizedBox(height: 24),

          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref) {
    return Card(
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
                        data: (name) => Text(name, style: AppTextStyles.h2),
                        loading:
                            () =>
                                Text('Fitness Friend', style: AppTextStyles.h2),
                        error:
                            (_, __) =>
                                Text('Fitness Friend', style: AppTextStyles.h2),
                      );
                    },
                  ),
                  if (profile.age != null)
                    Text('Age: ${profile.age}', style: AppTextStyles.body),
                  if (profile.heightCm != null && profile.weightKg != null)
                    Text(
                      'Height: ${UnitConversionService.formatHeight(profile.heightCm, profile.unitPreference)} • Weight: ${UnitConversionService.formatWeight(profile.weightKg, profile.unitPreference)}',
                      style: AppTextStyles.body,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipCard(Widget content) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Edit profile button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
          },
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
        ),

        const SizedBox(height: 16),

        // Feedback button
        OutlinedButton.icon(
          onPressed: () {
            // Show feedback dialog
            final userId =
                FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
            showDialog(
              context: context,
              builder:
                  (context) =>
                      FeedbackDialog(userId: userId, currentScreen: 'Profile'),
            );
          },
          icon: const Icon(Icons.feedback_outlined),
          label: const Text('Send Feedback'),
        ),

        const SizedBox(height: 16),

        // Privacy & GDPR settings button
        OutlinedButton.icon(
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
      ],
    );
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
}
