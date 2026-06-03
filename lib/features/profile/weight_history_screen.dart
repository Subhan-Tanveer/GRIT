import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/routes.dart';
import '../../core/theme/grit_theme.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/dao_providers.dart';
import '../../providers/profile_provider.dart';
import '../../data/models/body_weight_entry.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../core/utils/workout_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../shared/widgets/grit_error_state.dart';
import '../../shared/widgets/grit_empty_state.dart';

class WeightHistoryScreen extends ConsumerWidget {
  const WeightHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final weightHistoryAsync = ref.watch(bodyWeightProvider);

    return Scaffold(
      backgroundColor: grit.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHistoryHeader(context),
            Expanded(
              child: weightHistoryAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return GritEmptyState(
                      icon: PhosphorIcons.scales(PhosphorIconsStyle.bold),
                      title: 'NO WEIGHT LOGS FOUND',
                      description: 'Start logging your weight to visualize trends and calculate relative strength metrics.',
                    );
                  }

                  final sorted = List<BodyWeightEntry>.from(entries)
                    ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Text('LOG HISTORY',
                            style: GritTextStyles.metric(13,
                                color: grit.accent,
                                letterSpacing: 2)),
                      ).animate().fadeIn(delay: 200.ms),
                      ...sorted.asMap().entries.map((entry) {
                        final index = entry.key;
                        final e = entry.value;
                        return _buildWeightRow(context, ref, e)
                            .animate()
                            .fadeIn(delay: (300 + index.clamp(0, 12) * 30).ms, duration: 400.ms)
                            .slideX(begin: 0.05, curve: Curves.easeOutBack);
                      }),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: GritSkeleton(height: 200),
                ),
                error: (err, _) => GritErrorState(
                  error: err,
                  onRetry: () => ref.invalidate(bodyWeightProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryHeader(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: grit.background,
        border: Border(bottom: BorderSide(color: grit.border, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(PhosphorIcons.arrowLeft(),
                color: grit.textPrimary, size: 28),
            onPressed: () => context.canPop() ? context.pop() : context.go(GritRoutes.profile),
          ),
          const SizedBox(width: 12),
          Text(
            'WEIGHT HISTORY',
            style: GritTextStyles.metric(24,
                weight: FontWeight.w900, height: 1, color: grit.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightRow(
      BuildContext context, WidgetRef ref, BodyWeightEntry e) {
    final grit = Theme.of(context).grit;
    final profile = ref.watch(profileProvider);
    final unit = profile.weightUnit;
    double displayWeight = e.weightKg;
    if (unit == 'LBS') {
      displayWeight = displayWeight * 2.20462;
    }

    return Dismissible(
      key: Key('weight_history_${e.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: grit.accent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(PhosphorIcons.trash(), color: Colors.white),
      ),
      onDismissed: (_) async {
        if (e.id != null) {
          final dao = ref.read(bodyWeightDaoProvider);
          await dao.delete(e.id!);
          ref.invalidate(bodyWeightProvider);
          ref.invalidate(dashboardDataProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('LOG DELETED',
                    style: GritTextStyles.label(12,
                        color: Colors.white, weight: FontWeight.w900)),
                backgroundColor: grit.accent,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'RESTORE',
                  textColor: Colors.white,
                  onPressed: () async {
                    await dao.insert(e);
                    ref.invalidate(bodyWeightProvider);
                    ref.invalidate(dashboardDataProvider);
                  },
                ),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: grit.border, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('MMM d, y').format(DateTime.parse(e.loggedAt)).toUpperCase(),
                    style: GritTextStyles.label(13, weight: FontWeight.w700).copyWith(color: grit.textSecondary)),
                const SizedBox(height: 1),
                Text(DateFormat('HH:mm').format(DateTime.parse(e.loggedAt)),
                    style: GritTextStyles.mono(11, color: grit.muted)),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(WorkoutUtils.formatWeight(displayWeight),
                    style: GritTextStyles.metric(24, weight: FontWeight.w900, color: grit.textPrimary)),
                const SizedBox(width: 4),
                Text(unit,
                    style: GritTextStyles.metric(12, color: grit.textSecondary, weight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
