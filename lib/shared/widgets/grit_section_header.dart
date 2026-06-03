import 'package:flutter/material.dart';
import '../../core/theme/grit_theme.dart';

class GritSectionHeader extends StatelessWidget {
  final String label;
  final Color? color;
  final bool showHorizontalLine;
  final EdgeInsets padding;
  final Widget? trailing;

  const GritSectionHeader({
    super.key,
    required this.label,
    this.color,
    this.showHorizontalLine = false,
    this.padding = const EdgeInsets.fromLTRB(
      GritSpacing.horizontalMargin,
      GritSpacing.sectionHeaderTop,
      GritSpacing.horizontalMargin,
      GritSpacing.sectionHeaderBottom,
    ),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final effectiveColor = color ?? grit.accent;

    return Container(
      width: double.infinity,
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 2,
            height: 14,
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: BorderRadius.zero,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: GritTextStyles.sectionHeader().copyWith(
              color: effectiveColor == grit.accent 
                  ? grit.textSecondary 
                  : effectiveColor,
              height: 1.0, // Force tight height for better centering
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: showHorizontalLine
                ? Container(
                    height: 0.5,
                    color: effectiveColor.withValues(alpha: 0.15),
                  )
                : const SizedBox.shrink(),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
