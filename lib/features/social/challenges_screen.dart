import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/challenge.dart';
import '../../providers/social_provider.dart';
import '../../services/grit_api_service.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../shared/widgets/grit_button.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final mineAsync = ref.watch(myChallengesProvider);
    final availableAsync = ref.watch(availableChallengesProvider);

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
                Text('CHALLENGES', style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add_circle, color: grit.accent),
                  onPressed: () => _showCreateDialog(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myChallengesProvider);
          ref.invalidate(availableChallengesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 20),
          children: [
            Text('YOUR CHALLENGES', style: GritTextStyles.sectionHeader().copyWith(color: grit.textSecondary)),
            const SizedBox(height: 12),
            mineAsync.when(
              loading: () => const GritSkeleton(height: 80, width: double.infinity),
              error: (e, st) => Text(
                e is ApiException ? e.message : 'Could not load challenges',
                style: GritTextStyles.label(12, color: grit.textSecondary),
              ),
              data: (challenges) {
                if (challenges.isEmpty) {
                  return Text('No challenges yet — tap + to create one.',
                      style: GritTextStyles.label(12, color: grit.muted));
                }
                return Column(
                  children: [for (final c in challenges) _myChallengeCard(context, c)],
                );
              },
            ),
            const SizedBox(height: 28),
            Text('FROM YOUR FRIENDS', style: GritTextStyles.sectionHeader().copyWith(color: grit.textSecondary)),
            const SizedBox(height: 12),
            availableAsync.when(
              loading: () => const GritSkeleton(height: 60, width: double.infinity),
              error: (e, st) => const SizedBox.shrink(),
              data: (challenges) {
                if (challenges.isEmpty) {
                  return Text('No open challenges from friends right now.',
                      style: GritTextStyles.label(12, color: grit.muted));
                }
                return Column(
                  children: [for (final c in challenges) _availableChallengeCard(context, ref, c)],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _myChallengeCard(BuildContext context, Challenge c) {
    final grit = Theme.of(context).grit;
    final daysLeft = c.endDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border.all(color: c.myCompleted ? grit.success : grit.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(c.title, style: GritTextStyles.tileTitle().copyWith(color: grit.textPrimary)),
              ),
              if (c.myCompleted)
                Icon(Icons.check_circle, color: grit.success, size: 20)
              else
                Text(
                  daysLeft >= 0 ? '${daysLeft}D LEFT' : 'ENDED',
                  style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 1),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            child: Stack(
              children: [
                Container(height: 6, color: grit.surface2),
                FractionallySizedBox(
                  widthFactor: c.myProgressRatio,
                  child: Container(height: 6, color: c.myCompleted ? grit.success : grit.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${c.myProgress.round()} / ${c.goalTarget.round()} ${c.goalType.label}',
            style: GritTextStyles.label(11, color: grit.textSecondary),
          ),
          const SizedBox(height: 10),
          for (final p in c.participants.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p.displayName, style: GritTextStyles.label(11, color: grit.textSecondary)),
                  Text('${p.progress.round()}', style: GritTextStyles.mono(11, color: grit.textPrimary)),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _availableChallengeCard(BuildContext context, WidgetRef ref, Challenge c) {
    final grit = Theme.of(context).grit;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: grit.surface, border: Border.all(color: grit.border)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: GritTextStyles.tileTitle().copyWith(color: grit.textPrimary)),
                Text(
                  'GOAL: ${c.goalTarget.round()} ${c.goalType.label}',
                  style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 1),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              GritHaptics.mediumImpact();
              ref.read(socialActionsProvider).joinChallenge(c.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: grit.accent),
              child: Text('JOIN', style: GritTextStyles.label(12, weight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    ChallengeGoalType selectedType = ChallengeGoalType.workoutCount;
    int durationDays = 7;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (statefulContext, setState) {
          return AlertDialog(
            backgroundColor: grit.surface,
            title: Text('NEW CHALLENGE', style: GritTextStyles.titleMedium().copyWith(color: grit.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: GritTextStyles.label(13, color: grit.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. 10 Workouts in 14 Days',
                    hintStyle: GritTextStyles.label(13, color: grit.muted),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: ChallengeGoalType.values.map((type) {
                    final isSelected = type == selectedType;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedType = type),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? grit.accent : Colors.transparent,
                            border: Border.all(color: isSelected ? grit.accent : grit.border),
                          ),
                          child: Text(
                            type.label,
                            style: GritTextStyles.label(10, weight: FontWeight.w700,
                                color: isSelected ? Colors.white : grit.textSecondary),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  style: GritTextStyles.label(13, color: grit.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Target (e.g. 10)',
                    hintStyle: GritTextStyles.label(13, color: grit.muted),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DURATION', style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary)),
                    Row(
                      children: [7, 14, 30].map((days) {
                        final isSelected = durationDays == days;
                        return GestureDetector(
                          onTap: () => setState(() => durationDays = days),
                          child: Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? grit.accent : Colors.transparent,
                              border: Border.all(color: isSelected ? grit.accent : grit.border),
                            ),
                            child: Text('${days}D',
                                style: GritTextStyles.label(11, color: isSelected ? Colors.white : grit.textSecondary)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('CANCEL', style: GritTextStyles.label(13, color: grit.textSecondary)),
              ),
              GritPrimaryButton(
                label: 'CREATE',
                height: 40,
                onPressed: () {
                  final target = double.tryParse(targetController.text);
                  if (titleController.text.trim().isEmpty || target == null || target <= 0) return;
                  ref.read(socialActionsProvider).createChallenge(
                        title: titleController.text.trim(),
                        goalType: selectedType,
                        goalTarget: target,
                        durationDays: durationDays,
                      );
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
