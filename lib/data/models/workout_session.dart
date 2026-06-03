import 'session_exercise.dart';

class WorkoutSession {
  final int? id;
  final int? routineId;
  final String name;
  final String startedAt;
  final String? endedAt;
  final String notes;
  final double totalVolumeKg;
  final int workoutDurationSeconds;
  final int restDurationSeconds;
  final List<SessionExercise>? exercises;

  const WorkoutSession({
    this.id,
    this.routineId,
    required this.name,
    required this.startedAt,
    this.endedAt,
    this.notes = '',
    this.totalVolumeKg = 0.0,
    this.workoutDurationSeconds = 0,
    this.restDurationSeconds = 0,
    this.exercises,
  });

  factory WorkoutSession.fromMap(Map<String, dynamic> m) => WorkoutSession(
        id: m['id'] as int?,
        routineId: m['routine_id'] as int?,
        name: m['name'] as String,
        startedAt: m['started_at'] as String,
        endedAt: m['ended_at'] as String?,
        notes: m['notes'] as String? ?? '',
        totalVolumeKg: (m['total_volume_kg'] as num?)?.toDouble() ?? 0.0,
        workoutDurationSeconds: m['workout_duration_seconds'] as int? ?? 0,
        restDurationSeconds: m['rest_duration_seconds'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'routine_id': routineId,
        'name': name,
        'started_at': startedAt,
        'ended_at': endedAt,
        'notes': notes,
        'total_volume_kg': totalVolumeKg,
        'workout_duration_seconds': workoutDurationSeconds,
        'rest_duration_seconds': restDurationSeconds,
        if (exercises != null)
          'exercises': exercises!.map((e) => e.toMap()).toList(),
      };

  Map<String, dynamic> toDbMap() {
    final map = toMap();
    map.remove('exercises');
    return map;
  }

  WorkoutSession copyWith({
    int? id,
    int? routineId,
    String? name,
    String? startedAt,
    String? endedAt,
    String? notes,
    double? totalVolumeKg,
    int? workoutDurationSeconds,
    int? restDurationSeconds,
    List<SessionExercise>? exercises,
  }) =>
      WorkoutSession(
        id: id ?? this.id,
        routineId: routineId ?? this.routineId,
        name: name ?? this.name,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        notes: notes ?? this.notes,
        totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
        workoutDurationSeconds:
            workoutDurationSeconds ?? this.workoutDurationSeconds,
        restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
        exercises: exercises ?? this.exercises,
      );
}
