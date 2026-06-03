import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/metrics_provider.dart';
import '../../providers/routine_provider.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/theme/grit_animations.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/workout_utils.dart';
import '../../shared/widgets/grit_section_header.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../shared/widgets/grit_error_state.dart';
import '../../shared/widgets/hero_comparison_card.dart';
import '../../shared/widgets/progression_card.dart';
import '../../app/routes.dart';

class ExerciseAnalysisScreen extends ConsumerWidget {
  final int exerciseId;
  const ExerciseAnalysisScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(exerciseDetailStatsProvider(exerciseId));
    final currentMetric = ref.watch(exerciseAnalysisMetricProvider(exerciseId));
    final progressionAsync = ref.watch(exerciseProgressionProvider(exerciseId));
    final historyAsync = ref.watch(exerciseSessionHistoryProvider(exerciseId));
    final grit = Theme.of(context).grit;

    return Scaffold(
      backgroundColor: grit.background,
      appBar: AppBar(
        backgroundColor: grit.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(PhosphorIcons.arrowLeft(), color: grit.textPrimary, size: 28),
          onPressed: () => context.canPop() ? context.pop() : context.go(GritRoutes.analysis),
        ),
        title: statsAsync.when(
          data: (s) => Text(
            (s['name'] ?? 'EXERCISE').toString().toUpperCase(),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GritTextStyles.metric(22,
              weight: FontWeight.w900,
              color: grit.textPrimary,
              height: 1.0,
            ),
          ),
          loading: () => GritSkeleton(height: 18, width: 150),
          error: (_, __) => const Text('ERROR'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: grit.border, height: 1),
        ),
      ),
      body: ListView(
        children: [
          progressionAsync.when(
            data: (points) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: HeroComparisonCard(points: points),
            ).animate().fadeIn(
              duration: GritAnimations.mechanicalDuration,
            ).slideY(
              begin: -0.05,
              curve: GritAnimations.mechanicalCurve,
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: GritSkeleton(height: 120, width: double.infinity),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: GritErrorState(
                error: err,
                onRetry: () => ref.invalidate(exerciseProgressionProvider(exerciseId)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildMetricSelector(ref, context, exerciseId, currentMetric),
          ProgressionCard(
            dataAsync: progressionAsync,
            metric: currentMetric,
          ).animate().fadeIn(
            delay: 100.ms,
            duration: GritAnimations.mechanicalDuration,
          ).slideY(
            begin: 0.05,
            curve: GritAnimations.mechanicalCurve,
          ),
          _buildSessionHistory(context, ref, exerciseId, historyAsync).animate().fadeIn(
            delay: 200.ms,
            duration: GritAnimations.mechanicalDuration,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSelector(WidgetRef ref, BuildContext context, int exId, ExerciseAnalysisMetric current) {
    final grit = Theme.of(context).grit;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border.all(color: grit.border, width: 1.5),
      ),
      child: Row(
        children: [
          _buildMetricButton(ref, context, exId, "1RM", ExerciseAnalysisMetric.e1rm, current == ExerciseAnalysisMetric.e1rm),
          _buildMetricButton(ref, context, exId, "VOLUME", ExerciseAnalysisMetric.volume, current == ExerciseAnalysisMetric.volume),
          _buildMetricButton(ref, context, exId, "MAX WEIGHT", ExerciseAnalysisMetric.weight, current == ExerciseAnalysisMetric.weight),
        ],
      ),
    );
  }

  Widget _buildMetricButton(WidgetRef ref, BuildContext context, int exId, String label, ExerciseAnalysisMetric target, bool isActive) {
    final grit = Theme.of(context).grit;
    return Expanded(
      child: InkWell(
        onTap: () {
          GritHaptics.selectionTick();
          ref.read(exerciseAnalysisMetricProvider(exId).notifier).state = target;
        },
        child: AnimatedContainer(
          duration: GritAnimations.mechanicalDuration,
          curve: GritAnimations.mechanicalCurve,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? grit.accent : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: GritTextStyles.metric(10,
                weight: FontWeight.w900,
                color: isActive ? Colors.white : grit.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return GritSectionHeader(
      label: text,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    );
  }

  Widget _buildSessionHistory(
    BuildContext context,
    WidgetRef ref,
    int exId,
    AsyncValue<List<Map<String, dynamic>>> historyAsync,
  ) {
    final grit = Theme.of(context).grit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel("SET HISTORY"),
        historyAsync.when(
          data: (sets) {
            // Group sets by session
            final Map<int, List<Map<String, dynamic>>> groups = {};
            for (final s in sets) {
              final sid = s['session_id'] as int;
              groups.putIfAbsent(sid, () => []).add(s);
            }

            final sessionList = groups.keys.toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessionList.length,
              itemBuilder: (ctx, i) {
                final sid = sessionList[i];
                final sessionSets = groups[sid]!;
                final first = sessionSets.first;
                
                // Calculate session stats
                double sessionVolume = 0;
                double bestE1RM = 0;
                for (var s in sessionSets) {
                  final w = (s['weight_kg'] as num?)?.toDouble() ?? 0;
                  final r = (s['reps'] as int?) ?? 0;
                  final vol = w * r;
                  sessionVolume += vol;
                  final e1rm = WorkoutUtils.calculateE1RM(w, r);
                  if (e1rm > bestE1RM) bestE1RM = e1rm;
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: grit.surface,
                    border: Border(
                      left: BorderSide(color: grit.accent, width: 3.0),
                      top: BorderSide(color: grit.border, width: 1.0),
                      right: BorderSide(color: grit.border, width: 1.0),
                      bottom: BorderSide(color: grit.border, width: 1.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          GritHaptics.selectionTick();
                          context.push(GritRoutes.sessionDetail(sid));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: grit.surface2,
                            border: Border(bottom: BorderSide(color: grit.border, width: 1)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      (first['session_name'] ?? 'SESSION').toString().toUpperCase(),
                                      style: GritTextStyles.metric(14, weight: FontWeight.w900, color: grit.textPrimary, letterSpacing: 0.5),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('d MMM yyyy').format(DateTime.parse(first['date'])),
                                    style: GritTextStyles.mono(10, color: grit.muted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildMiniStat(context, "VOLUME", "${NumberFormat('#,###').format(sessionVolume.round())} KG"),
                                  const SizedBox(width: 16),
                                  _buildMiniStat(context, "BEST 1RM", "${WorkoutUtils.formatWeight(bestE1RM)} KG"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...sessionSets.map((s) => _buildSetRow(context, s)),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: GritSkeleton(height: 100, width: double.infinity),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: GritErrorState(
              error: err,
              onRetry: () => ref.invalidate(exerciseSessionHistoryProvider(exId)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value) {
    final grit = Theme.of(context).grit;
    return Row(
      children: [
        Text("$label: ", style: GritTextStyles.mono(10, color: grit.textSecondary, weight: FontWeight.w800)),
        Text(value, style: GritTextStyles.mono(11, color: grit.textSecondary, weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSetRow(BuildContext context, Map<String, dynamic> s) {
    final grit = Theme.of(context).grit;
    final e1rm = WorkoutUtils.calculateE1RM((s['weight_kg'] as num?)?.toDouble() ?? 0, (s['reps'] as int?) ?? 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: grit.border.withValues(alpha: 0.1), width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              "${s['set_number']}",
              style: GritTextStyles.mono(11, weight: FontWeight.w400, color: grit.textSecondary),
            ),
          ),
          Text(
            WorkoutUtils.formatWeight((s['weight_kg'] as num?)?.toDouble() ?? 0),
            style: GritTextStyles.mono(15, weight: FontWeight.w700, color: grit.textSecondary),
          ),
          const SizedBox(width: 4),
          Text("×", style: GritTextStyles.mono(14, color: grit.textSecondary)),
          const SizedBox(width: 4),
          Text(
            "${s['reps']}",
            style: GritTextStyles.mono(15, weight: FontWeight.w700, color: grit.textSecondary),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              "1RM: ${WorkoutUtils.formatWeight(e1rm)}",
              style: GritTextStyles.mono(11, color: grit.textSecondary),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const Spacer(),
          if (s['is_pr'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: grit.accent.withValues(alpha: 0.12),
                border: Border.all(color: grit.accent, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.trophy(PhosphorIconsStyle.fill),
                    color: grit.accent,
                    size: 10,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "NEW MAX",
                    style: GritTextStyles.metric(9, weight: FontWeight.w900, color: grit.accent),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
