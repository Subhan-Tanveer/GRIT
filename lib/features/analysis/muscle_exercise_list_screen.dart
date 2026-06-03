import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/routine_provider.dart';
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

class MuscleExerciseListScreen extends ConsumerWidget {
  final String muscle;
  const MuscleExerciseListScreen({super.key, required this.muscle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(muscleExercisesProvider(muscle));
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
        title: Hero(
          tag: 'muscle_name_$muscle',
          child: Material(
            color: Colors.transparent,
            child: Text(
              MuscleMapper.toDisplayLabel(muscle),
              style: GritTextStyles.metric(24,
                weight: FontWeight.w900,
                color: grit.textPrimary,
                height: 1.0,
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: grit.border, height: 1),
        ),
      ),
      body: exercisesAsync.when(
        data: (exercises) {
          if (exercises.isEmpty) {
            return GritEmptyState(
              icon: PhosphorIcons.barbell(PhosphorIconsStyle.bold),
              title: 'NO EXERCISES YET',
              description: 'Recorded exercises for this muscle group will appear here with performance history.',
            );
          }

          return ListView(
            children: [
              _buildSectionLabel("EXERCISES · ${MuscleMapper.toDisplayLabel(muscle)}"),
              ...exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final ex = entry.value;
                return _buildExerciseRow(context, ex)
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
          itemCount: 8,
          itemBuilder: (c, i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: grit.border, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GritSkeleton(height: 20, width: 180),
                    GritSkeleton(height: 16, width: 60),
                  ],
                ),
                const SizedBox(height: 8),
                GritSkeleton(height: 12, width: 100),
              ],
            ),
          ),
        ),
        error: (err, _) => GritErrorState(
          error: err,
          onRetry: () => ref.invalidate(muscleExercisesProvider(muscle)),
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

  Widget _buildExerciseRow(BuildContext context, Map<String, dynamic> ex) {
    final name = (ex['name'] as String).toUpperCase();
    final prWeight = (ex['pr_weight'] as num?)?.toDouble() ?? 0.0;
    final totalSets = (ex['total_sets'] as int?) ?? 0;
    final lastTrainedStr = ex['last_trained'] as String?;
    final trend = (ex['trend'] as List<double>?) ?? [];

    String lastText = "Never";
    if (lastTrainedStr != null) {
      final date = DateTime.parse(lastTrainedStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      if (diff == 0) {
        lastText = "Today";
      } else if (diff == 1) {
        lastText = "Yesterday";
      } else if (diff < 7) {
        lastText = DateFormat('EEEE').format(date);
      } else if (diff < 30) {
        lastText = "$diff days ago";
      } else {
        lastText = DateFormat('d MMM').format(date);
      }
    }

    final grit = Theme.of(context).grit;
    return InkWell(
      onTap: () {
        GritHaptics.selectionTick();
        context.push(GritRoutes.exerciseAnalysis(ex['id'] as int));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: grit.border, width: 1)),
        ),
        constraints: const BoxConstraints(minHeight: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: GritTextStyles.metric(18,
                      weight: FontWeight.w800,
                      color: grit.textPrimary,
                    ),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: WorkoutUtils.formatWeight(prWeight),
                        style: GritTextStyles.mono(13, weight: FontWeight.w700, color: grit.textPrimary),
                      ),
                      TextSpan(
                        text: " KG",
                        style: GritTextStyles.metric(9, weight: FontWeight.w600, color: grit.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  Text(
                    "LAST: $lastText",
                    style: GritTextStyles.mono(11, color: grit.muted),
                  ),
                  Text(
                    "$totalSets SETS TOTAL",
                     style: GritTextStyles.mono(11, color: grit.textSecondary),
                  ),
              ],
            ),
            if (trend.length >= 2) ...[
              const SizedBox(height: 8),
              _buildSparkline(context, trend),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSparkline(BuildContext context, List<double> values) {
    if (values.isEmpty) return const SizedBox.shrink();
    
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    
    return SizedBox(
      height: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.asMap().entries.map((entry) {
          final idx = entry.key;
          final val = entry.value;
          final isLast = idx == values.length - 1;
          
          double height = 8.0;
          if (max > min) {
            height = 8 + (val - min) / (max - min) * 12;
          }
          
          return Container(
            width: 20, // Fitting available space is hard in ListView, fixed width for structured feel
            height: height,
            margin: const EdgeInsets.only(right: 2),
            color: isLast ? Theme.of(context).grit.accent : Theme.of(context).grit.textSecondary.withValues(alpha: 0.25),
          );
        }).toList(),
      ),
    );
  }
}
