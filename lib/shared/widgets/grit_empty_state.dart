import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/grit_theme.dart';
import 'grit_button.dart';

class GritEmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const GritEmptyState({
    super.key,
    this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 48,
              color: grit.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GritTextStyles.metric(
              22,
              weight: FontWeight.w900,
              color: grit.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 12),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: GritTextStyles.label(
                13,
                weight: FontWeight.w400,
                color: grit.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 32),
            GritGhostButton(
              label: actionLabel!,
              onTap: onAction!,
              isAccent: true,
              height: 52,
              fontSize: 14,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOutQuad);
  }
}
