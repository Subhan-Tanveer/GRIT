import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/models/set_entry.dart';
import '../../data/models/routine.dart';

class WorkoutUtils {
  static String formatWeight(double value) {
    if (value == value.toInt().toDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }

  static String formatDecimal(double? value) {
    if (value == null) return '0';
    if (value == value.toInt().toDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }

  static String formatVolume(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return formatDecimal(value);
  }

  static double calculateEffectiveLoad(double weight, String exerciseType, double userBodyweight) {
    if (exerciseType == 'assisted_bodyweight') {
      return (userBodyweight - weight).clamp(0.0, double.infinity);
    } else if (exerciseType == 'bodyweight') {
      return (userBodyweight + weight);
    }
    return weight;
  }

  static double calculateSetVolume(SetEntry s, String exerciseType, double userBodyweight) {
    if (!s.isCompleted || s.setType == SetEntryType.warmup) return 0.0;
    final reps = s.reps ?? 0;
    final effectiveLoad = calculateEffectiveLoad(s.weightKg, exerciseType, userBodyweight);
    return effectiveLoad * reps;
  }

  static double calculateTotalVolume(Map<int, List<SetEntry>> setsMap, Map<int, String> exerciseTypes, double userBodyweight) {
    double total = 0;
    for (final entry in setsMap.entries) {
      final type = exerciseTypes[entry.key] ?? 'weighted';
      for (final s in entry.value) {
        total += calculateSetVolume(s, type, userBodyweight);
      }
    }
    return total;
  }

  static double calculateSessionVolume(List<List<SetEntry>> allSets, List<String> exerciseTypes, double userBodyweight) {
    double total = 0;
    for (int i = 0; i < allSets.length; i++) {
      final type = exerciseTypes.length > i ? exerciseTypes[i] : 'weighted';
      for (final s in allSets[i]) {
        total += calculateSetVolume(s, type, userBodyweight);
      }
    }
    return total;
  }

  static double calculateE1RM(double weight, int reps) {
    if (reps <= 0) return 0.0;
    if (reps == 1) return weight;
    // Align with SQL (Brzycki): weight * (36 / (37 - reps))
    final cappedReps = reps > 36 ? 36 : reps;
    return weight * (36.0 / (37.0 - cappedReps));
  }

  static int estimateRoutineMinutes(Routine routine) {
    final exercises = routine.exercises ?? [];
    if (exercises.isEmpty) return 0;
    int totalSec = 0;
    for (final ex in exercises) {
      final sets = ex.defaultSets;
      final reps = parseAvgReps(ex.defaultReps);
      // Assume 3s per rep + rest period
      totalSec += (ex.restSeconds * (sets - 1)) +
          (sets * reps * 4) +
          60; // 60s setup time
    }
    return (totalSec / 60).ceil();
  }

  static int parseAvgReps(String repsStr) {
    if (repsStr.contains('-')) {
      final parts = repsStr.split('-');
      final lo = int.tryParse(parts[0].trim()) ?? 8;
      final hi = int.tryParse(parts[1].trim()) ?? 12;
      return ((lo + hi) / 2).round();
    }
    return int.tryParse(repsStr.trim()) ?? 8;
  }

  static ({int current, int best}) calculateStreaks(
      List<DateTime> trainedDays, List<DateTime> restDays,
      {int firstDayOfWeek = 1}) {
    if (trainedDays.isEmpty) return (current: 0, best: 0);

    // 1. Normalize and Sort
    final trainedSet = trainedDays
        .map((d) => DateTime.utc(d.year, d.month, d.day))
        .toSet();
    final sortedTrained = trainedSet.toList()..sort((a, b) => a.compareTo(b));
    final restSet = restDays
        .map((d) => DateTime.utc(d.year, d.month, d.day))
        .toSet();

    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    // 2. Helper to find the start of the current intentional chain
    // A streak is continuous as long as we don't hit 3 consecutive "Ghost Days"
    // A Ghost Day is a day that is NOT a workout and NOT a marked rest day.
    
    int calculateIntentionalStreak(DateTime endDate) {
      if (sortedTrained.isEmpty) return 0;
      
      // Find the last "Valid" or "Allowed Grace" day ending at or before endDate
      // A day is valid if it's a workout or a marked rest day.
      
      // First, check if the current period is already broken (3+ consecutive ghost days)
      DateTime check = endDate;
      int ghostCount = 0;
      while (ghostCount < 3) {
        if (trainedSet.contains(check) || restSet.contains(check)) {
          // Found a valid anchor
          break;
        } else {
          ghostCount++;
          check = check.subtract(const Duration(days: 1));
        }
      }
      
      if (ghostCount >= 3) return 0; // Streak is currently broken
      endDate = check; // Terminate calculation at the last actual active/valid anchor day

      // Now we know we are in an active chain. Find where it started.
      // We walk backwards from 'endDate' and look for a 3-day ghost gap.
      
      // We need to find the earliest day such that no 3-day ghost gap exists between it and endDate
      // and it must start with a valid day (Workout or Rest).
      
      // Actually, it's easier to find all 3-day ghost gaps in history and take the most recent one.
      DateTime streakStart = sortedTrained.first;
      
      // Scan all days from first workout to endDate
      DateTime scan = sortedTrained.first;
      int currentGhosts = 0;
      while (!scan.isAfter(endDate)) {
        if (trainedSet.contains(scan) || restSet.contains(scan)) {
          currentGhosts = 0;
        } else {
          currentGhosts++;
          if (currentGhosts >= 3) {
            // Gap found! The streak starts over at the next valid day.
            // But we don't know the next valid day yet. 
            // We'll set a flag to reset streakStart at the next valid day.
            streakStart = scan.add(const Duration(days: 1)); 
          }
        }
        scan = scan.add(const Duration(days: 1));
      }
      
      // After the loop, if streakStart is on a ghost day, move it forward to the first valid day
      while (streakStart.isBefore(endDate) && 
             !trainedSet.contains(streakStart) && 
             !restSet.contains(streakStart)) {
        streakStart = streakStart.add(const Duration(days: 1));
      }

      if (streakStart.isAfter(endDate)) return 0;
      return endDate.difference(streakStart).inDays + 1;
    }

    // 3. Current Streak
    final current = calculateIntentionalStreak(today);

    // 4. Best Streak (All-time)
    int best = 0;
    // We only need to check the 'ends' of workout chains to find the max
    for (final workoutDate in sortedTrained) {
      final streakAtDate = calculateIntentionalStreak(workoutDate);
      if (streakAtDate > best) best = streakAtDate;
    }
    
    // Also check if the current streak (which might end today, after the last workout) is the best
    if (current > best) best = current;

    return (current: current, best: best);
  }

  static const double kgToLbConstant = 2.20462;
  static const double cmToInConstant = 0.393701;

  static double kgToLb(double kg) => kg * kgToLbConstant;
  static double lbToKg(double lb) => lb / kgToLbConstant;
  static double cmToIn(double cm) => cm * cmToInConstant;
  static double inToCm(double inches) => inches / cmToInConstant;

  static String formatHeight(double? cm, String unit) {
    if (cm == null) return '--';
    if (unit == 'FT·IN' || unit == 'FT-IN' || unit == 'FT/IN') {
      final totalInches = cm * cmToInConstant;
      int feet = (totalInches / 12).floor();
      int inches = (totalInches % 12).round();
      if (inches == 12) {
        feet++;
        inches = 0;
      }
      return "$feet' $inches\"";
    }
    return "${cm.round()} CM";
  }

  static DateTime getStartOfWeek(DateTime now, int firstDayOfWeek) {
    int daysToSubtract;
    if (firstDayOfWeek == 7) {
      daysToSubtract = now.weekday % 7;
    } else {
      daysToSubtract = now.weekday - 1;
    }
    final date = now.subtract(Duration(days: daysToSubtract));
    return DateTime(date.year, date.month, date.day);
  }

  // normalizeMuscle purged. Use MuscleMapper.toSvgId(name) for logic-driven mapping.
  // Prebuilt exercises already have normalized muscleGroup via Exercise.fromJson.

  static IconData getMuscleIcon(String muscle) {
    final m = muscle.toLowerCase();
    
    if (m.contains('chest')) return PhosphorIcons.barbell();
    
    if (m.contains('back') || m.contains('lat') || m.contains('trap')) {
      return PhosphorIcons.rows();
    }
    
    if (m.contains('shoulder') || m.contains('delt')) {
      return PhosphorIcons.arrowsOut();
    }
    
    if (m.contains('biceps') || m.contains('triceps') || m.contains('forearm')) {
      return PhosphorIcons.armchair(); 
    }
    
    if (m.contains('quad') || m.contains('ham') || m.contains('glute') || m.contains('calve')) {
      return PhosphorIcons.steps();
    }
    
    if (m.contains('core') || m.contains('abs') || m.contains('oblique')) {
      return PhosphorIcons.gridFour();
    }
    
    if (m.contains('cardio')) return PhosphorIcons.heartbeat();
    
    return PhosphorIcons.chartLine();
  }

  static bool isPersonalRecord(
    SetEntry set, {
    required double bestWeightBefore,
    required double bestE1RMBefore,
    required double bestSetVolumeBefore,
    required String exerciseType,
    required double userBodyweight,
  }) {
    if (!set.isCompleted || set.setType == SetEntryType.warmup) return false;
    final reps = set.reps ?? 0;
    if (reps <= 0) return false;

    // Use Effective Load for all comparisons to handle Assisted/Bodyweight correctly
    final currentWeight = calculateEffectiveLoad(set.weightKg, exerciseType, userBodyweight);
    final currentE1RM = calculateE1RM(currentWeight, reps);
    final currentSetVolume = currentWeight * reps;

    // A PR is achieved if any metric beats the historical best
    final isWeightPr = currentWeight > bestWeightBefore + 0.001;
    final isE1rmPr = currentE1RM > bestE1RMBefore + 0.001;
    final isVolumePr = currentSetVolume > bestSetVolumeBefore + 0.001;

    return isWeightPr || isE1rmPr || isVolumePr;
  }
}
