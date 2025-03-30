// lib/features/workout_planning/widgets/plan_analytics_card.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/workout_plan.dart';
import '../../../shared/theme/color_palette.dart';

class PlanAnalyticsCard extends StatelessWidget {
  final WorkoutPlan plan;
  
  const PlanAnalyticsCard({
    Key? key,
    required this.plan,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDistributionChart(),
            const SizedBox(height: 16),
            if (plan.aiSuggestionRationale != null) ...[
              Text(
                'AI Insights',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plan.aiSuggestionRationale!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDistributionChart() {
    // If no distribution data, show placeholder
    if (plan.targetAreaDistribution == null || plan.targetAreaDistribution!.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No workout distribution data available'),
        ),
      );
    }
    
    // Prepare data for pie chart
    final distributionData = plan.targetAreaDistribution!;
    
    // Create color mapping for categories
    final colorMap = {
      'Bums': AppColors.pink,
      'Tums': AppColors.popCoral,
      'Full Body': AppColors.popBlue,
      'Cardio': AppColors.popGreen,
      'Arms': AppColors.popYellow,
      'Legs': AppColors.terracotta,
      'Core': AppColors.popTurquoise,
    };
    
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: distributionData.entries.map((entry) {
            return PieChartSectionData(
              color: colorMap[entry.key] ?? Colors.grey,
              value: entry.value,
              title: '${entry.value.toStringAsFixed(0)}%',
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}