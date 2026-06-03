import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/haptics.dart';
import '../services/notification_service.dart';
import 'shared_preferences_provider.dart';
import 'dao_providers.dart';

enum ChronoMode { timer, stopwatch }

class WorkoutTimerState {
  // Workout-specific timing
  final int? restSecondsRemaining;
  final DateTime? restStartTime;
  final DateTime? restEndTime;
  final int cumulativeRestSeconds;
  final int elapsedSeconds;
  final String? activeSessionName;
  final String? exerciseName;
  final String? setInfo;
  final String? weightInfo;
  final String? repsInfo;
  final int currentExerciseIndex;
  final int totalExercises;
  final DateTime? startedAt;

  // Standalone Chrono/Utility timing
  final ChronoMode chronoMode;
  final int chronoSecondsRemaining;
  final int chronoInitialSeconds;
  final bool isChronoRunning;
  final DateTime? chronoEndTime;
  final int stopwatchSeconds;
  final List<int> laps;
  final bool isStopwatchRunning;
  final DateTime? stopwatchStartTime;

  const WorkoutTimerState({
    this.restSecondsRemaining,
    this.restStartTime,
    this.restEndTime,
    this.cumulativeRestSeconds = 0,
    this.elapsedSeconds = 0,
    this.startedAt,
    this.activeSessionName,
    this.exerciseName,
    this.setInfo,
    this.weightInfo,
    this.repsInfo,
    this.chronoMode = ChronoMode.timer,
    this.chronoSecondsRemaining = 60,
    this.chronoInitialSeconds = 60,
    this.isChronoRunning = false,
    this.chronoEndTime,
    this.stopwatchSeconds = 0,
    this.laps = const [],
    this.currentExerciseIndex = 0,
    this.totalExercises = 0,
    this.isStopwatchRunning = false,
    this.stopwatchStartTime,
  });

  WorkoutTimerState copyWith({
    int? restSecondsRemaining,
    DateTime? restStartTime,
    DateTime? restEndTime,
    int? cumulativeRestSeconds,
    int? elapsedSeconds,
    DateTime? startedAt,
    String? activeSessionName,
    String? exerciseName,
    String? setInfo,
    String? weightInfo,
    String? repsInfo,
    bool clearRestTimer = false,
    ChronoMode? chronoMode,
    int? chronoSecondsRemaining,
    int? chronoInitialSeconds,
    bool? isChronoRunning,
    DateTime? chronoEndTime,
    bool clearChronoEnd = false,
    int? stopwatchSeconds,
    List<int>? laps,
    int? currentExerciseIndex,
    int? totalExercises,
    bool? isStopwatchRunning,
    DateTime? stopwatchStartTime,
    bool clearStopwatchStart = false,
  }) =>
      WorkoutTimerState(
        restSecondsRemaining: clearRestTimer
            ? null
            : restSecondsRemaining ?? this.restSecondsRemaining,
        restStartTime:
            clearRestTimer ? null : restStartTime ?? this.restStartTime,
        restEndTime: clearRestTimer ? null : restEndTime ?? this.restEndTime,
        cumulativeRestSeconds:
            cumulativeRestSeconds ?? this.cumulativeRestSeconds,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        startedAt: startedAt ?? this.startedAt,
        activeSessionName: activeSessionName ?? this.activeSessionName,
        exerciseName: clearRestTimer ? null : exerciseName ?? this.exerciseName,
        setInfo: clearRestTimer ? null : setInfo ?? this.setInfo,
        weightInfo: clearRestTimer ? null : weightInfo ?? this.weightInfo,
        repsInfo: clearRestTimer ? null : repsInfo ?? this.repsInfo,
        chronoMode: chronoMode ?? this.chronoMode,
        chronoSecondsRemaining:
            chronoSecondsRemaining ?? this.chronoSecondsRemaining,
        chronoInitialSeconds: chronoInitialSeconds ?? this.chronoInitialSeconds,
        isChronoRunning: isChronoRunning ?? this.isChronoRunning,
        chronoEndTime:
            clearChronoEnd ? null : chronoEndTime ?? this.chronoEndTime,
        stopwatchSeconds: stopwatchSeconds ?? this.stopwatchSeconds,
        laps: laps ?? this.laps,
        currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
        totalExercises: totalExercises ?? this.totalExercises,
        isStopwatchRunning: isStopwatchRunning ?? this.isStopwatchRunning,
        stopwatchStartTime: clearStopwatchStart
            ? null
            : stopwatchStartTime ?? this.stopwatchStartTime,
      );

