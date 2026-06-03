import 'package:flutter/material.dart';
import '../../../shared/widgets/grit_section_header.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../core/utils/muscle_mapper.dart';
import '../../../core/theme/grit_theme.dart';

class MuscleBreakdownPanel extends StatelessWidget {
  final DashboardWorkoutData data;

  const MuscleBreakdownPanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GritSpacing.horizontalMargin,
        vertical: GritSpacing.cardMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Section
          GritSectionHeader(
            label: "PRIMARY MUSCLES",
            color: grit.textSecondary,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          if (data.muscles.primary.isEmpty)
            _buildEmptyState(context)
          else
            ...data.muscles.primary.map((m) => _buildMuscleRow(context, m, isPrimary: true, color: grit.textPrimary)),
          
          const SizedBox(height: 24),

          // Secondary Section
          GritSectionHeader(
            label: "SECONDARY MUSCLES",
            color: grit.textSecondary,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          if (data.muscles.secondary.isEmpty)
            _buildEmptyState(context)
          else
            ...data.muscles.secondary.map((m) => _buildMuscleRow(context, m, isPrimary: false, color: grit.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        "No data logged for today",
        style: GritTextStyles.label(
          11,
          color: grit.muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMuscleRow(BuildContext context, String muscle, {required bool isPrimary, required Color color}) {
    final grit = Theme.of(context).grit;
    final double volume = data.stats.muscleVolumes[muscle] ?? 0.0;
    // Calculate intensity relative to the highest volume muscle for the session
    final double maxVolume = data.stats.muscleVolumes.values.fold(0.1, (m, v) => v > m ? v : m);
    final double intensity = (volume / maxVolume).clamp(0.05, 1.0); // Minimum 5% visible

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              MuscleMapper.toDisplayLabel(muscle),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GritTextStyles.mono(13,
                  color: grit.textPrimary
                      .withValues(alpha: isPrimary ? 1.0 : 0.5)),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildIntensityBar(context, intensity, isPrimary, color),
          ),
          const SizedBox(width: 12),
          Text(
            "${(intensity * 100).toInt()}%",
            style: GritTextStyles.mono(11,
                color: isPrimary ? color : color.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityBar(BuildContext context, double value, bool isPrimary, Color color) {
    final grit = Theme.of(context).grit;
    return Stack(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: grit.surface2,
            borderRadius: BorderRadius.zero,
          ),
        ),
        FractionallySizedBox(
          widthFactor: value,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: isPrimary ? color : color.withValues(alpha: 0.5),
              borderRadius: BorderRadius.zero,
              boxShadow: null,
            ),
          ),
        ),
      ],
    );
  }
}
