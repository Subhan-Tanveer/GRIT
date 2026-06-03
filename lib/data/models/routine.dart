import 'exercise.dart';

class Routine {
  final int? id;
  final String name;
  final bool isPrebuilt;
  final String createdAt;
  final List<RoutineExercise>? exercises;

  const Routine({
    this.id,
    required this.name,
    this.isPrebuilt = false,
    required this.createdAt,
    this.exercises,
  });

  factory Routine.fromMap(Map<String, dynamic> m) => Routine(
        id: m['id'] as int?,
        name: m['name'] as String,
        isPrebuilt: (m['is_prebuilt'] as int) == 1,
        createdAt: m['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'is_prebuilt': isPrebuilt ? 1 : 0,
        'created_at': createdAt,
      };

  Routine copyWith({
    int? id,
    String? name,
    bool? isPrebuilt,
    String? createdAt,
    List<RoutineExercise>? exercises,
  }) =>
      Routine(
        id: id ?? this.id,
        name: name ?? this.name,
        isPrebuilt: isPrebuilt ?? this.isPrebuilt,
        createdAt: createdAt ?? this.createdAt,
        exercises: exercises ?? this.exercises,
      );
}

class RoutineExercise {
  final int? id;
  final int routineId;
  final int exerciseId;
  final int orderIndex;
  final int defaultSets;
  final String defaultReps;
  final int restSeconds;
  final Exercise? exercise;

  const RoutineExercise({
    this.id,
    required this.routineId,
    required this.exerciseId,
    required this.orderIndex,
    this.defaultSets = 1,
    this.defaultReps = '8-12',
    this.restSeconds = 90,
    this.exercise,
  });

  factory RoutineExercise.fromMap(Map<String, dynamic> m) => RoutineExercise(
        id: m['id'] as int?,
        routineId: m['routine_id'] as int,
        exerciseId: m['exercise_id'] as int,
        orderIndex: m['order_index'] as int,
        defaultSets: m['default_sets'] as int,
        defaultReps: m['default_reps'] as String,
        restSeconds: m['rest_seconds'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'routine_id': routineId,
        'exercise_id': exerciseId,
        'order_index': orderIndex,
        'default_sets': defaultSets,
        'default_reps': defaultReps,
        'rest_seconds': restSeconds,
      };

  RoutineExercise copyWith({
    int? id,
    int? routineId,
    int? exerciseId,
    int? orderIndex,
    int? defaultSets,
    String? defaultReps,
    int? restSeconds,
    Exercise? exercise,
  }) =>
      RoutineExercise(
        id: id ?? this.id,
        routineId: routineId ?? this.routineId,
        exerciseId: exerciseId ?? this.exerciseId,
        orderIndex: orderIndex ?? this.orderIndex,
        defaultSets: defaultSets ?? this.defaultSets,
        defaultReps: defaultReps ?? this.defaultReps,
        restSeconds: restSeconds ?? this.restSeconds,
        exercise: exercise ?? this.exercise,
      );
}
