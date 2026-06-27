enum ChallengeGoalType { workoutCount, volumeKg }

extension ChallengeGoalTypeX on ChallengeGoalType {
  String get dbValue => switch (this) {
        ChallengeGoalType.workoutCount => 'workout_count',
        ChallengeGoalType.volumeKg => 'volume_kg',
      };

  String get label => switch (this) {
        ChallengeGoalType.workoutCount => 'WORKOUTS',
        ChallengeGoalType.volumeKg => 'KG LIFTED',
      };

  static ChallengeGoalType fromDb(String value) =>
      value == 'volume_kg' ? ChallengeGoalType.volumeKg : ChallengeGoalType.workoutCount;
}

class ChallengeParticipant {
  final int userId;
  final String displayName;
  final double progress;
  final bool completed;

  const ChallengeParticipant({
    required this.userId,
    required this.displayName,
    required this.progress,
    required this.completed,
  });

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) => ChallengeParticipant(
        userId: json['userId'] as int,
        displayName: json['displayName'] as String,
        progress: (json['progress'] as num).toDouble(),
        completed: json['completed'] as bool,
      );
}

class Challenge {
  final int id;
  final String title;
  final ChallengeGoalType goalType;
  final double goalTarget;
  final DateTime startDate;
  final DateTime endDate;
  final int creatorId;
  final bool isJoined;
  final double myProgress;
  final bool myCompleted;
  final List<ChallengeParticipant> participants;

  const Challenge({
    required this.id,
    required this.title,
    required this.goalType,
    required this.goalTarget,
    required this.startDate,
    required this.endDate,
    required this.creatorId,
    required this.isJoined,
    required this.myProgress,
    required this.myCompleted,
    required this.participants,
  });

  bool get isActive => DateTime.now().isBefore(endDate);
  double get myProgressRatio => goalTarget <= 0 ? 0 : (myProgress / goalTarget).clamp(0.0, 1.0);

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
        id: json['id'] as int,
        title: json['title'] as String,
        goalType: ChallengeGoalTypeX.fromDb(json['goalType'] as String),
        goalTarget: (json['goalTarget'] as num).toDouble(),
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        creatorId: (json['creator'] as Map<String, dynamic>)['id'] as int,
        isJoined: json['isJoined'] as bool,
        myProgress: (json['myProgress'] as num).toDouble(),
        myCompleted: json['myCompleted'] as bool,
        participants: (json['participants'] as List)
            .map((p) => ChallengeParticipant.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
