import 'package:vibration/vibration.dart';

/// Premium haptic vocabulary for GRIT.
///
/// Each method is named for its semantic meaning, not its physical weight.
/// Pattern arrays: [delay, duration, delay, duration, ...] in ms.
/// Single-buzz methods use `amplitude` (0–255) where supported.
class GritHaptics {
  // ─────────────────────────────────────────────────────────────────────
  // Quiet interactions (navigation, selection, toggles)
  // ─────────────────────────────────────────────────────────────────────

  /// Whisper tick — tab changes, toggles, chips, back navigation.
  static Future<void> selectionTick() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 25, amplitude: 120);
    }
  }

  /// Standard button tap — any non-special button press.
  static Future<void> buttonTap() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 40, amplitude: 180);
    }
  }

  /// Adjustment clicks — weight/rep (+/-) increments.
  static Future<void> counterClick() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 15, amplitude: 160);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Workout logging actions
  // ─────────────────────────────────────────────────────────────────────

  /// Set checkoff — satisfying double-bump confirming a logged set.
  static Future<void> setComplete() async {
    if (await Vibration.hasVibrator()) {
      // short-pause-stronger: rhythmic double-thud
      Vibration.vibrate(pattern: [0, 40, 50, 100]);
    }
  }

  /// Adding a new set row within an exercise.
  static Future<void> addSet() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 60, amplitude: 200);
    }
  }

  /// Adding an exercise to the workout or routine.
  static Future<void> addExercise() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 70, amplitude: 220);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Rest timer moments
  // ─────────────────────────────────────────────────────────────────────

  /// Rest timer starts — rising pair, feels like an exhale.
  static Future<void> startRest() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 40, 60, 120]);
    }
  }

  /// At 10 seconds remaining — urgency double-buzz.
  static Future<void> restWarning() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 80, 50, 100]);
    }
  }

  /// Rest timer hits 0 — Triple beat clear signal.
  static Future<void> restEnd() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 100, 80, 150, 80, 100]);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Session lifecycle
  // ─────────────────────────────────────────────────────────────────────

  /// Workout session begins — energising burst.
  static Future<void> workoutStart() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 60, 80, 150]);
    }
  }

  /// Workout finished — Triumphant sweeping sequence.
  static Future<void> workoutComplete() async {
    if (await Vibration.hasVibrator()) {
      // Sweeping rhythmic sequence: [delay, dur, delay, dur...]
      Vibration.vibrate(pattern: [0, 50, 50, 100, 50, 150, 50, 300]);
    }
  }

  /// Personal record achieved — Triple pulse celebration.
  static Future<void> prAchieved() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 60, 40, 60, 40, 200]);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Destructive / confirmatory / Error
  // ─────────────────────────────────────────────────────────────────────

  /// Error / blocked action — sharp double buzz.
  static Future<void> error() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 50, 50, 50]);
    }
  }

  /// Destructive delete — heavy thud.
  static Future<void> deleteAction() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 120, amplitude: 255);
    }
  }

  /// Discard workout — heavy double thud.
  static Future<void> discardWorkout() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 120, 80, 120]);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Editing / organisation
  // ─────────────────────────────────────────────────────────────────────

  /// Routine saved — rising pair.
  static Future<void> saveRoutine() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 60, 80, 150]);
    }
  }

  /// Drag-to-reorder started.
  static Future<void> reorderItem() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 35, amplitude: 150);
    }
  }

  /// Long press detected — heavy single burst.
  static Future<void> longPress() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 80, amplitude: 220);
    }
  }

  /// Scroll limit hit.
  static Future<void> scrollLimit() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 20, amplitude: 100);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Standard Impact Profiles (iOS style)
  // ─────────────────────────────────────────────────────────────────────

  /// Light impact — subtle feedback.
  static Future<void> lightImpact() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 20, amplitude: 100);
    }
  }

  /// Medium impact — standard confirmation feedback.
  static Future<void> mediumImpact() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 40, amplitude: 180);
    }
  }

  /// Heavy impact — strong confirmation or emphasis.
  static Future<void> heavyImpact() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 70, amplitude: 240);
    }
  }
}
