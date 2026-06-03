import 'exercise.dart';
import 'set_entry.dart';

class SessionExercise {
  final int? id;
  final int sessionId;
  final int exerciseId;
  final int orderIndex;
  final int targetSets;
  final String targetReps;
  final int targetRest;
  final Exercise? exercise;
  final List<SetEntry> sets;

  const SessionExercise({
    this.id,
    required this.sessionId,
    required this.exerciseId,
    this.orderIndex = 0,
    this.targetSets = 1,
    this.targetReps = '8-12',
    this.targetRest = 90,
    this.exercise,
    this.sets = const [],
  });

  factory SessionExercise.fromMap(Map<String, dynamic> m) => SessionExercise(
        id: m['id'] as int?,
        sessionId: m['session_id'] as int,
        exerciseId: m['exercise_id'] as int,
        orderIndex: m['order_index'] as int? ?? 0,
        targetSets: m['target_sets'] as int? ?? 1,
        targetReps: m['target_reps'] as String? ?? '8-12',
        targetRest: m['target_rest'] as int? ?? 90,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'order_index': orderIndex,
        'target_sets': targetSets,
        'target_reps': targetReps,
        'target_rest': targetRest,
      };

  SessionExercise copyWith({
    int? id,
    int? sessionId,
    int? exerciseId,
    int? orderIndex,
    int? targetSets,
    String? targetReps,
    int? targetRest,
    Exercise? exercise,
    List<SetEntry>? sets,
  }) =>
      SessionExercise(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        exerciseId: exerciseId ?? this.exerciseId,
        orderIndex: orderIndex ?? this.orderIndex,
        targetSets: targetSets ?? this.targetSets,
        targetReps: targetReps ?? this.targetReps,
        targetRest: targetRest ?? this.targetRest,
        exercise: exercise ?? this.exercise,
        sets: sets ?? this.sets,
      );
}
