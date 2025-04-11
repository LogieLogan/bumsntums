import 'package:bums_n_tums/features/workout_analytics/widgets/achievement_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/achievement_provider.dart';
import '../../../shared/components/indicators/loading_indicator.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(userAchievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: AppTextStyles.h3.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.salmon,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: achievementsAsync.when(
        data: (achievements) {
          if (achievements.isEmpty) {
            return Center(
              child: Text(
                "No achievements defined yet.",
                style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
              ),
            );
          }

          return ListView.builder(
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];

              return AchievementTile(achievement: achievement);
            },
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) {
          print("Error loading achievements screen: $error\n$stack");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Could not load achievements.\nPlease try again later.",
                style: AppTextStyles.body.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}
