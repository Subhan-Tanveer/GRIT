// Bodyweight-ratio strength standards for the big compound lifts. These are
// commonly-cited approximate benchmarks (1RM as a multiple of bodyweight),
// not a scientifically precise dataset — good enough for "where do I stand"
// context, not a medical or competitive ranking.

enum StrengthLevel { beginner, novice, intermediate, advanced, elite }

extension StrengthLevelX on StrengthLevel {
  String get label => switch (this) {
        StrengthLevel.beginner => 'BEGINNER',
        StrengthLevel.novice => 'NOVICE',
        StrengthLevel.intermediate => 'INTERMEDIATE',
        StrengthLevel.advanced => 'ADVANCED',
        StrengthLevel.elite => 'ELITE',
      };
}

enum StandardLift { benchPress, squat, deadlift, overheadPress }

extension StandardLiftX on StandardLift {
  String get label => switch (this) {
        StandardLift.benchPress => 'BENCH PRESS',
        StandardLift.squat => 'SQUAT',
        StandardLift.deadlift => 'DEADLIFT',
        StandardLift.overheadPress => 'OVERHEAD PRESS',
      };

  /// SQL LIKE pattern used to find a matching logged exercise by name.
  String get namePattern => switch (this) {
        StandardLift.benchPress => '%bench press%',
        StandardLift.squat => '%squat%',
        StandardLift.deadlift => '%deadlift%',
        StandardLift.overheadPress => '%overhead press%',
      };
}

class StrengthStandards {
  StrengthStandards._();

  // bodyweight multipliers, [beginner, novice, intermediate, advanced, elite]
  static const Map<StandardLift, List<double>> _male = {
    StandardLift.benchPress: [0.5, 0.75, 1.0, 1.5, 2.0],
    StandardLift.squat: [0.75, 1.0, 1.5, 2.0, 2.5],
    StandardLift.deadlift: [1.0, 1.25, 1.75, 2.25, 2.75],
    StandardLift.overheadPress: [0.35, 0.5, 0.7, 1.0, 1.3],
  };

  static const Map<StandardLift, List<double>> _female = {
    StandardLift.benchPress: [0.3, 0.45, 0.65, 0.95, 1.3],
    StandardLift.squat: [0.5, 0.75, 1.0, 1.5, 1.9],
    StandardLift.deadlift: [0.65, 0.9, 1.25, 1.75, 2.25],
    StandardLift.overheadPress: [0.2, 0.3, 0.45, 0.65, 0.85],
  };

  static List<double> multipliersFor(StandardLift lift, bool isMale) =>
      (isMale ? _male : _female)[lift]!;

  static StrengthLevel levelFor(double oneRepMaxKg, double bodyweightKg, StandardLift lift, bool isMale) {
    if (bodyweightKg <= 0) return StrengthLevel.beginner;
    final ratio = oneRepMaxKg / bodyweightKg;
    final thresholds = multipliersFor(lift, isMale);

    if (ratio >= thresholds[4]) return StrengthLevel.elite;
    if (ratio >= thresholds[3]) return StrengthLevel.advanced;
    if (ratio >= thresholds[2]) return StrengthLevel.intermediate;
    if (ratio >= thresholds[1]) return StrengthLevel.novice;
    if (ratio >= thresholds[0]) return StrengthLevel.beginner;
    return StrengthLevel.beginner;
  }

  /// Progress (0.0-1.0) from the current level's threshold to the next level's.
  static double progressToNextLevel(double oneRepMaxKg, double bodyweightKg, StandardLift lift, bool isMale) {
    if (bodyweightKg <= 0) return 0;
    final ratio = oneRepMaxKg / bodyweightKg;
    final thresholds = multipliersFor(lift, isMale);

    for (int i = 0; i < thresholds.length; i++) {
      if (ratio < thresholds[i]) {
        final lowerBound = i == 0 ? 0.0 : thresholds[i - 1];
        final span = thresholds[i] - lowerBound;
        if (span <= 0) return 1.0;
        return ((ratio - lowerBound) / span).clamp(0.0, 1.0);
      }
    }
    return 1.0; // at or above elite
  }
}
