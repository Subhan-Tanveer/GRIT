import '../../data/models/user_profile.dart';
import '../../data/models/session_exercise.dart';
import '../../data/models/set_entry.dart';
import '../../data/models/exercise.dart';
import '../../core/utils/workout_utils.dart';

class WorkoutNotificationData {
  final String? setInfo;
  final String? weightInfo;
  final String? repsInfo;
  final String exerciseName;
  final int currentIndex;

  WorkoutNotificationData({
    this.setInfo,
    this.weightInfo,
    this.repsInfo,
    required this.exerciseName,
    required this.currentIndex,
  });
}

class WorkoutNotificationManager {
  static WorkoutNotificationData? calculateNotificationData({
    required List<SessionExercise> exercises,
    required Map<int, List<SetEntry>> sets,
    required Map<int, Exercise> exerciseDetails,
    required int? restingExerciseIndex,
    required UserProfile profile,
  }) {
    if (exercises.isEmpty) return null;

    SessionExercise? currentSE;
    int currentIndex = -1;

    // 1. Identify current exercise (either resting or first incomplete)
    if (restingExerciseIndex != null &&
        restingExerciseIndex < exercises.length) {
      currentIndex = restingExerciseIndex;
      currentSE = exercises[currentIndex];
    } else {
      for (int i = 0; i < exercises.length; i++) {
        final se = exercises[i];
        final exerciseSets = sets[se.id] ?? [];
        if (exerciseSets.any((s) => !s.isCompleted)) {
          currentSE = se;
          currentIndex = i;
          break;
        }
      }
      if (currentSE == null && exercises.isNotEmpty) {
        currentSE = exercises.last;
        currentIndex = exercises.length - 1;
      }
    }

    if (currentSE == null) return null;

    final detail = exerciseDetails[currentSE.exerciseId];
    final currentExName = detail?.name ?? 'EXERCISE';

    final exerciseSets = sets[currentSE.id] ?? [];
    final total = exerciseSets.length;
    final activeSetIndex = exerciseSets.indexWhere((s) => !s.isCompleted);
    final displaySetNum = activeSetIndex != -1 ? activeSetIndex + 1 : total;
    final activeSet = activeSetIndex != -1
        ? exerciseSets[activeSetIndex]
        : (exerciseSets.isNotEmpty ? exerciseSets.last : null);

    final isLb = profile.weightUnit.toLowerCase() == 'lb';
    final unit = isLb ? 'lb' : 'kg';

    String? setInfo = 'Set $displaySetNum of $total';
    String? weightInfo;
    String? repsInfo;

    if (activeSet != null && activeSet.weightKg > 0) {
      final displayWeight = isLb
          ? WorkoutUtils.formatWeight(WorkoutUtils.kgToLb(activeSet.weightKg))
          : WorkoutUtils.formatWeight(activeSet.weightKg);
      weightInfo = '$displayWeight $unit';
    }

    if (activeSet != null && activeSet.reps != null && activeSet.reps! > 0) {
      repsInfo = activeSet.reps.toString();
    }

    return WorkoutNotificationData(
      exerciseName: currentExName,
      setInfo: setInfo,
      weightInfo: weightInfo,
      repsInfo: repsInfo,
      currentIndex: currentIndex,
    );
  }
}
