import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/set_entry.dart';
import '../../data/models/session_exercise.dart';
import '../../data/models/workout_session.dart';
import '../../data/models/exercise.dart';
import '../../core/utils/workout_utils.dart';
import '../../data/daos/sessions_dao.dart';
import '../../data/daos/sets_dao.dart';
import '../../data/models/user_profile.dart';

class WorkoutPersistenceManager {
  /// Flushes all pending set updates to the database immediately.
  /// Typically called when the app is paused, inactive, or disposed.
  static Future<void> flushPendingSets({
    required Map<int, Timer> debouncers,
    required Map<int, List<SetEntry>> setsMap,
    required List<SessionExercise> exercises,
    required Map<int, Exercise> exerciseDetails,
    required WorkoutSession? session,
    required UserProfile profile,
    required SetsDao setDao,
    required SessionsDao sessionsDao,
  }) async {
    if (debouncers.isEmpty) return;

    debugPrint('GRIT: Persistence flush triggered for ${debouncers.length} pending updates');

    // Copy and clear debouncers to prevent concurrent modification
    final timers = Map<int, Timer>.from(debouncers);
    debouncers.clear();

    final updateSets = <SetEntry>[];

    for (final entry in timers.entries) {
      if (entry.value.isActive) {
        entry.value.cancel();

        final setId = entry.key;
        SetEntry? targetSet;
        
        // Find the set in the current state
        for (final list in setsMap.values) {
          final found = list.where((s) => s.id == setId);
          if (found.isNotEmpty) {
            targetSet = found.first;
            break;
          }
        }

        if (targetSet != null) {
          debugPrint('GRIT: Immediate sync for set $setId');
          updateSets.add(targetSet);
        }
      }
    }

    try {
      if (updateSets.isNotEmpty) {
        await setDao.updateTransaction(updateSets);
      }
    } catch (e) {
      debugPrint('GRIT ERROR: Lifecycle flush sets failed: $e');
    }

    // Update final session volume
    if (session?.id != null) {
      try {
        final exTypesMap = {
          for (final se in exercises)
            se.id!: exerciseDetails[se.exerciseId]?.type ?? 'weighted'
        };
        final volume = WorkoutUtils.calculateTotalVolume(setsMap, exTypesMap, profile.weightKg);
        await sessionsDao.updateSessionVolume(session!.id!, volume);
      } catch (e) {
        debugPrint('GRIT ERROR: Lifecycle volume update failed: $e');
      }
    }
  }
}
