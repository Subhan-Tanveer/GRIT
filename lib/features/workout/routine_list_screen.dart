import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../shared/widgets/grit_section_header.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../shared/widgets/grit_error_state.dart';
import '../../shared/widgets/grit_button.dart';
import '../../shared/widgets/grit_empty_state.dart';
import '../../providers/workout_provider.dart';
import '../../providers/routine_provider.dart';
import '../../core/constants/hero_tags.dart';
import '../../providers/dao_providers.dart';
import '../../data/models/routine.dart';
import '../../core/utils/tour_keys.dart';
import '../../app/routes.dart';

class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final routineListAsync = ref.watch(routineListProvider);

    return Scaffold(
      backgroundColor: grit.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: grit.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: false,
          title: Text(
            'WORKOUT',
            style: GritTextStyles.metric(24, color: grit.textPrimary),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: grit.border),
          ),
          actions: [
            IconButton(
              icon: Icon(PhosphorIcons.timer(),
                  color: grit.textPrimary, size: 24),
              onPressed: () {
                GritHaptics.buttonTap();
                context.push(GritRoutes.workoutTimer);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GritGhostButton(
                key: GritTourKeys.startWorkoutKey,
                label: "NEW",
                isAccent: true,
                onTap: () async {
                  await GritHaptics.buttonTap();
                  if (context.mounted) {
                    context.push(GritRoutes.routineEdit('new'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: routineListAsync.when(
          data: (routines) {
            return Scaffold(
              backgroundColor:
                  Colors.transparent, // Let parent Scaffold handle bg
              body: Column(
                children: [
                  _buildSectionLabel(),
                  Expanded(
                      child: routines.isEmpty
                          ? _buildEmptyState(context)
                          : _buildList(context, routines)),
                ],
              ),
            );
          },
          loading: () => ListView.builder(
            itemCount: 4,
            itemBuilder: (c, i) => Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: grit.border, width: 1)),
              ),
              child: const GritSkeleton(height: 36),
            ),
          ),
          error: (e, __) => GritErrorState(error: e),
        ),
      ),
    );
  }

  Widget _buildSectionLabel() {
    return const GritSectionHeader(
      label: 'MY ROUTINES',
    );
  }

  // QuickStart bar removed was replaced by _QuickStartFAB (Option 3)

  Widget _buildEmptyState(BuildContext context) {
    return GritEmptyState(
      icon: PhosphorIcons.clipboardText(PhosphorIconsStyle.fill),
      title: 'NO ROUTINES FOUND.',
      description:
          'Grit enforces structured, routine-based training for maximum metabolic stress. Create your first routine to begin.',
      actionLabel: 'CREATE FIRST ROUTINE',
      onAction: () async {
        await GritHaptics.buttonTap();
        if (context.mounted) {
          context.push(GritRoutes.routineEdit('new'));
        }
      },
    );
  }

  Widget _buildList(BuildContext context, List<Routine> routines) {
    return ListView.builder(
      itemCount: routines.length,
      itemBuilder: (context, index) {
        final routine = routines[index];
        return _RoutineListItem(routine: routine)
            .animate()
            .fadeIn(delay: (index.clamp(0, 10) * 30).ms, duration: 400.ms)
            .scale(
              begin: const Offset(0.98, 0.98),
              end: const Offset(1, 1),
              curve: Curves.easeOutCubic,
            )
            .slideY(begin: 0.05, curve: Curves.easeOutCubic);
      },
    );
  }
}

class _RoutineListItem extends ConsumerWidget {
  final Routine routine;
  const _RoutineListItem({required this.routine});

