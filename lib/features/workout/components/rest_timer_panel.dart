import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/workout_timer_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../core/utils/workout_utils.dart';
import '../../../shared/widgets/grit_rest_timer_picker.dart';

class RestTimerPanel extends ConsumerWidget {
  const RestTimerPanel({super.key});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(workoutTimerProvider.select((s) => s.restSecondsRemaining));
    final isRunning = remaining != null;
    
    // Watch activeWorkoutProvider for exercise list changes
    final state = ref.watch(activeWorkoutProvider);
    
    // Determine what time to display when IDLE
    int displayTime = remaining ?? state.sessionRestOverride ?? 90;
    if (!isRunning && state.sessionRestOverride == null) {
      final activeExIdx = _findActiveExerciseIndex(ref);
      if (activeExIdx != -1) {
        final se = state.exercises[activeExIdx];
        displayTime = se.targetRest;
      }
    }

    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).grit.surface2,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).grit.border, width: 1),
        ),
      ),
      child: Stack(
        children: [
          // Background Progress Fill (Only if running)
          if (isRunning) _RestProgressFill(),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Slot 1: Total Volume (Left Aligned)
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildVolumeDisplay(context, ref),
                  ),
                ),
                
                // Slot 2: Timer (Digit-Centered)
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {
                      GritHaptics.selectionTick();
                      _showTimerPicker(context, ref, displayTime);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text('REST', 
                              style: GritTextStyles.labelMicro().copyWith(
                                fontSize: 10, 
                                letterSpacing: 2.0,
                                color: Theme.of(context).grit.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(displayTime),
                            style: GritTextStyles.mono(24,
                              weight: FontWeight.w900,
                              color: isRunning ? Theme.of(context).grit.accent : Theme.of(context).grit.textPrimary,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Slot 3: Action Buttons (Right Aligned)
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildActionButtons(ref, isRunning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeDisplay(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);
    final profile = ref.watch(profileProvider);
    final isLb = profile.weightUnit.toLowerCase() == 'lb';
    
    final exTypesMap = { 
      for (final se in state.exercises) 
        se.id!: state.exerciseDetails[se.exerciseId]?.type ?? 'weighted' 
    };
    final totalKg = WorkoutUtils.calculateTotalVolume(state.sets, exTypesMap, profile.weightKg);
    final displayVolume = isLb ? totalKg * 2.20462 : totalKg;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('VOLUME', 
          style: GritTextStyles.labelMicro().copyWith(
            fontSize: 10, 
            fontWeight: FontWeight.w900,
            color: Theme.of(context).grit.textPrimary,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              WorkoutUtils.formatDecimal(displayVolume),
              style: GritTextStyles.mono(24, 
                weight: FontWeight.w900,
                color: Theme.of(context).grit.textPrimary,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              isLb ? 'LB' : 'KG',
              style: GritTextStyles.labelMicro().copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).grit.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(WidgetRef ref, bool isRunning) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallActionButton(
          label: '+30',
          enabled: isRunning,
          onTap: () {
            GritHaptics.selectionTick();
            ref.read(activeWorkoutProvider.notifier).adjustSessionRestOverride(30);
          },
        ),
        const SizedBox(width: 8),
        _SmallActionButton(
          label: 'SKIP',
          isAccent: isRunning,
          enabled: true,
          onTap: () {
            GritHaptics.buttonTap();
            ref.read(activeWorkoutProvider.notifier).skipRest();
          },
        ),
      ],
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
          final isRunning = ref.read(workoutTimerProvider).restSecondsRemaining != null;
          if (isRunning) {
            // 1. Update running timer
            ref.read(workoutTimerProvider.notifier).startRestTimer(
              newSeconds,
              exerciseName: ref.read(workoutTimerProvider).exerciseName,
            );
          }
          
          // 2. Persist for the entire session
          ref.read(activeWorkoutProvider.notifier).setSessionRestOverride(newSeconds);
          GritHaptics.selectionTick();
        },
      ),
    );
  }
}

class _RestProgressFill extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(workoutTimerProvider.select((s) => s.restSecondsRemaining)) ?? 0;
    final restingIdx = ref.watch(activeWorkoutProvider.select((s) => s.restingExerciseIndex));
    
    int total = ref.watch(activeWorkoutProvider.select((s) => s.sessionRestOverride)) ?? 90;
    if (restingIdx != null && total == 90 && ref.read(activeWorkoutProvider).sessionRestOverride == null) {
      final targetRest = ref.watch(activeWorkoutProvider.select((s) => 
        s.exercises.length > restingIdx ? s.exercises[restingIdx].targetRest : 90));
      total = targetRest;
    }
    
    final fillFrac = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;
    
    return Positioned.fill(
      child: Align(
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 1),
          curve: Curves.linear,
          tween: Tween<double>(begin: (1.0 - fillFrac), end: (1.0 - fillFrac)),
          builder: (context, value, _) {
            return FractionallySizedBox(
              widthFactor: value,
              child: Container(
                color: Theme.of(context).grit.accent.withValues(alpha: 0.06),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAccent;
  final bool enabled;

  const _SmallActionButton({
    required this.label,
    required this.onTap,
    this.isAccent = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final color = isAccent ? grit.accent : grit.textPrimary;
    
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isAccent ? grit.accent.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(
              color: isAccent ? grit.accent : grit.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GritTextStyles.metric(12, 
              weight: FontWeight.w900, 
              color: color,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
