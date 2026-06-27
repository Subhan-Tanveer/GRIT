import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../providers/strength_standards_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/strength_standards.dart';
import '../../shared/widgets/grit_skeleton.dart';

class StrengthStandardsScreen extends ConsumerWidget {
  const StrengthStandardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final standardsAsync = ref.watch(strengthStandardsProvider);
    final isMale = ref.watch(isMaleProvider);
    final bodyweightKg = ref.watch(profileProvider).weightKg;

    return Scaffold(
      backgroundColor: grit.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: grit.border, width: 1))),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: grit.textPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Text('STRENGTH STANDARDS', style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary)),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GritSpacing.horizontalMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sexToggle(context, ref, isMale),
            const SizedBox(height: 8),
            Text(
              'Estimated 1RM compared to bodyweight-ratio benchmarks. Approximate — not a precise or competitive ranking.',
              style: GritTextStyles.label(11, color: grit.muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            standardsAsync.when(
              loading: () => const GritSkeleton(height: 300, width: double.infinity),
              error: (e, st) => Text('Failed to load standards', style: GritTextStyles.label(13, color: grit.textSecondary)),
              data: (standards) => Column(
                children: [
                  for (int i = 0; i < standards.length; i++) ...[
                    _liftCard(context, standards[i], i, bodyweightKg, isMale),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sexToggle(BuildContext context, WidgetRef ref, bool isMale) {
    final grit = Theme.of(context).grit;
    return Row(
      children: [
        Text('STANDARDS FOR', style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 1)),
        const SizedBox(width: 12),
        for (final option in [true, false])
          GestureDetector(
            onTap: () {
              GritHaptics.selectionTick();
              ref.read(isMaleProvider.notifier).set(option);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isMale == option ? grit.accent : Colors.transparent,
                border: Border.all(color: isMale == option ? grit.accent : grit.border),
              ),
              child: Text(
                option ? 'MALE' : 'FEMALE',
                style: GritTextStyles.label(11, weight: FontWeight.w700,
                    color: isMale == option ? Colors.white : grit.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Color _levelColor(StrengthLevel level, GritThemeData grit) {
    return switch (level) {
      StrengthLevel.beginner => grit.textSecondary,
      StrengthLevel.novice => const Color(0xFF9FA8B2),
      StrengthLevel.intermediate => grit.accent,
      StrengthLevel.advanced => const Color(0xFFFFD60A),
      StrengthLevel.elite => const Color(0xFFFF1744),
    };
  }

  Widget _liftCard(BuildContext context, LiftStandard standard, int index, double bodyweightKg, bool isMale) {
    final grit = Theme.of(context).grit;
    final color = _levelColor(standard.level, grit);
    final hasData = standard.bestE1rmKg > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: grit.surface, border: Border.all(color: grit.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(standard.lift.label, style: GritTextStyles.tileTitle().copyWith(color: grit.textPrimary, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(border: Border.all(color: color)),
                child: Text(standard.level.label,
                    style: GritTextStyles.labelMicro().copyWith(color: color, letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasData)
            Text('No logged lifts yet for this exercise.', style: GritTextStyles.label(12, color: grit.muted))
          else ...[
            Text(
              '${standard.bestE1rmKg.round()} KG EST. 1RM',
              style: GritTextStyles.displayMedium().copyWith(color: grit.textPrimary, fontSize: 24),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              child: Stack(
                children: [
                  Container(height: 6, color: grit.surface2),
                  FractionallySizedBox(
                    widthFactor: standard.progressToNext,
                    child: Container(height: 6, color: color),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(height: 1, color: grit.border),
          const SizedBox(height: 10),
          _tierBreakdown(context, standard, bodyweightKg, isMale),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.05);
  }

  Widget _tierBreakdown(BuildContext context, LiftStandard standard, double bodyweightKg, bool isMale) {
    final thresholds = StrengthStandards.multipliersFor(standard.lift, isMale);
    final levelOrder = StrengthLevel.values;
    final currentIndex = levelOrder.indexOf(standard.level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < levelOrder.length; i++) _tierRow(context, levelOrder[i], thresholds[i] * bodyweightKg, i <= currentIndex && standard.bestE1rmKg > 0),
      ],
    );
  }

  Widget _tierRow(BuildContext context, StrengthLevel level, double targetKg, bool unlocked) {
    final grit = Theme.of(context).grit;
    final color = unlocked ? _levelColor(level, grit) : grit.muted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(unlocked ? Icons.lock_open : Icons.lock_outline, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(level.label, style: GritTextStyles.label(11, color: color, weight: FontWeight.w600)),
          ),
          Text(
            unlocked ? '${targetKg.round()} KG' : 'LOCKED UNTIL ${targetKg.round()} KG',
            style: GritTextStyles.mono(11, color: color),
          ),
        ],
      ),
    );
  }
}
