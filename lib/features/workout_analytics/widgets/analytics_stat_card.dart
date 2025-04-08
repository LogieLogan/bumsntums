// lib/features/workout_analytics/widgets/analytics_stat_card.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/services/unit_conversion_service.dart';
import '../../../features/auth/models/user_profile.dart';

class AnalyticsStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AnalyticsStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.salmon,
    this.onTap,
  }) : super(key: key);

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
    final formattedWeight = UnitConversionService.formatWeight(weightKg, unitSystem);
    
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
    final formattedHeight = UnitConversionService.formatHeight(heightCm, unitSystem);
    
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
    final formattedDistance = unitSystem == UnitSystem.metric
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
}