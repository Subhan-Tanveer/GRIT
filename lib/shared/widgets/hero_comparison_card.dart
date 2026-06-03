import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/grit_theme.dart';
import 'grit_components.dart';
import 'milestone_badges.dart';

class HeroComparisonCard extends StatelessWidget {
  final List<Map<String, dynamic>> points;

  const HeroComparisonCard({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    if (points.isEmpty) return const SizedBox.shrink();

    final latest = points.last;
    final latest1rm = (latest['max_e1rm'] as num?)?.toDouble() ?? 0.0;
    final latestWeight = (latest['max_weight'] as num?)?.toDouble() ?? 0.0;
    final latestReps = (latest['total_reps'] as num?)?.toDouble() ?? 0.0;

    double? prev1rm;
    double? prevWeight;
    double? prevReps;

    if (points.length > 1) {
      final prev = points[points.length - 2];
      prev1rm = (prev['max_e1rm'] as num?)?.toDouble();
      prevWeight = (prev['max_weight'] as num?)?.toDouble();
      prevReps = (prev['total_reps'] as num?)?.toDouble();
    }

    final delta1rm = prev1rm != null ? latest1rm - prev1rm : null;
    final percent1rm = (prev1rm != null && prev1rm > 0) ? (delta1rm! / prev1rm) * 100 : 0.0;

    final deltaWeight = prevWeight != null ? latestWeight - prevWeight : null;
    final deltaReps = prevReps != null ? latestReps - prevReps : null;

    // Check if new all-time PR
    bool isAllTimePR = true;
    for (int i = 0; i < points.length - 1; i++) {
      final val = (points[i]['max_e1rm'] as num?)?.toDouble() ?? 0.0;
      if (val >= latest1rm) {
        isAllTimePR = false;
        break;
      }
    }
    final showPR = points.length > 1 && isAllTimePR && latest1rm > 0;

    // Check for session streak (e1rm increasing consecutive times)
    int streak = 0;
    for (int i = points.length - 1; i > 0; i--) {
      final currentVal = (points[i]['max_e1rm'] as num?)?.toDouble() ?? 0.0;
      final prevVal = (points[i - 1]['max_e1rm'] as num?)?.toDouble() ?? 0.0;
      if (currentVal > prevVal) {
        streak++;
      } else {
        break;
      }
    }

    return GritCard(
      title: "PROGRESS SNAPSHOT",
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMetricCol(
                  context,
                  icon: PhosphorIcons.lightning(PhosphorIconsStyle.bold),
                  label: "ESTIMATED 1RM",
                  value: latest1rm.toStringAsFixed(1),
                  unit: "KG",
                  delta: delta1rm,
                  percentLabel: delta1rm != null
                      ? "${delta1rm >= 0 ? '+' : ''}${percent1rm.toStringAsFixed(1)}% VS. PREV"
                      : null,
                  isPrimary: true,
                ),
              ),
              Container(
                height: 70,
                width: 1,
                color: grit.border.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildMetricCol(
                  context,
                  icon: PhosphorIcons.barbell(PhosphorIconsStyle.bold),
                  label: "MAX WEIGHT",
                  value: latestWeight.toStringAsFixed(1),
                  unit: "KG",
                  delta: deltaWeight,
                ),
              ),
              Container(
                height: 70,
                width: 1,
                color: grit.border.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildMetricCol(
                  context,
                  icon: PhosphorIcons.pulse(PhosphorIconsStyle.bold),
                  label: "TOTAL REPS",
                  value: latestReps > 0 ? latestReps.toStringAsFixed(0) : "—",
                  unit: "",
                  delta: latestReps > 0 ? deltaReps : null,
                  isReps: true,
                ),
              ),
            ],
          ),
          if (showPR || streak >= 2) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: grit.border.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (showPR)
                  GritBadge(
                    icon: Icon(
                      PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                      color: grit.accent,
                      size: 12,
                    ),
                    label: "NEW ALL-TIME PR!",
                    color: grit.accent,
                  ),
                if (streak >= 2)
                  GritBadge(
                    icon: Icon(
                      PhosphorIcons.fire(PhosphorIconsStyle.fill),
                      color: Colors.orange,
                      size: 12,
                    ),
                    label: "$streak-SESSION IMPROVEMENT STREAK!",
                    color: Colors.orange,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCol(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    double? delta,
    String? percentLabel,
    bool isPrimary = false,
    bool isReps = false,
  }) {
    final grit = Theme.of(context).grit;

    Widget? deltaWidget;
    if (delta != null) {
      final isPositive = delta >= 0;
      final color = isPositive ? grit.deltaPositive : grit.accent;
      final sign = isPositive ? "+" : "";
      final formattedDelta = isReps ? delta.toStringAsFixed(0) : delta.toStringAsFixed(1);
      deltaWidget = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isPositive ? PhosphorIcons.arrowUp() : PhosphorIcons.arrowDown(),
            color: color,
            size: 12,
          ),
          const SizedBox(width: 2),
          Text(
            "$sign$formattedDelta${(isPrimary && !isReps) ? ' $unit' : ''}",
            style: isPositive
                ? GritTextStyles.heroDeltaPositive(color: color)
                : GritTextStyles.heroDeltaNegative(color: color),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isPrimary ? grit.accent : grit.muted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: GritTextStyles.labelMicro().copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: grit.muted,
                  letterSpacing: 0.8,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GritTextStyles.mono(28, weight: FontWeight.w800, color: grit.textPrimary, height: 1.0),
            ),
            if (unit.isNotEmpty && value != "—") ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: GritTextStyles.labelMicro().copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: grit.muted,
                ),
              ),
            ],
          ],
        ),
        if (deltaWidget != null) ...[
          const SizedBox(height: 4),
          deltaWidget,
        ],
        if (percentLabel != null) ...[
          const SizedBox(height: 2),
          Text(
            percentLabel,
            style: GritTextStyles.labelMicro().copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: grit.muted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}
