// lib/features/workout_analytics/widgets/analytics_stat_card.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/services/unit_conversion_service.dart';
import '../../../features/auth/models/user_profile.dart';

class AnalyticsStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AnalyticsStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.salmon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.small.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Factory constructor for weight stat card
  static AnalyticsStatCard weight({
    required double? weightKg,
    required UnitSystem unitSystem,
    Color color = AppColors.popCoral,
    VoidCallback? onTap,
  }) {
    final formattedWeight = UnitConversionService.formatWeight(
      weightKg,
      unitSystem,
    );

    return AnalyticsStatCard(
      title: 'Current Weight',
      value: formattedWeight,
      icon: Icons.monitor_weight_outlined,
      color: color,
      onTap: onTap,
    );
  }

  // Factory constructor for height stat card
  static AnalyticsStatCard height({
    required double? heightCm,
    required UnitSystem unitSystem,
    Color color = AppColors.popBlue,
    VoidCallback? onTap,
  }) {
    final formattedHeight = UnitConversionService.formatHeight(
      heightCm,
      unitSystem,
    );

    return AnalyticsStatCard(
      title: 'Height',
      value: formattedHeight,
      icon: Icons.height,
      color: color,
      onTap: onTap,
    );
  }

  // Factory constructor for distance stat card
  static AnalyticsStatCard distance({
    required double distanceKm,
    required UnitSystem unitSystem,
    required String title,
    Color color = AppColors.popGreen,
    VoidCallback? onTap,
  }) {
    final formattedDistance =
        unitSystem == UnitSystem.metric
            ? '${distanceKm.toStringAsFixed(2)} km'
            : '${(distanceKm * 0.621371).toStringAsFixed(2)} mi';

    return AnalyticsStatCard(
      title: title,
      value: formattedDistance,
      icon: Icons.straighten,
      color: color,
      onTap: onTap,
    );
  }

  // Add these factory constructors to your existing analytics_stat_card.dart file

  // Factory constructor for rep count stat card
  static AnalyticsStatCard repCount({
    required int repCount,
    required String title,
    Color color = AppColors.popYellow,
    VoidCallback? onTap,
  }) {
    return AnalyticsStatCard(
      title: title,
      value: '$repCount reps',
      icon: Icons.repeat,
      color: color,
      onTap: onTap,
    );
  }

  // Factory constructor for duration stat card
  static AnalyticsStatCard duration({
    required int durationMinutes,
    required String title,
    Color color = AppColors.salmon,
    VoidCallback? onTap,
  }) {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    final formattedDuration =
        hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return AnalyticsStatCard(
      title: title,
      value: formattedDuration,
      icon: Icons.timer,
      color: color,
      onTap: onTap,
    );
  }

  // Factory constructor for personal record stat card
  static AnalyticsStatCard personalRecord({
    required String recordType,
    required String recordValue,
    required DateTime recordDate,
    Color color = AppColors.popTurquoise,
    VoidCallback? onTap,
  }) {
    IconData recordIcon;

    switch (recordType.toLowerCase()) {
      case 'weight':
        recordIcon = Icons.fitness_center;
        break;
      case 'distance':
        recordIcon = Icons.straighten;
        break;
      case 'reps':
        recordIcon = Icons.repeat;
        break;
      case 'duration':
        recordIcon = Icons.timer;
        break;
      default:
        recordIcon = Icons.emoji_events;
    }

    return AnalyticsStatCard(
      title: 'PR: $recordType',
      value: recordValue,
      icon: recordIcon,
      color: color,
      onTap: onTap,
    );
  }

  // Factory constructor for workout streak stat card
  static AnalyticsStatCard streak({
    required int streakCount,
    required String title,
    Color color = AppColors.popYellow,
    VoidCallback? onTap,
  }) {
    return AnalyticsStatCard(
      title: title,
      value: '$streakCount days',
      icon: Icons.local_fire_department,
      color: color,
      onTap: onTap,
    );
  }
}
