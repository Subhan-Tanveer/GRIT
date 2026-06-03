import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/body_measurement_entry.dart';
import '../../../core/constants/biometric_sites.dart';

class MeasurementHistoryTile extends StatelessWidget {
  final BodyMeasurementEntry entry;
  final String displayUnit;
  final bool isExpanded;
  final VoidCallback onToggle;

  const MeasurementHistoryTile({
    super.key,
    required this.entry,
    required this.displayUnit,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final date = DateTime.parse(entry.createdAt);
    final count = entry.activeCount;

    return Column(
      children: [
        InkWell(
          onTap: () {
            GritHaptics.selectionTick();
            onToggle();
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: grit.border, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(date).toUpperCase(),
                        style: GritTextStyles.tileTitle().copyWith(
                          color: grit.textPrimary,
                          height: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count MEASUREMENTS',
                        style: GritTextStyles.tileSubtitle().copyWith(
                          color: grit.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: 300.ms,
                  curve: Curves.easeOutBack,
                  child: Icon(
                    PhosphorIcons.caretDown(),
                    color: isExpanded ? grit.accent : grit.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          AnimatedSize(
            duration: 250.ms,
            curve: Curves.easeOutExpo,
            child: Container(
              padding: const EdgeInsets.all(GritSpacing.horizontalMargin),
              color: grit.surface,
              child: Wrap(
                runSpacing: 12,
                children: BiometricSites.all.map((site) {
                  final value = entry.getValue(site.id, displayUnit);
                  return _HistorySubTile(
                    label: site.label,
                    value: value,
                    unit: displayUnit,
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _HistorySubTile extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;

  const _HistorySubTile({
    required this.label,
    this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final valueText = value != null ? value!.toStringAsFixed(1) : "---";

    return SizedBox(
      width: (MediaQuery.of(context).size.width - GritSpacing.horizontalMargin * 2) / 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GritTextStyles.tileSubtitle().copyWith(
              color: grit.textSecondary,
            ),
          ),
          Text(
            value != null ? '$valueText $unit' : '---',
            style: GritTextStyles.mono(15,
              weight: FontWeight.w700,
              color: value != null ? grit.textPrimary : grit.muted,
            ),
          ),
        ],
      ),
    );
  }
}
