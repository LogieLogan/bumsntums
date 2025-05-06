// lib/features/home/screens/profile_tab.dart
import 'package:bums_n_tums/features/workouts/screens/workout_history_screen.dart';
import 'package:bums_n_tums/shared/services/unit_conversion_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bums_n_tums/features/auth/models/user_profile.dart';
import 'package:bums_n_tums/features/auth/screens/edit_profile_screen.dart';
import 'package:bums_n_tums/features/settings/screens/gdpr_settings_screen.dart';
import 'package:bums_n_tums/shared/components/feedback/feedback_button.dart';
import 'package:bums_n_tums/shared/theme/app_colors.dart';
import 'package:bums_n_tums/shared/theme/app_text_styles.dart';
import '../providers/display_name_provider.dart';
import '../../../shared/analytics/firebase_analytics_service.dart'; // Import Analytics

class ProfileTab extends ConsumerWidget {
  final UserProfile profile;

  // Use super parameter for Key
  const ProfileTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Instantiate analytics service (or use provider)
    final AnalyticsService analyticsService = AnalyticsService();
    analyticsService.logScreenView(screenName: 'profile_tab'); // Log screen view

    // --- Add Scaffold and AppBar ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true, // Keep title centered if desired
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () {
               analyticsService.logEvent(name: 'profile_edit_tapped');
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                  // Consider passing the profile for pre-filling fields
                  // settings: RouteSettings(arguments: profile),
                ),
              );
            },
          ),
          // Add other actions like Settings later if needed
          // IconButton(icon: Icon(Icons.settings_outlined), onPressed: (){}),
        ],
      ),
      // --- End AppBar addition ---
      body: SingleChildScrollView( // Keep content scrollable
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            _buildProfileHeader(context, ref),

            const SizedBox(height: 24),

            // --- Reordered Sections for better flow ---

            // Workout History
            _buildListTileAction(
              context: context,
              icon: Icons.history,
              iconColor: AppColors.popBlue,
              title: 'Workout History',
              onTap: () {
                analyticsService.logEvent(name: 'profile_view_history');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WorkoutHistoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16), // Added space

             // Privacy & Data Settings
            _buildListTileAction(
              context: context,
              icon: Icons.privacy_tip_outlined,
              iconColor: AppColors.popGreen,
              title: 'Privacy & Data Settings',
              onTap: () {
                 analyticsService.logEvent(name: 'profile_view_privacy');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GdprSettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16), // Added space

            // Send Feedback
             _buildListTileAction(
              context: context,
              icon: Icons.feedback_outlined,
              iconColor: AppColors.popCoral,
              title: 'Send Feedback',
              onTap: () {
                 analyticsService.logEvent(name: 'profile_send_feedback_tapped');
                 final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
                 showDialog(
                   context: context,
                   builder: (context) => FeedbackDialog(userId: userId, currentScreen: 'Profile'),
                 );
              },
            ),

            // --- End Reordered Sections ---


            const SizedBox(height: 24),
            const Divider(), // Divider before detailed profile info
            const SizedBox(height: 24),


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
                            backgroundColor: AppColors.salmon.withAlpha((255*0.1).round()),
                            labelStyle: const TextStyle(color: AppColors.salmon),
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
                            backgroundColor: AppColors.popTurquoise.withAlpha((255*0.1).round()),
                            labelStyle: const TextStyle(color: AppColors.popTurquoise),
                          );
                        }).toList(),
                  ),
            ),

             const SizedBox(height: 16),

            // Available Equipment
            Text('Your Equipment', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            _buildChipCard(
              profile.availableEquipment.isEmpty
                  ? const Text('No equipment listed')
                  : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        profile.availableEquipment.map((equip) {
                          return Chip(
                            label: Text(equip),
                            backgroundColor: AppColors.popBlue.withAlpha((255*0.1).round()),
                            labelStyle: const TextStyle(color: AppColors.popBlue),
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
                            backgroundColor: AppColors.popGreen.withAlpha((255*0.1).round()),
                            labelStyle: const TextStyle(color: AppColors.popGreen),
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
                            backgroundColor: AppColors.popCoral.withAlpha((255*0.1).round()),
                            labelStyle: const TextStyle(color: AppColors.popCoral),
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
                            backgroundColor: AppColors.salmon.withAlpha((255*0.1).round()),
                            labelStyle: const TextStyle(color: AppColors.salmon),
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
                                backgroundColor: AppColors.popYellow.withAlpha((255*0.1).round()),
                                labelStyle: const TextStyle(color: AppColors.popYellow),
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

            // --- Removed old action buttons section ---
            // _buildActionButtons(context), // Removed as actions are now ListTiles or in AppBar
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.salmon.withAlpha((255*0.1).round()),
              child: const Icon(Icons.person_outline, color: AppColors.salmon, size: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      // Use watch for dynamic updates if name can change elsewhere
                      final displayNameAsync = ref.watch(displayNameProvider(profile.userId));
                      return displayNameAsync.when(
                        data: (name) => Text(name, style: AppTextStyles.h2),
                        loading: () => Text('Fitness Friend', style: AppTextStyles.h2),
                        error: (_, __) => Text('Fitness Friend', style: AppTextStyles.h2),
                      );
                    },
                  ),
                  if (profile.age != null) Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('Age: ${profile.age}', style: AppTextStyles.body),
                    ),
                  if (profile.heightCm != null && profile.weightKg != null) Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                         // Using helper service for consistent formatting
                        '${UnitConversionService.formatHeight(profile.heightCm, profile.unitPreference)}  •  ${UnitConversionService.formatWeight(profile.weightKg, profile.unitPreference)}',
                        style: AppTextStyles.body,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Level: ${profile.fitnessLevel.name}',
                       style: AppTextStyles.body,
                    ),
                   ),
                ],
              ),
            ),
             // Add Edit Icon Button directly here for quick access
            // IconButton(
            //   icon: Icon(Icons.edit_outlined, color: AppColors.mediumGrey),
            //   onPressed: () {
            //      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            //   },
            //   tooltip: 'Edit Profile',
            // ),
          ],
        ),
      ),
    );
  }

  // Refactored helper for list tile actions
   Widget _buildListTileAction({
     required BuildContext context,
     required IconData icon,
     required Color iconColor,
     required String title,
     required VoidCallback onTap,
     String? subtitle,
   }) {
      return Card(
         margin: const EdgeInsets.symmetric(vertical: 4.0),
         child: ListTile(
            leading: CircleAvatar(
               backgroundColor: iconColor.withAlpha((255*0.1).round()),
               child: Icon(icon, color: iconColor),
            ),
            title: Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
            subtitle: subtitle != null ? Text(subtitle, style: AppTextStyles.small) : null,
            trailing: const Icon(Icons.chevron_right, color: AppColors.mediumGrey),
            onTap: onTap,
         ),
      );
   }

  Widget _buildChipCard(Widget content) {
    return Card(
      elevation: 0, // Less emphasis than header/actions
      color: Colors.grey.shade50, // Subtle background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
          padding: const EdgeInsets.all(16),
          // Ensure content takes full width if needed (e.g., for single text lines)
          child: Align(
            alignment: Alignment.topLeft,
            child: content
          )
       ),
    );
  }

  // Removed _buildActionButtons as they are integrated into AppBar or ListTiles

  String _getMotivationTitle(MotivationType type) {
    // Keep this helper method as is
    switch (type) {
      case MotivationType.appearance: return 'Look Better';
      case MotivationType.health: return 'Health';
      case MotivationType.energy: return 'Energy';
      case MotivationType.stress: return 'Less Stress';
      case MotivationType.confidence: return 'Confidence';
      case MotivationType.other: return 'Other';
    }
  }
} // End of ProfileTab class