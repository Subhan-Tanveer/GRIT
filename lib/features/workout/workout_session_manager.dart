import '../../data/models/workout_session.dart';
import '../../data/models/exercise.dart';
import '../../data/models/routine.dart';
import '../../data/models/session_exercise.dart';
import '../../data/models/set_entry.dart';
import '../../data/models/user_profile.dart';
import '../../core/utils/workout_utils.dart';
import '../../data/daos/sessions_dao.dart';
import '../../data/daos/exercises_dao.dart';
import '../../data/daos/sets_dao.dart';

class SessionLoadResult {
  final WorkoutSession? session;
  final List<SessionExercise> exercises;
  final Map<int, List<SetEntry>> sets;
  final Map<int, Exercise> exerciseDetails;
  final Map<int, double> bestWeights;
  final Map<int, double> bestE1RMs;
  final Map<int, double> bestSetVolumes;
  final Map<int, List<SetEntry>> previousSets;

  SessionLoadResult({
    this.session,
    this.exercises = const [],
    this.sets = const {},
    this.exerciseDetails = const {},
    this.bestWeights = const {},
    this.bestE1RMs = const {},
    this.bestSetVolumes = const {},
    this.previousSets = const {},
  });
}

class NextSetRestDetails {
  final int restSeconds;
  final String? exerciseName;
  final String? nextSetInfo;
  final String? nextWeightRepsInfo;

  NextSetRestDetails({
    required this.restSeconds,
    this.exerciseName,
    this.nextSetInfo,
    this.nextWeightRepsInfo,
  });
}

class WorkoutSessionManager {
  static Future<SessionLoadResult> loadActiveSession({
    required SessionsDao sessionsDao,
    required ExercisesDao exercisesDao,
    required SetsDao setsDao,
  }) async {
    final session = await sessionsDao.getActive();
    if (session == null) return SessionLoadResult();

    // Normalization logic
    final normalizedName = session.name.toLowerCase();
    if (normalizedName.contains('free workout') ||
        normalizedName.contains('empty workout') ||
        normalizedName == 'workout' ||
        normalizedName.trim().isEmpty) {
      final recoveredSession = session.copyWith(name: 'RECOVERED SESSION');
      await sessionsDao.update(recoveredSession);
    }

    final exercises = await sessionsDao.getExercises(session.id!);
    final setsMap = <int, List<SetEntry>>{};
    final detailsMap = <int, Exercise>{};
    final bestWeightsMap = <int, double>{};
    final bestE1RMsMap = <int, double>{};
    final bestSetVolumesMap = <int, double>{};

    for (final se in exercises) {
      final sets = await setsDao.getForSessionExercise(se.id!);
      final detail = await exercisesDao.getById(se.exerciseId);
      final benchmarks = await setsDao.getBestBenchmarksBefore(
          se.exerciseId, session.startedAt);

      setsMap[se.id!] = sets;
      if (detail != null) detailsMap[se.exerciseId] = detail;
      bestWeightsMap[se.exerciseId] = benchmarks.weight;
      bestE1RMsMap[se.exerciseId] = benchmarks.e1rm;
      bestSetVolumesMap[se.exerciseId] = benchmarks.volume;
    }

    return SessionLoadResult(
      session: session,
      exercises: exercises,
      sets: setsMap,
      exerciseDetails: detailsMap,
      bestWeights: bestWeightsMap,
      bestE1RMs: bestE1RMsMap,
      bestSetVolumes: bestSetVolumesMap,
    );
  }

  static Future<SessionLoadResult> startWorkout({
    required int routineId,
    required String name,
    required List<RoutineExercise> routineExercises,
    required double userBodyweightKg,
    required dynamic db, // sqlite database for transaction
    required SessionsDao sessionsDao,
    required SetsDao setsDao,
  }) async {
    return await db.transaction((txn) async {
      final session = WorkoutSession(
        name: name,
        routineId: routineId,
        startedAt: DateTime.now().toIso8601String(),
      );

      final sessionId = await sessionsDao.insert(session,
          userBodyweightKg: userBodyweightKg, executor: txn);
      final sessionWithId = session.copyWith(id: sessionId);

      final setsMap = <int, List<SetEntry>>{};
      final sessionExercises = <SessionExercise>[];
      final detailsMap = <int, Exercise>{};

      for (var re in routineExercises) {
        final se = SessionExercise(
          sessionId: sessionId,
          exerciseId: re.exerciseId,
          orderIndex: re.orderIndex,
          targetSets: re.defaultSets,
          targetReps: re.defaultReps,
          targetRest: re.restSeconds,
        );
        final seId = await sessionsDao.insertExercise(se, executor: txn);

        final int setsToCreate = re.defaultSets > 0 ? re.defaultSets : 1;
        final createdSets = <SetEntry>[];

        for (int i = 1; i <= setsToCreate; i++) {
          final newSet = SetEntry(
            sessionExerciseId: seId,
            setNumber: i,
            weightKg: 0.0,
            reps: null,
            loggedAt: DateTime.now().toIso8601String(),
          );
          final setId = await setsDao.insert(newSet, executor: txn);
          createdSets.add(newSet.copyWith(id: setId));
        }

        final seWithId = se.copyWith(id: seId, exercise: re.exercise);
        sessionExercises.add(seWithId);
        setsMap[seId] = createdSets;
        if (re.exercise != null) detailsMap[re.exerciseId] = re.exercise!;
      }

      return SessionLoadResult(
        session: sessionWithId,
        exercises: sessionExercises,
        sets: setsMap,
        exerciseDetails: detailsMap,
      );
    });
  }

