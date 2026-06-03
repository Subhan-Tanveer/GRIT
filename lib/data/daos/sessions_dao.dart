import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/workout_session.dart';
import '../models/session_exercise.dart';
import '../../core/database/grit_database.dart';

class SessionsDao {
  final Database _db;

  /// CANONICAL E1RM FORMULA (Brzycki): weight * (36 / (37 - reps))
  /// Standardized across SQL and Dart for 100% mathematical consistency.
  static const String e1rmSql =
      "(CASE WHEN reps <= 0 THEN 0.0 WHEN reps = 1 THEN weight_kg ELSE weight_kg * (36.0 / (37.0 - CASE WHEN reps > 36 THEN 36 ELSE reps END)) END)";

  SessionsDao(this._db);

  Future<int> insert(WorkoutSession s,
      {double? userBodyweightKg, DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    // Ensure strict mutual exclusion: Close/purge ALL existing active sessions
    // before starting a new one. This prevents "ghost" sessions from appearing.
    await closeAllActiveSessions(
        userBodyweightKg: userBodyweightKg, executor: executor);
    return db.insert('workout_sessions', s.toDbMap());
  }

  Future<void> update(WorkoutSession s, {DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    await db.update(
      'workout_sessions',
      s.toDbMap(),
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  Future<WorkoutSession?> getById(int id, {DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    final rows =
        await db.query('workout_sessions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return WorkoutSession.fromMap(rows.first);
  }

  Future<List<WorkoutSession>> getAllFinished(
      {int? limit, int? offset, DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    final rows = await db.query(
      'workout_sessions',
      where: 'ended_at IS NOT NULL',
      orderBy: 'started_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<List<WorkoutSession>> getSessionsForDay(String dayIso,
      {DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    final rows = await db.rawQuery('''
      SELECT * FROM workout_sessions 
      WHERE date(started_at) = date(?) AND ended_at IS NOT NULL
      ORDER BY started_at DESC
    ''', [dayIso]);
    return rows.map(WorkoutSession.fromMap).toList();
  }

  Future<WorkoutSession?> getActive({DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    final rows = await db.query(
      'workout_sessions',
      where: 'ended_at IS NULL',
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkoutSession.fromMap(rows.first);
  }

  Future<int> insertExercise(SessionExercise se,
      {DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    return db.insert('session_exercises', se.toMap());
  }

  Future<void> updateExerciseOrder(int id, int orderIndex,
      {DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    await db.update(
      'session_exercises',
      {'order_index': orderIndex},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateExerciseType(int id, int exerciseId,
      {DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    await db.update(
      'session_exercises',
      {'exercise_id': exerciseId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateExerciseRestTime(int id, int seconds,
      {DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    await db.update(
      'session_exercises',
      {'target_rest': seconds},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SessionExercise>> getExercises(int sessionId,
      {DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    final rows = await db.query(
      'session_exercises',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'order_index ASC',
    );
    return rows.map(SessionExercise.fromMap).toList();
  }

  Future<void> delete(int id, {DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    await db.delete('workout_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteExercise(int id, {DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    await db.delete('session_exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getWeeklySessionCount(String mondayIso) async {
    final result = await _db.rawQuery('''
      SELECT COUNT(*) as count FROM workout_sessions 
      WHERE started_at >= ? AND ended_at IS NOT NULL
    ''', [mondayIso]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<double>> getDailyVolumesForWeek(String mondayIso) async {
    final volumes = List<double>.generate(7, (_) => 0.0);
    final rows = await _db.rawQuery('''
      SELECT date(started_at) as day, SUM(total_volume_kg) as volume
      FROM workout_sessions
      WHERE started_at >= ? AND ended_at IS NOT NULL
      GROUP BY day
    ''', [mondayIso]);

    final monday = DateTime.tryParse(mondayIso) ?? DateTime.now();
    for (final r in rows) {
      final dayStr = r['day'] as String?;
      if (dayStr == null) continue;
      final sessionDate = DateTime.tryParse(dayStr);
      if (sessionDate == null) continue;

      final index = sessionDate.difference(monday).inDays;
      if (index >= 0 && index < 7) {
        volumes[index] = (r['volume'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return volumes;
  }

  Future<List<bool>> getTrainedDaysForWeek(String mondayIso) async {
    final trained = List<bool>.generate(7, (_) => false);
    final rows = await _db.rawQuery('''
      SELECT date(started_at) as day
      FROM workout_sessions
      WHERE started_at >= ? AND ended_at IS NOT NULL
      GROUP BY day
    ''', [mondayIso]);

    final monday = DateTime.tryParse(mondayIso) ?? DateTime.now();
    for (final r in rows) {
      final dayStr = r['day'] as String?;
      if (dayStr == null) continue;
      final sessionDate = DateTime.tryParse(dayStr);
      if (sessionDate == null) continue;

      final index = sessionDate.difference(monday).inDays;
      if (index >= 0 && index < 7) {
        trained[index] = true;
      }
    }
    return trained;
  }

  Future<List<Map<String, dynamic>>> getTopLiftCandidatesForWeek(
      String mondayIso) async {
    final rows = await _db.rawQuery('''
      SELECT $e1rmSql as e1rm, s.weight_kg, s.reps, e.name as exercise_name, ws.name as session_name, ws.started_at as date
      FROM sets s
      JOIN session_exercises se ON s.session_exercise_id = se.id
      JOIN exercises e ON se.exercise_id = e.id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE ws.started_at >= ? AND ws.ended_at IS NOT NULL AND s.is_completed = 1 AND s.set_type != 'warmup'
      ORDER BY e1rm DESC
      LIMIT 1
    ''', [mondayIso]);

    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<String>> getTrainedDaysForPeriod(String startIso) async {
    final rows = await _db.rawQuery('''
      SELECT date(started_at) as day
      FROM workout_sessions
      WHERE started_at >= ? AND ended_at IS NOT NULL
      GROUP BY day
    ''', [startIso]);
    return rows.map((r) => r['day'] as String).toList();
  }

  Future<Map<String, double>> getDailyVolumesForPeriod(String startIso) async {
    final rows = await _db.rawQuery('''
      SELECT date(started_at) as day, SUM(total_volume_kg) as volume
      FROM workout_sessions
      WHERE started_at >= ? AND ended_at IS NOT NULL
      GROUP BY day
    ''', [startIso]);

    final Map<String, double> volumes = {};
    for (final r in rows) {
      volumes[r['day'] as String] = (r['volume'] as num).toDouble();
    }
    return volumes;
  }

  Future<List<DateTime>> getAllTrainedDays() async {
    final rows = await _db.rawQuery('''
      SELECT date(started_at) as day
      FROM workout_sessions
      WHERE ended_at IS NOT NULL
      GROUP BY day
      ORDER BY day ASC
    ''');
    return rows.map((r) => DateTime.parse(r['day'] as String)).toList();
  }

  Future<Map<String, dynamic>> getRollingStats(String startIso) async {
    final result = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(total_volume_kg) as volume
      FROM workout_sessions
      WHERE started_at >= ? AND ended_at IS NOT NULL
    ''', [startIso]);
    if (result.isEmpty) return {'count': 0, 'volume': 0.0};
    return {
      'count': result.first['count'] ?? 0,
      'volume': (result.first['volume'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getMuscleProgressStats(
      String muscleGroup) async {
    // Get max weight for any exercise in this group per session day
    final rows = await _db.rawQuery('''
      SELECT date(ws.started_at) as day, MAX($e1rmSql) as max_e1rm
      FROM sets s
      JOIN session_exercises se ON s.session_exercise_id = se.id
      JOIN exercises e ON se.exercise_id = e.id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE LOWER(e.muscle_group) = ? AND ws.ended_at IS NOT NULL AND s.is_completed = 1
      GROUP BY day
      ORDER BY day ASC
      LIMIT 12
    ''', [muscleGroup.toLowerCase()]);
    return rows;
  }

  Future<int> getMuscleFrequency(String muscleGroup, String startIso) async {
    final result = await _db.rawQuery('''
      SELECT COUNT(DISTINCT ws.id) as count
      FROM workout_sessions ws
      JOIN session_exercises se ON se.session_id = ws.id
      JOIN exercises e ON se.exercise_id = e.id
      WHERE LOWER(e.muscle_group) = ? AND ws.started_at >= ? AND ws.ended_at IS NOT NULL
    ''', [muscleGroup.toLowerCase(), startIso]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getDetailedMuscleVolumeHistory(
      String muscleGroup) async {
    return await _db.rawQuery('''
      SELECT 
        date(ws.started_at) as day, 
        SUM(s.weight_kg * s.reps) as volume,
        SUM(s.weight_kg) as total_weight,
        SUM(s.reps) as total_reps,
        MAX($e1rmSql) as max_e1rm
      FROM sets s
      JOIN session_exercises se ON s.session_exercise_id = se.id
      JOIN exercises e ON se.exercise_id = e.id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE LOWER(e.muscle_group) = ? AND ws.ended_at IS NOT NULL AND s.is_completed = 1
      GROUP BY day
      ORDER BY day ASC
    ''', [muscleGroup.toLowerCase()]);
  }

  Future<List<Map<String, dynamic>>> getMuscleAnalysisForPeriod(
      String startIso, String endIso) async {
    return await _db.rawQuery('''
      SELECT 
        e.muscle_group as name,
        COUNT(DISTINCT se.session_id) as sessions,
        COUNT(s.id) as working_sets,
        SUM(s.weight_kg * s.reps) as volume
      FROM exercises e
      JOIN session_exercises se ON e.id = se.exercise_id
      JOIN sets s ON se.id = s.session_exercise_id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE ws.started_at >= ? AND ws.started_at <= ?
        AND ws.ended_at IS NOT NULL
        AND s.is_completed = 1
        AND s.is_warmup = 0
      GROUP BY e.muscle_group
    ''', [startIso, endIso]);
  }

  Future<List<Map<String, dynamic>>> getMuscleGroupSummaries() async {
    final db = await GritDatabase.instance;
    return await db.rawQuery('''
      SELECT 
        e.muscle_group as name,
        COUNT(DISTINCT e.id) as exerciseCount,
        COUNT(DISTINCT se.session_id) as workoutCount,
        SUM(s.weight_kg * s.reps) as totalVolume
      FROM exercises e
      JOIN session_exercises se ON e.id = se.exercise_id
      JOIN sets s ON se.id = s.session_exercise_id
      WHERE s.is_completed = 1
      GROUP BY e.muscle_group
      ORDER BY workoutCount DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getExerciseProgressByMuscle(
      String muscle) async {
    final db = await GritDatabase.instance;
    return await db.rawQuery('''
      SELECT 
        e.id,
        e.name,
        MAX(s.weight_kg) as personalRecord,
        (
          SELECT MAX(s2.weight_kg) 
          FROM sets s2 
          JOIN session_exercises se2 ON s2.session_exercise_id = se2.id
          JOIN workout_sessions ws2 ON se2.session_id = ws2.id
          WHERE se2.exercise_id = e.id 
            AND ws2.started_at > datetime('now', '-30 days')
            AND s2.is_completed = 1
        ) as maxLast30Days,
        (
          SELECT MAX(s3.weight_kg) 
          FROM sets s3 
          JOIN session_exercises se3 ON s3.session_exercise_id = se3.id
          JOIN workout_sessions ws3 ON se3.session_id = ws3.id
          WHERE se3.exercise_id = e.id 
            AND ws3.started_at <= datetime('now', '-30 days')
            AND s3.is_completed = 1
        ) as maxPrevious
      FROM exercises e
      JOIN session_exercises se ON e.id = se.exercise_id
      JOIN sets s ON se.id = s.session_exercise_id
      WHERE LOWER(e.muscle_group) = LOWER(?) AND s.is_completed = 1
      GROUP BY e.id
      ORDER BY e.name ASC
    ''', [muscle]);
  }

  Future<List<Map<String, dynamic>>> getExerciseHistory(int exerciseId,
      {int limit = 10}) async {
    final db = await GritDatabase.instance;
    return await db.rawQuery('''
      SELECT 
        ws.id,
        ws.name,
        ws.started_at,
        (SUM(s.weight_kg * s.reps)) as volume
      FROM workout_sessions ws
      JOIN session_exercises se ON ws.id = se.session_id
      JOIN sets s ON se.id = s.session_exercise_id
      WHERE se.exercise_id = ? 
        AND s.is_completed = 1 
        AND s.is_warmup = 0
      GROUP BY ws.id
      ORDER BY ws.started_at DESC
      LIMIT ?
    ''', [exerciseId, limit]);
  }

  Future<List<Map<String, dynamic>>> getMuscleExerciseStats(
      String muscleGroup) async {
    return await _db.rawQuery('''
      SELECT 
        e.id as exercise_id, 
        e.name, 
        MAX(s.weight_kg) as best_weight,
        (SELECT s2.reps FROM sets s2 
         JOIN session_exercises se2 ON s2.session_exercise_id = se2.id 
         WHERE se2.exercise_id = e.id 
         ORDER BY s2.weight_kg DESC, s2.reps DESC
         LIMIT 1) as best_reps,
        COUNT(s.id) as total_sets,
        SUM(s.weight_kg * s.reps) as total_volume
      FROM sets s
      JOIN session_exercises se ON s.session_exercise_id = se.id
      JOIN exercises e ON se.exercise_id = e.id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE LOWER(e.muscle_group) = ? 
        AND ws.ended_at IS NOT NULL 
        AND s.is_completed = 1
        AND s.is_warmup = 0
      GROUP BY e.id, e.name
      ORDER BY total_volume DESC
    ''', [muscleGroup.toLowerCase()]);
  }

  Future<double> getBestWeightForExerciseBefore(
      int exerciseId, String beforeDateIso) async {
    final res = await _db.rawQuery('''
      SELECT MAX(s.weight_kg) as best FROM sets s
      JOIN session_exercises se ON se.id = s.session_exercise_id
      JOIN workout_sessions ws ON ws.id = se.session_id
      WHERE se.exercise_id = ? 
        AND ws.started_at < ?
        AND ws.ended_at IS NOT NULL 
        AND s.is_completed = 1
        AND s.is_warmup = 0
    ''', [exerciseId, beforeDateIso]);
    final val = res.first['best'];
    if (val == null) return 0.0;
    return (val as num).toDouble();
  }

  Future<void> updateSessionVolume(int sessionId, double volume) async {
    await _db.update(
      'workout_sessions',
      {'total_volume_kg': volume},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> updateExerciseOrderBulk(List<Map<String, int>> updates) async {
    await _db.transaction((txn) async {
      for (final update in updates) {
        await txn.update(
          'session_exercises',
          {'order_index': update['order_index']},
          where: 'id = ?',
          whereArgs: [update['id']],
        );
      }
    });
  }

  Future<void> closeAllActiveSessions(
      {double? userBodyweightKg, DatabaseExecutor? executor}) async {
    final db = executor ?? _db;
    // SECURITY FIX: Prevent accidental deletion of long active workouts.
    // A session is only "garbage" if it has 0 volume, 0 sets, AND is older than 60 mins.
    final safetyThreshold =
        DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();

    // 1. Clean up "ghost" sessions (started but no activity)
    final ghostSessions = await db.rawQuery('''
      SELECT ws.id FROM workout_sessions ws
      WHERE ws.ended_at IS NULL 
        AND ws.total_volume_kg = 0 
        AND ws.started_at < ?
        AND NOT EXISTS (SELECT 1 FROM sets s JOIN session_exercises se ON s.session_exercise_id = se.id WHERE se.session_id = ws.id)
    ''', [safetyThreshold]);

    for (final session in ghostSessions) {
      final id = session['id'] as int;
      await delete(id, executor: db);
    }

    // 2. Finalize all other active sessions.
    // Before closing, we calculate their volume to ensure they show up correctly in history.
    final activeSessions =
        await db.query('workout_sessions', where: 'ended_at IS NULL');
    if (activeSessions.isEmpty) return;

    final now = DateTime.now().toIso8601String();
    final bodyweight =
        userBodyweightKg ?? 75.0; // Fallback to average if unknown

    Future<void> finalize(DatabaseExecutor executor) async {
      for (final sRow in activeSessions) {
        final sessionId = sRow['id'] as int;

        // Calculate volume for this session using SQL logic consistent with WorkoutUtils
        final volRes = await executor.rawQuery('''
          SELECT SUM(
            CASE 
              WHEN e.type = 'assisted_bodyweight' THEN (CASE WHEN ? - s.weight_kg < 0 THEN 0 ELSE ? - s.weight_kg END)
              WHEN e.type = 'bodyweight' THEN (? + s.weight_kg)
              ELSE s.weight_kg
            END * s.reps
          ) as total_vol
          FROM sets s
          JOIN session_exercises se ON s.session_exercise_id = se.id
          JOIN exercises e ON se.exercise_id = e.id
          WHERE se.session_id = ? AND s.is_completed = 1 AND s.set_type != 'warmup'
        ''', [bodyweight, bodyweight, bodyweight, sessionId]);

        final volume = (volRes.first['total_vol'] as num?)?.toDouble() ?? 0.0;

        await executor.update(
          'workout_sessions',
          {
            'ended_at': now,
            'total_volume_kg': volume,
          },
          where: 'id = ?',
          whereArgs: [sessionId],
        );
      }
    }

    if (db is Database) {
      await (db).transaction((txn) => finalize(txn));
    } else {
      await finalize(db);
    }
  }

  Future<List<WorkoutSession>> getAllFinishedWithExercises(
      {int limit = 10}) async {
    final sessions = (await getAllFinished()).take(limit).toList();
    if (sessions.isEmpty) return [];

    final sessionIds = sessions.map((s) => s.id!).toList();
    final placeholders = List.filled(sessionIds.length, '?').join(',');

    // Fetch all exercises for these sessions in one query
    final exRows = await _db.query(
      'session_exercises',
      where: 'session_id IN ($placeholders)',
      whereArgs: sessionIds,
      orderBy: 'session_id, order_index ASC',
    );

    final exerciseMap = <int, List<SessionExercise>>{};
    for (final r in exRows) {
      final sid = r['session_id'] as int;
      final se = SessionExercise.fromMap(r);
      exerciseMap.putIfAbsent(sid, () => []).add(se);
    }

    return sessions.map((s) {
      return s.copyWith(exercises: exerciseMap[s.id] ?? []);
    }).toList();
  }

  Future<String?> getLastTrainedDateForRoutine(String routineName) async {
    final rows = await _db.rawQuery('''
      SELECT started_at FROM workout_sessions
      WHERE name = ? AND ended_at IS NOT NULL
      ORDER BY started_at DESC
      LIMIT 1
    ''', [routineName]);
    if (rows.isEmpty) return null;
    return rows.first['started_at'] as String?;
  }

  Future<List<Map<String, dynamic>>> getMuscleDistributionRaw(
      String dayIso) async {
    return await _db.rawQuery('''
      SELECT 
        e.name, 
        e.muscle_group, 
        e.secondary_muscles,
        COUNT(s.id) as total_sets,
        SUM(s.weight_kg * COALESCE(s.reps, 1)) as total_volume
      FROM sets s
      JOIN session_exercises se ON s.session_exercise_id = se.id
      JOIN exercises e ON se.exercise_id = e.id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE date(ws.started_at) = date(?) 
        AND s.is_completed = 1
        AND s.is_warmup = 0
      GROUP BY e.name, e.muscle_group, e.secondary_muscles
    ''', [dayIso]);
  }

  Future<List<Map<String, dynamic>>> getMuscleDistributionRawForPeriod(
      String startIso) async {
    return await _db.rawQuery('''
      SELECT e.name, e.muscle_group, e.secondary_muscles, SUM(s.weight_kg * COALESCE(s.reps, 1)) as total_volume
      FROM sets s
      JOIN session_exercises se ON s.session_exercise_id = se.id
      JOIN exercises e ON se.exercise_id = e.id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE ws.started_at >= ? 
        AND s.is_completed = 1
        AND s.is_warmup = 0
      GROUP BY e.name, e.muscle_group, e.secondary_muscles
    ''', [startIso]);
  }

  Future<Map<String, int>> getMuscleDistributionForWeek(
      String mondayIso) async {
    final rows = await _db.rawQuery('''
      SELECT e.name, e.muscle_group, SUM(s.weight_kg * COALESCE(s.reps, 1)) as total_volume
      FROM sets s
      JOIN session_exercises se ON s.session_exercise_id = se.id
      JOIN exercises e ON se.exercise_id = e.id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE ws.started_at >= ? 
        AND s.is_completed = 1
        AND s.is_warmup = 0
      GROUP BY e.name, e.muscle_group
      ORDER BY total_volume DESC
    ''', [mondayIso]);

    final Map<String, int> distribution = {};
    for (final r in rows) {
      final group = r['muscle_group'] as String? ?? '';
      final volume = (r['total_volume'] as num?)?.round() ?? 0;

      if (volume > 0) {
        // muscle_group is the canonical SVG ID – use directly
        distribution[group] = (distribution[group] ?? 0) + volume;
      }
    }
    return distribution;
  }

  Future<List<Map<String, dynamic>>> getRollingVolumeStats(
      String startIso, String endIso) async {
    return await _db.rawQuery('''
      SELECT 
        e.muscle_group as name,
        SUM(s.weight_kg * s.reps) as total_volume,
        COUNT(DISTINCT date(ws.started_at)) as days_trained,
        MIN(ws.started_at) as earliest_session,
        MAX(ws.started_at) as latest_session
      FROM exercises e
      JOIN session_exercises se ON e.id = se.exercise_id
      JOIN sets s ON se.id = s.session_exercise_id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE ws.started_at >= ? AND ws.started_at <= ?
        AND ws.ended_at IS NOT NULL
        AND s.is_completed = 1
        AND s.is_warmup = 0
      GROUP BY e.muscle_group
    ''', [startIso, endIso]);
  }

  Future<List<Map<String, dynamic>>> getLastTrainedDates() async {
    return await _db.rawQuery('''
      SELECT 
        e.muscle_group as name,
        MAX(ws.started_at) as last_trained
      FROM exercises e
      JOIN session_exercises se ON e.id = se.exercise_id
      JOIN sets s ON se.id = s.session_exercise_id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE ws.ended_at IS NOT NULL
        AND s.is_completed = 1
        AND s.is_warmup = 0
      GROUP BY e.muscle_group
    ''');
  }

  Future<List<Map<String, dynamic>>> getAllTimeMuscleStats() async {
    return await _db.rawQuery('''
      SELECT 
        e.muscle_group,
        e.secondary_muscles,
        COUNT(DISTINCT se.session_id) as workouts,
        COUNT(s.id) as working_sets,
        SUM(s.weight_kg * s.reps) as total_volume,
        MAX(ws.started_at) as last_trained
      FROM exercises e
      JOIN session_exercises se ON e.id = se.exercise_id
      JOIN sets s ON se.id = s.session_exercise_id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE ws.ended_at IS NOT NULL
        AND s.is_completed = 1
        AND s.is_warmup = 0
      GROUP BY e.muscle_group, e.secondary_muscles
    ''');
  }

  Future<List<Map<String, dynamic>>> getRecentMuscleStats(int days) async {
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return await _db.rawQuery('''
      SELECT 
        e.muscle_group,
        e.secondary_muscles,
        SUM(s.weight_kg * s.reps) as total_volume
      FROM exercises e
      JOIN session_exercises se ON e.id = se.exercise_id
      JOIN sets s ON se.id = s.session_exercise_id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE ws.ended_at IS NOT NULL
        AND ws.started_at >= ?
        AND s.is_completed = 1
        AND s.is_warmup = 0
      GROUP BY e.muscle_group, e.secondary_muscles
    ''', [cutoff]);
  }

  Future<double> getTotalAllTimeVolume() async {
    final result = await _db.rawQuery('''
      SELECT SUM(s.weight_kg * s.reps) as total_volume
      FROM sets s
      JOIN session_exercises se ON s.session_exercise_id = se.id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE ws.ended_at IS NOT NULL
        AND s.is_completed = 1
        AND s.is_warmup = 0
    ''');
    return (result.first['total_volume'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getExercisesForMuscle(
      String muscle) async {
    return await _db.rawQuery('''
      SELECT 
        e.id,
        e.name,
        MAX(s.weight_kg) as pr_weight,
        MAX(ws.started_at) as last_trained,
        COUNT(s.id) as total_sets
      FROM exercises e
      JOIN session_exercises se ON e.id = se.exercise_id
      JOIN sets s ON se.id = s.session_exercise_id
      JOIN workout_sessions ws ON se.session_id = ws.id
      WHERE UPPER(e.muscle_group) = UPPER(?)
        AND ws.ended_at IS NOT NULL
        AND s.is_completed = 1
        AND s.is_warmup = 0
      GROUP BY e.id, e.name
    ''', [muscle]);
  }

  Future<List<Map<String, dynamic>>> getExerciseProgression(
      int exerciseId) async {
    return await _db.rawQuery('''
      SELECT 
        ws.id as session_id,
        ws.started_at as date,
        SUM(s.weight_kg * s.reps) as session_volume,
        MAX($e1rmSql) as max_e1rm,
        MAX(s.weight_kg) as max_weight,
        SUM(s.reps) as total_reps
      FROM workout_sessions ws
      JOIN session_exercises se ON ws.id = se.session_id
      JOIN sets s ON se.id = s.session_exercise_id
      WHERE se.exercise_id = ?
        AND ws.ended_at IS NOT NULL
        AND s.is_completed = 1
        AND s.is_warmup = 0
      GROUP BY ws.id, ws.started_at
      ORDER BY ws.started_at ASC
    ''', [exerciseId]);
  }

  Future<List<Map<String, dynamic>>> getExerciseLastSessions(
      int exerciseId, int limit) async {
    return await _db.rawQuery('''
      SELECT 
        ws.id as session_id,
        MAX($e1rmSql) as max_e1rm
      FROM workout_sessions ws
      JOIN session_exercises se ON ws.id = se.session_id
      JOIN sets s ON se.id = s.session_exercise_id
      WHERE se.exercise_id = ?
        AND ws.ended_at IS NOT NULL
        AND s.is_completed = 1
        AND s.is_warmup = 0
      GROUP BY ws.id
      ORDER BY ws.started_at DESC
      LIMIT ?
    ''', [exerciseId, limit]);
  }

  Future<Map<String, dynamic>> getExerciseAllTimeStats(int exerciseId) async {
    final result = await _db.rawQuery('''
      SELECT 
        e.name as name,
        MAX(s.weight_kg) as pr_weight,
        SUM(s.weight_kg * s.reps) as total_volume,
        COUNT(s.id) as total_sets,
        COUNT(DISTINCT se.session_id) as total_sessions
      FROM exercises e
      LEFT JOIN session_exercises se ON e.id = se.exercise_id
      LEFT JOIN sets s ON se.id = s.session_exercise_id AND s.is_completed = 1 AND s.is_warmup = 0
      LEFT JOIN workout_sessions ws ON se.session_id = ws.id AND ws.ended_at IS NOT NULL
      WHERE e.id = ?
      GROUP BY e.id
    ''', [exerciseId]);

    if (result.isEmpty) return {};
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getExerciseSessionHistory(
      int exerciseId) async {
    final result = await _db.rawQuery('''
      SELECT 
        ws.id as session_id,
        ws.name as session_name,
        ws.started_at as date,
        s.id as set_id,
        s.weight_kg,
        s.reps,
        s.set_number
      FROM workout_sessions ws
      JOIN session_exercises se ON ws.id = se.session_id
      JOIN sets s ON se.id = s.session_exercise_id
      WHERE se.exercise_id = ?
        AND ws.ended_at IS NOT NULL
        AND s.is_completed = 1
        AND s.is_warmup = 0
      ORDER BY ws.started_at DESC, s.set_number ASC
    ''', [exerciseId]);
    return result;
  }

  Future<String?> getEarliestFinishedSessionDate() async {
    final result = await _db.rawQuery('''
      SELECT MIN(started_at) as earliest FROM workout_sessions 
      WHERE ended_at IS NOT NULL
    ''');
    if (result.isEmpty) return null;
    return result.first['earliest'] as String?;
  }

  Future<List<bool>> getRestDaysForWeek(String mondayIso) async {
    final rest = List<bool>.generate(7, (_) => false);
    final rows = await _db.rawQuery('''
      SELECT date FROM rest_days
      WHERE date >= ? AND date <= date(?, '+6 days')
    ''', [mondayIso, mondayIso]);

    final monday = DateTime.tryParse(mondayIso) ?? DateTime.now();
    for (final r in rows) {
      try {
        final dayStr = r['date'] as String?;
        if (dayStr == null) continue;
        final restDate = DateTime.parse(dayStr);
        final index = restDate.difference(monday).inDays;
        if (index >= 0 && index < 7) {
          rest[index] = true;
        }
      } catch (e) {
        debugPrint('GRIT ERROR: Failed to parse rest day: $e');
      }
    }
    return rest;
  }

  Future<bool> isRestDay(String dateIso) async {
    final result = await _db.rawQuery(
        'SELECT COUNT(*) FROM rest_days WHERE date(date) = date(?)', [dateIso]);
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  Future<void> toggleRestDay(String dateIso, bool isRest) async {
    if (isRest) {
      await _db.insert('rest_days', {'date': dateIso},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await _db.delete('rest_days',
          where: 'date(date) = date(?)', whereArgs: [dateIso]);
    }
  }

  Future<List<DateTime>> getAllRestDays() async {
    final rows = await _db.rawQuery('''
      SELECT date FROM rest_days
      ORDER BY date ASC
    ''');
    return rows.map((r) => DateTime.parse(r['date'] as String)).toList();
  }
}
