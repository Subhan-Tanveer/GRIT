import 'package:sqflite/sqflite.dart';
import '../models/body_weight_entry.dart';

class BodyWeightDao {
  final Database _db;

  BodyWeightDao(this._db);

  Future<void> upsert(double weightKg) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Check if exists for today
    final existing = await _db.query(
      'body_weight_log',
      where: 'logged_at = ?',
      whereArgs: [today],
    );

    if (existing.isNotEmpty) {
      await _db.update(
        'body_weight_log',
        {'weight_kg': weightKg},
        where: 'logged_at = ?',
        whereArgs: [today],
      );
    } else {
      await _db.insert('body_weight_log', {
        'weight_kg': weightKg,
        'logged_at': today,
      });
    }
  }

  Future<List<BodyWeightEntry>> getRecent(int days) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .split('T')[0];

    final rows = await _db.query(
      'body_weight_log',
      where: 'logged_at >= ?',
      whereArgs: [cutoff],
      orderBy: 'logged_at ASC',
    );

    return rows.map(BodyWeightEntry.fromMap).toList();
  }

  Future<List<BodyWeightEntry>> getAll() async {
    final rows = await _db.query(
      'body_weight_log',
      orderBy: 'logged_at ASC',
    );
    return rows.map(BodyWeightEntry.fromMap).toList();
  }

  Future<BodyWeightEntry?> getLatest() async {
    final rows = await _db.query(
      'body_weight_log',
      orderBy: 'logged_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BodyWeightEntry.fromMap(rows.first);
  }

  Future<void> delete(int id) async {
    await _db.delete('body_weight_log', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insert(BodyWeightEntry entry) async {
    await _db.insert('body_weight_log', {
      'weight_kg': entry.weightKg,
      'logged_at': entry.loggedAt,
    });
  }
}
