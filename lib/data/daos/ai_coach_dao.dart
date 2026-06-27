import 'package:sqflite/sqflite.dart';
import '../models/ai_message.dart';

class AiCoachDao {
  final Database _db;

  AiCoachDao(this._db);

  Future<int> insert(AiMessage message) async {
    return _db.insert('ai_messages', message.toMap());
  }

  Future<List<AiMessage>> getAll() async {
    final rows = await _db.query('ai_messages', orderBy: 'created_at ASC, id ASC');
    return rows.map(AiMessage.fromMap).toList();
  }

  Future<void> clear() async {
    await _db.delete('ai_messages');
  }
}
