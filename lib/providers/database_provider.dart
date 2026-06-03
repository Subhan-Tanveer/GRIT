import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database/grit_database.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return await GritDatabase.instance;
});
