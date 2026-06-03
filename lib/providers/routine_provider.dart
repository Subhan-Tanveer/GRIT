import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dao_providers.dart';
import '../data/models/exercise.dart';
import '../data/models/routine.dart';
import '../data/models/muscle_analysis.dart';
import '../core/utils/workout_utils.dart';
import 'profile_provider.dart';

final exercisesProvider = FutureProvider<List<Exercise>>((ref) {
  return ref.watch(exercisesDaoProvider).getAll();
});

final routineListProvider = FutureProvider<List<Routine>>((ref) {
  return ref.watch(routinesDaoProvider).getCustomOnly();
});

final routineProvider =
    FutureProvider.family<Routine?, int>((ref, routineId) async {
  return ref.watch(routinesDaoProvider).getById(routineId);
});

final allMuscleGroupsProvider = FutureProvider<List<String>>((ref) async {
  final exercises = await ref.watch(exercisesProvider.future);
  final groups = exercises.map((e) => e.muscleGroup).toSet().toList();
  groups.sort();
  return groups;
});

final muscleExercisesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, muscle) async {
  final dao = ref.watch(sessionsDaoProvider);
  final exercises = await dao.getExercisesForMuscle(muscle);
  
  final List<Map<String, dynamic>> results = [];
  for (final ex in exercises) {
    final exId = ex['id'] as int;
    final last5 = await dao.getExerciseLastSessions(exId, 5);
    results.add({
      ...ex,
      'trend': last5.reversed.map((s) => s['max_e1rm'] as double).toList(),
    });
  }
  
  results.sort((a, b) {
    final ltA = a['last_trained'] as String?;
    final ltB = b['last_trained'] as String?;
    if (ltA == null) return 1;
    if (ltB == null) return -1;
    return ltB.compareTo(ltA);
  });
  
  return results;
});

final sessionDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final sDao = ref.watch(sessionsDaoProvider);
  final setsDao = ref.watch(setsDaoProvider);
  final exDao = ref.watch(exercisesDaoProvider);

  final session = await sDao.getById(id);
  if (session == null) throw Exception('Session not found');

  final exercises = await sDao.getExercises(id);
  final List<Map<String, dynamic>> enrichedExercises = [];

    for (final se in exercises) {
      final sets = await setsDao.getForSessionExercise(se.id!);
      final exercise = await exDao.getById(se.exerciseId);
      final benchmarks = await setsDao.getBestBenchmarksBefore(se.exerciseId, session.startedAt);

      final List<Map<String, dynamic>> enrichedSets = sets.map((s) {
        final isPR = WorkoutUtils.isPersonalRecord(
          s,
          bestWeightBefore: benchmarks.weight,
          bestE1RMBefore: benchmarks.e1rm,
          bestSetVolumeBefore: benchmarks.volume,
          exerciseType: exercise?.type ?? 'weighted',
          userBodyweight: ref.watch(profileProvider).weightKg,
        );
        return {
          'set': s,
          'isPR': isPR,
        };
      }).toList();

    enrichedExercises.add({
      'sessionExercise': se,
      'exercise': exercise,
      'sets': enrichedSets,
    });
  }

  return {
    'session': session,
    'exercises': enrichedExercises,
  };
});

final exerciseProgressionProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, exerciseId) async {
  final dao = ref.watch(sessionsDaoProvider);
  return await dao.getExerciseProgression(exerciseId);
});

final exerciseDetailStatsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, exerciseId) async {
  final dao = ref.watch(sessionsDaoProvider);
  return await dao.getExerciseAllTimeStats(exerciseId);
});

final exerciseSessionHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, exerciseId) async {
  final dao = ref.watch(sessionsDaoProvider);
  final rows = await dao.getExerciseSessionHistory(exerciseId);
  if (rows.isEmpty) return [];

  final chronRows = List<Map<String, dynamic>>.from(rows);
  chronRows.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  
  double maxWeight = 0;
  final Map<int, bool> prMap = {};
  
  for (final r in chronRows) {
    final weight = (r['weight_kg'] as num).toDouble();
    if (weight > maxWeight) {
      maxWeight = weight;
      if (weight > 0) prMap[r['set_id'] as int] = true;
    }
  }

  return rows.map((r) {
    return {
      ...r,
      'is_pr': prMap[r['set_id'] as int] ?? false,
    };
  }).toList();
});

class ExerciseChartRangeNotifier extends Notifier<String> {
  @override
  String build() => 'MONTH';
  void setRange(String range) => state = range;
}

final exerciseChartRangeProvider = NotifierProvider<ExerciseChartRangeNotifier, String>(ExerciseChartRangeNotifier.new);

final exerciseHistoryProvider = FutureProvider.family<List<ExerciseHistoryPoint>, int>((ref, exerciseId) async {
  final dao = ref.watch(sessionsDaoProvider);
  final range = ref.watch(exerciseChartRangeProvider);
  
  int limit;
  switch (range) {
    case 'WEEK': limit = 5; break;
    case 'MONTH': limit = 15; break;
    case 'YEAR': limit = 100; break;
    default: limit = 15;
  }
  
  final rows = await dao.getExerciseHistory(exerciseId, limit: limit);
  
  return rows.map((row) {
    final weight = (row['topWeight'] as num?)?.toDouble() ?? 0.0;
    final reps = row['reps'] as int? ?? 0;
    return ExerciseHistoryPoint(
      date: DateTime.parse(row['day'] as String),
      topWeight: weight,
      reps: reps,
      volume: (row['volume'] as num?)?.toDouble() ?? 0.0,
      estimated1RM: WorkoutUtils.calculateE1RM(weight, reps),
    );
  }).toList();
});

final lastTrainedForRoutineProvider =
    FutureProvider.family<String?, String>((ref, routineName) {
  return ref
      .watch(sessionsDaoProvider)
      .getLastTrainedDateForRoutine(routineName);
});
