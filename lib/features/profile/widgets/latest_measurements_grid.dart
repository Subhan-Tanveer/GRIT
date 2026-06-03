import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../data/models/body_measurement_entry.dart';
import '../../../core/constants/biometric_sites.dart';

import '../../../core/theme/grit_animations.dart';

class LatestMeasurementsGrid extends StatelessWidget {
  final BodyMeasurementEntry? latest;
  final String displayUnit;

  const LatestMeasurementsGrid({
    super.key,
    this.latest,
    required this.displayUnit,
  });

  @override
  Widget build(BuildContext context) {
    if (latest == null) return const SizedBox.shrink();
    
    final grit = Theme.of(context).grit;
    final sites = BiometricSites.all;

    return Container(
      decoration: BoxDecoration(
        color: grit.background,
      ),
      child: Wrap(
        children: sites.map((site) {
          final value = latest!.getValue(site.id, displayUnit);
          final valueText = value != null ? value.toStringAsFixed(1) : "---";

          return Container(
            width: MediaQuery.of(context).size.width / 2,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: grit.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.label,
                  style: GritTextStyles.labelMicro().copyWith(
                    fontWeight: FontWeight.w800,
                    color: grit.textSecondary,
                    letterSpacing: 2.5,
                  ),
                ),
                Text(
                  valueText,
                  style: GritTextStyles.dataValueLarge().copyWith(
                    color: value == null ? grit.muted : grit.textPrimary,
                  ),
                ),
                Text(
                  displayUnit,
                  style: GritTextStyles.labelCaps().copyWith(
                    color: grit.textSecondary,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
            delay: (100 + sites.indexOf(site) * 20).ms,
            duration: GritAnimations.mechanicalDuration,
          ).slideY(begin: 0.1, curve: GritAnimations.mechanicalCurve);
        }).toList(),
      ),
    );
  }
}
