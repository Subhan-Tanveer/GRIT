import 'package:flutter/material.dart';
import '../../core/theme/grit_theme.dart';

class GritBadge extends StatelessWidget {
  final Widget? icon;
  final String label;
  final Color color;

  const GritBadge({
    super.key,
    this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: GritTextStyles.labelCaps().copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
