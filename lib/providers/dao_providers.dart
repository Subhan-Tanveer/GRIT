import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';
import '../data/daos/exercises_dao.dart';
import '../data/daos/sessions_dao.dart';
import '../data/daos/sets_dao.dart';
import '../data/daos/routines_dao.dart';
import '../data/daos/body_weight_dao.dart';
import '../data/daos/body_measurement_dao.dart';
import '../data/daos/wellness_dao.dart';
import '../data/daos/nutrition_dao.dart';
import '../data/daos/ai_coach_dao.dart';
import '../data/daos/progress_photo_dao.dart';

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

final wellnessDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider).value;
  if (db == null) throw Exception('Database not ready');
  return WellnessDao(db);
});

final nutritionDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider).value;
  if (db == null) throw Exception('Database not ready');
  return NutritionDao(db);
});

final aiCoachDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider).value;
  if (db == null) throw Exception('Database not ready');
  return AiCoachDao(db);
});

final progressPhotoDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider).value;
  if (db == null) throw Exception('Database not ready');
  return ProgressPhotoDao(db);
});
