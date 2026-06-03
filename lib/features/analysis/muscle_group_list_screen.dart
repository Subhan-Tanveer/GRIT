import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/metrics_provider.dart';
import '../../data/models/muscle_analysis.dart';
import '../../data/models/workout_session.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/theme/grit_animations.dart';
import '../../core/utils/muscle_mapper.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/workout_utils.dart';
import '../../shared/widgets/grit_section_header.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../shared/widgets/grit_empty_state.dart';
import '../../shared/widgets/grit_error_state.dart';
import '../../app/routes.dart';

class MuscleGroupListScreen extends ConsumerWidget {
  const MuscleGroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(muscleGroupSummariesProvider);
    final historyAsync = ref.watch(allFinishedSessionsProvider);
    final viewMode = ref.watch(analysisViewModeProvider);
    final grit = Theme.of(context).grit;

    return Scaffold(
      backgroundColor: grit.background,
      appBar: AppBar(
        backgroundColor: grit.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'ANALYSIS',
          style: GritTextStyles.metric(24,
            weight: FontWeight.w900,
            color: grit.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: grit.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          _buildViewSwitcher(ref, viewMode, context),
          Expanded(
            child: AnimatedSwitcher(
              duration: GritAnimations.mechanicalDuration,
              switchInCurve: GritAnimations.mechanicalCurve,
              switchOutCurve: GritAnimations.mechanicalCurve,
              child: viewMode == AnalysisViewMode.muscles
                  ? _buildMuscleGroupSection(context, ref, summariesAsync)
                  : _buildHistorySection(context, ref, historyAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher(WidgetRef ref, AnalysisViewMode mode, BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 16),
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border(bottom: BorderSide(color: grit.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildSwitchButton(ref, context, "MUSCLES", AnalysisViewMode.muscles, mode == AnalysisViewMode.muscles)),
          const SizedBox(width: 12),
          Expanded(child: _buildSwitchButton(ref, context, "HISTORY", AnalysisViewMode.history, mode == AnalysisViewMode.history)),
        ],
      ),
    );
  }

  Widget _buildSwitchButton(WidgetRef ref, BuildContext context, String label, AnalysisViewMode target, bool isActive) {
    final grit = Theme.of(context).grit;
    return InkWell(
      onTap: () {
        GritHaptics.selectionTick();
        ref.read(analysisViewModeProvider.notifier).state = target;
      },
      child: AnimatedContainer(
        duration: GritAnimations.mechanicalDuration,
        curve: GritAnimations.mechanicalCurve,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? grit.accent : Colors.transparent,
          border: Border.all(color: isActive ? grit.accent : grit.border, width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: GritTextStyles.metric(12, 
              weight: FontWeight.w900, 
              color: isActive ? Colors.white : grit.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleGroupSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<MuscleGroupSummary>> summariesAsync,
  ) {
    final grit = Theme.of(context).grit;
    return summariesAsync.when(
      data: (summaries) {
        if (summaries.isEmpty) {
          return Center(
            child: GritEmptyState(
              icon: PhosphorIcons.chartLine(PhosphorIconsStyle.bold),
              title: 'NO DATA RECORDED',
              description: 'Complete your first workout to generate metabolic performance metrics and muscle distribution charts.',
            ),
          );
        }

        return ListView(
          key: const ValueKey('muscles_view_data'),
          children: [
            const GritSectionHeader(
              label: 'MUSCLE GROUPS',
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            ),
            ...summaries.asMap().entries.map((entry) {
              final index = entry.key;
              final s = entry.value;
              return _buildMuscleGroupCard(context, s)
                  .animate()
                  .fadeIn(
                    delay: (index.clamp(0, 10) * 20).ms,
                    duration: GritAnimations.mechanicalDuration,
                  )
                  .slideY(
                    begin: 0.05,
                    curve: GritAnimations.mechanicalCurve,
                  );
            }),
          ],
        );
      },
      loading: () => ListView.builder(
        itemCount: 6,
        itemBuilder: (c, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: grit.border, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const GritSkeleton(height: 24, width: 140),
                  Container(width: 60, height: 18, decoration: BoxDecoration(border: Border.all(color: grit.border))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  GritSkeleton(height: 20, width: 80),
                  const SizedBox(width: 40),
                  GritSkeleton(height: 20, width: 40),
                ],
              ),
            ],
          ),
        ),
      ),
      error: (err, _) => GritErrorState(
        error: err,
        onRetry: () => ref.invalidate(muscleGroupSummariesProvider),
      ),
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<WorkoutSession>> historyAsync,
  ) {
    final grit = Theme.of(context).grit;
    return historyAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Center(
            child: GritEmptyState(
              icon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.bold),
              title: 'NO HISTORY FOUND',
              description: 'Your completed workout sessions will be archived here with detailed performance metrics.',
            ),
          );
        }

        return ListView.builder(
          key: const ValueKey('history_view_data'),
          itemCount: sessions.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const GritSectionHeader(
                label: 'WORKOUT LOG',
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              );
            }
            final session = sessions[index - 1];
            return _buildHistoryCard(context, session)
                .animate()
                .fadeIn(
                  delay: ((index - 1).clamp(0, 10) * 20).ms,
                  duration: GritAnimations.mechanicalDuration,
                )
                .slideX(
                  begin: 0.05,
                  curve: GritAnimations.mechanicalCurve,
                );
          },
        );
      },
      loading: () => ListView.builder(
        itemCount: 8,
        itemBuilder: (c, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: grit.border, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GritSkeleton(height: 24, width: 180),
              const SizedBox(height: 12),
              Row(
                children: [
                  GritSkeleton(height: 14, width: 100),
                  const SizedBox(width: 20),
                  GritSkeleton(height: 14, width: 60),
                ],
              ),
            ],
          ),
        ),
      ),
      error: (err, _) => GritErrorState(
        error: err,
        onRetry: () => ref.invalidate(allFinishedSessionsProvider),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, WorkoutSession session) {
    final grit = Theme.of(context).grit;
    final start = DateTime.parse(session.startedAt);
    final dateStr = DateFormat('d MMM yyyy').format(start).toUpperCase();
    final timeStr = DateFormat('HH:mm').format(start);
    final durationMin = (session.workoutDurationSeconds / 60).round();
    
    return InkWell(
      onTap: () {
        GritHaptics.selectionTick();
        context.push(GritRoutes.sessionDetail(session.id!));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Theme.of(context).grit.border, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: GritTextStyles.mono(10, color: grit.textSecondary, weight: FontWeight.w700),
                ),
                Text(
                  "$timeStr · ${durationMin}M",
                  style: GritTextStyles.mono(10, color: grit.textSecondary, weight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    session.name.toUpperCase(),
                    style: GritTextStyles.metric(22,
                      weight: FontWeight.w900,
                      color: grit.textPrimary,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      WorkoutUtils.formatWeight(session.totalVolumeKg),
                      style: GritTextStyles.metric(22, color: grit.accent),
                    ),
                    Text(
                      "TOTAL VOLUME (KG)",
                      style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleGroupCard(BuildContext context, MuscleGroupSummary summary) {
    final now = DateTime.now();
    final daysAgo = summary.lastTrainedDate != null 
        ? now.difference(summary.lastTrainedDate!).inDays 
        : null;
    
    final lastTrainedText = daysAgo == null 
        ? "NEVER" 
        : daysAgo == 0 ? "TODAY" : daysAgo == 1 ? "1D AGO" : "${daysAgo}D AGO";

    final grit = Theme.of(context).grit;
    return InkWell(
      onTap: () {
        GritHaptics.selectionTick();
        context.push(GritRoutes.muscleAnalysis(summary.name));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: grit.border, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'muscle_name_${summary.name}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          MuscleMapper.toDisplayLabel(summary.name),
                          style: GritTextStyles.metric(22,
                            weight: FontWeight.w900,
                            color: grit.textPrimary,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildBadge(context, summary.rank),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatBlock(context, "VOLUME", "${NumberFormat('#,###').format(summary.totalVolume.round())}KG"),
                const SizedBox(width: 40),
                _buildStatBlock(context, "SETS", "${summary.totalSets}"),
                const SizedBox(width: 40),
                _buildStatBlock(context, "LAST", lastTrainedText),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 4,
                        width: double.infinity,
                        color: grit.border.withValues(alpha: 0.12),
                      ),
                      Container(
                        height: 4,
                        width: (MediaQuery.of(context).size.width - 80) * (summary.score / 100),
                        decoration: BoxDecoration(
                          color: _getRankColor(context, summary.rank),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "${summary.score.round()}%",
                  style: GritTextStyles.mono(10, weight: FontWeight.w900, color: _getRankColor(context, summary.rank)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBlock(BuildContext context, String label, String value) {
    final grit = Theme.of(context).grit;
    List<TextSpan> valueSpans = [];
    final numberMatch = RegExp(r'(\d+[\.,]?\d*)').firstMatch(value);
    
    if (numberMatch != null) {
      final numberStr = numberMatch.group(1)!;
      final parts = value.split(numberStr);
      
      if (parts[0].isNotEmpty) {
        valueSpans.add(TextSpan(text: parts[0], style: GritTextStyles.metric(10, weight: FontWeight.w600, letterSpacing: 1)));
      }
      valueSpans.add(TextSpan(text: numberStr, style: GritTextStyles.mono(15, weight: FontWeight.w700)));
      if (parts.length > 1 && parts[1].isNotEmpty) {
        valueSpans.add(TextSpan(text: parts[1], style: GritTextStyles.metric(10, weight: FontWeight.w600, letterSpacing: 1)));
      }
    } else {
      valueSpans.add(TextSpan(text: value, style: GritTextStyles.metric(15, weight: FontWeight.w700)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GritTextStyles.labelMicro().copyWith(
            color: grit.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            style: GritTextStyles.metric(15, color: grit.textPrimary),
            children: valueSpans,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, String rank) {
    Color color = _getRankColor(context, rank);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        rank.toUpperCase(),
        style: GritTextStyles.metric(8,
          weight: FontWeight.w900,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Color _getRankColor(BuildContext context, String rank) {
    final grit = Theme.of(context).grit;
    switch (rank) {
      case 'NEEDS ATTENTION':
      case 'NEGLECTED':
        return grit.warning;
      case 'DOMINANT':
        return grit.accent;
      default:
        return grit.success;
    }
  }
}
