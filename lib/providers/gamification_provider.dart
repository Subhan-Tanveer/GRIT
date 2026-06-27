import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dao_providers.dart';
import '../utils/gamification.dart';

class GamificationSummary {
  final GritStats stats;
  final int totalXp;
  final GritLevelInfo levelInfo;
  final double progressToNextLevel;
  final int? xpToNextLevel;
  final int gritScore;
  final List<GritAchievement> unlocked;
  final List<GritAchievement> locked;

  const GamificationSummary({
    required this.stats,
    required this.totalXp,
    required this.levelInfo,
    required this.progressToNextLevel,
    required this.xpToNextLevel,
    required this.gritScore,
    required this.unlocked,
    required this.locked,
  });
}

final gamificationProvider = FutureProvider<GamificationSummary>((ref) async {
  final sessionsDao = ref.watch(sessionsDaoProvider);

  final trainedDays = await sessionsDao.getAllTrainedDays();
  final totalWorkouts = (await sessionsDao.getAllFinished()).length;
  final totalVolume = await sessionsDao.getTotalAllTimeVolume();
  final totalPrs = await sessionsDao.getTotalPrCount();
  final earlyBird = await sessionsDao.getEarlySessionCount(7);
  final nightOwl = await sessionsDao.getLateSessionCount(20);

  final currentStreak = GritGamification.currentStreak(trainedDays);
  final bestStreak = GritGamification.bestStreak(trainedDays);

  final stats = GritStats(
    totalWorkouts: totalWorkouts,
    totalPrs: totalPrs,
    totalVolumeKg: totalVolume,
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    earlyBirdSessions: earlyBird,
    nightOwlSessions: nightOwl,
  );

  final totalXp = GritGamification.totalXp(
    totalWorkouts: stats.totalWorkouts,
    totalPrs: stats.totalPrs,
    currentStreakDays: stats.currentStreak,
  );
  final levelInfo = GritGamification.levelForXp(totalXp);
  final gritScore = GritGamification.gritScore(
    currentStreakDays: stats.currentStreak,
    totalVolumeKg: stats.totalVolumeKg,
    totalPrs: stats.totalPrs,
  );

  final unlocked = <GritAchievement>[];
  final locked = <GritAchievement>[];
  for (final a in gritAchievements) {
    if (a.isUnlocked(stats)) {
      unlocked.add(a);
    } else {
      locked.add(a);
    }
  }
  unlocked.sort((a, b) => b.xpReward.compareTo(a.xpReward));
  locked.sort((a, b) => b.progress(stats).compareTo(a.progress(stats)));

  return GamificationSummary(
    stats: stats,
    totalXp: totalXp,
    levelInfo: levelInfo,
    progressToNextLevel: GritGamification.progressToNextLevel(totalXp),
    xpToNextLevel: GritGamification.xpRemainingToNextLevel(totalXp),
    gritScore: gritScore,
    unlocked: unlocked,
    locked: locked,
  );
});
