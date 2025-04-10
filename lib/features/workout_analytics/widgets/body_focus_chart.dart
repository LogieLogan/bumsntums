// lib/features/workout_analytics/widgets/body_focus_chart.dart
import 'package:bums_n_tums/shared/theme/color_palette.dart';
import 'package:bums_n_tums/shared/theme/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BodyFocusChart extends StatefulWidget {
  final Map<String, int> workoutsByCategory;

  const BodyFocusChart({Key? key, required this.workoutsByCategory})
    : super(key: key);

  @override
  State<BodyFocusChart> createState() => _BodyFocusChartState();
}

class _BodyFocusChartState extends State<BodyFocusChart> {
  int? _touchedIndex;

  Color _getCategoryColor(String category) {
    final lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('chest')) return AppColors.terracotta;
    if (lowerCategory.contains('back')) return AppColors.popBlue;
    if (lowerCategory.contains('legs') ||
        lowerCategory.contains('lower body') ||
        lowerCategory.contains('glutes') ||
        lowerCategory.contains('calves') ||
        lowerCategory.contains('hamstrings') ||
        lowerCategory.contains('quadriceps')) {
      return AppColors.pink;
    }
    if (lowerCategory.contains('arms') ||
        lowerCategory.contains('upper body') ||
        lowerCategory.contains('biceps') ||
        lowerCategory.contains('triceps')) {
      return AppColors.popYellow;
    }
    if (lowerCategory.contains('shoulders')) return AppColors.popTurquoise;
    if (lowerCategory.contains('core') ||
        lowerCategory.contains('abs') ||
        lowerCategory.contains('abdominals') ||
        lowerCategory.contains('tum')) {
      return AppColors.popCoral;
    }
    if (lowerCategory.contains('cardio')) return AppColors.popGreen;
    if (lowerCategory.contains('full body')) return AppColors.salmon;

    if (lowerCategory.contains('bum')) return AppColors.popGreen;
    return AppColors.mediumGrey;
  }

  @override
  Widget build(BuildContext context) {
    final double internalTotal = widget.workoutsByCategory.values.fold(
      0.0,
      (sum, item) => sum + item,
    );

    if (widget.workoutsByCategory.isEmpty || internalTotal <= 0) {
      return _buildEmptyDataWidget();
    }

    final cardBackgroundColor =
        AppColors.white; // Use AppColors.white or offWhite
    final shadowColor = Colors.black.withOpacity(0.05);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Body Focus Distribution',
            // Use AppTextStyles
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildSections(internalTotal),
              ),
              swapAnimationDuration: const Duration(milliseconds: 150),
              swapAnimationCurve: Curves.linear,
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend(internalTotal),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(double internalTotal) {
    final entries = widget.workoutsByCategory.entries.toList();

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final isTouched = index == _touchedIndex;
      final color = _getCategoryColor(entry.key);

      final double percentageValue =
          internalTotal > 0 ? (entry.value / internalTotal) * 100 : 0.0;

      final String percentageText =
          percentageValue >= 1 ? '${percentageValue.toStringAsFixed(0)}%' : '';

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: percentageText,
        radius: isTouched ? 70 : 60,
        // Use AppTextStyles
        titleStyle: AppTextStyles.caption.copyWith(
          color: AppColors.white, // Ensure contrast with section color
          fontWeight: FontWeight.bold, // Make percentage bolder
          fontSize: isTouched ? 14 : 12,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 2.0),
          ],
        ),
        titlePositionPercentageOffset: 0.65,
        borderSide:
            isTouched
                ? BorderSide(color: color.withOpacity(0.8), width: 4)
                : BorderSide.none,
      );
    });
  }

  Widget _buildLegend(double internalTotal) {
    final entries = widget.workoutsByCategory.entries.toList();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children:
          entries.map((entry) {
            final percentage =
                internalTotal > 0 ? ((entry.value / internalTotal) * 100) : 0.0;
            final color = _getCategoryColor(entry.key);

            if (percentage < 1) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${entry.key} (${entry.value}) - ${percentage.toStringAsFixed(0)}%',
                      // Use AppTextStyles
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.darkGrey,
                      ), // Adjust color if needed
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildEmptyDataWidget() {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white, // Use AppColors
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 50,
              color: AppColors.mediumGrey,
            ), // Use AppColors
            const SizedBox(height: 16),
            Text(
              'No Body Focus Data',
              // Use AppTextStyles and AppColors
              style: AppTextStyles.body.copyWith(
                color: AppColors.mediumGrey,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete workouts to see your focus distribution.',
              // Use AppTextStyles and AppColors
              style: AppTextStyles.caption.copyWith(color: AppColors.darkGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
