import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../core/utils/workout_utils.dart';
import '../../../data/models/set_entry.dart';

import '../../../shared/widgets/grit_button.dart';

class FinishWorkoutSheet extends ConsumerWidget {
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  const FinishWorkoutSheet({super.key, required this.onSave, required this.onDiscard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);
    final session = state.session;

    final profile = ref.watch(profileProvider);
    final isLb = profile.weightUnit.toLowerCase() == 'lb';
    final unit = isLb ? 'LBS' : 'KG';

    int setsDone = 0;
    double volumeKg = 0;
    for (final sets in state.sets.values) {
      for (final s in sets) {
        if (s.isCompleted && s.setType != SetEntryType.warmup) {
          setsDone++;
          volumeKg += s.weightKg * (s.reps ?? 0);
        }
      }
    }

    final displayVolume = isLb ? WorkoutUtils.kgToLb(volumeKg) : volumeKg;

    Duration elapsed = Duration.zero;
    if (session != null) {
      elapsed = DateTime.now().difference(DateTime.parse(session.startedAt));
    }
    final hs = elapsed.inHours.toString().padLeft(2, '0');
    final ms = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final durationStr = '$hs:$ms:$ss';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).grit.background,
          border: Border(top: BorderSide(color: Theme.of(context).grit.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text('FINISH WORKOUT',
                  style: GritTextStyles.metric(20,
                      weight: FontWeight.w800,
                      color: Theme.of(context).grit.textPrimary)),
            ),
            Divider(height: 1, color: Theme.of(context).grit.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(durationStr,
                      style: GritTextStyles.mono(48,
                          weight: FontWeight.w900,
                          color: Theme.of(context).grit.textPrimary)),
                  const SizedBox(height: 4),
                  Text('TOTAL DURATION',
                      style: GritTextStyles.labelMicro()
                          .copyWith(color: Theme.of(context).grit.textSecondary, letterSpacing: 2)),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                    horizontal: BorderSide(color: Theme.of(context).grit.border, width: 1)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _FinishStatCell(
                        value: displayVolume.toInt().toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (m) => '${m[1]},'),
                        label: 'VOLUME ($unit)'),
                    _FinishStatCell(
                        value: '${state.exercises.length}', label: 'EXERCISES'),
                    _FinishStatCell(value: '$setsDone', label: 'SETS', isLast: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GritPrimaryButton(
                label: 'SAVE WORKOUT',
                onPressed: onSave,
                isLoading: state.isLoading,
                icon: Icons.arrow_forward,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: GritGhostButton(
                label: 'DISCARD WORKOUT',
                onTap: onDiscard,
                isAccent: true,
                height: 44,
                fontSize: 12,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _FinishStatCell extends StatelessWidget {
  final String value;
  final String label;
  final bool isLast;

  const _FinishStatCell({
    required this.value,
    required this.label,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(right: BorderSide(color: Theme.of(context).grit.border, width: 1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GritTextStyles.mono(16,
                    weight: FontWeight.w700,
                    color: Theme.of(context).grit.textPrimary)),
            const SizedBox(height: 4),
            Text(label,
                style: GritTextStyles.labelMicro().copyWith(
                    color: Theme.of(context).grit.textSecondary,
                    letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
