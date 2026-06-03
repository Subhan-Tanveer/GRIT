import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';
import '../data/daos/exercises_dao.dart';
import '../data/daos/sessions_dao.dart';
import '../data/daos/sets_dao.dart';
import '../data/daos/routines_dao.dart';
import '../data/daos/body_weight_dao.dart';
import '../data/daos/body_measurement_dao.dart';

final exercisesDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider).value;
  if (db == null) throw Exception('Database not ready');
  return ExercisesDao(db);
});

final sessionsDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider).value;
  if (db == null) throw Exception('Database not ready');
  return SessionsDao(db);
});

final setsDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider).value;
  if (db == null) throw Exception('Database not ready');
  return SetsDao(db);
});

final routinesDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider).value;
  if (db == null) throw Exception('Database not ready');
  return RoutinesDao(db);
});

final bodyWeightDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider).value;
  if (db == null) throw Exception('Database not ready');
  return BodyWeightDao(db);
});

final bodyMeasurementDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider).value;
  if (db == null) throw Exception('Database not ready');
  return BodyMeasurementDao(db);
});
