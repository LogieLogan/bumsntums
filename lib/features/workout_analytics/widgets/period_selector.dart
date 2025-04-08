// lib/features/workout_analytics/widgets/period_selector.dart
import 'package:flutter/material.dart';
import '../models/workout_analytics_timeframe.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';

class PeriodSelector extends StatelessWidget {
  final AnalyticsTimeframe selectedPeriod;
  final Function(AnalyticsTimeframe) onPeriodChanged;

  const PeriodSelector({
    Key? key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPeriodButton(
            AnalyticsTimeframe.weekly,
            selectedPeriod == AnalyticsTimeframe.weekly,
          ),
          const SizedBox(width: 16),
          _buildPeriodButton(
            AnalyticsTimeframe.monthly,
            selectedPeriod == AnalyticsTimeframe.monthly,
          ),
          const SizedBox(width: 16),
          _buildPeriodButton(
            AnalyticsTimeframe.yearly,
            selectedPeriod == AnalyticsTimeframe.yearly,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(AnalyticsTimeframe period, bool isSelected) {
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.salmon : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          period.label,
          style: AppTextStyles.small.copyWith(
            color: isSelected ? Colors.white : AppColors.mediumGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}