import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/grit_theme.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../shared/widgets/grit_error_state.dart';
import '../../providers/routine_provider.dart';
import '../../data/models/workout_session.dart';
import '../../data/models/set_entry.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/workout_utils.dart';
import '../../providers/profile_provider.dart';
import '../../app/routes.dart';

class SessionDetailScreen extends ConsumerWidget {
  final int sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(sessionDetailProvider(sessionId));
    final grit = Theme.of(context).grit;

    return Scaffold(
      backgroundColor: grit.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildPageLabel(),
            detailAsync.when(
              data: (data) =>
                  Expanded(child: _buildContent(context, data, ref)),
              loading: () => const Expanded(
                  child: Padding(
                padding: EdgeInsets.all(20),
                child: GritSkeleton(height: double.infinity),
              )),
              error: (e, __) => Expanded(child: GritErrorState(error: e)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageLabel() {
    return const SizedBox.shrink();
  }

  Widget _buildContent(
      BuildContext context, Map<String, dynamic> data, WidgetRef ref) {
    final session = data['session'] as WorkoutSession;
    final exercises = data['exercises'] as List<Map<String, dynamic>>;

    return ListView(
      children: [
        _buildHeader(context, session, exercises).animate().fadeIn().slideY(begin: -0.1),
        _buildSubHeader(context, session, exercises).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
        ...exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final ex = entry.value;
          return _buildExerciseBlock(context, ref, ex).animate().fadeIn(delay: (400 + index * 100).ms, duration: 500.ms).slideY(begin: 0.05);
        }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WorkoutSession session, List exercises) {
    final grit = Theme.of(context).grit;
    return Container(
      padding: const EdgeInsets.fromLTRB(GritSpacing.horizontalMargin - 8, 12,
          GritSpacing.horizontalMargin, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: grit.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(PhosphorIcons.arrowLeft(),
                color: grit.textPrimary, size: 24),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(GritRoutes.dashboard),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ANALYSIS",
                  style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 1.5),
                ),
                Text(session.name.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: GritTextStyles.metric(22,
                        weight: FontWeight.w900, height: 1.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(BuildContext context, WorkoutSession session, List exercises) {
    final grit = Theme.of(context).grit;
    final start = DateTime.parse(session.startedAt);
    final totalMin = (session.workoutDurationSeconds / 60).round();
    final restMin = (session.restDurationSeconds / 60).round();
    final workoutMin = ((session.workoutDurationSeconds - session.restDurationSeconds).clamp(0, session.workoutDurationSeconds) / 60).round();

    int totalSets = 0;
    for (var ex in exercises) {
      final sets = ex['sets'] as List<Map<String, dynamic>>? ?? [];
      totalSets += sets.where((s) => (s['set'] as SetEntry).isCompleted).length;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: 16, horizontal: GritSpacing.horizontalMargin),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: grit.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEE, d MMM y').format(start).toUpperCase(),
                  style: GritTextStyles.mono(12,
                      color: grit.textPrimary, weight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '${exercises.length} EXERCISES  ·  $totalSets SETS',
                  style: GritTextStyles.labelMicro().copyWith(
                      color: grit.textSecondary, letterSpacing: 1),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSimpleTimeItem(context, 'TOTAL', '$totalMin MIN')),
              _buildDivider(context),
              Expanded(child: _buildSimpleTimeItem(context, 'WORK', '$workoutMin MIN')),
              _buildDivider(context),
              Expanded(child: _buildSimpleTimeItem(context, 'REST', '$restMin MIN')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTimeItem(BuildContext context, String label, String value) {
    final grit = Theme.of(context).grit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GritTextStyles.label(10,
                color: grit.textSecondary, weight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: GritTextStyles.metric(20, weight: FontWeight.w800, color: grit.textPrimary)),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      color: Theme.of(context).grit.border,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildExerciseBlock(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    final exercise = data['exercise'];
    final sets = data['sets'] as List<Map<String, dynamic>>;
    final profile = ref.watch(profileProvider);
    final isLb = profile.weightUnit == 'LBS';
    final unitLabel = isLb ? 'LBS' : 'KG';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(GritSpacing.horizontalMargin, 20,
              GritSpacing.horizontalMargin, 12),
          child: Text(exercise.name.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: GritTextStyles.label(20,
                  weight: FontWeight.w800,
                  height: 1.15,
                  color: Theme.of(context).grit.textPrimary)),
        ),
        Divider(height: 1, color: Theme.of(context).grit.border),
        ...sets
            .map((s) => _buildSetRow(context, s['set'] as SetEntry, s['isPR'] as bool, isLb, unitLabel)),
        Divider(height: 1, color: Theme.of(context).grit.border),
      ],
    );
  }

  Widget _buildSetRow(BuildContext context, SetEntry s, bool isPR, bool isLb, String unitLabel) {
    final grit = Theme.of(context).grit;
    final isCompleted = s.isCompleted;
    final displayWeight = isLb ? WorkoutUtils.kgToLb(s.weightKg) : s.weightKg;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: GritSpacing.horizontalMargin, vertical: 14),
      decoration: BoxDecoration(
        color: isCompleted ? grit.accent.withValues(alpha: 0.04) : Colors.transparent,
        border: Border(bottom: BorderSide(color: grit.surface2, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? grit.accent : grit.border,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 24,
            child: Text('${s.setNumber}',
                style: GritTextStyles.mono(11, color: isCompleted ? grit.textSecondary : grit.border)),
          ),
          Expanded(
            child: Row(
              children: [
                Text(WorkoutUtils.formatWeight(displayWeight),
                    style: GritTextStyles.mono(18,
                        weight: FontWeight.w700,
                        color: isCompleted ? grit.textPrimary : grit.border)),
                const SizedBox(width: 6),
                Text(unitLabel,
                    style: GritTextStyles.metric(9,
                        color: grit.muted,
                        weight: FontWeight.w600)),
                const SizedBox(width: 20),
                Text('×',
                    style: GritTextStyles.metric(14,
                        color: grit.muted)),
                const SizedBox(width: 20),
                Text('${s.reps ?? 0}',
                    style: GritTextStyles.mono(18,
                        weight: FontWeight.w700,
                        color: isCompleted ? grit.textPrimary : grit.border)),
                const SizedBox(width: 6),
                Text('REPS',
                    style: GritTextStyles.metric(9,
                        color: grit.muted,
                        weight: FontWeight.w600)),
              ],
            ),
          ),
          if (isPR) _buildPRBadge(context),
        ],
      ),
    );
  }

  Widget _buildPRBadge(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: grit.background,
        border: Border.all(color: grit.accent, width: 1.5),
      ),
      child: Center(
        child: Text('PR',
            style: GritTextStyles.labelMicro().copyWith(
              color: grit.accent,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            )),
      ),
    );
  }
}
