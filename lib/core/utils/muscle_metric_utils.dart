import 'workout_utils.dart';

enum MuscleRank {
  dominant,
  consistent,
  neglected,
  needsAttention,
}

extension MuscleRankExtension on MuscleRank {
  String get label {
    switch (this) {
      case MuscleRank.dominant:
        return 'DOMINANT';
      case MuscleRank.consistent:
        return 'CONSISTENT';
      case MuscleRank.neglected:
        return 'NEGLECTED';
      case MuscleRank.needsAttention:
        return 'NEEDS ATTENTION';
    }
  }
}

class MuscleMetricUtils {
  /// Standardized threshold for a "Dominant" muscle in terms of total all-time volume proportion.
  static const double dominantThreshold = 0.40;

  /// Standardized threshold for a "Neglected" muscle in terms of total all-time volume proportion.
  static const double neglectedThreshold = 0.05;

  /// Threshold for "Needs Attention" in terms of days since last trained.
  static const int inactivityThresholdDays = 7; // Tightened from 14 for professional rigor

  /// Calculates the rank of a muscle group based on weighted momentum.
  static MuscleRank calculateRank({
    required double volumeProportion,
    required double recentVolumeProportion,
    required int daysSinceLastTrained,
  }) {
    // Priority 1: Inactivity is an immediate flag
    if (daysSinceLastTrained > inactivityThresholdDays) {
      return MuscleRank.needsAttention;
    }

    // Priority 2: Use a weighted momentum score
    // Recent volume contributes 70%, Lifetime contributes 30%
    final momentumScore = (recentVolumeProportion * 0.7) + (volumeProportion * 0.3);

    if (momentumScore > dominantThreshold) {
      return MuscleRank.dominant;
    }
    if (momentumScore < neglectedThreshold) {
      return MuscleRank.neglected;
    }
    return MuscleRank.consistent;
  }

  /// Calculates a normalized momentum-weighted score (0-100) for UI progress bars.
  /// (RecentVolume * 0.7 + LifetimeTotal * 0.3) compared against the top performer.
  static double calculateMomentumScore({
    required double lifetimeVolume,
    required double recentVolume,
    required double maxMomentumAcrossGroups,
  }) {
    if (maxMomentumAcrossGroups <= 0) return 0;
    
    final currentMomentum = (recentVolume * 0.70) + (lifetimeVolume * 0.30);
    return (currentMomentum / maxMomentumAcrossGroups) * 100;
  }

  /// Unified logic to process raw volume rows and attribute 50% benefit to secondary muscles.
  /// Returns a map of MuscleGroup -> Total Weighted Volume.
  static Map<String, double> processMuscleVolumes(List<Map<String, dynamic>> rawRows) {
    final Map<String, double> volumes = {};
    for (final r in rawRows) {
      final primary = (r['muscle_group'] as String? ?? '').toUpperCase();
      final secondaries = (r['secondary_muscles'] as String? ?? '').toUpperCase();
      final volume = (r['total_volume'] as num?)?.toDouble() ?? 0.0;

      if (primary.isNotEmpty) {
        volumes[primary] = (volumes[primary] ?? 0) + volume;
      }
      
      if (secondaries.isNotEmpty) {
        final parts = secondaries
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s != primary);
        
        for (final s in parts) {
          // Attribute 50% credit as an industrial-standard for compound benefit
          volumes[s] = (volumes[s] ?? 0) + (volume * 0.5);
        }
      }
    }
    return volumes;
  }

  /// Provides a unified formula for E1RM (centralized in WorkoutUtils).
  static double calculateE1RM(double weight, int reps) {
    return WorkoutUtils.calculateE1RM(weight, reps);
  }
}
