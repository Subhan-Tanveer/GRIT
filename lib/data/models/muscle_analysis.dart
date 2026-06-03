class MuscleGroupSummary {
  final String name;
  final int exerciseCount;
  final int workoutCount;
  final double totalVolume;
  final double score;
  final String rank;

  // All-time stats
  final int totalSessions;
  final int totalSets;
  final DateTime? lastTrainedDate;

  const MuscleGroupSummary({
    required this.name,
    required this.exerciseCount,
    required this.workoutCount,
    this.totalVolume = 0.0,
    this.score = 0.0,
    this.rank = '',
    this.totalSessions = 0,
    this.totalSets = 0,
    this.lastTrainedDate,
  });

  MuscleGroupSummary copyWith({
    double? totalVolume,
    double? score,
    String? rank,
    int? totalSessions,
    int? totalSets,
    DateTime? lastTrainedDate,
  }) {
    return MuscleGroupSummary(
      name: name,
      exerciseCount: exerciseCount,
      workoutCount: workoutCount,
      totalVolume: totalVolume ?? this.totalVolume,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      totalSessions: totalSessions ?? this.totalSessions,
      totalSets: totalSets ?? this.totalSets,
      lastTrainedDate: lastTrainedDate ?? this.lastTrainedDate,
    );
  }
}

class ExerciseProgress {
  final int id;
  final String name;
  final double personalRecord;
  final double progressDelta; // Weight change in last 30 days
  final ProgressDirection direction;

  const ExerciseProgress({
    required this.id,
    required this.name,
    required this.personalRecord,
    required this.progressDelta,
    required this.direction,
  });
}

enum ProgressDirection { up, down, same }

class ExerciseHistoryPoint {
  final DateTime date;
  final double topWeight;
  final int reps;
  final double volume;
  final double estimated1RM;

  const ExerciseHistoryPoint({
    required this.date,
    required this.topWeight,
    required this.reps,
    this.volume = 0.0,
    this.estimated1RM = 0.0,
  });
}

class MuscleExerciseStat {
  final int exerciseId;
  final String name;
  final double bestWeight;
  final double bestE1RM;
  final int totalSets;
  final double totalVolume;

  const MuscleExerciseStat({
    required this.exerciseId,
    required this.name,
    required this.bestWeight,
    required this.bestE1RM,
    required this.totalSets,
    required this.totalVolume,
  });
}

class MuscleAnalysisData {
  final String muscleGroup;
  final int totalSessions;
  final double totalVolume;
  final double avgIntensity;
  final double lifetimeAvgIntensity; 
  final double sessionTrend; 
  final double peakE1RM;
  final List<Map<String, dynamic>> dailyHistory; // {day: String, volume: double, intensity: double, e1rm: double}
  final List<MuscleExerciseStat> exerciseStats;

  const MuscleAnalysisData({
    required this.muscleGroup,
    required this.totalSessions,
    required this.totalVolume,
    required this.avgIntensity,
    required this.lifetimeAvgIntensity,
    required this.sessionTrend,
    required this.peakE1RM,
    required this.dailyHistory,
    required this.exerciseStats,
  });
}
