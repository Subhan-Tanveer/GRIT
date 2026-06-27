import 'package:sqflite/sqflite.dart';
import '../models/nutrition_entry.dart';

class NutritionDao {
  final Database _db;

  NutritionDao(this._db);

  Future<int> insertEntry(NutritionEntry entry) async {
    return _db.insert('nutrition_logs', entry.toMap());
  }

  Future<void> deleteEntry(int id) async {
    await _db.delete('nutrition_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<NutritionEntry>> getForDate(String date) async {
    final rows = await _db.query(
      'nutrition_logs',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at ASC',
    );
    return rows.map(NutritionEntry.fromMap).toList();
  }

  Future<Map<String, double>> getTotalsForDate(String date) async {
    final result = await _db.rawQuery('''
      SELECT
        SUM(calories) as total_calories,
        SUM(protein) as total_protein,
        SUM(carbs) as total_carbs,
        SUM(fat) as total_fat
      FROM nutrition_logs WHERE date = ?
    ''', [date]);
    final row = result.first;
    return {
      'calories': (row['total_calories'] as num?)?.toDouble() ?? 0.0,
      'protein': (row['total_protein'] as num?)?.toDouble() ?? 0.0,
      'carbs': (row['total_carbs'] as num?)?.toDouble() ?? 0.0,
      'fat': (row['total_fat'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<Map<String, double>> getDailyCaloriesForPeriod(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String().split('T')[0];
    final rows = await _db.rawQuery('''
      SELECT date, SUM(calories) as total FROM nutrition_logs
      WHERE date >= ? GROUP BY date ORDER BY date ASC
    ''', [cutoff]);
    final Map<String, double> result = {};
    for (final r in rows) {
      result[r['date'] as String] = (r['total'] as num?)?.toDouble() ?? 0.0;
    }
    return result;
  }

  Future<int> addWater(String date, int amountMl) async {
    return _db.insert('water_logs', {'date': date, 'amount_ml': amountMl});
  }

  Future<int> getTotalWaterForDate(String date) async {
    final result = await _db.rawQuery('''
      SELECT SUM(amount_ml) as total FROM water_logs WHERE date = ?
    ''', [date]);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<void> resetWaterForDate(String date) async {
    await _db.delete('water_logs', where: 'date = ?', whereArgs: [date]);
  }

  Future<void> removeLastWaterEntry(String date) async {
    final rows = await _db.query(
      'water_logs',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'logged_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return;
    await _db.delete('water_logs', where: 'id = ?', whereArgs: [rows.first['id']]);
  }
}
