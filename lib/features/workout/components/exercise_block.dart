import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../core/constants/hero_tags.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/muscle_mapper.dart';
import '../../../data/models/exercise.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/profile_provider.dart';
import 'set_row.dart';

class ExerciseBlock extends ConsumerWidget {
  final int exerciseIndex;
  const ExerciseBlock({super.key, required this.exerciseIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);
    if (exerciseIndex >= state.exercises.length) return const SizedBox.shrink();
    final se = state.exercises[exerciseIndex];
    final detail = state.exerciseDetails[se.exerciseId];
    final exerciseName = detail?.name ?? 'Exercise';
    final currentSets = state.sets[se.id] ?? [];
    final isLocked = state.lockedExerciseIds.contains(se.id);

    final activeIndex = state.exercises.indexWhere((ex) {
      final s = state.sets[ex.id] ?? [];
      return s.isEmpty || s.any((set) => !set.isCompleted);
    });
    final isUpNext = exerciseIndex > activeIndex && currentSets.isEmpty;

    final muscle = detail?.muscleGroup ?? 'MUSCLE';
    final unit = ref.watch(profileProvider.select((p) => p.weightUnit));
    final isLb = unit == 'LBS';

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: GritSpacing.horizontalMargin, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).grit.surface,
        border: Border.all(color: Theme.of(context).grit.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Theme.of(context).grit.border, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onLongPress: () async {
                          if (isLocked) return;
                          if (!ref.read(activeWorkoutProvider).isPreview) {
                            await GritHaptics.mediumImpact();
                            if (!context.mounted) return;
                            showActionMenu(context, ref, exerciseIndex);
                          }
                        },
                        child: Hero(
                          tag: HeroTags.exerciseName(se.id ?? se.hashCode),
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(exerciseName.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: GritTextStyles.label(20,
                                    weight: FontWeight.w800,
                                    height: 1.15,
                                    color: isUpNext
                                        ? Theme.of(context).grit.muted
                                        : Theme.of(context).grit.textPrimary)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!isUpNext && se.id != null) ...[
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(activeWorkoutProvider.notifier)
                              .toggleExerciseLock(se.id!);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isLocked
                                ? PhosphorIcons.lock(PhosphorIconsStyle.fill)
                                : PhosphorIcons.lockOpen(PhosphorIconsStyle.regular),
                            size: 16,
                            color: isLocked
                                ? Theme.of(context).grit.accent
                                : Theme.of(context).grit.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (!isUpNext) ...[
                      GestureDetector(
                        onTap: () => _showSetTypesDialog(context),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            PhosphorIcons.info(PhosphorIconsStyle.regular),
                            size: 16,
                            color: Theme.of(context).grit.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                isUpNext ? Theme.of(context).grit.border : Theme.of(context).grit.muted,
                            width: 1),
                      ),
                      child: Text(MuscleMapper.toDisplayLabel(muscle),
                          style: GritTextStyles.labelMicro().copyWith(
                              color: isUpNext
                                  ? Theme.of(context).grit.muted
                                  : Theme.of(context).grit.textSecondary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isUpNext)
            Container(
              height: 44,
              alignment: Alignment.center,
              child: Text('UP NEXT',
                  style: GritTextStyles.labelCaps().copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Theme.of(context).grit.muted,
                      letterSpacing: 4.0)), // Balanced dramatic spacing
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    child: Center(
                      child: Text('SET',
                          style: GritTextStyles.labelMicro().copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).grit.muted)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (detail?.type == 'cardio' || detail?.type == 'timed') ...[
                    SizedBox(
                      width: 152,
                      child: Center(
                        child: Text('DURATION',
                            style: GritTextStyles.labelMicro().copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).grit.muted)),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                        width: 72,
                        child: Center(
                            child: Text('WEIGHT',
                                style: GritTextStyles.labelMicro().copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).grit.muted)))),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 72,
                        child: Center(
                            child: Text('REPS',
                                style: GritTextStyles.labelMicro().copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).grit.muted)))),
                  ],
                  const SizedBox(width: 8),
                  const SizedBox(width: 32), // PR Header Placeholder
                  const SizedBox(width: 8),
                  SizedBox(
                      width: 44,
                      child: Center(
                          child: Text('DONE',
                              style: GritTextStyles.labelMicro().copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).grit.muted)))),
                ],
              ),
            ),
            ...currentSets.asMap().entries.map((entry) {
              final setEntry = entry.value;
              return SetRow(
                key: ValueKey('set_row_${se.id}_${setEntry.id ?? entry.key}'),
                exerciseIndex: exerciseIndex,
                sessionExerciseId: se.id!,
                setIndex: entry.key,
                isLb: isLb,
                showBottomBorder: entry.key < currentSets.length - 1,
              );
            }),
            if (!isLocked)
              _AddSetRow(
                  onTap: () => ref
                      .read(activeWorkoutProvider.notifier)
                      .addSet(exerciseIndex)),
          ],
        ],
      ),
    );
  }

  void _showSetTypesDialog(BuildContext context) {
    final grit = Theme.of(context).grit;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('SET TYPES', style: GritTextStyles.metric(24, color: grit.textPrimary, weight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem(context, '1', 'NORMAL SET', 'Standard working set. Counts towards personal records and volume.'),
            const SizedBox(height: 14),
            _buildLegendItem(context, 'W', 'WARMUP SET', 'Warmup preparation. Excluded from personal record checks and volume stats.', color: grit.warmupSet),
            const SizedBox(height: 14),
            _buildLegendItem(context, 'D', 'DROP SET', 'Set performed at a lower weight immediately after a working set.', color: grit.dropSet),
            const SizedBox(height: 14),
            _buildLegendItem(context, 'F', 'FAILURE SET', 'Working set performed to absolute muscular failure.', color: grit.failureSet),
            const SizedBox(height: 20),
            Text('TIP: TAP a set number to cycle its type, or LONG PRESS it to select directly.',
                style: GritTextStyles.label(14, weight: FontWeight.w700, color: grit.textSecondary, height: 1.25)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CLOSE', style: GritTextStyles.metric(16, weight: FontWeight.w900, color: grit.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String indicator, String title, String desc, {Color? color}) {
    final grit = Theme.of(context).grit;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          alignment: Alignment.center,
          child: Text(indicator, style: GritTextStyles.mono(18, weight: FontWeight.w900, color: color ?? grit.textSecondary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GritTextStyles.metric(17, weight: FontWeight.w900, color: color ?? grit.textPrimary, letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Text(desc, style: GritTextStyles.label(14, weight: FontWeight.w600, color: grit.textSecondary, height: 1.2)),
            ],
          ),
        ),
      ],
    );
  }

  void showActionMenu(BuildContext context, WidgetRef ref, int index) async {
    final state = ref.read(activeWorkoutProvider);
    final currentEx = state.exercises[index];
    final detail = state.exerciseDetails[currentEx.exerciseId];

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('EXERCISE OPTIONS', style: GritTextStyles.metric(20, color: Theme.of(context).grit.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('CURRENT: ${detail?.name.toUpperCase()}',
                style: GritTextStyles.labelMicro()
                    .copyWith(color: Theme.of(context).grit.muted)),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(PhosphorIcons.arrowsLeftRight(),
                  color: Theme.of(context).grit.accent),
              title: Text('SWAP EXERCISE', style: GritTextStyles.labelCaps().copyWith(color: Theme.of(context).grit.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'SWAP'),
            ),
            ListTile(
              leading: Icon(PhosphorIcons.trash(), color: Theme.of(context).grit.accent),
              title: Text('REMOVE EXERCISE',
                  style: GritTextStyles.labelCaps()
                      .copyWith(color: Theme.of(context).grit.accent)),
              onTap: () => Navigator.pop(ctx, 'REMOVE'),
            ),
          ],
        ),
      ),
    );

    if (result == 'SWAP' && context.mounted) {
      final exercises =
          await context.push<List<Exercise>>(GritRoutes.exerciseLibrarySwap);
      if (exercises != null && exercises.isNotEmpty && context.mounted) {
        final newExercise = exercises.first;
        final oldName = detail?.name ?? 'Old';

        final confirmSwap = await showDialog<bool>(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: Text('CONFIRM SWAP', style: GritTextStyles.metric(22, color: Theme.of(context).grit.textPrimary)),
            content: Text(
                'REPLACE ${oldName.toUpperCase()} WITH ${newExercise.name.toUpperCase()}?',
                style:
                    GritTextStyles.label(13, color: Theme.of(context).grit.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dCtx, false),
                  child: Text('CANCEL',
                      style: GritTextStyles.labelCaps()
                          .copyWith(color: Theme.of(context).grit.textPrimary))),
              TextButton(
                  onPressed: () => Navigator.pop(dCtx, true),
                  child: Text('SWAP',
                      style: GritTextStyles.labelCaps()
                          .copyWith(color: Theme.of(context).grit.accent))),
            ],
          ),
        );

        if (confirmSwap == true && context.mounted) {
          await ref
              .read(activeWorkoutProvider.notifier)
              .swapExercise(index, newExercise);
          await GritHaptics.selectionTick();
        }
      }
    } else if (result == 'REMOVE' && context.mounted) {
      final name = detail?.name ?? 'Exercise';
      final confirmRemove = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          title: Text('REMOVE EXERCISE?', style: GritTextStyles.metric(22, color: Theme.of(context).grit.textPrimary)),
          content: Text(
              'REALLY REMOVE ${name.toUpperCase()} FROM THIS SESSION?',
              style: GritTextStyles.label(13, color: Theme.of(context).grit.textSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dCtx, false),
                child: Text('CANCEL',
                    style: GritTextStyles.labelCaps()
                        .copyWith(color: Theme.of(context).grit.textPrimary))),
            TextButton(
                onPressed: () => Navigator.pop(dCtx, true),
                child: Text('REMOVE',
                    style: GritTextStyles.labelCaps()
                        .copyWith(color: Theme.of(context).grit.accent))),
          ],
        ),
      );

      if (confirmRemove == true && context.mounted) {
        await ref.read(activeWorkoutProvider.notifier).removeExercise(index);
        await GritHaptics.mediumImpact();
      }
    }
  }
}

class _AddSetRow extends StatelessWidget {
  final VoidCallback onTap;
  const _AddSetRow({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await GritHaptics.selectionTick();
        onTap();
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
              top: BorderSide(color: Theme.of(context).grit.border, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.plus(),
                color: Theme.of(context).grit.textSecondary, size: 16),
            const SizedBox(width: 8),
            Text('ADD SET',
                style: GritTextStyles.labelCaps().copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Theme.of(context).grit.muted,
                    letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
