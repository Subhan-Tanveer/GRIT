import 'package:sqflite/sqflite.dart';
import '../models/progress_photo.dart';

class ProgressPhotoDao {
  final Database _db;

  ProgressPhotoDao(this._db);

  Future<int> insert(ProgressPhoto photo) async {
    return _db.insert('progress_photos', photo.toMap());
  }

  Future<List<ProgressPhoto>> getByCategory(PhotoCategory category) async {
    final rows = await _db.query(
      'progress_photos',
      where: 'category = ?',
      whereArgs: [category.dbValue],
      orderBy: 'date DESC',
    );
    return rows.map(ProgressPhoto.fromMap).toList();
  }

  Future<List<ProgressPhoto>> getAll() async {
    final rows = await _db.query('progress_photos', orderBy: 'date DESC');
    return rows.map(ProgressPhoto.fromMap).toList();
  }

  Future<void> delete(int id) async {
    await _db.delete('progress_photos', where: 'id = ?', whereArgs: [id]);
  }
}
