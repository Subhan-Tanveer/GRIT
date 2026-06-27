import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../providers/gamification_provider.dart';
import '../../../shared/widgets/gamification_widgets.dart';
import '../../../shared/widgets/grit_error_state.dart';
import '../../../shared/widgets/grit_skeleton.dart';
import '../../../utils/gamification.dart';

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final summaryAsync = ref.watch(gamificationProvider);

    return Scaffold(
      backgroundColor: grit.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: GritSpacing.horizontalMargin, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: grit.border, width: 1)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: grit.textPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Text(
                  'GRIT RANK',
                  style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: GritSkeleton(height: 200, width: 200)),
        error: (e, st) => GritErrorState(error: e, onRetry: () => ref.refresh(gamificationProvider)),
        data: (summary) => _buildBody(context, summary),
      ),
    );
  }

  Widget _buildBody(BuildContext context, GamificationSummary summary) {
    final grit = Theme.of(context).grit;
    final stats = summary.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: GritSpacing.horizontalMargin, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                GritScoreRing(score: summary.gritScore),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LevelBadge(levelInfo: summary.levelInfo, size: 44),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.levelInfo.name,
                          style: GritTextStyles.headlineSmall().copyWith(
                            color: levelColor(summary.levelInfo.level, grit),
                          ),
                        ),
                        Text(
                          '${summary.totalXp} XP TOTAL',
                          style: GritTextStyles.label(11, color: grit.textSecondary, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          XpProgressBar(
            progress: summary.progressToNextLevel,
            label: summary.xpToNextLevel != null
                ? '${summary.xpToNextLevel} XP TO NEXT RANK'
                : 'MAX RANK REACHED',
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: StreakFlame(streakDays: stats.currentStreak)),
              Text(
                'BEST ${stats.bestStreak}D',
                style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _statsStrip(context, stats),
          const SizedBox(height: 32),
          Text(
            'ACHIEVEMENTS (${summary.unlocked.length}/${summary.unlocked.length + summary.locked.length})',
            style: GritTextStyles.sectionHeader().copyWith(color: grit.textSecondary),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemCount: summary.unlocked.length + summary.locked.length,
            itemBuilder: (context, index) {
              final isUnlocked = index < summary.unlocked.length;
              final a = isUnlocked
                  ? summary.unlocked[index]
                  : summary.locked[index - summary.unlocked.length];
              return AchievementTile(
                achievement: a,
                unlocked: isUnlocked,
                progress: isUnlocked ? 1.0 : a.progress(stats),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statsStrip(BuildContext context, GritStats stats) {
    final grit = Theme.of(context).grit;
    Widget tile(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GritTextStyles.dataValueLarge().copyWith(color: grit.textPrimary)),
              const SizedBox(height: 2),
              Text(label,
                  style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 1)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: grit.border), bottom: BorderSide(color: grit.border)),
      ),
      child: Row(
        children: [
          tile('WORKOUTS', '${stats.totalWorkouts}'),
          tile('PRS', '${stats.totalPrs}'),
          tile('VOLUME', '${(stats.totalVolumeKg / 1000).toStringAsFixed(1)}T'),
        ],
      ),
    );
  }
}
