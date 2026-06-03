import 'package:sqflite/sqflite.dart';
import '../models/exercise.dart';
import 'package:flutter/foundation.dart';

class ExercisesDao {
  final Database _db;

  ExercisesDao(this._db);

  Future<List<Exercise>> getAll({bool includeHidden = false}) async {
    final where = includeHidden ? null : 'is_hidden = 0';
    final rows =
        await _db.query('exercises', where: where, orderBy: 'name ASC');
    return rows.map(Exercise.fromMap).toList();
  }

  Future<List<Exercise>> getByMuscleGroup(String group,
      {bool includeHidden = false}) async {
    final where = includeHidden
        ? 'LOWER(muscle_group) = LOWER(?)'
        : 'LOWER(muscle_group) = LOWER(?) AND is_hidden = 0';
    final rows = await _db.query(
      'exercises',
      where: where,
      whereArgs: [group],
      orderBy: 'name ASC',
    );
    return rows.map(Exercise.fromMap).toList();
  }

  Future<Exercise?> getById(int id) async {
    final rows = await _db.query('exercises', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Exercise.fromMap(rows.first);
  }

  Future<int> insert(Exercise ex) async {
    // muscle_group is already a canonical SVG ID set by MuscleMapper – do NOT re-normalize.
    return _db.insert('exercises', ex.toMap());
  }

  Future<void> update(Exercise ex) async {
    // muscle_group is already a canonical SVG ID set by MuscleMapper – do NOT re-normalize.
    await _db.update(
      'exercises',
      ex.toMap(),
      where: 'id = ?',
      whereArgs: [ex.id],
    );
  }

  Future<void> softDelete(int id) async {
    await _db.update('exercises', {'is_hidden': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    try {
      await _db.transaction((txn) async {
        // Manually cascade routine_exercises to prevent ON DELETE RESTRICT crash
        await txn.delete('routine_exercises', where: 'exercise_id = ?', whereArgs: [id]);
        await txn.delete('exercises', where: 'id = ?', whereArgs: [id]);
      });
    } catch (e) {
      debugPrint('GRIT ERROR: Failed to delete custom exercise: $e');
      rethrow;
    }
  }

  Future<bool> isUsed(int exerciseId) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) as c FROM session_exercises WHERE exercise_id = ?',
      [exerciseId],
    );
    return (rows.first['c'] as int) > 0;
  }

  Future<List<String>> getAllMuscleGroups() async {
    final rows = await _db.rawQuery(
        'SELECT DISTINCT muscle_group FROM exercises ORDER BY muscle_group ASC');
    return rows.map((r) => r['muscle_group'] as String).toList();
  }
}
