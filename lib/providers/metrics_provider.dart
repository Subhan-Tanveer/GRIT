import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dao_providers.dart';
import 'profile_provider.dart';
import 'date_provider.dart';
import '../data/models/body_weight_entry.dart';
import '../data/models/body_measurement_entry.dart';
import '../data/models/workout_session.dart';
import '../data/models/muscle_analysis.dart';
import '../core/utils/workout_utils.dart';
import '../core/utils/muscle_metric_utils.dart';

enum AnalysisViewMode { muscles, history }
enum ExerciseAnalysisMetric { e1rm, volume, weight }

final analysisViewModeProvider = StateProvider<AnalysisViewMode>((ref) => AnalysisViewMode.muscles);
final exerciseAnalysisMetricProvider = StateProvider.family<ExerciseAnalysisMetric, int>((ref, exId) => ExerciseAnalysisMetric.e1rm);

final bodyWeightProvider = FutureProvider<List<BodyWeightEntry>>((ref) {
  return ref.watch(bodyWeightDaoProvider).getAll();
});

final latestMeasurementsProvider = FutureProvider<BodyMeasurementEntry?>((ref) {
  return ref.watch(bodyMeasurementDaoProvider).getLatest();
});

final measurementHistoryProvider = FutureProvider<List<BodyMeasurementEntry>>((ref) {
  return ref.watch(bodyMeasurementDaoProvider).getAll();
});

final measurementTrendsProvider =
    FutureProvider.family<List<({DateTime date, double value})>, String>(
        (ref, site) async {
  final history = await ref.watch(bodyMeasurementDaoProvider).getAll();
  final dataPoints = history
      .where((e) {
        final map = e.toMap();
        return map[site] != null;
      })
      .map((e) {
        final map = e.toMap();
        return (
          date: DateTime.parse(e.createdAt),
          value: (map[site] as num).toDouble(),
        );
      })
      .toList()
      .reversed
      .toList();
  return dataPoints;
});

final allFinishedSessionsProvider = FutureProvider<List<WorkoutSession>>((ref) {
  return ref.watch(sessionsDaoProvider).getAllFinished();
});

final lastSessionProvider = FutureProvider<WorkoutSession?>((ref) async {
  final sDao = ref.watch(sessionsDaoProvider);
  final sessions = await sDao.getAllFinishedWithExercises(limit: 1);
  if (sessions.isEmpty) return null;
  return sessions.first;
});

final streakProvider = FutureProvider<({int current, int best})>((ref) async {
  final sDao = ref.watch(sessionsDaoProvider);
  final profile = ref.watch(profileProvider);
  // Watch date to ensure streak recalculates at midnight
  ref.watch(selectedDateProvider);
  
  final trainedDays = await sDao.getAllTrainedDays();
  final restDays = await sDao.getAllRestDays();
  
  return WorkoutUtils.calculateStreaks(
    trainedDays, 
    restDays,
    firstDayOfWeek: profile.firstDayOfWeek,
  );
});

final muscleAnalysisProvider = FutureProvider.family<MuscleAnalysisData, String>(
    (ref, muscleGroup) async {
  final dao = ref.watch(sessionsDaoProvider);
  final trendRows = await dao.getDetailedMuscleVolumeHistory(muscleGroup);
  final exerciseRows = await dao.getMuscleExerciseStats(muscleGroup);
  
  double totalVolume = 0;
  int totalReps = 0;
  double peakE1RM = 0;

  // STEP 1: Calculate Peak E1RM first to avoid circular dependency in intensity trend
  final List<MuscleExerciseStat> exerciseStats = exerciseRows.map((row) {
    final weight = (row['best_weight'] as num?)?.toDouble() ?? 0.0;
    final reps = (row['best_reps'] as int?) ?? 1;
    final e1rm = MuscleMetricUtils.calculateE1RM(weight, reps);
    if (e1rm > peakE1RM) peakE1RM = e1rm;

    return MuscleExerciseStat(
      exerciseId: row['exercise_id'] as int,
      name: row['name'] as String,
      bestWeight: weight,
      bestE1RM: e1rm,
      totalSets: row['total_sets'] as int,
      totalVolume: (row['total_volume'] as num?)?.toDouble() ?? 0.0,
    );
  }).toList();

  // STEP 2: Process daily history using the pre-calculated peakE1RM
  final List<Map<String, dynamic>> dailyHistory = [];
  for (final row in trendRows) {
    final v = (row['volume'] as num?)?.toDouble() ?? 0.0;
    final r = (row['total_reps'] as int?) ?? 0;
    final maxE1RMInSession = (row['max_e1rm'] as num?)?.toDouble() ?? 0.0;
    
    totalVolume += v;
    totalReps += r;
    
    // Intensity as % of Lifetime Peak Capacity
    final sessionIntensity = peakE1RM > 0 ? (maxE1RMInSession / peakE1RM) * 100 : 0.0;
    
    dailyHistory.add({
      'day': row['day'],
      'volume': v,
      'intensity': sessionIntensity,
      'e1rm': maxE1RMInSession,
    });
  }

  // Calculate trends and averages
  final lifetimeAvgLoad = totalReps > 0 ? totalVolume / totalReps : 0.0;
  double intensityTrend = 0;
  if (dailyHistory.length >= 2) {
    final currentIntensity = dailyHistory.last['intensity'] as double;
    final prevIntensity = dailyHistory[dailyHistory.length - 2]['intensity'] as double;
    if (prevIntensity > 0) {
      intensityTrend = ((currentIntensity - prevIntensity) / prevIntensity) * 100;
    }
  }

  return MuscleAnalysisData(
    muscleGroup: muscleGroup,
    totalSessions: trendRows.length,
    totalVolume: totalVolume,
    avgIntensity: lifetimeAvgLoad, // Average weight per rep
    lifetimeAvgIntensity: lifetimeAvgLoad,
    sessionTrend: intensityTrend,
    peakE1RM: peakE1RM,
    dailyHistory: dailyHistory,
    exerciseStats: exerciseStats,
  );
});

