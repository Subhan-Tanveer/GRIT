import 'package:sqflite/sqflite.dart';
import '../models/routine.dart';
import '../models/exercise.dart';

class RoutinesDao {
  final Database _db;

  RoutinesDao(this._db);

  Future<int> insert(Routine r) async {
    return _db.insert('routines', r.toMap());
  }

  Future<void> update(Routine r) async {
    await _db.update(
      'routines',
      r.toMap(),
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  Future<void> delete(int id) async {
    await _db.delete('routines', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Routine>> getAll() async {
    final routineRows = await _db.query(
      'routines',
      orderBy: 'is_prebuilt ASC, created_at DESC',
    );
    if (routineRows.isEmpty) return [];

    final routineIds = routineRows.map((r) => r['id'] as int).toList();
    final placeholders = List.filled(routineIds.length, '?').join(',');

    final exRows = await _db.rawQuery('''
      SELECT re.*, e.name as ex_name, e.muscle_group as ex_muscle_group, 
             e.secondary_muscles as ex_secondary_muscles, e.equipment as ex_equipment,
             e.type as ex_type, e.instructions as ex_instructions, e.created_at as ex_created_at
      FROM routine_exercises re
      JOIN exercises e ON re.exercise_id = e.id
      WHERE re.routine_id IN ($placeholders)
      ORDER BY re.routine_id, re.order_index ASC
    ''', routineIds);

    final exerciseMap = <int, List<RoutineExercise>>{};
    for (final r in exRows) {
      final rid = r['routine_id'] as int;
      final re = RoutineExercise.fromMap(r);
      final exercise = RoutineExercise(
        id: re.id,
        routineId: re.routineId,
        exerciseId: re.exerciseId,
        orderIndex: re.orderIndex,
        defaultSets: re.defaultSets,
        defaultReps: re.defaultReps,
        restSeconds: re.restSeconds,
        exercise: Exercise(
          id: re.exerciseId,
          name: r['ex_name'] as String,
          muscleGroup: r['ex_muscle_group'] as String,
          secondaryMuscles: r['ex_secondary_muscles'] as String? ?? '',
          equipment: r['ex_equipment'] as String,
          type: r['ex_type'] as String,
          instructions: r['ex_instructions'] as String? ?? '',
          createdAt: r['ex_created_at'] as String,
        ),
      );
      exerciseMap.putIfAbsent(rid, () => []).add(exercise);
    }

    return routineRows.map((r) {
      final routine = Routine.fromMap(r);
      return routine.copyWith(exercises: exerciseMap[routine.id] ?? []);
    }).toList();
  }

  Future<List<Routine>> getCustomOnly() async {
    final routineRows = await _db.query(
      'routines',
      where: 'is_prebuilt = 0',
      orderBy: 'created_at DESC',
    );
    if (routineRows.isEmpty) return [];

    final routineIds = routineRows.map((r) => r['id'] as int).toList();
    final placeholders = List.filled(routineIds.length, '?').join(',');

    final exRows = await _db.rawQuery('''
      SELECT re.*, e.name as ex_name, e.muscle_group as ex_muscle_group, 
             e.secondary_muscles as ex_secondary_muscles, e.equipment as ex_equipment,
             e.type as ex_type, e.instructions as ex_instructions, e.created_at as ex_created_at
      FROM routine_exercises re
      JOIN exercises e ON re.exercise_id = e.id
      WHERE re.routine_id IN ($placeholders)
      ORDER BY re.routine_id, re.order_index ASC
    ''', routineIds);

    final exerciseMap = <int, List<RoutineExercise>>{};
    for (final r in exRows) {
      final rid = r['routine_id'] as int;
      final re = RoutineExercise.fromMap(r);
      final exercise = RoutineExercise(
        id: re.id,
        routineId: re.routineId,
        exerciseId: re.exerciseId,
        orderIndex: re.orderIndex,
        defaultSets: re.defaultSets,
        defaultReps: re.defaultReps,
        restSeconds: re.restSeconds,
        exercise: Exercise(
          id: re.exerciseId,
          name: r['ex_name'] as String,
          muscleGroup: r['ex_muscle_group'] as String,
          secondaryMuscles: r['ex_secondary_muscles'] as String? ?? '',
          equipment: r['ex_equipment'] as String,
          type: r['ex_type'] as String,
          instructions: r['ex_instructions'] as String? ?? '',
          createdAt: r['ex_created_at'] as String,
        ),
      );
      exerciseMap.putIfAbsent(rid, () => []).add(exercise);
    }

    return routineRows.map((r) {
      final routine = Routine.fromMap(r);
      return routine.copyWith(exercises: exerciseMap[routine.id] ?? []);
    }).toList();
  }

  Future<Routine?> getById(int id) async {
    final rows = await _db.query('routines', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final routine = Routine.fromMap(rows.first);
    final exercises = await getExercises(id);
    return routine.copyWith(exercises: exercises);
  }

  Future<List<RoutineExercise>> getExercises(int routineId) async {
    final rows = await _db.rawQuery('''
      SELECT re.*, e.name as ex_name, e.muscle_group as ex_muscle_group, 
             e.secondary_muscles as ex_secondary_muscles, e.equipment as ex_equipment,
             e.type as ex_type, e.instructions as ex_instructions, e.created_at as ex_created_at
      FROM routine_exercises re
      JOIN exercises e ON re.exercise_id = e.id
      WHERE re.routine_id = ?
      ORDER BY re.order_index ASC
    ''', [routineId]);

    return rows.map((r) {
      final re = RoutineExercise.fromMap(r);
      return RoutineExercise(
        id: re.id,
        routineId: re.routineId,
        exerciseId: re.exerciseId,
        orderIndex: re.orderIndex,
        defaultSets: re.defaultSets,
        defaultReps: re.defaultReps,
        restSeconds: re.restSeconds,
        exercise: Exercise(
          id: re.exerciseId,
          name: r['ex_name'] as String,
          muscleGroup: r['ex_muscle_group'] as String,
          secondaryMuscles: r['ex_secondary_muscles'] as String? ?? '',
          equipment: r['ex_equipment'] as String,
          type: r['ex_type'] as String,
          instructions: r['ex_instructions'] as String? ?? '',
          createdAt: r['ex_created_at'] as String,
        ),
      );
    }).toList();
  }

  Future<void> saveExercises(
      int routineId, List<RoutineExercise> exercises) async {
    await _db.transaction((txn) async {
      // Get existing exercise IDs to determine what to delete
      final existing = await txn.query('routine_exercises',
          where: 'routine_id = ?', whereArgs: [routineId]);
      final existingIds = existing.map((e) => e['id'] as int).toSet();
      final incomingIds =
          exercises.where((e) => e.id != null).map((e) => e.id!).toSet();

      // Delete removed exercises
      final toDelete = existingIds.difference(incomingIds);
      if (toDelete.isNotEmpty) {
        await txn.delete('routine_exercises',
            where: 'id IN (${toDelete.join(',')})');
      }

      // Upsert incoming
      for (var i = 0; i < exercises.length; i++) {
        final re = exercises[i];
        final data = {
          'routine_id': routineId,
          'exercise_id': re.exerciseId,
          'order_index': i,
          'default_sets': re.defaultSets,
          'default_reps': re.defaultReps,
          'rest_seconds': re.restSeconds,
        };

        if (re.id != null && existingIds.contains(re.id)) {
          await txn.update('routine_exercises', data,
              where: 'id = ?', whereArgs: [re.id]);
        } else {
          await txn.insert('routine_exercises', data);
        }
      }
    });
  }

  Future<void> updateExerciseOrder(List<RoutineExercise> exercises) async {
    await _db.transaction((txn) async {
      for (final ex in exercises) {
        await txn.update(
          'routine_exercises',
          {'order_index': ex.orderIndex},
          where: 'id = ?',
          whereArgs: [ex.id],
        );
      }
    });
  }
}