  static Future<SessionLoadResult> loadRoutinePreview({
    required Routine routine,
    required SetsDao setsDao,
  }) async {
    final routineExercises = routine.exercises ?? [];

    final previewExercises = <SessionExercise>[];
    final detailsMap = <int, Exercise>{};
    final setsMap = <int, List<SetEntry>>{};
    final previousSetsMap = <int, List<SetEntry>>{};
    final bestWeightsMap = <int, double>{};
    final bestE1RMsMap = <int, double>{};
    final bestVolumesMap = <int, double>{};

    for (int i = 0; i < routineExercises.length; i++) {
      final re = routineExercises[i];
      final se = SessionExercise(
        id: -(i + 1),
        sessionId: -1,
        exerciseId: re.exerciseId,
        orderIndex: i,
        targetSets: re.defaultSets,
        targetReps: re.defaultReps,
        targetRest: re.restSeconds,
        exercise: re.exercise,
      );
      previewExercises.add(se);
      if (re.exercise != null) {
        detailsMap[re.exerciseId] = re.exercise!;
      }

      // Load history for preview
      final benchmarks = await setsDao.getBestBenchmarksBefore(
          re.exerciseId, DateTime.now().toIso8601String());

      bestWeightsMap[re.exerciseId] = benchmarks.weight;
      bestE1RMsMap[re.exerciseId] = benchmarks.e1rm;
      bestVolumesMap[re.exerciseId] = benchmarks.volume;

      final pSets = await setsDao.getSetsFromLastCompletedSession(re.exerciseId);
      previousSetsMap[re.exerciseId] = pSets;

      final dummySets = List.generate(
          re.defaultSets > 0 ? re.defaultSets : 1,
          (idx) => SetEntry(
                sessionExerciseId: -(i + 1),
                setNumber: idx + 1,
                weightKg: 0.0,
                reps: null,
                isCompleted: false,
                loggedAt: DateTime.now().toIso8601String(),
              ));
      setsMap[-(i + 1)] = dummySets;
    }

    return SessionLoadResult(
      exercises: previewExercises,
      exerciseDetails: detailsMap,
      sets: setsMap,
      previousSets: previousSetsMap,
      bestWeights: bestWeightsMap,
      bestE1RMs: bestE1RMsMap,
      bestSetVolumes: bestVolumesMap,
    );
  }

  static NextSetRestDetails calculateNextSetRestDetails({
    required int? exerciseIndex,
    required List<SessionExercise> exercises,
    required Map<int, List<SetEntry>> sets,
    required Map<int, Exercise> exerciseDetails,
    required int? sessionRestOverride,
    required UserProfile profile,
  }) {
    int restSeconds = sessionRestOverride ?? 90;
    String? exName;
    String? nextSet;
    String? nextLoad;

    if (exerciseIndex != null && exerciseIndex < exercises.length) {
      final se = exercises[exerciseIndex];
      restSeconds = sessionRestOverride ?? se.targetRest;
      exName = exerciseDetails[se.exerciseId]?.name;

      final isLb = profile.weightUnit.toLowerCase() == 'lb';
      final currentSets = sets[se.id!] ?? [];
      final nextSetIdx = currentSets.indexWhere((s) => !s.isCompleted);

      if (nextSetIdx != -1) {
        exName = exerciseDetails[se.exerciseId]?.name;
        nextSet = 'Set ${nextSetIdx + 1} of ${currentSets.length}';
        final s = currentSets[nextSetIdx];
        if (s.weightKg > 0 && s.reps != null && s.reps! > 0) {
          final displayWeight = isLb
              ? WorkoutUtils.formatWeight(WorkoutUtils.kgToLb(s.weightKg))
              : WorkoutUtils.formatWeight(s.weightKg);
          final unit = isLb ? 'lb' : 'kg';
          nextLoad = '$displayWeight $unit x ${s.reps} reps';
        } else if (s.weightKg > 0) {
          final displayWeight = isLb
              ? WorkoutUtils.formatWeight(WorkoutUtils.kgToLb(s.weightKg))
              : WorkoutUtils.formatWeight(s.weightKg);
          final unit = isLb ? 'lb' : 'kg';
          nextLoad = '$displayWeight $unit';
        } else if (s.reps != null && s.reps! > 0) {
          nextSet += ' (${s.reps} reps)';
        }
      } else {
        // Look ahead to next exercise
        for (int i = exerciseIndex + 1; i < exercises.length; i++) {
          final nextSE = exercises[i];
          final nSets = sets[nextSE.id!] ?? [];
          final nIdx = nSets.indexWhere((s) => !s.isCompleted);
          if (nIdx != -1) {
            exName = exerciseDetails[nextSE.exerciseId]?.name;
            nextSet = 'Set ${nIdx + 1} of ${nSets.length}';
            final s = nSets[nIdx];
            if (s.weightKg > 0 && s.reps != null && s.reps! > 0) {
              final displayWeight = isLb
                  ? WorkoutUtils.formatWeight(WorkoutUtils.kgToLb(s.weightKg))
                  : WorkoutUtils.formatWeight(s.weightKg);
              final unit = isLb ? 'lb' : 'kg';
              nextLoad = '$displayWeight $unit x ${s.reps} reps';
            } else if (s.weightKg > 0) {
              final displayWeight = isLb
                  ? WorkoutUtils.formatWeight(WorkoutUtils.kgToLb(s.weightKg))
                  : WorkoutUtils.formatWeight(s.weightKg);
              final unit = isLb ? 'lb' : 'kg';
              nextLoad = '$displayWeight $unit';
            } else if (s.reps != null && s.reps! > 0) {
              nextSet += ' (${s.reps} reps)';
            }
            break;
          }
        }
      }
    }

    return NextSetRestDetails(
      restSeconds: restSeconds,
      exerciseName: exName,
      nextSetInfo: nextSet,
      nextWeightRepsInfo: nextLoad,
    );
  }
}
