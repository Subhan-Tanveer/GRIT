import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/workout_utils.dart';
import '../../core/utils/haptics.dart';
import '../../providers/metrics_provider.dart';
import 'grit_components.dart';
import 'grit_skeleton.dart';

class ProgressionCard extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> dataAsync;
  final ExerciseAnalysisMetric metric;

  const ProgressionCard({
    super.key,
    required this.dataAsync,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    String label = "PROGRESSION";
    switch (metric) {
      case ExerciseAnalysisMetric.e1rm:
        label = "STRENGTH (E1RM)";
        break;
      case ExerciseAnalysisMetric.volume:
        label = "VOLUME (TOTAL KG)";
        break;
      case ExerciseAnalysisMetric.weight:
        label = "MAX WEIGHT (KG)";
        break;
    }

    final grit = Theme.of(context).grit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GritCard(
        title: label,
        padding: const EdgeInsets.fromLTRB(0, 16, 12, 8),
        child: SizedBox(
          height: 180,
          child: dataAsync.when(
            data: (points) {
              if (points.isEmpty) {
                return Stack(
                  children: [
                    Opacity(
                      opacity: 0.1,
                      child: LineChart(_createShadowGridData(context)),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PhosphorIcons.chartLineUp(),
                            size: 24,
                            color: grit.textSecondary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "NO SESSIONS LOGGED YET",
                            style: GritTextStyles.metric(
                              10,
                              weight: FontWeight.w900,
                              color: grit.textSecondary.withValues(alpha: 0.6),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              // Only show the last 15 points
              final chartPoints = points.length > 15 ? points.sublist(points.length - 15) : points;
              return LineChart(_createLineData(context, chartPoints, metric));
            },
            loading: () => const Center(
              child: GritSkeleton(height: 140, width: double.infinity),
            ),
            error: (e, _) => Center(
              child: Text("ERROR: $e", style: GritTextStyles.mono(10)),
            ),
          ),
        ),
      ),
    );
  }

  LineChartData _createShadowGridData(BuildContext context) {
    final grit = Theme.of(context).grit;
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: 20,
        verticalInterval: 1,
        getDrawingHorizontalLine: (val) => FlLine(color: grit.border, strokeWidth: 0.5),
        getDrawingVerticalLine: (val) => FlLine(color: grit.border, strokeWidth: 0.5),
      ),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: [const FlSpot(0, 50), const FlSpot(5, 80)],
          isCurved: false,
          color: grit.border,
          barWidth: 1,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  LineChartData _createLineData(
      BuildContext context, List<Map<String, dynamic>> points, ExerciseAnalysisMetric metric) {
    final grit = Theme.of(context).grit;
    String field = 'max_e1rm';
    switch (metric) {
      case ExerciseAnalysisMetric.e1rm:
        field = 'max_e1rm';
        break;
      case ExerciseAnalysisMetric.volume:
        field = 'session_volume';
        break;
      case ExerciseAnalysisMetric.weight:
        field = 'max_weight';
        break;
    }

    final spots = <FlSpot>[];
    if (points.length == 1) {
      final val = (points[0][field] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(-0.5, val));
      spots.add(FlSpot(0.0, val));
      spots.add(FlSpot(0.5, val));
    } else {
      spots.addAll(points.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), (e.value[field] as num?)?.toDouble() ?? 0.0);
      }));
    }

    final values = spots.map((s) => s.y).toList();
    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);

    double range = maxY - minY;
    if (range == 0) {
      if (minY == 0) {
        minY = 0.0;
        maxY = 10.0;
      } else {
        minY = (minY * 0.95).floorToDouble();
        maxY = (maxY * 1.05).ceilToDouble();
      }
    } else {
      minY = (minY - range * 0.2).clamp(0, double.infinity).floorToDouble();
      maxY = (maxY + range * 0.2).ceilToDouble();
    }

    return LineChartData(
      minX: points.length == 1 ? -0.5 : 0.0,
      maxX: points.length == 1 ? 0.5 : (points.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: (maxY - minY) / 3,
        getDrawingHorizontalLine: (val) => FlLine(
          color: grit.border.withValues(alpha: 0.08),
          strokeWidth: 0.5,
          dashArray: [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (val, meta) {
              if (val == meta.max || val == meta.min) return const SizedBox();
              final rounded = val.round();
              if ((val - rounded).abs() > 0.01) return const SizedBox();
              return Text(
                rounded.toString(),
                style: GritTextStyles.mono(10, color: grit.textSecondary),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1.0,
            getTitlesWidget: (val, meta) {
              final rounded = val.round();
              if ((val - rounded).abs() > 0.01) return const SizedBox();
              final idx = rounded;
              if (idx < 0 || idx >= points.length) return const SizedBox();
              if (points.length > 8 && idx % (points.length ~/ 4) != 0) return const SizedBox();

              final date = DateTime.parse(points[idx]['date']);
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('d MMM').format(date).toLowerCase(),
                  style: GritTextStyles.mono(10, color: grit.textSecondary),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: grit.border.withValues(alpha: 0.3), width: 1),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: grit.accent,
          barWidth: 3.5,
          shadow: Shadow(
            color: grit.accent.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: Offset.zero,
          ),
          dashArray: points.length == 1 ? const [6, 4] : null,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, barData) {
              if (points.length == 1) {
                return spot.x == 0.0;
              }
              return points.length <= 10;
            },
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 3.5,
              color: grit.accent,
              strokeWidth: 2,
              strokeColor: grit.background,
            ),
          ),
          belowBarData: BarAreaData(
            show: Theme.of(context).brightness == Brightness.dark,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                grit.accent.withValues(alpha: 0.15),
                grit.accent.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchCallback: (event, response) {
          if (event is FlTapDownEvent) GritHaptics.selectionTick();
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => grit.surface,
          tooltipBorder: BorderSide(color: grit.border, width: 1.5),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((s) {
              final date = DateTime.parse(points[s.spotIndex]['date']);

              String unit = "kg";
              return LineTooltipItem(
                "${DateFormat('EEE, d MMM').format(date).toUpperCase()}\n",
                GritTextStyles.mono(11, color: grit.textSecondary, weight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: "${WorkoutUtils.formatWeight(s.y)} $unit",
                    style: GritTextStyles.mono(14, weight: FontWeight.w700, color: grit.textPrimary),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
