import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/grit_theme.dart';
import '../../utils/nutrition.dart';

class MacroRings extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final MacroTargets targets;
  final double size;

  const MacroRings({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.targets,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingsPainter(
          rings: [
            _RingValue(calories / targets.calories, grit.accent),
            _RingValue(protein / targets.proteinG, grit.success),
            _RingValue(carbs / targets.carbsG, grit.warning),
            _RingValue(fat / targets.fatG, grit.timerAmber),
          ],
          trackColor: grit.surface2,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                calories.round().toString(),
                style: GritTextStyles.displayMedium().copyWith(color: grit.textPrimary),
              ),
              Text(
                'OF ${targets.calories.round()} KCAL',
                style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingValue {
  final double progress;
  final Color color;
  _RingValue(this.progress, this.color);
}

class _RingsPainter extends CustomPainter {
  final List<_RingValue> rings;
  final Color trackColor;

  _RingsPainter({required this.rings, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    const strokeWidth = 12.0;
    const gap = 4.0;

    for (int i = 0; i < rings.length; i++) {
      final radius = maxRadius - (i * (strokeWidth + gap)) - strokeWidth / 2;
      final ring = rings[i];

      final trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, trackPaint);

      final progressPaint = Paint()
        ..color = ring.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweep = (ring.progress.clamp(0.0, 1.0)) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => true;
}

class MacroLegendRow extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final String unit;
  final Color color;

  const MacroLegendRow({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: GritTextStyles.label(12, color: grit.textSecondary, weight: FontWeight.w600)),
          const Spacer(),
          Text(
            '${value.round()} / ${target.round()}$unit',
            style: GritTextStyles.mono(12, weight: FontWeight.w700, color: grit.textPrimary),
          ),
        ],
      ),
    );
  }
}

class WaterTracker extends StatelessWidget {
  final int currentMl;
  final int targetMl;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const WaterTracker({
    super.key,
    required this.currentMl,
    required this.targetMl,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final progress = (currentMl / targetMl).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border.all(color: grit.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 48,
                    height: 48 * progress,
                    alignment: Alignment.bottomCenter,
                    color: Colors.blue.withValues(alpha: 0.5),
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(border: Border.all(color: grit.border)),
                ),
                Icon(Icons.water_drop, size: 20, color: grit.textSecondary),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentMl}ML / ${targetMl}ML',
                  style: GritTextStyles.tileTitle().copyWith(color: grit.textPrimary),
                ),
                Text(
                  '${waterIncrementMl}ML PER TAP',
                  style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 1),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: currentMl > 0 ? onRemove : null,
            child: Icon(
              Icons.remove_circle,
              color: currentMl > 0 ? grit.textSecondary : grit.muted,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onAdd,
            child: Icon(Icons.add_circle, color: grit.accent, size: 28),
          ),
        ],
      ),
    );
  }
}