final muscleGroupSummariesProvider =
    FutureProvider<List<MuscleGroupSummary>>((ref) async {
  final dao = ref.watch(sessionsDaoProvider);
  
  // 1. Fetch raw datasets for all-time and recent intervals
  final allStatsRaw = await dao.getAllTimeMuscleStats();
  if (allStatsRaw.isEmpty) return [];
  
  final recentStatsRaw = await dao.getRecentMuscleStats(30);

  // 2. Process volumes with consistent 50% secondary credit
  final Map<String, double> lifetimeVolumeMap = MuscleMetricUtils.processMuscleVolumes(allStatsRaw);
  final Map<String, double> recentVolumeMap = MuscleMetricUtils.processMuscleVolumes(recentStatsRaw);

  // Filter to only include muscle groups that have been trained as a primary muscle group
  final primaryMuscleGroups = allStatsRaw
      .map((row) => (row['muscle_group'] as String? ?? '').toUpperCase())
      .where((name) => name.isNotEmpty)
      .toSet();

  lifetimeVolumeMap.removeWhere((key, _) => !primaryMuscleGroups.contains(key));
  recentVolumeMap.removeWhere((key, _) => !primaryMuscleGroups.contains(key));

  // 3. Aggregate metadata (sessions, sets, last trained) across raw rows
  final Map<String, int> sessionMap = {};
  final Map<String, int> setMap = {};
  final Map<String, DateTime?> lastTrainedMap = {};
  
  for (final row in allStatsRaw) {
    // Note: SQL now returns muscle_group directly (no 'name' alias)
    final name = (row['muscle_group'] as String? ?? '').toUpperCase();
    if (name.isEmpty) continue;
    
    sessionMap[name] = (sessionMap[name] ?? 0) + (row['workouts'] as int? ?? 0);
    setMap[name] = (setMap[name] ?? 0) + (row['working_sets'] as int? ?? 0);
    
    final lastStr = row['last_trained'] as String?;
    if (lastStr != null) {
      final date = DateTime.parse(lastStr);
      if (lastTrainedMap[name] == null || date.isAfter(lastTrainedMap[name]!)) {
        lastTrainedMap[name] = date;
      }
    }
  }

  // 4. Calculate global stats for proportion logic
  double totalAllTimeVolume = 0;
  lifetimeVolumeMap.forEach((_, vol) => totalAllTimeVolume += vol);
  
  double totalRecentVolume = 0;
  recentVolumeMap.forEach((_, vol) => totalRecentVolume += vol);

  final List<({String name, double momentum})> momentumList = [];
  final now = ref.watch(selectedDateProvider);

  // 5. Build summaries and find max momentum
  for (final name in lifetimeVolumeMap.keys) {
    final lifetimeVol = lifetimeVolumeMap[name] ?? 0.0;
    final recentVol = recentVolumeMap[name] ?? 0.0;
    
    // Momentum = 70% Recent + 30% Lifetime
    final momentum = (recentVol * 0.70) + (lifetimeVol * 0.30);
    momentumList.add((name: name, momentum: momentum));
  }

  final maxMomentum = momentumList.isEmpty 
      ? 0.0 
      : momentumList.map((m) => m.momentum).reduce((a, b) => a > b ? a : b);

  final List<MuscleGroupSummary> results = [];
  for (final name in lifetimeVolumeMap.keys) {
    final lifetimeVol = lifetimeVolumeMap[name] ?? 0.0;
    final recentVol = recentVolumeMap[name] ?? 0.0;
    
    final volumeProp = totalAllTimeVolume > 0 ? lifetimeVol / totalAllTimeVolume : 0.0;
    final recentProp = totalRecentVolume > 0 ? recentVol / totalRecentVolume : 0.0;
    
    final lastTrained = lastTrainedMap[name];
    final daysSinceLast = lastTrained != null ? now.difference(lastTrained).inDays : 999;

    final rank = MuscleMetricUtils.calculateRank(
      volumeProportion: volumeProp,
      recentVolumeProportion: recentProp,
      daysSinceLastTrained: daysSinceLast,
    ).label;

    final score = MuscleMetricUtils.calculateMomentumScore(
      lifetimeVolume: lifetimeVol,
      recentVolume: recentVol,
      maxMomentumAcrossGroups: maxMomentum,
    );

    results.add(MuscleGroupSummary(
      name: name,
      exerciseCount: 0,
      workoutCount: sessionMap[name] ?? 0,
      totalVolume: lifetimeVol,
      totalSessions: sessionMap[name] ?? 0,
      totalSets: setMap[name] ?? 0,
      lastTrainedDate: lastTrained,
      rank: rank,
      score: score,
    ));
  }

  final statusOrder = {
    'NEEDS ATTENTION': 0,
    'NEGLECTED': 1,
    'CONSISTENT': 2,
    'DOMINANT': 3,
  };

  results.sort((a, b) {
    int cmp = (statusOrder[a.rank] ?? 99).compareTo(statusOrder[b.rank] ?? 99);
    if (cmp != 0) return cmp;
    return b.totalVolume.compareTo(a.totalVolume);
  });

  return results;
});
