// lib/features/home/widgets/achievements_summary_card.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bums_n_tums/features/workout_analytics/providers/achievement_provider.dart';
import 'package:bums_n_tums/features/workout_analytics/data/achievement_definitions.dart';
import 'package:bums_n_tums/shared/theme/app_colors.dart';
import 'package:bums_n_tums/shared/theme/app_text_styles.dart';
import 'package:bums_n_tums/shared/components/indicators/loading_indicator.dart';
import 'package:bums_n_tums/features/workout_analytics/screens/achievements_screen.dart'; // For navigation

// Convert back to ConsumerWidget
class AchievementsSummaryCard extends ConsumerWidget {
  const AchievementsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider that fetches achievement data
    final achievementsAsync = ref.watch(userAchievementsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration( // Keep decoration
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2),),],
      ),
      child: achievementsAsync.when(
        data: (achievements) {
          final currentUnlockedCount = achievements.where((a) => a.isUnlocked).length;
          final totalCount = achievements.length;

          // Sort and get recent icons (Keep this logic)
          List<DisplayAchievement> unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
          unlockedAchievements.sort((a, b) => b.unlockedInfo!.unlockedDate.compareTo(a.unlockedInfo!.unlockedDate));
          final recentIcons = unlockedAchievements.take(3).map((a) => a.definition.iconIdentifier).toList();

          // Return the Column directly (No ScaleTransition)
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row( /* Title/Counts */
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text("Achievements", style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
                   Text("$currentUnlockedCount / $totalCount Unlocked", style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey)),
                 ],
               ),
              const SizedBox(height: 16),
              if (currentUnlockedCount > 0)
                Row( /* Recent Icons */
                  children: [
                    Text("Recent: ", style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey)),
                    const SizedBox(width: 8),
                    Row(children: recentIcons.map((icon) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: Text(icon, style: const TextStyle(fontSize: 20)),)).toList()),
                    const Spacer(),
                    TextButton(
                      onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const AchievementsScreen())); },
                      child: Text("View All", style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.salmon)),
                    )
                  ],
                )
              else
                Center(child: Text("Keep working out to earn your first badge!", /*...*/)),
            ],
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) {
           if (kDebugMode) { print("Error loading achievements summary: $error\n$stack"); }
           return Center(child: Text("Could not load achievements", /*...*/));
        },
      ),
    );
  }
}