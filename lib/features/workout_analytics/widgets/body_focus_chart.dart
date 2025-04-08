// lib/features/workout_analytics/widgets/body_focus_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';

class BodyFocusChart extends StatefulWidget {
  final Map<String, int> workoutsByCategory;
  final int totalWorkouts;

  const BodyFocusChart({
    Key? key, 
    required this.workoutsByCategory,
    required this.totalWorkouts,
  }) : super(key: key);

  @override
  State<BodyFocusChart> createState() => _BodyFocusChartState();
}

class _BodyFocusChartState extends State<BodyFocusChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.workoutsByCategory.isEmpty || widget.totalWorkouts == 0) {
      return _buildEmptyDataWidget();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: Row(
              children: [
                Expanded(
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
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildSections(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: widget.workoutsByCategory.entries.map((entry) {
              final percentage = widget.totalWorkouts > 0
                  ? ((entry.value / widget.totalWorkouts) * 100).toStringAsFixed(0)
                  : '0';
                  
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.key} (${entry.value}) - $percentage%',
                    style: AppTextStyles.caption,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyHeatSpot(double intensity, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(intensity),
            color.withOpacity(0),
          ],
          stops: const [0.3, 1.0],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return widget.workoutsByCategory.entries.map((entry) {
      final index = widget.workoutsByCategory.keys.toList().indexOf(entry.key);
      final isTouched = index == _touchedIndex;
      final color = _getCategoryColor(entry.key);
      final percentage = widget.totalWorkouts > 0
          ? ((entry.value / widget.totalWorkouts) * 100).toStringAsFixed(0)
          : '0';
          
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '$percentage%',
        radius: isTouched ? 80 : 70,
        titleStyle: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isTouched ? 18 : 14,
        ),
        titlePositionPercentageOffset: 0.6,
        borderSide: isTouched 
            ? const BorderSide(color: Colors.white, width: 3)
            : BorderSide.none,
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('bum')) return AppColors.salmon;
    if (lowerCategory.contains('tum')) return AppColors.popCoral;
    if (lowerCategory.contains('fullbody')) return AppColors.popBlue;
    if (lowerCategory.contains('cardio')) return AppColors.popGreen;
    if (lowerCategory.contains('quick')) return AppColors.popTurquoise;
    return AppColors.mediumGrey;
  }

  Widget _buildEmptyDataWidget() {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            Icon(Icons.pie_chart, size: 64, color: AppColors.lightGrey),
            const SizedBox(height: 16),
            Text(
              'No body focus data available yet',
              style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete workouts to see which body areas you focus on the most',
              style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}