  double get timerProgress => chronoInitialSeconds > 0
      ? chronoSecondsRemaining / chronoInitialSeconds
      : 0.0;

  String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class WorkoutTimerNotifier extends Notifier<WorkoutTimerState> {
  Timer? _ticker;
  Timer? _restTicker;
  Timer? _chronoTicker;
  Timer? _stopwatchTicker;
  bool _restWarningFired = false;
  bool _isUpdatingNotification = false; // Guard against overlapping async calls

  @override
  WorkoutTimerState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _restTicker?.cancel();
      _chronoTicker?.cancel();
      _stopwatchTicker?.cancel();
    });

    // Auto-recovery of timers on startup
    Future.microtask(() => _recoverTimers());

    return const WorkoutTimerState();
  }

  Future<void> _recoverTimers() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);

      // 1. Recover Workout Elapsed Timer
      final startedStr = prefs.getString('grit_timer_workout_started_at');
      final sessionName = prefs.getString('grit_timer_active_session_name');

      if (startedStr != null) {
        // ANTI-ZOMBIE HARDENING: Verify with the DB that a session actually exists and is active.
        // If the DB says no active session, we must not revive the timer even if prefs exist.
        final sDao = ref.read(sessionsDaoProvider);
        final activeSession = await sDao.getActive();

        if (activeSession == null) {
          debugPrint(
              'GRIT: Anti-Zombie trigger. Prefs exist but DB has no active session. Purging.');
          stopElapsedTimer();
          _clearRestPersistence();
          NotificationService().cancelWorkoutNotification().ignore();
          return;
        }

        // SAFETY RECOVERY: Ensure we don't revive ad-hoc sessions that have been purged from the core engine.
        final lowerName = sessionName?.toLowerCase() ?? '';
        if (lowerName.contains('free workout') ||
            lowerName.contains('empty workout') ||
            lowerName == 'workout') {
          debugPrint(
              'GRIT: Blocking legacy session timer recovery: $sessionName');
          stopElapsedTimer(); // Wipes prefs
          _clearRestPersistence();
          NotificationService().cancelWorkoutNotification().ignore();
          return;
        }

        final startedAt = DateTime.parse(startedStr);
        startElapsedTimer(startedAt, sessionName: sessionName);
      }

      // 2. Recover Rest Timer
      final restEndStr = prefs.getString('grit_timer_rest_end_time');
      if (restEndStr != null) {
        final endTime = DateTime.parse(restEndStr);
        final now = DateTime.now();
        if (endTime.isAfter(now)) {
          final remaining = endTime.difference(now).inSeconds;
          final startTimeStr = prefs.getString('grit_timer_rest_start_time');
          final exerciseName = prefs.getString('grit_timer_rest_exercise_name');
          final cumulative = prefs.getInt('grit_timer_cumulative_rest') ?? 0;

          state = state.copyWith(
            restSecondsRemaining: remaining,
            restStartTime:
                startTimeStr != null ? DateTime.parse(startTimeStr) : now,
            restEndTime: endTime,
            exerciseName: exerciseName,
            cumulativeRestSeconds: cumulative,
          );

          _resumeRestTicker();
        } else {
          _clearRestPersistence();
        }
      }

      // 3. Recover Chrono Timer
      final chronoEndStr = prefs.getString('grit_timer_chrono_end');
      if (chronoEndStr != null) {
        final endTime = DateTime.parse(chronoEndStr);
        final now = DateTime.now();
        if (endTime.isAfter(now)) {
          final remaining = endTime.difference(now).inSeconds;
          state = state.copyWith(
            chronoSecondsRemaining: remaining,
            chronoEndTime: endTime,
          );
          _startChronoTimer(recover: true);
        } else {
          prefs.remove('grit_timer_chrono_end');
        }
      }

      // 4. Recover Stopwatch
      final stopwatchStartStr = prefs.getString('grit_timer_stopwatch_start');
      if (stopwatchStartStr != null) {
        final startTime = DateTime.parse(stopwatchStartStr);
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        state = state.copyWith(
          stopwatchSeconds: elapsed,
          stopwatchStartTime: startTime,
        );
        _startStopwatch(recover: true);
      }
    } catch (e) {
      debugPrint('GRIT ERROR: Failed to recover timers: $e');
    }
  }

  // --- WORKOUT DURATION TIMER ---
  void startElapsedTimer(DateTime startedAt, {String? sessionName}) {
    _ticker?.cancel();
    state = state.copyWith(
      activeSessionName: sessionName,
      startedAt: startedAt,
    );

    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(
        'grit_timer_workout_started_at', startedAt.toIso8601String());
    if (sessionName != null) {
      prefs.setString('grit_timer_active_session_name', sessionName);
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      int elapsed = DateTime.now().difference(startedAt).inSeconds;

      // TIME-JUMP DETECTION: Clamp to valid 24h range
      if (elapsed < 0) {
        elapsed = 0;
      } else if (elapsed > 86400) {
        elapsed = 86400;
      }

      state = state.copyWith(elapsedSeconds: elapsed);
    });

    _updateNotification();
  }

  void stopElapsedTimer() {
    _ticker?.cancel();
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove('grit_timer_workout_started_at');
    prefs.remove('grit_timer_active_session_name');
  }

  void ensureElapsedTimerRunning() {
    final currentTicker = _ticker;
    if (state.startedAt != null &&
        (currentTicker == null || !currentTicker.isActive)) {
      startElapsedTimer(state.startedAt!, sessionName: state.activeSessionName);
    }
  }

  // --- REST TIMER ---
  void startRestTimer(
    int seconds, {
    String? exerciseName,
    String? nextSetInfo,
    String? nextWeightRepsInfo,
  }) {
    _restTicker?.cancel();
    _restWarningFired = false;

    // ANTI-ZERO GUARD: Do not start a timer for 0 or negative seconds.
    if (seconds <= 0) {
      skipRest();
      return;
    }

    final now = DateTime.now();
    final endTime = now.add(Duration(seconds: seconds));

    state = state.copyWith(
      restSecondsRemaining: seconds,
      restStartTime: now,
      restEndTime: endTime,
      exerciseName: exerciseName,
      setInfo: nextSetInfo,
      weightInfo: nextWeightRepsInfo,
    );

    _persistRestState();
    _resumeRestTicker();
  }

  void _resumeRestTicker() {
    _restTicker?.cancel();

    DateTime lastTimestamp = DateTime.now();

    _restTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final delta = now.difference(lastTimestamp).inSeconds;
      lastTimestamp = now;

      final remaining = state.restEndTime?.difference(now).inSeconds ?? 0;

      if (remaining <= 0) {
        timer.cancel();
        // Fire rest-complete alert before clearing state
        final exName = state.exerciseName;
        state = state.copyWith(
          clearRestTimer: true,
          cumulativeRestSeconds: state.cumulativeRestSeconds + delta,
        );
        _clearRestPersistence();
        _updateNotification(force: true); // Force update on completion
        Future.microtask(() {
          GritHaptics.restEnd();
          NotificationService().showRestCompleteAlert(exerciseName: exName);
        });
      } else {
        state = state.copyWith(
          restSecondsRemaining: remaining,
          cumulativeRestSeconds: state.cumulativeRestSeconds + delta,
        );

        // Periodically persist cumulative rest (every 5s)
        if (remaining % 5 == 0) {
          ref.read(sharedPreferencesProvider).setInt(
              'grit_timer_cumulative_rest', state.cumulativeRestSeconds);
        }

        if (remaining <= 10 && !_restWarningFired) {
          _restWarningFired = true;
          Future.microtask(() => GritHaptics.restWarning());
        }
      }
    });
  }

  void _persistRestState() {
    final prefs = ref.read(sharedPreferencesProvider);
    final restEnd = state.restEndTime;
    final restStart = state.restStartTime;
    if (restEnd != null && restStart != null) {
      prefs.setString('grit_timer_rest_end_time', restEnd.toIso8601String());
      prefs.setString(
          'grit_timer_rest_start_time', restStart.toIso8601String());
      if (state.exerciseName != null) {
        prefs.setString('grit_timer_rest_exercise_name', state.exerciseName!);
      }
      prefs.setInt('grit_timer_cumulative_rest', state.cumulativeRestSeconds);
    }
  }

  void _clearRestPersistence() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove('grit_timer_rest_end_time');
    prefs.remove('grit_timer_rest_start_time');
    prefs.remove('grit_timer_rest_exercise_name');
    prefs.remove('grit_timer_cumulative_rest');
  }

  void adjustRestTime(int seconds) {
    final currentEnd = state.restEndTime;
    if (currentEnd != null) {
      final newEndTime = currentEnd.add(Duration(seconds: seconds));
      final newRemaining = newEndTime.difference(DateTime.now()).inSeconds;

      if (newRemaining <= 0) {
        skipRest();
        return;
      }

      state = state.copyWith(
        restEndTime: newEndTime,
        restSecondsRemaining: newRemaining,
      );

      _persistRestState();
      _updateNotification(isResting: true, force: true);
    }
  }

  void addRestTime(int seconds) => adjustRestTime(seconds);
  void subtractRestTime(int seconds) => adjustRestTime(-seconds);

  void skipRest() {
    _restTicker?.cancel();
    state = state.copyWith(clearRestTimer: true);
    _clearRestPersistence();
    _updateNotification();
  }

  // --- CHRONO / UTILITY TIMER ---
  void setChronoMode(ChronoMode mode) {
    state = state.copyWith(chronoMode: mode);
  }

  void setChronoTimer(int seconds) {
    _chronoTicker?.cancel();
    state = state.copyWith(
      chronoSecondsRemaining: seconds,
      chronoInitialSeconds: seconds,
      isChronoRunning: false,
    );
  }

  void toggleChronoTimer() {
    if (state.isChronoRunning) {
      _pauseChronoTimer();
    } else {
      _startChronoTimer();
    }
  }

  void resetChronoTimer() {
    _chronoTicker?.cancel();
    state = state.copyWith(
      chronoSecondsRemaining: state.chronoInitialSeconds,
      isChronoRunning: false,
      clearChronoEnd: true,
    );
    ref.read(sharedPreferencesProvider).remove('grit_timer_chrono_end');
    NotificationService().cancelChronoNotification().ignore();
  }

  void _startChronoTimer({bool recover = false}) {
    if (state.chronoSecondsRemaining <= 0) return;

    final now = DateTime.now();
    DateTime endTime;
    if (recover && state.chronoEndTime != null) {
      endTime = state.chronoEndTime!;
    } else {
      endTime = now.add(Duration(seconds: state.chronoSecondsRemaining));
      ref
          .read(sharedPreferencesProvider)
          .setString('grit_timer_chrono_end', endTime.toIso8601String());
    }

    state = state.copyWith(isChronoRunning: true, chronoEndTime: endTime);
    _chronoTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentNow = DateTime.now();
      final remaining = endTime.difference(currentNow).inSeconds;
      if (remaining > 0) {
        state = state.copyWith(chronoSecondsRemaining: remaining);
        // Notify device - throttle to every 2s to avoid flooding
        if (remaining % 2 == 0) {
          NotificationService()
              .showChronoTimerNotification(
                secondsRemaining: remaining,
                totalSeconds: state.chronoInitialSeconds,
              )
              .ignore();
        }
      } else {
        timer.cancel();
        state = state.copyWith(
            isChronoRunning: false,
            chronoSecondsRemaining: 0,
            clearChronoEnd: true);
        ref.read(sharedPreferencesProvider).remove('grit_timer_chrono_end');
        GritHaptics.restEnd(); // Reuse rest end haptic for timer finish
        NotificationService().showChronoCompleteAlert().ignore();
      }
    });
  }

  void _pauseChronoTimer() {
    _chronoTicker?.cancel();
    state = state.copyWith(isChronoRunning: false, clearChronoEnd: true);
    ref.read(sharedPreferencesProvider).remove('grit_timer_chrono_end');
    NotificationService().cancelChronoNotification().ignore();
  }

  // --- STOPWATCH LOGIC ---
  void toggleStopwatch() {
    if (state.isStopwatchRunning) {
      _pauseStopwatch();
    } else {
      _startStopwatch();
    }
  }

  void _startStopwatch({bool recover = false}) {
    final now = DateTime.now();
    DateTime startTime;
    if (recover && state.stopwatchStartTime != null) {
      startTime = state.stopwatchStartTime!;
    } else {
      startTime = now.subtract(Duration(seconds: state.stopwatchSeconds));
      ref
          .read(sharedPreferencesProvider)
          .setString('grit_timer_stopwatch_start', startTime.toIso8601String());
    }

    state =
        state.copyWith(isStopwatchRunning: true, stopwatchStartTime: startTime);
    // Fire initial notification immediately
    NotificationService()
        .showStopwatchNotification(elapsedSeconds: state.stopwatchSeconds)
        .ignore();
    _stopwatchTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      state = state.copyWith(stopwatchSeconds: elapsed);
      // Update notification every 5 seconds to avoid flooding
      if (elapsed % 5 == 0) {
        NotificationService()
            .showStopwatchNotification(elapsedSeconds: elapsed)
            .ignore();
      }
    });
  }

  void _pauseStopwatch() {
    _stopwatchTicker?.cancel();
    state =
        state.copyWith(isStopwatchRunning: false, clearStopwatchStart: true);
    ref.read(sharedPreferencesProvider).remove('grit_timer_stopwatch_start');
    NotificationService().cancelChronoNotification().ignore();
  }

  void recordLap() {
    if (!state.isStopwatchRunning && state.stopwatchSeconds == 0) return;
    final newLaps = [state.stopwatchSeconds, ...state.laps];
    if (newLaps.length > 50) newLaps.removeRange(50, newLaps.length);
    state = state.copyWith(laps: newLaps);
  }

  void resetStopwatch() {
    _stopwatchTicker?.cancel();
    state = state.copyWith(
      stopwatchSeconds: 0,
      laps: [],
      isStopwatchRunning: false,
      clearStopwatchStart: true,
    );
    ref.read(sharedPreferencesProvider).remove('grit_timer_stopwatch_start');
    NotificationService().cancelChronoNotification().ignore();
  }

  void updateWorkoutInfo({
    String? sessionName,
    String? exerciseName,
    String? setInfo,
    String? weightInfo,
    String? repsInfo,
    DateTime? startedAt,
    int? currentExerciseIndex,
    int? totalExercises,
  }) {
    state = state.copyWith(
      activeSessionName: sessionName,
      exerciseName: exerciseName,
      setInfo: setInfo,
      weightInfo: weightInfo,
      repsInfo: repsInfo,
      startedAt: startedAt,
      currentExerciseIndex: currentExerciseIndex,
      totalExercises: totalExercises,
    );
    _updateNotification();
    ensureElapsedTimerRunning();
  }

  // --- SHARED HELPER ---
  Future<void> _updateNotification({
    bool isResting = false,
    bool force = false,
  }) async {
    // ANTI-ZOMBIE GUARD: If no workout start time is set, do not push updates.
    if (state.startedAt == null && !isResting) {
      if (!force) {
        NotificationService().cancelWorkoutNotification().ignore();
        return;
      }
    }

    // Keep the notification active in status bar while workout is running.

    // OVERLAP GUARD: Prevent concurrent async notification updates
    if (_isUpdatingNotification) return;
    _isUpdatingNotification = true;

    try {
      if (isResting) {
        final total =
            state.restEndTime?.difference(state.restStartTime!).inSeconds ?? 1;
        final elapsed = total - (state.restSecondsRemaining ?? 0);
        await NotificationService().updateWorkoutNotification(
          sessionName: state.activeSessionName ?? 'REST',
          exerciseName: state.exerciseName,
          isResting: true,
          progressMax: total,
          progressCurrent: elapsed,
          restSecondsRemaining: state.restSecondsRemaining,
          nextSetInfo: state.setInfo,
          nextWeightRepsInfo: state.weightInfo,
        );
      } else {
        await NotificationService().updateWorkoutNotification(
          sessionName: state.activeSessionName ?? 'Active Workout',
          exerciseName: state.exerciseName,
          setInfo: state.setInfo,
          weightInfo: state.weightInfo,
          repsInfo: state.repsInfo,
          startedAt: state.startedAt,
          currentVariation: state.currentExerciseIndex,
          totalVariations: state.totalExercises,
        );
      }
    } catch (e) {
      debugPrint('GRIT ERROR: NotificationService threw exception: $e');
    } finally {
      _isUpdatingNotification = false;
    }
  }

  /// Re-sync timers after the app returns from background.
  /// Dart Timer.periodic pauses when the OS suspends the process;
  /// this recalculates elapsed/rest from persisted wall-clock anchors.
  void handleLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.paused || appState == AppLifecycleState.inactive) {
      final remaining = state.restSecondsRemaining;
      if (remaining != null && remaining > 0) {
        NotificationService().scheduleRestCompleteNotification(
          seconds: remaining,
          exerciseName: state.exerciseName,
        );
      }
    } else if (appState == AppLifecycleState.resumed) {
      NotificationService().cancelScheduledRestNotification();
    }
  }

  void recoverFromBackground() {
    // 1. Re-sync elapsed workout timer
    if (state.startedAt != null) {
      final elapsed = DateTime.now().difference(state.startedAt!).inSeconds;
      state = state.copyWith(elapsedSeconds: elapsed);
      // Restart ticker if it died in background
      if (_ticker == null || !_ticker!.isActive) {
        startElapsedTimer(state.startedAt!,
            sessionName: state.activeSessionName);
      }
    }

    // 2. Re-sync rest timer
    final currentEnd = state.restEndTime;
    if (currentEnd != null) {
      final remaining = currentEnd.difference(DateTime.now()).inSeconds;
      if (remaining > 0) {
        state = state.copyWith(restSecondsRemaining: remaining);
        _updateNotification(isResting: true, force: true);
        _resumeRestTicker(); // Ensure ticker is running
      } else {
        // Rest ended while in background
        final exName = state.exerciseName;
        state = state.copyWith(clearRestTimer: true);
        _clearRestPersistence();
        _updateNotification(force: true);
        Future.microtask(() {
          GritHaptics.restEnd();
          NotificationService().showRestCompleteAlert(exerciseName: exName);
        });
      }
    }

    // 3. Re-sync Chrono Timer
    if (state.isChronoRunning && state.chronoEndTime != null) {
      final remaining =
          state.chronoEndTime!.difference(DateTime.now()).inSeconds;
      if (remaining > 0) {
        state = state.copyWith(chronoSecondsRemaining: remaining);
        if (_chronoTicker == null || !_chronoTicker!.isActive) {
          _startChronoTimer(recover: true);
        }
      } else {
        state = state.copyWith(
            isChronoRunning: false,
            chronoSecondsRemaining: 0,
            clearChronoEnd: true);
        ref.read(sharedPreferencesProvider).remove('grit_timer_chrono_end');
        if (_chronoTicker != null && _chronoTicker!.isActive) {
          _chronoTicker!.cancel();
        }
        GritHaptics.restEnd();
      }
    }

    // 4. Re-sync Stopwatch
    if (state.isStopwatchRunning && state.stopwatchStartTime != null) {
      final elapsed =
          DateTime.now().difference(state.stopwatchStartTime!).inSeconds;
      state = state.copyWith(stopwatchSeconds: elapsed);
      if (_stopwatchTicker == null || !_stopwatchTicker!.isActive) {
        _startStopwatch(recover: true);
      }
    }
  }

  void reset() {
    _ticker?.cancel();
    _restTicker?.cancel();
    _chronoTicker?.cancel();
    _stopwatchTicker?.cancel();

    // Hard purge all persistence to prevent ghost recovery
    stopElapsedTimer();
    _clearRestPersistence();
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove('grit_timer_chrono_end');
    prefs.remove('grit_timer_stopwatch_start');

    state = const WorkoutTimerState();
    // Ensure notification is purged on hard reset
    NotificationService().cancelWorkoutNotification().ignore();
  }
}

final workoutTimerProvider =
    NotifierProvider<WorkoutTimerNotifier, WorkoutTimerState>(
  WorkoutTimerNotifier.new,
);