  String _lastTrainedLabel(DateTime? lastTrainedAt) {
    if (lastTrainedAt == null) return 'NEVER';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final trainedDate =
        DateTime(lastTrainedAt.year, lastTrainedAt.month, lastTrainedAt.day);
    final diff = today.difference(trainedDate).inDays;

    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return DateFormat('d MMM').format(lastTrainedAt).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final r = routine;
    final exerciseCount = r.exercises?.length ?? 0;
    final lastTrainedAsync = ref.watch(lastTrainedForRoutineProvider(r.name));

    return Slidable(
      key: Key('routine_${r.id}'),
      endActionPane: ActionPane(
        extentRatio: 0.25,
        motion: const ScrollMotion(),
        children: [
          CustomSlidableAction(
            onPressed: (context) => _showDeleteConfirmation(context, ref),
            backgroundColor: grit.accent,
            foregroundColor: Colors.white,
            child: Icon(PhosphorIcons.trash(), size: 24),
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: () => _showDeleteConfirmation(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 20),
          decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: grit.border, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Hero(
                          tag: HeroTags.routineName(r.id!),
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              r.name.toUpperCase(),
                              style: GritTextStyles.metric(22, color: grit.textPrimary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$exerciseCount EXERCISES",
                          style: GritTextStyles.label(12, color: grit.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  lastTrainedAsync.when(
                    data: (dateString) {
                      final date = dateString != null
                          ? DateTime.parse(dateString)
                          : null;
                      final label = _lastTrainedLabel(date);
                      final isAccent = label != 'NEVER';
                      return _StatusBadge(label: label, isAccent: isAccent);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              if (r.exercises != null && r.exercises!.isNotEmpty) ...[
                const SizedBox(height: GritSpacing.sectionSpacing),
                ...r.exercises!.take(5).map((re) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 2,
                          height: 12,
                          margin:
                              const EdgeInsets.only(top: 1), // Optical nudge
                          color: grit.accent.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (re.exercise?.name ?? "UNKNOWN").toUpperCase(),
                            style: GritTextStyles.labelMicro().copyWith(
                              color: grit.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (r.exercises!.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 8),
                    child: Text(
                      "+ ${r.exercises!.length - 5} MORE",
                      style: GritTextStyles.labelMicro().copyWith(
                        color: grit.muted,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: GritSpacing.sectionSpacing),
              Row(
                children: [
                  Expanded(
                    child: GritSecondaryButton(
                      label: "EDIT",
                      height: 44,
                      icon: PhosphorIcons.pencil(),
                      onPressed: () async {
                        await GritHaptics.buttonTap();
                        if (context.mounted) {
                          context.push(GritRoutes.routineEdit(r.id.toString()));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GritPrimaryButton(
                      label: "START",
                      height: 44,
                      icon: PhosphorIcons.play(PhosphorIconsStyle.fill),
                      onPressed: () async {
                        if (!context.mounted) return;
                        await GritHaptics.selectionTick();
                        if (!context.mounted) return;
                        final hasActive =
                            ref.read(activeWorkoutProvider).hasActiveSession;
                        final activeSession =
                            ref.read(activeWorkoutProvider).session;

                        if (hasActive && activeSession != null) {
                          _showConflictDialog(
                              context, ref, activeSession.name, r.id!);
                        } else {
                          await ref
                              .read(activeWorkoutProvider.notifier)
                              .startWorkout(r.id!);
                          if (context.mounted) {
                            context.push(GritRoutes.activeWorkout);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    GritHaptics.longPress();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "DELETE ROUTINE",
          style: GritTextStyles.metric(22, weight: FontWeight.w900, color: grit.textPrimary),
        ),
        content: Text(
          "ARE YOU SURE YOU WANT TO REMOVE '${routine.name.toUpperCase()}'? THIS ACTION CANNOT BE UNDONE.",
          style: GritTextStyles.label(13, color: grit.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCEL",
              style: GritTextStyles.labelCaps()
                  .copyWith(color: grit.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await GritHaptics.deleteAction();
              ref.read(routinesDaoProvider).delete(routine.id!);
              ref.invalidate(routineListProvider);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(
              "DELETE",
              style:
                  GritTextStyles.labelCaps().copyWith(color: grit.accent),
            ),
          ),
        ],
      ),
    );
  }
}

void _showConflictDialog(
    BuildContext context, WidgetRef ref, String currentName, int newRoutineId) {
  final grit = Theme.of(context).grit;
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: grit.background,
          border: Border.all(color: grit.border, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: grit.surface,
              child: Row(
                children: [
                  Icon(PhosphorIcons.warning(),
                      color: grit.accent, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    "WORKOUT IN PROGRESS",
                    style: GritTextStyles.metric(18, weight: FontWeight.w900, color: grit.textPrimary),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: grit.border),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "YOU HAVE AN ACTIVE SESSION: '${currentName.toUpperCase()}'.\n\nWHAT WOULD YOU LIKE TO DO WITH IT BEFORE STARTING THE NEW ROUTINE?",
                style: GritTextStyles.label(13,
                    color: grit.textSecondary, height: 1.2),
              ),
            ),
            Divider(height: 1, thickness: 1, color: grit.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GritGhostButton(
                    label: "SAVE CURRENT & START NEW",
                    isAccent: true,
                    onTap: () async {
                      await GritHaptics.buttonTap();
                      if (!dialogContext.mounted) return;
                      // 1. Pop dialog first
                      Navigator.pop(dialogContext);
                      // 2. Perform background replacement
                      await ref
                          .read(activeWorkoutProvider.notifier)
                          .replaceActiveWorkout(newRoutineId, shouldSave: true);
                      // 3. Navigate using outer STABLE context
                      if (context.mounted) {
                        context.push(GritRoutes.activeWorkout);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  GritGhostButton(
                    label: "DISCARD CURRENT & START NEW",
                    isAccent: false,
                    onTap: () async {
                      await GritHaptics.buttonTap();
                      if (!dialogContext.mounted) return;
                      // 1. Pop dialog first
                      Navigator.pop(dialogContext);
                      // 2. Perform background replacement
                      await ref
                          .read(activeWorkoutProvider.notifier)
                          .replaceActiveWorkout(newRoutineId,
                              shouldSave: false);
                      // 3. Navigate using outer STABLE context
                      if (context.mounted) {
                        context.push(GritRoutes.activeWorkout);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isAccent;

  const _StatusBadge({required this.label, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final color = isAccent ? grit.accent : grit.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label,
        style: GritTextStyles.labelMicro().copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
