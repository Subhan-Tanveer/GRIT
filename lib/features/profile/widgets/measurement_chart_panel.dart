import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../core/utils/workout_utils.dart';
import '../../../providers/metrics_provider.dart';
import '../../../shared/widgets/grit_skeleton.dart';

class MeasurementChartPanel extends ConsumerWidget {
  final String siteId;
  final String unit;

  const MeasurementChartPanel({
    super.key,
    required this.siteId,
    required this.unit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (siteId == 'ALL') return const SizedBox.shrink();

    final grit = Theme.of(context).grit;
    final trendsAsync = ref.watch(measurementTrendsProvider(siteId));

    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: grit.border, width: 1)),
      ),
      child: trendsAsync.when(
        data: (points) {
          if (points.length < 2) {
            return Center(
              child: Text(
                'LOG MORE SESSIONS TO SEE YOUR TREND.',
                style: GritTextStyles.labelMicro().copyWith(
                  color: grit.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            );
          }

          final spots = points.map((p) {
            double val = p.value;
            if (unit == 'IN') val = val / 2.54;
            return FlSpot(p.date.millisecondsSinceEpoch.toDouble(), val);
          }).toList();

          return Padding(
            padding: const EdgeInsets.only(
                top: 24, bottom: 8, left: GritSpacing.horizontalMargin, right: GritSpacing.horizontalMargin),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: grit.border,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Text(
                          DateFormat('MMM').format(date).toUpperCase(),
                          style: GritTextStyles.labelMicro().copyWith(
                            color: grit.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: grit.accent,
                    barWidth: 1.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, xPercentage, bar, index) => FlDotCirclePainter(
                        radius: 4,
                        color: grit.accent,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: Theme.of(context).brightness == Brightness.dark,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          grit.accent.withValues(alpha: 0.2),
                          grit.accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => grit.surface,
                    tooltipBorder: BorderSide(color: grit.borderHighlight),
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                      return LineTooltipItem(
                        '${DateFormat('MMM d').format(date)}\n${WorkoutUtils.formatDecimal(spot.y)} $unit',
                        GritTextStyles.labelMicro().copyWith(color: grit.textPrimary),
                      );
                    }).toList(),
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 24),
          child: GritSkeleton(height: 100, width: double.infinity),
        ),
        error: (e, _) => Center(child: Text('Error: $e', style: GritTextStyles.label(12, color: grit.warning))),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.98, 0.98), curve: Curves.easeOutExpo);
  }
}
