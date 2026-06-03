import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dao_providers.dart';
import 'profile_provider.dart';
import 'date_provider.dart';
import '../data/models/workout_muscles.dart';
import '../data/models/today_workout_stats.dart';
import '../core/utils/workout_utils.dart';
import '../core/utils/muscle_metric_utils.dart';
import 'metrics_provider.dart';

class DashboardWorkoutData {
  final WorkoutMuscles muscles;
  final TodayWorkoutStats stats;

  DashboardWorkoutData({required this.muscles, required this.stats});

  factory DashboardWorkoutData.empty() => DashboardWorkoutData(
        muscles: WorkoutMuscles.empty(),
        stats: TodayWorkoutStats.empty(),
      );
}

/// Unified provider for all "Today" or "Selected Day" workout metrics.
/// This replaces multiple redundant providers hitting the same DAO methods.
final dashboardWorkoutProvider =
    FutureProvider<DashboardWorkoutData>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final dao = ref.watch(sessionsDaoProvider);
  
  // Watch all muscle summaries to find the global "Weakest Link" (Needs Attention)
  final muscleSummariesAsync = ref.watch(muscleGroupSummariesProvider);

  final dateIso =
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
          .toIso8601String();

  final isRest = await dao.isRestDay(dateIso);
  final raw = await dao.getMuscleDistributionRaw(dateIso);

  if (raw.isEmpty) {
    // Determine global weakest link even on rest days for tactical guidance
    String? globalWeakest;
    if (muscleSummariesAsync.hasValue && muscleSummariesAsync.value!.isNotEmpty) {
      globalWeakest = muscleSummariesAsync.value!.first.name;
    } else {
      try {
        final list = await ref.read(muscleGroupSummariesProvider.future);
        if (list.isNotEmpty) {
          globalWeakest = list.first.name;
        }
      } catch (_) {}
    }

    return DashboardWorkoutData(
      muscles: WorkoutMuscles.empty(),
      stats: TodayWorkoutStats(
        totalVolume: 0,
        dominantMuscle: null,
        weakestMuscle: globalWeakest,
        muscleVolumes: {},
        isRestDay: isRest,
      ),
    );
  }

  // 1. Calculate Today's Stats with Unified 50% Secondary logic
  final Map<String, double> volumesPerMuscle = MuscleMetricUtils.processMuscleVolumes(raw);
  
  // Calculate raw total volume (Primary only to avoid double-counting the athlete's output)
  double totalVolume = 0;
  for (final r in raw) {
    totalVolume += (r['total_volume'] as num?)?.toDouble() ?? 0.0;
  }

  final Set<String> primarySet = {};
  final Set<String> secondarySet = {};
  
  for (final r in raw) {
    final group = (r['muscle_group'] as String? ?? '').toUpperCase();
    final secondariesStr = (r['secondary_muscles'] as String? ?? '').toUpperCase();
    
    if (group.isNotEmpty) primarySet.add(group);
    if (secondariesStr.isNotEmpty) {
      final parts = secondariesStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty && s != group);
      secondarySet.addAll(parts);
    }
  }
  secondarySet.removeAll(primarySet);
  final muscles = WorkoutMuscles(primary: primarySet, secondary: secondarySet);

  // 2. Determine Dominant and Weakest for this specific day
  String? dominant;
  String? dayWeakest;
  double maxVol = -1.0;
  double minVol = double.infinity;

  if (volumesPerMuscle.isNotEmpty) {
    volumesPerMuscle.forEach((muscle, volume) {
      if (volume > maxVol) {
        maxVol = volume;
        dominant = muscle;
      }
      if (volume < minVol) {
        minVol = volume;
        dayWeakest = muscle;
      }
    });
  }

  // Tactical fallback for rest days or empty days: use global strategic weakest
  String? finalWeakest = dayWeakest;
  if (finalWeakest == null) {
    if (muscleSummariesAsync.hasValue && muscleSummariesAsync.value!.isNotEmpty) {
      finalWeakest = muscleSummariesAsync.value!.first.name;
    } else {
      try {
        final list = await ref.read(muscleGroupSummariesProvider.future);
        if (list.isNotEmpty) {
          finalWeakest = list.first.name;
        }
      } catch (_) {}
    }
  }

  return DashboardWorkoutData(
    muscles: muscles,
    stats: TodayWorkoutStats(
      totalVolume: totalVolume.roundToDouble(), 
      dominantMuscle: dominant,
      weakestMuscle: finalWeakest,
      muscleVolumes: volumesPerMuscle,
      isRestDay: isRest,
    ),
  );
});

class DashboardData {
  final int sessionCount;
  final List<double> dailyVolumes;
  final double weeklyTotal;
  final double lastWeekTotal;
  final List<bool> trainedDays;
  final List<bool> restDays;

  DashboardData({
    required this.sessionCount,
    required this.dailyVolumes,
    required this.weeklyTotal,
    required this.lastWeekTotal,
    required this.trainedDays,
    required this.restDays,
  });
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final profile = ref.watch(profileProvider);
  final now = ref.watch(selectedDateProvider);
  final monday = WorkoutUtils.getStartOfWeek(now, profile.firstDayOfWeek);
  final mondayIso = monday.toIso8601String();

  final sDao = ref.watch(sessionsDaoProvider);
  final count = await sDao.getWeeklySessionCount(mondayIso);
  final active = await sDao.getActive();
  final volumes = await sDao.getDailyVolumesForWeek(mondayIso);
  final trained = await sDao.getTrainedDaysForWeek(mondayIso);
  final rests = await sDao.getRestDaysForWeek(mondayIso);

  final lastMonday = monday.subtract(const Duration(days: 7));
  final lastMondayIso = lastMonday.toIso8601String();
  final lastVolumes = await sDao.getDailyVolumesForWeek(lastMondayIso);

  double total = volumes.fold(0, (sum, item) => sum + item);
  double lastTotal = lastVolumes.fold(0, (sum, item) => sum + item);

  int displayCount = count;
  if (active != null) {
    if (DateTime.parse(active.startedAt).isAfter(monday) ||
        DateTime.parse(active.startedAt).isAtSameMomentAs(monday)) {
      displayCount++;
    }
  }

  return DashboardData(
    sessionCount: displayCount,
    dailyVolumes: volumes,
    weeklyTotal: total,
    lastWeekTotal: lastTotal,
    trainedDays: trained,
    restDays: rests,
  );
});
