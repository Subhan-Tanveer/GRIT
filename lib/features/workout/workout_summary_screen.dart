import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/routine_provider.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../shared/widgets/grit_error_state.dart';
import '../../data/models/workout_session.dart';
import '../../data/models/set_entry.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/workout_utils.dart';
import '../../providers/profile_provider.dart';
import '../../app/routes.dart';
import '../../shared/widgets/grit_button.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  final int sessionId;
  const WorkoutSummaryScreen({super.key, required this.sessionId});

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _titleCtrl;
  late final Animation<double> _titleScale;

  @override
  void initState() {
    super.initState();
    _titleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _titleScale = CurvedAnimation(parent: _titleCtrl, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleCtrl.forward();
      GritHaptics.workoutComplete();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final detailAsync = ref.watch(sessionDetailProvider(widget.sessionId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        GritHaptics.buttonTap();
      },
      child: Scaffold(
        backgroundColor: grit.background,
        body: SafeArea(
          child: detailAsync.when(
            data: (data) => _buildContent(context, data),
            loading: () => Column(
              children: [
                Builder(
                  builder: (context) => SizedBox(
                    height: MediaQuery.of(context).padding.top + 40,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: 3,
                    itemBuilder: (c, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GritSpacing.horizontalMargin,
                        vertical: 10,
                      ),
                      child: GritSkeleton(height: 120),
                    ),
                  ),
                ),
              ],
            ),
            error: (e, __) => GritErrorState(error: e),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final grit = Theme.of(context).grit;
    final session = data['session'] as WorkoutSession;
    final exercises = data['exercises'] as List<Map<String, dynamic>>;

    // Calculate total sets (excluding warmups)
    int totalSets = 0;
    for (var ex in exercises) {
      final setsMapList = ex['sets'] as List<Map<String, dynamic>>;
      totalSets += setsMapList.where((s) {
        final entry = s['set'] as SetEntry;
        return entry.isCompleted && entry.setType != SetEntryType.warmup;
      }).length;
    }

    // Calculate PR Count (ensuring warmth sets didn't sneak in)
    final prExercises = exercises.where((ex) {
      final sets = ex['sets'] as List<Map<String, dynamic>>;
      return sets.any((s) {
        final entry = s['set'] as SetEntry;
        return s['isPR'] == true && entry.setType != SetEntryType.warmup;
      });
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 24),
        ScaleTransition(
          scale: _titleScale,
          child: Text('WORKOUT COMPLETE',
              style: GritTextStyles.headlineSmall().copyWith(
                  color: grit.textPrimary)),
        ),
        const SizedBox(height: 8),
        Text(
          session.name.toUpperCase(),
          style: GritTextStyles.labelMicro().copyWith(
            color: grit.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('EEEE, d MMM').format(DateTime.parse(session.startedAt)).toUpperCase(),
          style: GritTextStyles.labelMicro().copyWith(
            color: grit.muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeroSummary(context, session, totalSets, prExercises.length)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1),
              const SizedBox(height: 16), // Reduced from 32 for tighter rhythm to Diagnostics
              _buildSectionHeader(context, 'DIAGNOSTICS'),
              _buildExerciseDetails(context, exercises)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 16), // Reduced for consistency
              _buildSectionHeader(context, 'NEW RECORDS'),
              _buildPRSection(context, prExercises)
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 64), // Extra bottom breathing room
            ],
          ),
        ),
        _buildBottomCTA(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    final grit = Theme.of(context).grit;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: grit.border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(
        GritSpacing.horizontalMargin,
        GritSpacing.sectionSpacing,
        GritSpacing.horizontalMargin,
        GritSpacing.sectionHeaderBottom,
      ),
      child: Text(
        label,
        style: GritTextStyles.sectionHeader(),
      ),
    );
  }

  Widget _buildHeroSummary(BuildContext context, WorkoutSession session,
      int totalSets, int prCount) {
    final grit = Theme.of(context).grit;
    final totalMin = (session.workoutDurationSeconds / 60).round();
    final restMin = (session.restDurationSeconds / 60).round();
    final workoutMin = ((session.workoutDurationSeconds - session.restDurationSeconds).clamp(0, session.workoutDurationSeconds) / 60).round();

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Text(totalMin.toString(),
                style: GritTextStyles.dataValueMassive().copyWith(
                    color: grit.textPrimary,
                    height: 0.9)),
          ],
        ),
        Text('MINUTES',
            style: GritTextStyles.labelMicro().copyWith(
                color: grit.textSecondary,
                letterSpacing: 12,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: grit.surface,
            border: Border.symmetric(horizontal: BorderSide(color: grit.border, width: 1)),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildStatTile(context, 'WORK', '$workoutMin', 'MIN'),
                _buildStatDivider(context),
                _buildStatTile(context, 'REST', '$restMin', 'MIN'),
                _buildStatDivider(context),
                _buildStatTile(context, 'SETS', '$totalSets', 'DONE'),
                _buildStatDivider(context),
                _buildStatTile(context, 'RECORDS', '$prCount', 'NEW'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value, String unit) {
    final grit = Theme.of(context).grit;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(label, style: GritTextStyles.labelMicro().copyWith(fontSize: 9, color: grit.muted, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: GritTextStyles.dataValueLarge()),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2), // Optical baseline fix
                    child: Text(unit, style: GritTextStyles.labelMicro().copyWith(
                        color: grit.muted, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider(BuildContext context) => VerticalDivider(color: Theme.of(context).grit.border, width: 1, thickness: 1);

  Widget _buildExerciseDetails(BuildContext context, List<Map<String, dynamic>> exercises) {
    final grit = Theme.of(context).grit;
    final profile = ref.watch(profileProvider);
    final isLb = profile.weightUnit.toLowerCase() == 'lb';

    return Column(
      children: exercises.map((ex) {
        final exercise = ex['exercise'];
        final sets = ex['sets'] as List<Map<String, dynamic>>;
        final completedSets = sets.where((s) => (s['set'] as SetEntry).isCompleted).toList();

        if (completedSets.isEmpty) return const SizedBox();

        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: grit.border, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name.toUpperCase(),
                        style: GritTextStyles.headlineSmall().copyWith(letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: completedSets.map((s) {
                        final set = s['set'] as SetEntry;
                        final isPR = s['isPR'] == true;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPR ? grit.accent.withValues(alpha: 0.15) : grit.surface,
                            border: Border.all(color: isPR ? grit.accent : grit.border, width: 1),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            '${WorkoutUtils.formatWeight(isLb ? WorkoutUtils.kgToLb(set.weightKg) : set.weightKg)}x${set.reps}',
                            style: GritTextStyles.labelMicro().copyWith(
                                color: isPR ? grit.accent : grit.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 11),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${completedSets.length}', style: GritTextStyles.dataValueSmall()),
                  Text('SETS', style: GritTextStyles.labelMicro().copyWith(fontSize: 9, color: grit.muted, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPRSection(BuildContext context, List<Map<String, dynamic>> prExercises) {
    final grit = Theme.of(context).grit;
    final profile = ref.watch(profileProvider);
    final isLb = profile.weightUnit.toLowerCase() == 'lb';
    final unit = isLb ? 'LBS' : 'KG';

    if (prExercises.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          GritSpacing.horizontalMargin,
          GritSpacing.cardGap,
          GritSpacing.horizontalMargin,
          0,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: grit.surface,
            border: Border.all(color: grit.border, width: 1),
          ),
          child: Column(
            children: [
              Icon(PhosphorIcons.target(), color: grit.muted, size: 28),
              const SizedBox(height: 12),
              Text('NO NEW RECORDS', 
                  style: GritTextStyles.labelCaps().copyWith(
                      color: grit.muted,
                      letterSpacing: 2)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: prExercises.map((ex) {
        final exercise = ex['exercise'];
        final sets = ex['sets'] as List<Map<String, dynamic>>;
        final maxWeightKg = sets
            .where((s) => s['isPR'] == true)
            .map((s) => (s['set'] as SetEntry).weightKg)
            .reduce((a, b) => a > b ? a : b);
        
        final maxWeight = isLb ? WorkoutUtils.kgToLb(maxWeightKg) : maxWeightKg;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: grit.border, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(exercise.name.toUpperCase(), 
                    style: GritTextStyles.headlineSmall().copyWith(letterSpacing: 1)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(WorkoutUtils.formatWeight(maxWeight),
                      style: GritTextStyles.dataValueLarge().copyWith(color: grit.accent)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2), // Optical baseline fix
                    child: Text(unit, style: GritTextStyles.labelMicro().copyWith(color: grit.muted)),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomCTA(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      padding: EdgeInsets.fromLTRB(
          GritSpacing.horizontalMargin, 16, GritSpacing.horizontalMargin, GritSpacing.bottomSafeArea(context) + 16),
      decoration: BoxDecoration(
        color: grit.background,
        border: Border(top: BorderSide(color: grit.border, width: 1)),
      ),
      child: GritPrimaryButton(
        label: 'FINISH SESSION',
        onPressed: () async {
          await GritHaptics.selectionTick();
          // Clear active notification upon truly finishing the session
          NotificationService().cancelWorkoutNotification().ignore();
          if (context.mounted) {
            context.go(GritRoutes.dashboard);
          }
        },
      ),
    );
  }
}
