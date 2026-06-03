import 'package:flutter/material.dart';
import '../../core/theme/grit_theme.dart';

class GritGridPainter extends CustomPainter {
  final BuildContext context;
  GritGridPainter(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final grit = Theme.of(context).grit;
    final paint = Paint()
      ..color = grit.border.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    const spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GritCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry? padding;
  final bool expandChild;
  final Widget? trailingHeader;

  const GritCard({
    super.key,
    required this.child,
    this.title,
    this.padding,
    this.expandChild = false,
    this.trailingHeader,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      decoration: GritTheme.gritDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GritGridPainter(context),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: grit.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title!.toUpperCase(),
                        style: GritTextStyles.label(11,
                            weight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: grit.textSecondary),
                      ),
                      trailingHeader ?? const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
              if (expandChild)
                Expanded(
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
                )
              else
                Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class GritMeter extends StatelessWidget {
  final double percentage;
  final double height;
  final Color? color;
  final int segments;

  const GritMeter({
    super.key,
    required this.percentage,
    this.height = 24.0,
    this.color,
    this.segments = 20,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final segmentWidth = (totalWidth - (segments - 1) * 2) / segments;
        final filledSegments = (percentage / 100 * segments).round();

        return SizedBox(
          height: height,
          child: Row(
            children: List.generate(segments, (index) {
              final isFilled = index < filledSegments;
              return Container(
                width: segmentWidth,
                height: height,
                margin: EdgeInsets.only(right: index == segments - 1 ? 0 : 2),
                decoration: BoxDecoration(
                  color: isFilled
                      ? (color ?? grit.accent)
                      : grit.border,
                  borderRadius: BorderRadius.zero,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
