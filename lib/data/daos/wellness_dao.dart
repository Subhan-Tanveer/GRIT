import 'package:sqflite/sqflite.dart';
import '../models/wellness_log.dart';

class WellnessDao {
  final Database _db;

  WellnessDao(this._db);

  Future<void> upsert(WellnessLog log) async {
    final existing = await _db.query(
      'wellness_logs',
      where: 'date = ?',
      whereArgs: [log.date],
    );

    if (existing.isNotEmpty) {
      await _db.update(
        'wellness_logs',
        log.toMap(),
        where: 'date = ?',
        whereArgs: [log.date],
      );
    } else {
      await _db.insert('wellness_logs', log.toMap());
    }
  }

  Future<WellnessLog?> getForDate(String date) async {
    final rows = await _db.query(
      'wellness_logs',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (rows.isEmpty) return null;
    return WellnessLog.fromMap(rows.first);
  }

  Future<List<WellnessLog>> getRecent(int days) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .split('T')[0];

    final rows = await _db.query(
      'wellness_logs',
      where: 'date >= ?',
      whereArgs: [cutoff],
      orderBy: 'date ASC',
    );
    return rows.map(WellnessLog.fromMap).toList();
  }

  Future<int> getAverageStress(int days) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .split('T')[0];
    final result = await _db.rawQuery('''
      SELECT AVG(stress_level) as avg_stress FROM wellness_logs WHERE date >= ?
    ''', [cutoff]);
    return ((result.first['avg_stress'] as num?)?.toDouble() ?? 5.0).round();
  }
}
