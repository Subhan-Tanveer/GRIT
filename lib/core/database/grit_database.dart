import 'dart:convert';
import 'dart:async'; // Import for Completer
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../data/models/exercise.dart';

class GritDatabase {
  static Database? _db;
  static Future<Database>? _initFuture;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    
    _initFuture ??= _open().then((db) {
      _db = db;
      return db;
    });
    
    return await _initFuture!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'grit.db');
    final db = await openDatabase(
      path,
      version: 34,
      onCreate: (db, version) async {
        await _onCreate(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _runMigrations(db, oldVersion, newVersion);
      },
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
    return db;
  }

  static Future<void> clearAndReSeed() async {
    final db = await instance;
    // Clear ALL exercises to be safe
    final deleted = await db.delete('exercises');
    debugPrint('GRIT: Manual refresh - cleared $deleted exercises.');
    await seed(db, force: true);
  }

  static Future<void> seed(Database db, {bool force = false}) async {
    final countRaw =
        await db.rawQuery('SELECT COUNT(*) FROM exercises WHERE is_custom = 0');
    final count = Sqflite.firstIntValue(countRaw);

    debugPrint('GRIT: Current prebuilt exercise count: $count (force: $force)');
    if (!force && count != null && count > 50) {
      debugPrint('GRIT: Library already seeded. Skipping.');
      return;
    }

    try {
      debugPrint('GRIT: Loading assets/exercises.json...');
      final jsonStr = await rootBundle.loadString('assets/exercises.json');
      final decoded = json.decode(jsonStr);

      final List<dynamic> jsonList = decoded is Map
          ? (decoded['exercises'] as List<dynamic>? ?? [])
          : decoded as List<dynamic>;

      // Fetch all existing canonical IDs in one go to minimize queries
      final existingRows = await db.query('exercises', columns: ['canonical_id']);
      final existingIds = existingRows
          .map((r) => r['canonical_id'] as String?)
          .whereType<String>()
          .toSet();

      debugPrint('GRIT: JSON loaded. Items: ${jsonList.length}. Existing prebuilt: ${existingIds.length}');

      final batch = db.batch();
      int updated = 0;
      int inserted = 0;

      for (final item in jsonList) {
        try {
          final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
          final ex = Exercise.fromJson(map);
          final exMap = ex.toMap();

          if (existingIds.contains(ex.canonicalId)) {
            // Update existing row match by canonical_id
            batch.update(
              'exercises',
              exMap,
              where: 'canonical_id = ?',
              whereArgs: [ex.canonicalId],
            );
            updated++;
          } else {
            // Insert new row
            batch.insert('exercises', exMap);
            inserted++;
          }
        } catch (itemError) {
          debugPrint('GRIT: Skipping item due to error: $itemError');
        }
      }

      debugPrint('GRIT: Committing batch ($updated updates, $inserted inserts)...');
      await batch.commit(noResult: true);

      final finalCountRaw = await db.rawQuery('SELECT COUNT(*) FROM exercises WHERE is_custom = 0');
      final finalCount = Sqflite.firstIntValue(finalCountRaw);
      debugPrint('GRIT: Seed complete. Final count: $finalCount');
    } catch (e, stack) {
      debugPrint('GRIT ERROR: Global seeding failure: $e');
      debugPrint('GRIT ERROR: Stack: $stack');
    }
  }

  static Future<void> _runMigrations(Database db, int oldVersion, int newVersion) async {
    bool needsReseed = false;

    if (oldVersion < 34) {
      debugPrint('GRIT: Squashed migration running (Upgrading legacy schema < 34 to 34)...');
      await db.execute('PRAGMA foreign_keys = OFF');
      try {
        // 1. Ensure new tables exist
        await db.execute('''
          CREATE TABLE IF NOT EXISTS rest_days (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_rest_days_date ON rest_days(date)');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS body_measurements_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            neck REAL,
            shoulders REAL,
            chest REAL,
            waist REAL,
            hips REAL,
            left_bicep REAL,
            right_bicep REAL,
            left_forearm REAL,
            right_forearm REAL,
            left_thigh REAL,
            right_thigh REAL,
            left_calf REAL,
            right_calf REAL
          )
        ''');

        // 2. Helper to check and add columns
        Future<void> addColumnSafe(String table, String col, String typeDef) async {
          final cols = await db.rawQuery('PRAGMA table_info($table)');
          final colNames = cols.map((c) => c['name'] as String).toSet();
          if (!colNames.contains(col)) {
            await db.execute('ALTER TABLE $table ADD COLUMN $col $typeDef');
          }
        }

        await addColumnSafe('exercises', 'instructions', 'TEXT DEFAULT ""');
        await addColumnSafe('exercises', 'secondary_muscles', 'TEXT DEFAULT ""');
        await addColumnSafe('exercises', 'canonical_id', 'TEXT');
        
        await addColumnSafe('sets', 'is_pr', 'INTEGER NOT NULL DEFAULT 0');
        await addColumnSafe('sets', 'set_type', "TEXT DEFAULT 'normal'");

        await addColumnSafe('workout_sessions', 'notes', 'TEXT DEFAULT ""');
        await addColumnSafe('workout_sessions', 'total_volume_kg', 'REAL NOT NULL DEFAULT 0.0');
        await addColumnSafe('workout_sessions', 'workout_duration_seconds', 'INTEGER NOT NULL DEFAULT 0');
        await addColumnSafe('workout_sessions', 'rest_duration_seconds', 'INTEGER NOT NULL DEFAULT 0');
        await addColumnSafe('workout_sessions', 'routine_id', 'INTEGER REFERENCES routines(id) ON DELETE SET NULL');

        await addColumnSafe('body_measurements_log', 'left_calf', 'REAL');
        await addColumnSafe('body_measurements_log', 'right_calf', 'REAL');

        // 3. Ensure indexes exist
        await db.execute('CREATE INDEX IF NOT EXISTS idx_exercises_muscle_group ON exercises(muscle_group)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_exercises_is_custom ON exercises(is_custom)');
        await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_exercises_canonical_unique ON exercises(canonical_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_exercises_name ON exercises(name)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_workout_sessions_date ON workout_sessions(started_at)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_session_exercises_session ON session_exercises(session_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_session_exercises_exercise ON session_exercises(exercise_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_sets_session_exercise ON sets(session_exercise_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_routine_exercises_routine ON routine_exercises(routine_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_routine_exercises_exercise ON routine_exercises(exercise_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_body_weight_date ON body_weight_log(logged_at)');

        // 4. Force cleaning of un-custom exercises to re-seed from the latest exercises.json asset
        await db.execute('DELETE FROM routine_exercises WHERE exercise_id IN (SELECT id FROM exercises WHERE is_custom = 0)');
        await db.delete('exercises', where: 'is_custom = ?', whereArgs: [0]);

        needsReseed = true;
      } finally {
        await db.execute('PRAGMA foreign_keys = ON');
      }
    }

    if (needsReseed) {
      debugPrint('GRIT: Triggering consolidated seed logic...');
      await seed(db, force: true);
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        canonical_id TEXT,
        secondary_muscles TEXT NOT NULL DEFAULT '',
        equipment TEXT NOT NULL,
        type TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        is_hidden INTEGER NOT NULL DEFAULT 0,
        instructions TEXT DEFAULT '',
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Create performance indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_exercises_muscle_group ON exercises(muscle_group)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_exercises_is_custom ON exercises(is_custom)');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_exercises_canonical_unique ON exercises(canonical_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_exercises_name ON exercises(name)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        started_at TEXT NOT NULL DEFAULT (datetime('now')),
        ended_at TEXT,
        notes TEXT DEFAULT '',
        total_volume_kg REAL NOT NULL DEFAULT 0.0,
        workout_duration_seconds INTEGER NOT NULL DEFAULT 0,
        rest_duration_seconds INTEGER NOT NULL DEFAULT 0,
        routine_id INTEGER REFERENCES routines(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS session_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
        exercise_id INTEGER NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
        order_index INTEGER NOT NULL DEFAULT 0,
        target_sets INTEGER NOT NULL DEFAULT 1,
        target_reps TEXT NOT NULL DEFAULT "8-12",
        target_rest INTEGER NOT NULL DEFAULT 90
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_exercise_id INTEGER NOT NULL REFERENCES session_exercises(id) ON DELETE CASCADE,
        set_number INTEGER NOT NULL,
        weight_kg REAL NOT NULL DEFAULT 0.0,
        reps INTEGER,
        duration_seconds INTEGER,
        is_warmup INTEGER NOT NULL DEFAULT 0,
        set_type TEXT NOT NULL DEFAULT 'normal',
        rpe REAL,
        notes TEXT DEFAULT '',
        logged_at TEXT NOT NULL DEFAULT (datetime('now')),
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_pr INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS routines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_prebuilt INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS routine_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
        exercise_id INTEGER NOT NULL REFERENCES exercises(id) ON DELETE RESTRICT,
        order_index INTEGER NOT NULL DEFAULT 0,
        default_sets INTEGER NOT NULL DEFAULT 1,
        default_reps TEXT NOT NULL DEFAULT '8-12',
        rest_seconds INTEGER NOT NULL DEFAULT 90
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS body_weight_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight_kg REAL NOT NULL,
        logged_at TEXT NOT NULL DEFAULT (date('now')),
        notes TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS body_measurements_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        neck REAL,
        shoulders REAL,
        chest REAL,
        waist REAL,
        hips REAL,
        left_bicep REAL,
        right_bicep REAL,
        left_forearm REAL,
        right_forearm REAL,
        left_thigh REAL,
        right_thigh REAL,
        left_calf REAL,
        right_calf REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS rest_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_rest_days_date ON rest_days(date)');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_workout_sessions_date ON workout_sessions(started_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_session_exercises_session ON session_exercises(session_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_session_exercises_exercise ON session_exercises(exercise_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sets_session_exercise ON sets(session_exercise_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_routine_exercises_routine ON routine_exercises(routine_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_routine_exercises_exercise ON routine_exercises(exercise_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_body_weight_date ON body_weight_log(logged_at)');

    // Seed logic
    await seed(db);

    // Note: Muscle normalization is handled by Exercise.fromJson() via MuscleMapper.
    // No post-seed normalization pass needed.
  }
}
