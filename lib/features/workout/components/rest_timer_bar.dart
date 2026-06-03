import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/workout_timer_provider.dart';
import '../../../shared/widgets/grit_rest_timer_picker.dart';
import 'action_button.dart';

class RestTimerBar extends ConsumerWidget {
  const RestTimerBar({super.key});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(workoutTimerProvider.select((s) => s.restSecondsRemaining)) ?? 0;
    final isRunning = ref.watch(workoutTimerProvider.select((s) => s.restSecondsRemaining != null));
    
    // Watch activeWorkoutProvider for exercise list changes
    final state = ref.watch(activeWorkoutProvider);
    final isAuto = state.autoRestEnabled;
    final grit = Theme.of(context).grit;
    
    int total = 90;
    final activeExIdx = _findActiveExerciseIndex(ref);
    if (activeExIdx != -1) {
      final se = state.exercises[activeExIdx];
      total = se.targetRest;
    }
    final fillFrac = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        height: 44, 
        width: double.infinity,
        decoration: BoxDecoration(
          color: grit.surface2, 
          border: Border(
            bottom: BorderSide(color: grit.border, width: 1),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isRunning)
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      flex: ((1.0 - fillFrac) * 1000).toInt(),
                      child: Container(color: grit.accent.withValues(alpha: 0.1)),
                    ),
                    Expanded(
                      flex: (fillFrac * 1000).toInt(),
                      child: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox.expand(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          GritHaptics.selectionTick();
                          ref.read(activeWorkoutProvider.notifier).setAutoRest(!isAuto);
                        },
                        child: Container(
                          width: 52,
                          height: 24,
                          decoration: BoxDecoration(
                            color: grit.background,
                            border: Border.all(color: grit.border, width: 1),
                          ),
                          child: Stack(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Text('A', 
                                          style: GritTextStyles.labelMicro().copyWith(
                                              fontWeight: FontWeight.w700, 
                                              color: isAuto ? grit.textPrimary : grit.muted)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text('M', 
                                          style: GritTextStyles.labelMicro().copyWith(
                                              fontWeight: FontWeight.w700, 
                                              color: !isAuto ? grit.textPrimary : grit.muted)),
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                alignment: isAuto ? Alignment.centerLeft : Alignment.centerRight,
                                child: Container(
                                  width: 26,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: grit.accent,
                                  ),
                                  child: Center(
                                    child: Text(
                                      isAuto ? 'A' : 'M',
                                      style: GritTextStyles.labelMicro().copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (isRunning)
                      GestureDetector(
                        onTap: () {
                          GritHaptics.selectionTick();
                          _showTimerPicker(context, ref, remaining);
                        },
                        child: Text(_formatTime(remaining),
                            style: GritTextStyles.mono(24,
                                weight: FontWeight.w900,
                                color: grit.accent)),
                      )
                    else if (!isAuto)
                      GestureDetector(
                        onTap: () {
                          GritHaptics.buttonTap();
                          ref.read(activeWorkoutProvider.notifier).startManualRest(null);
                        },
                        child: Text('START REST',
                            style: GritTextStyles.metric(14,
                                weight: FontWeight.w800,
                                color: grit.textSecondary,
                                letterSpacing: 2)),
                      ),

                    if (isRunning)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ActionButton(
                              label: '+30',
                              onTap: () => ref.read(workoutTimerProvider.notifier).adjustRestTime(30),
                            ),
                            const SizedBox(width: 8),
                            ActionButton(
                              label: 'SKIP',
                              onTap: () => ref.read(activeWorkoutProvider.notifier).skipRest(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _findActiveExerciseIndex(WidgetRef ref) {
    final state = ref.read(activeWorkoutProvider);
    if (state.restingExerciseIndex != null) return state.restingExerciseIndex!;
    
    // Find first incomplete exercise
    for (int i = 0; i < state.exercises.length; i++) {
      final sets = state.sets[state.exercises[i].id] ?? [];
      if (sets.any((s) => !s.isCompleted)) return i;
    }
    return -1;
  }

  void _showTimerPicker(BuildContext context, WidgetRef ref, int currentSeconds) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GritRestTimerPicker(
        initialSeconds: currentSeconds,
        onTimerChanged: (newSeconds) {
          // Adjust the timer in real-time
          ref.read(workoutTimerProvider.notifier).startRestTimer(
            newSeconds,
            exerciseName: ref.read(workoutTimerProvider).exerciseName,
          );
        },
      ),
    );
  }
}
