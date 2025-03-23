// lib/features/workouts/widgets/calendar/rest_day_indicator.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/color_palette.dart';
import '../../../../shared/theme/text_styles.dart';

class RestDayIndicator extends StatelessWidget {
  final bool isRecommended;
  final String? reason;
  
  const RestDayIndicator({
    Key? key,
    required this.isRecommended,
    this.reason,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isRecommended) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: reason ?? 'Recommended rest day to aid recovery',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: AppColors.popBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: AppColors.popBlue.withOpacity(0.5),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.nightlight_round,
              size: 14.0,
              color: AppColors.popBlue,
            ),
            const SizedBox(width: 4.0),
            Text(
              'Rest Day',
              style: AppTextStyles.small.copyWith(
                color: AppColors.popBlue,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}