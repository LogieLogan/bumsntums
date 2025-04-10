// lib/features/workout_analytics/widgets/workout_progress_chart.dart

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/workout_analytics_timeframe.dart';
import '../providers/workout_stats_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/theme/color_palette.dart';
import '../../../shared/theme/text_styles.dart';
import '../../../shared/components/indicators/loading_indicator.dart';

class WorkoutProgressChart extends ConsumerStatefulWidget {
  final AnalyticsTimeframe timeframe;

  const WorkoutProgressChart({Key? key, required this.timeframe})
    : super(key: key);

  @override
  ConsumerState<WorkoutProgressChart> createState() =>
      _WorkoutProgressChartState();
}

class _WorkoutProgressChartState extends ConsumerState<WorkoutProgressChart>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _metricTabs = ['Workouts', 'Minutes', 'Calories'];

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
    final userId = ref.watch(authStateProvider).value?.uid;

    final progressDataAsync = ref.watch(
      workoutProgressDataProvider((
        userId: userId ?? '',
        timeframe: widget.timeframe,
      )),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TabBar(
              controller: _tabController,
              tabs: _metricTabs.map((tab) => Tab(text: tab)).toList(),
              labelColor: AppColors.salmon,
              unselectedLabelColor: AppColors.mediumGrey,
              indicatorColor: AppColors.salmon,
              indicatorSize: TabBarIndicatorSize.label,
            ),
          ),
          const SizedBox(height: 16),

          progressDataAsync.when(
            data: (progressData) {
              if (progressData.isEmpty) {
                return SizedBox(height: 250, child: _buildEmptyDataWidget());
              }

              final workoutSpots = _createSpots(progressData, 'workouts');
              final minuteSpots = _createSpots(progressData, 'minutes');
              final calorieSpots = _createSpots(progressData, 'calories');

              return SizedBox(
                height: 250,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLineChart(
                        workoutSpots,
                        progressData,
                        widget.timeframe,
                        'Workouts',
                        AppColors.salmon,
                      ),
                      _buildLineChart(
                        minuteSpots,
                        progressData,
                        widget.timeframe,
                        'Minutes',
                        AppColors.popBlue,
                      ),
                      _buildLineChart(
                        calorieSpots,
                        progressData,
                        widget.timeframe,
                        'Calories',
                        AppColors.popCoral,
                      ),
                    ],
                  ),
                ),
              );
            },
            loading:
                () => const SizedBox(
                  height: 250,
                  child: Center(child: LoadingIndicator()),
                ),
            error:
                (error, stack) => SizedBox(
                  height: 250,
                  child: Center(
                    child: Text(
                      'Error loading progress: $error',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _createSpots(List<Map<String, dynamic>> data, String metricKey) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final value = (data[i][metricKey] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    if (spots.length == 1) {
      spots.insert(0, FlSpot(-1, spots[0].y));
      spots.add(FlSpot(1, spots[0].y));
    }
    return spots;
  }

  Widget _buildLineChart(
    List<FlSpot> spots,
    List<Map<String, dynamic>> originalData,
    AnalyticsTimeframe timeframe,
    String yAxisLabel, // e.g., 'Workouts', 'Minutes', 'Calories'
    Color color,
  ) {
    // ... (previous calculations for minX, maxX, maxY, intervals remain the same) ...
    if (originalData.isEmpty || spots.isEmpty) {
      return _buildEmptyDataWidget();
    }
    final double minX = spots.first.x;
    final double maxX = spots.last.x;
    final double maxSpotY = spots.map((spot) => spot.y).reduce(max);
    final double maxY = (maxSpotY * 1.2).clamp(5.0, double.infinity);
    final double horizontalInterval = (maxY / 5).ceilToDouble().clamp(
      1.0,
      double.infinity,
    );
    final double leftInterval = horizontalInterval;
    double bottomInterval = 1.0;
    if (spots.length > 10) {
      if (timeframe == AnalyticsTimeframe.weekly)
        bottomInterval = 2.0;
      else if (timeframe == AnalyticsTimeframe.monthly)
        bottomInterval = 1.0;
      else if (timeframe == AnalyticsTimeframe.yearly)
        bottomInterval = 2.0;
    }

    return LineChart(
      LineChartData(
        // *** MOVE animation parameters here ***
        lineTouchData: LineTouchData(
          // ... (touchTooltipData, handleBuiltInTouches, getTouchedSpotIndicator remain the same) ...
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot touchedSpot) {
              return AppColors.darkGrey.withOpacity(0.9);
            },
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots
                  .map((barSpot) {
                    final flSpot = barSpot;
                    final index = flSpot.x.toInt();
                    final dataIndex =
                        (spots.length > 1 && spots.first.x < 0) ? index : index;

                    if (dataIndex < 0 || dataIndex >= originalData.length) {
                      return null;
                    }

                    final periodData = originalData[dataIndex];
                    final value = flSpot.y;
                    final periodString = periodData['period'] as String? ?? '';
                    String periodLabel = '';

                    try {
                      switch (timeframe) {
                        case AnalyticsTimeframe.weekly:
                          final date = DateFormat(
                            'yyyy-MM-dd',
                          ).parse(periodString);
                          periodLabel = DateFormat('EEE, MMM d').format(date);
                          break;
                        case AnalyticsTimeframe.monthly:
                          final date = DateFormat(
                            'yyyy-MM-dd',
                          ).parse(periodString);
                          final endDate = date.add(const Duration(days: 6));
                          periodLabel =
                              'Week: ${DateFormat('MMM d').format(date)} - ${DateFormat('MMM d').format(endDate)}';
                          break;
                        case AnalyticsTimeframe.yearly:
                          if (periodString.contains('-')) {
                            final date = DateFormat(
                              'yyyy-MM',
                            ).parse(periodString);
                            periodLabel = DateFormat('MMMM yyyy').format(date);
                          } else {
                            periodLabel = periodString;
                          }
                          break;
                      }
                    } catch (e) {
                      if (kDebugMode)
                        print(
                          "Error formatting tooltip label for period: $periodString - $e",
                        );
                      periodLabel = periodString;
                    }
                    String valueString;
                    final valueInt = value.toInt();
                    if (yAxisLabel == 'Minutes') {
                      valueString = '$valueInt min';
                    } else if (yAxisLabel == 'Calories') {
                      valueString =
                          '${NumberFormat.decimalPattern().format(valueInt)} kcal';
                    } else {
                      valueString =
                          '$valueInt workout${valueInt == 1 ? '' : 's'}';
                    }

                    return LineTooltipItem(
                      '$periodLabel\n',
                      AppTextStyles.small.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: valueString,
                          style: AppTextStyles.small.copyWith(
                            color: color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                      textAlign: TextAlign.left,
                    );
                  })
                  .whereType<LineTooltipItem>()
                  .toList();
            },
          ),
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (
            LineChartBarData barData,
            List<int> spotIndexes,
          ) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: AppColors.mediumGrey,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: AppColors.white,
                      strokeWidth: 2,
                      strokeColor: barData.color ?? AppColors.mediumGrey,
                    );
                  },
                ),
              );
            }).toList();
          },
        ), // End of lineTouchData
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: horizontalInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: AppColors.paleGrey, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: leftInterval,
              getTitlesWidget: (value, meta) {
                if (value == 0 && meta.max > 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    NumberFormat.compact().format(value.toInt()),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: bottomInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final dataIndex =
                    (spots.length > 1 && spots.first.x < 0) ? index : index;

                if (dataIndex < 0 || dataIndex >= originalData.length) {
                  return const SizedBox.shrink();
                }
                if (value != meta.min &&
                    value != meta.max &&
                    index % bottomInterval.round() != 0) {
                  return const SizedBox.shrink();
                }

                final periodData = originalData[dataIndex];
                final periodString = periodData['period'] as String? ?? '';
                String label = '?';

                try {
                  switch (timeframe) {
                    case AnalyticsTimeframe.weekly:
                      final date = DateFormat('yyyy-MM-dd').parse(periodString);
                      label = DateFormat('d').format(date);
                      break;
                    case AnalyticsTimeframe.monthly:
                      final date = DateFormat('yyyy-MM-dd').parse(periodString);
                      label = DateFormat('MMM d').format(date);
                      break;
                    case AnalyticsTimeframe.yearly:
                      if (periodString.contains('-')) {
                        final date = DateFormat('yyyy-MM').parse(periodString);
                        label = DateFormat('MMM').format(date);
                      } else {
                        label = periodString;
                      }
                      break;
                  }
                } catch (e) {
                  if (kDebugMode)
                    print(
                      "Error formatting bottom title label for period: $periodString - $e",
                    );
                  label = '?';
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
                final dataIndex =
                    (spots.length > 1 && spots.first.x < 0) ? index : index;
                if (dataIndex < 0 || dataIndex >= originalData.length) {
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                  );
                }
                final lastActualDataIndex =
                    (spots.length > 1 && spots.first.x < 0)
                        ? spots.length - 2
                        : spots.length - 1;
                if (index == lastActualDataIndex) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: AppColors.white,
                    strokeWidth: 2,
                    strokeColor: color,
                  );
                }
                return FlDotCirclePainter(
                  radius: 2,
                  color: color,
                  strokeColor: Colors.transparent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
                stops: const [0.1, 0.9],
              ),
            ),
          ),
        ],
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
      ),
      duration: const Duration(
        milliseconds: 250,
      ),
      curve: Curves.linear,
    );
  }

  Widget _buildEmptyDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 50,
            color: AppColors.lightGrey,
          ), // Changed icon
          const SizedBox(height: 16),
          Text(
            'No progress data yet', // Adjusted text
            style: AppTextStyles.body.copyWith(color: AppColors.mediumGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Keep logging workouts to see your trends!', // Adjusted text
            style: AppTextStyles.small.copyWith(color: AppColors.mediumGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
