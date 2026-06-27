// GRIT gamification rules: XP, levels (Rookie -> Legend), streaks, achievements.
// Everything here is derived live from existing workout data — no extra
// persistence is required, so unlock state always matches the real database.

enum GritLevel { rookie, iron, steel, titan, legend }

class GritLevelInfo {
  final GritLevel level;
  final String name;
  final int minXp;
  final int? maxXp; // null = no ceiling (Legend)

  const GritLevelInfo(this.level, this.name, this.minXp, this.maxXp);
}

class GritGamification {
  GritGamification._();

  static const int xpPerWorkout = 100;
  static const int xpPerPr = 50;
  static const int xpStreakBonus = 200; // awarded once per 7-day streak block

  static const List<GritLevelInfo> levels = [
    GritLevelInfo(GritLevel.rookie, 'ROOKIE', 0, 999),
    GritLevelInfo(GritLevel.iron, 'IRON', 1000, 2499),
    GritLevelInfo(GritLevel.steel, 'STEEL', 2500, 4999),
    GritLevelInfo(GritLevel.titan, 'TITAN', 5000, 9999),
    GritLevelInfo(GritLevel.legend, 'LEGEND', 10000, null),
  ];

  /// Total XP earned from workouts, PRs, and completed streak-weeks.
  static int totalXp({
    required int totalWorkouts,
    required int totalPrs,
    required int currentStreakDays,
  }) {
    final streakBonuses = currentStreakDays ~/ 7;
    return (totalWorkouts * xpPerWorkout) +
        (totalPrs * xpPerPr) +
        (streakBonuses * xpStreakBonus);
  }

  static GritLevelInfo levelForXp(int xp) {
    for (final l in levels.reversed) {
      if (xp >= l.minXp) return l;
    }
    return levels.first;
  }

  /// Progress (0.0-1.0) toward the next level. 1.0 if at max level.
  static double progressToNextLevel(int xp) {
    final current = levelForXp(xp);
    if (current.maxXp == null) return 1.0;
    final span = current.maxXp! + 1 - current.minXp;
    final into = xp - current.minXp;
    return (into / span).clamp(0.0, 1.0);
  }

  static int xpIntoLevel(int xp) => xp - levelForXp(xp).minXp;

  static int? xpRemainingToNextLevel(int xp) {
    final current = levelForXp(xp);
    if (current.maxXp == null) return null;
    return (current.maxXp! + 1) - xp;
  }

  /// GRIT Score: 0-1000 composite of consistency, volume, and PRs.
  static int gritScore({
    required int currentStreakDays,
    required double totalVolumeKg,
    required int totalPrs,
  }) {
    final consistencyScore = (currentStreakDays * 12).clamp(0, 400);
    final volumeScore = (totalVolumeKg / 250).clamp(0, 400).round();
    final prScore = (totalPrs * 8).clamp(0, 200);
    return (consistencyScore + volumeScore + prScore).clamp(0, 1000).round();
  }

  /// Computes the current consecutive-day streak from a sorted (ascending)
  /// list of distinct trained calendar days.
  static int currentStreak(List<DateTime> trainedDaysAsc) {
    if (trainedDaysAsc.isEmpty) return 0;
    final days = trainedDaysAsc
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastTrained = days.last;
    final gapFromToday = todayDate.difference(lastTrained).inDays;

    // Streak is broken if last workout wasn't today or yesterday.
    if (gapFromToday > 1) return 0;

    int streak = 1;
    for (int i = days.length - 1; i > 0; i--) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static int bestStreak(List<DateTime> trainedDaysAsc) {
    if (trainedDaysAsc.isEmpty) return 0;
    final days = trainedDaysAsc
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();

    int best = 1;
    int running = 1;
    for (int i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        running++;
        best = running > best ? running : best;
      } else {
        running = 1;
      }
    }
    return best;
  }
}

class GritStats {
  final int totalWorkouts;
  final int totalPrs;
  final double totalVolumeKg;
  final int currentStreak;
  final int bestStreak;
  final int earlyBirdSessions; // before 7am
  final int nightOwlSessions; // after 8pm

