import 'package:sqflite/sqflite.dart';
import '../models/body_measurement_entry.dart';

class BodyMeasurementDao {
  final Database _db;

  BodyMeasurementDao(this._db);

  Future<void> upsert(BodyMeasurementEntry entry) async {
    final date = entry.createdAt.split('T')[0];

    // Check if exists for today
    final existing = await _db.query(
      'body_measurements_log',
      where: "created_at LIKE ?",
      whereArgs: ['$date%'],
    );

    if (existing.isNotEmpty) {
      await _db.update(
        'body_measurements_log',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await _db.insert('body_measurements_log', entry.toMap());
    }
  }

  Future<BodyMeasurementEntry?> getLatest() async {
    final rows = await _db.query(
      'body_measurements_log',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BodyMeasurementEntry.fromMap(rows.first);
  }

  Future<List<BodyMeasurementEntry>> getAll() async {
    final rows = await _db.query(
      'body_measurements_log',
      orderBy: 'created_at DESC',
    );
    return rows.map(BodyMeasurementEntry.fromMap).toList();
  }

  Future<BodyMeasurementEntry?> getByDate(String dateIso) async {
    final date = dateIso.split('T')[0];
    final rows = await _db.query(
      'body_measurements_log',
      where: "created_at LIKE ?",
      whereArgs: ['$date%'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BodyMeasurementEntry.fromMap(rows.first);
  }

  Future<void> delete(int id) async {
    await _db.delete('body_measurements_log', where: 'id = ?', whereArgs: [id]);
  }
}
