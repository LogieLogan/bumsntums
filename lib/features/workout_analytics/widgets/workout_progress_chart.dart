// lib/features/workout_analytics/widgets/workout_progress_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/workout_stats.dart';
import '../models/workout_analytics_timeframe.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/analytics/firebase_analytics_service.dart';

class WorkoutProgressChart extends StatefulWidget {
  final UserWorkoutStats stats;
  final AnalyticsTimeframe timeframe;

  const WorkoutProgressChart({
    Key? key,
    required this.stats,
    required this.timeframe,
  }) : super(key: key);

  @override
  State<WorkoutProgressChart> createState() => _WorkoutProgressChartState();
}

class _WorkoutProgressChartState extends State<WorkoutProgressChart> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _metricTabs = [
    'Workouts',
    'Minutes',
    'Calories',
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _metricTabs.length, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            tabs: _metricTabs.map((tab) => Tab(text: tab)).toList(),
            labelColor: AppColors.salmon,
            unselectedLabelColor: AppColors.mediumGrey,
            indicatorColor: AppColors.salmon,
            indicatorSize: TabBarIndicatorSize.label,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWorkoutsChart(),
                _buildMinutesChart(),
                _buildCaloriesChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsChart() {
    // Generate data based on timeframe
    final data = _generateChartData(
      (month, year) => 10, // Get workout count for month/year - replace with actual data
      widget.timeframe,
    );
    
    if (data.isEmpty) {
      return _buildEmptyDataWidget();
    }
    
    return _buildLineChart(
      data,
      widget.timeframe,
      'Workouts',
      AppColors.salmon,
    );
  }

  Widget _buildMinutesChart() {
    // Generate data based on timeframe
    final data = _generateChartData(
      (month, year) => 250, // Get minutes for month/year - replace with actual data
      widget.timeframe,
    );
    
    if (data.isEmpty) {
      return _buildEmptyDataWidget();
    }
    
    return _buildLineChart(
      data,
      widget.timeframe,
      'Minutes',
      AppColors.popBlue,
    );
  }

  Widget _buildCaloriesChart() {
    // Generate data based on timeframe
    final data = _generateChartData(
      (month, year) => 1500, // Get calories for month/year - replace with actual data
      widget.timeframe,
    );
    
    if (data.isEmpty) {
      return _buildEmptyDataWidget();
    }
    
    return _buildLineChart(
      data,
      widget.timeframe,
      'Calories',
      AppColors.popCoral,
    );
  }

  List<FlSpot> _generateChartData(
    int Function(int month, int year) dataGetter,
    AnalyticsTimeframe timeframe,
  ) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    
    switch (timeframe) {
      case AnalyticsTimeframe.weekly:
        // Last 7 days
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          spots.add(FlSpot(6 - i.toDouble(), 
            10 + (i % 3 * 5).toDouble())); // Mock data for now
        }
        break;
      
      case AnalyticsTimeframe.monthly:
        // Last 30 days
        for (int i = 29; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          spots.add(FlSpot(29 - i.toDouble(), 
            (i % 7 * 3 + 5).toDouble())); // Mock data for now
        }
        break;
      
      case AnalyticsTimeframe.yearly:
        // Last 12 months
        for (int i = 11; i >= 0; i--) {
          final month = now.month - i > 0 ? now.month - i : now.month - i + 12;
          final year = now.month - i > 0 ? now.year : now.year - 1;
          spots.add(FlSpot(11 - i.toDouble(), 
            (month % 3 * 10 + 20).toDouble())); // Mock data for now
        }
        break;
    }
    
    return spots;
  }

  Widget _buildLineChart(
    List<FlSpot> spots,
    AnalyticsTimeframe timeframe,
    String yAxisLabel,
    Color color,
  ) {
    final maxY = spots.isEmpty ? 10.0 : spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.2;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.paleGrey,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % (maxY / 5).ceil() != 0) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                // Show dates based on timeframe
                final label = _getTimeLabel(value.toInt(), timeframe);
                if (label.isEmpty) return const SizedBox();
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(color: AppColors.mediumGrey),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Highlight the last point
                if (index == spots.length - 1) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: color,
                  );
                }
                return FlDotCirclePainter(
                  radius: 3,
                  color: color.withOpacity(0.5),
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: spots.length - 1.0,
        minY: 0,
        maxY: maxY,
      ),
    );
  }

  String _getTimeLabel(int index, AnalyticsTimeframe timeframe) {
    final now = DateTime.now();
    
    switch (timeframe) {
      case AnalyticsTimeframe.weekly:
        if (index % 2 == 0) {
          final date = now.subtract(Duration(days: 6 - index));
          return DateFormat('E').format(date);
        }
        break;
      
      case AnalyticsTimeframe.monthly:
        if (index % 7 == 0) {
          final date = now.subtract(Duration(days: 29 - index));
          return DateFormat('MMM d').format(date);
        }
        break;
      
      case AnalyticsTimeframe.yearly:
        final month = now.month - (11 - index);
        final year = month > 0 ? now.year : now.year - 1;
        final monthIndex = month > 0 ? month : month + 12;
        final date = DateTime(year, monthIndex);
        return DateFormat('MMM').format(date);
    }
    
    return '';
  }

// Continuing from lib/features/workout_analytics/widgets/workout_progress_chart.dart

  Widget _buildEmptyDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: AppColors.lightGrey),
          const SizedBox(height: 16),
          Text(
            'Not enough data yet',
            style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete more workouts to see your progress',
            style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}