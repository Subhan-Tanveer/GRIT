import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/grit_theme.dart';
import 'grit_button.dart';

class GritErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const GritErrorState({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.warning(), color: grit.accent, size: 48),
            const SizedBox(height: 16),
            Text('SOMETHING WENT WRONG',
                style: GritTextStyles.metric(24,
                    weight: FontWeight.w900, color: grit.textPrimary)),
            const SizedBox(height: 8),
            Text('We encountered a problem loading this data.',
                style:
                    GritTextStyles.label(14, color: grit.textSecondary),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              GritPrimaryButton(label: 'RETRY', onPressed: onRetry!),
            ]
          ],
        ),
      ),
    );
  }
}