  const GritStats({
    required this.totalWorkouts,
    required this.totalPrs,
    required this.totalVolumeKg,
    required this.currentStreak,
    required this.bestStreak,
    required this.earlyBirdSessions,
    required this.nightOwlSessions,
  });
}

class GritAchievement {
  final String id;
  final String name;
  final String description;
  final String category; // Consistency / Strength / Volume / Milestones
  final int xpReward;
  final bool Function(GritStats stats) isUnlocked;
  final double Function(GritStats stats) progress; // 0.0-1.0

  const GritAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.xpReward,
    required this.isUnlocked,
    required this.progress,
  });
}

double _ratio(num value, num target) => target <= 0 ? 1.0 : (value / target).clamp(0.0, 1.0).toDouble();

final List<GritAchievement> gritAchievements = [
  GritAchievement(
    id: 'first_blood',
    name: 'FIRST BLOOD',
    description: 'Complete your first workout',
    category: 'Milestones',
    xpReward: 25,
    isUnlocked: (s) => s.totalWorkouts >= 1,
    progress: (s) => _ratio(s.totalWorkouts, 1),
  ),
  GritAchievement(
    id: 'iron_will',
    name: 'IRON WILL',
    description: 'Hit a 7-day streak',
    category: 'Consistency',
    xpReward: 50,
    isUnlocked: (s) => s.bestStreak >= 7,
    progress: (s) => _ratio(s.bestStreak, 7),
  ),
  GritAchievement(
    id: 'the_grinder',
    name: 'THE GRINDER',
    description: 'Hit a 30-day streak',
    category: 'Consistency',
    xpReward: 150,
    isUnlocked: (s) => s.bestStreak >= 30,
    progress: (s) => _ratio(s.bestStreak, 30),
  ),
  GritAchievement(
    id: 'unbreakable',
    name: 'UNBREAKABLE',
    description: 'Hit a 60-day streak',
    category: 'Consistency',
    xpReward: 300,
    isUnlocked: (s) => s.bestStreak >= 60,
    progress: (s) => _ratio(s.bestStreak, 60),
  ),
  GritAchievement(
    id: 'centurion',
    name: 'CENTURION',
    description: 'Hit a 100-day streak',
    category: 'Consistency',
    xpReward: 500,
    isUnlocked: (s) => s.bestStreak >= 100,
    progress: (s) => _ratio(s.bestStreak, 100),
  ),
  GritAchievement(
    id: 'getting_started',
    name: 'GETTING STARTED',
    description: 'Complete 10 workouts',
    category: 'Milestones',
    xpReward: 50,
    isUnlocked: (s) => s.totalWorkouts >= 10,
    progress: (s) => _ratio(s.totalWorkouts, 10),
  ),
  GritAchievement(
    id: 'dedicated',
    name: 'DEDICATED',
    description: 'Complete 50 workouts',
    category: 'Milestones',
    xpReward: 150,
    isUnlocked: (s) => s.totalWorkouts >= 50,
    progress: (s) => _ratio(s.totalWorkouts, 50),
  ),
  GritAchievement(
    id: 'centurion_workouts',
    name: 'WAR MACHINE',
    description: 'Complete 100 workouts',
    category: 'Milestones',
    xpReward: 300,
    isUnlocked: (s) => s.totalWorkouts >= 100,
    progress: (s) => _ratio(s.totalWorkouts, 100),
  ),
  GritAchievement(
    id: 'veteran',
    name: 'VETERAN',
    description: 'Complete 250 workouts',
    category: 'Milestones',
    xpReward: 500,
    isUnlocked: (s) => s.totalWorkouts >= 250,
    progress: (s) => _ratio(s.totalWorkouts, 250),
  ),
  GritAchievement(
    id: 'first_pr',
    name: 'BREAKTHROUGH',
    description: 'Hit your first personal record',
    category: 'Strength',
    xpReward: 25,
    isUnlocked: (s) => s.totalPrs >= 1,
    progress: (s) => _ratio(s.totalPrs, 1),
  ),
  GritAchievement(
    id: 'pr_machine',
    name: 'PR MACHINE',
    description: 'Hit 50 personal records',
    category: 'Strength',
    xpReward: 200,
    isUnlocked: (s) => s.totalPrs >= 50,
    progress: (s) => _ratio(s.totalPrs, 50),
  ),
  GritAchievement(
    id: 'record_breaker',
    name: 'RECORD BREAKER',
    description: 'Hit 100 personal records',
    category: 'Strength',
    xpReward: 400,
    isUnlocked: (s) => s.totalPrs >= 100,
    progress: (s) => _ratio(s.totalPrs, 100),
  ),
  GritAchievement(
    id: 'ten_tonne',
    name: 'TEN TONNE CLUB',
    description: 'Lift 10,000 kg total volume',
    category: 'Volume',
    xpReward: 75,
    isUnlocked: (s) => s.totalVolumeKg >= 10000,
    progress: (s) => _ratio(s.totalVolumeKg, 10000),
  ),
  GritAchievement(
    id: 'volume_king',
    name: 'VOLUME KING',
    description: 'Lift 100,000 kg total volume',
    category: 'Volume',
    xpReward: 250,
    isUnlocked: (s) => s.totalVolumeKg >= 100000,
    progress: (s) => _ratio(s.totalVolumeKg, 100000),
  ),
  GritAchievement(
    id: 'half_million',
    name: 'HALF-MILLION HAULER',
    description: 'Lift 500,000 kg total volume',
    category: 'Volume',
    xpReward: 500,
    isUnlocked: (s) => s.totalVolumeKg >= 500000,
    progress: (s) => _ratio(s.totalVolumeKg, 500000),
  ),
  GritAchievement(
    id: 'one_million',
    name: 'ONE MILLION KG',
    description: 'Lift 1,000,000 kg total volume',
    category: 'Volume',
    xpReward: 1000,
    isUnlocked: (s) => s.totalVolumeKg >= 1000000,
    progress: (s) => _ratio(s.totalVolumeKg, 1000000),
  ),
  GritAchievement(
    id: 'early_bird',
    name: 'EARLY BIRD',
    description: 'Complete 10 workouts before 7am',
    category: 'Consistency',
    xpReward: 75,
    isUnlocked: (s) => s.earlyBirdSessions >= 10,
    progress: (s) => _ratio(s.earlyBirdSessions, 10),
  ),
  GritAchievement(
    id: 'night_owl',
    name: 'NIGHT OWL',
    description: 'Complete 10 workouts after 8pm',
    category: 'Consistency',
    xpReward: 75,
    isUnlocked: (s) => s.nightOwlSessions >= 10,
    progress: (s) => _ratio(s.nightOwlSessions, 10),
  ),
  GritAchievement(
    id: 'legendary',
    name: 'LEGENDARY',
    description: 'Reach Legend rank',
    category: 'Milestones',
    xpReward: 1000,
    isUnlocked: (s) =>
        GritGamification.levelForXp(GritGamification.totalXp(
                totalWorkouts: s.totalWorkouts,
                totalPrs: s.totalPrs,
                currentStreakDays: s.currentStreak))
            .level ==
        GritLevel.legend,
    progress: (s) => _ratio(
        GritGamification.totalXp(
            totalWorkouts: s.totalWorkouts,
            totalPrs: s.totalPrs,
            currentStreakDays: s.currentStreak),
        10000),
  ),
  GritAchievement(
    id: 'titan_rank',
    name: 'TITAN RISING',
    description: 'Reach Titan rank',
    category: 'Milestones',
    xpReward: 300,
    isUnlocked: (s) =>
        GritGamification.totalXp(
            totalWorkouts: s.totalWorkouts,
            totalPrs: s.totalPrs,
            currentStreakDays: s.currentStreak) >=
        5000,
    progress: (s) => _ratio(
        GritGamification.totalXp(
            totalWorkouts: s.totalWorkouts,
            totalPrs: s.totalPrs,
            currentStreakDays: s.currentStreak),
        5000),
  ),
];
