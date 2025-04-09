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
    String yAxisLabel,
    Color color,
  ) {
    final double minX = spots.length > 1 && spots.first.x < 0 ? -1 : 0;
    final double maxX =
        spots.length > 1 && spots.last.x > (originalData.length - 1)
            ? spots.last.x
            : (originalData.isEmpty ? 0 : originalData.length - 1.0);

    final double maxY =
        spots.isEmpty
            ? 10.0
            : (spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) *
                    1.2)
                .clamp(5.0, double.infinity);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY / 5).ceilToDouble().clamp(
            1.0,
            double.infinity,
          ),
          getDrawingHorizontalLine: (value) {
            return FlLine(color: AppColors.paleGrey, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (maxY / 5).ceilToDouble().clamp(1.0, double.infinity),
              getTitlesWidget: (value, meta) {
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

              interval:
                  (spots.length > 10 && timeframe == AnalyticsTimeframe.monthly)
                      ? 2
                      : (spots.length > 14 &&
                          timeframe == AnalyticsTimeframe.weekly)
                      ? 2
                      : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                final dataIndex =
                    (spots.length > 1 && spots.first.x < 0) ? index - 1 : index;

                if (dataIndex < 0 || dataIndex >= originalData.length) {
                  return const SizedBox.shrink();
                }

                final periodData = originalData[dataIndex];
                final periodString = periodData['period'] as String? ?? '';
                String label = '';

                try {
                  if (timeframe == AnalyticsTimeframe.weekly) {
                    final date = DateFormat('yyyy-MM-dd').parse(periodString);
                    label = DateFormat('MMM d').format(date);
                  } else if (timeframe == AnalyticsTimeframe.monthly) {
                    final year = int.parse(periodString.substring(0, 4));
                    final month = int.parse(periodString.substring(5, 7));
                    final date = DateTime(year, month);

                    label = DateFormat(
                      originalData.length > 12 ? 'MMM yy' : 'MMM',
                    ).format(date);
                  } else {
                    label = periodString;
                  }
                } catch (e) {
                  print(
                    "Error formatting date label for period: $periodString - $e",
                  );
                  label = '?';
                }

                if (meta.appliedInterval > 1.0 &&
                    index % meta.appliedInterval.round() != 0) {
                  return const SizedBox.shrink();
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
                if (spot.x < 0 || spot.x >= originalData.length) {
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                  );
                }

                if (index ==
                    (spots.length > 1 && spots.first.x < 0
                        ? spots.length - 2
                        : spots.length - 1)) {
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

        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot touchedSpot) {
              // You can optionally vary the color based on the spot,
              // but for a consistent background, just return the color.
              return AppColors.darkGrey.withOpacity(0.8);
            },
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              // Renamed parameter for clarity
              return touchedBarSpots
                  .map((barSpot) {
                    // Iterate through spots touched on the bar(s)

                    final flSpot =
                        barSpot.bar.spots[barSpot
                            .spotIndex]; // Get FlSpot using indices

                    // --- Logic to prevent tooltips for dummy points ---
                    if (flSpot.x < 0 || flSpot.x >= originalData.length) {
                      return null; // Return null to hide tooltip for this dummy spot
                    }
                    // --- End of dummy point check ---

                    // Use the index relative to the original data points
                    final index = flSpot.x.toInt();
                    if (index < 0 || index >= originalData.length) {
                      // Extra safety check if indices don't align perfectly
                      return null;
                    }
                    final periodData = originalData[index];
                    final value =
                        flSpot.y; // Use Y value from the retrieved FlSpot

                    // --- Period Label Formatting (remains the same) ---
                    String periodLabel = '';
                    try {
                      if (timeframe == AnalyticsTimeframe.weekly) {
                        final date = DateFormat(
                          'yyyy-MM-dd',
                        ).parse(periodData['period']);
                        periodLabel =
                            'Week of ${DateFormat('MMM d').format(date)}';
                      } else if (timeframe == AnalyticsTimeframe.monthly) {
                        final date = DateFormat(
                          'yyyy-MM',
                        ).parse(periodData['period']);
                        periodLabel = DateFormat('MMMM yyyy').format(date);
                      } else {
                        // Handle potential future yearly case
                        periodLabel = periodData['period'] ?? 'Unknown Period';
                      }
                    } catch (_) {
                      periodLabel = periodData['period'] ?? 'Unknown Period';
                    }
                    // --- End Period Label Formatting ---

                    return LineTooltipItem(
                      '$periodLabel\n', // Header text
                      AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          // Value text
                          text:
                              '${NumberFormat.decimalPattern().format(value.toInt())} ${yAxisLabel.toLowerCase()}',
                          style: AppTextStyles.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      textAlign: TextAlign.left,
                    );
                  })
                  .whereType<LineTooltipItem>()
                  .toList(); // Filter out any nulls created for dummy spots
            },
          ),
          handleBuiltInTouches: true,
        ),
        // --- End MODIFIED LineTouchData ---
      ),
    );
  }

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
