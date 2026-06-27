import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/grit_theme.dart';
import '../../data/models/social_models.dart';
import '../../providers/social_provider.dart';
import '../../services/grit_api_service.dart';
import '../../shared/widgets/grit_skeleton.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final leaderboardAsync = ref.watch(leaderboardProvider);

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
                Text('LEADERBOARD', style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary)),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(leaderboardProvider),
        child: leaderboardAsync.when(
          loading: () => const Center(child: GritSkeleton(height: 100, width: double.infinity)),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                e is ApiException ? e.message : 'Could not reach the server',
                style: GritTextStyles.label(13, color: grit.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (entries) {
            if (entries.length <= 1) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Add friends to start a leaderboard — right now it\'s just you.',
                    style: GritTextStyles.label(13, color: grit.muted),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 16),
              itemCount: entries.length,
              itemBuilder: (context, index) => _entryRow(context, entries[index], index),
            );
          },
        ),
      ),
    );
  }

  Widget _entryRow(BuildContext context, LeaderboardEntry entry, int index) {
    final grit = Theme.of(context).grit;
    final medalColor = switch (entry.rank) {
      1 => const Color(0xFFFFD60A),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => grit.textSecondary,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: entry.isMe ? grit.accent.withValues(alpha: 0.08) : grit.surface,
        border: Border.all(color: entry.isMe ? grit.accent : grit.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: GritTextStyles.label(14, weight: FontWeight.w800, color: medalColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isMe ? '${entry.displayName} (You)' : entry.displayName,
                  style: GritTextStyles.tileTitle().copyWith(color: grit.textPrimary),
                ),
                Text(
                  '${entry.streak}D STREAK · ${entry.totalWorkouts} WORKOUTS',
                  style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          Text(
            '${entry.gritScore}',
            style: GritTextStyles.displayMedium().copyWith(color: grit.textPrimary, fontSize: 22),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.05);
  }
}
