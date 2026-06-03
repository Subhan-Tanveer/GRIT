import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/workout_timer_provider.dart';
import '../../../core/constants/hero_tags.dart';
import '../../../app/routes.dart';

import 'package:flutter_animate/flutter_animate.dart';

class ActiveWorkoutStatusPanel extends ConsumerWidget {
  const ActiveWorkoutStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final activeState = ref.watch(activeWorkoutProvider);
    final session = activeState.session;
    
    // Only show if there's an active session
    if (session == null) return const SizedBox.shrink();

    final timerState = ref.watch(workoutTimerProvider);
    int elapsed = timerState.elapsedSeconds;
    if (elapsed == 0 && timerState.startedAt != null) {
      elapsed = DateTime.now().difference(timerState.startedAt!).inSeconds;
    }

    // Calculate completed and total variations (exercises)
    int completedVariations = 0;
    int totalVariations = activeState.exercises.length;

    for (final exercise in activeState.exercises) {
      final exerciseSets = activeState.sets[exercise.id] ?? [];
      if (exerciseSets.isNotEmpty && exerciseSets.every((s) => s.isCompleted)) {
        completedVariations++;
      }
    }

    final h = elapsed ~/ 3600;
    final m = (elapsed % 3600) ~/ 60;
    final s = elapsed % 60;
    final timeStr = '${h > 0 ? '${h.toString().padLeft(2, '0')}:' : ''}${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () => context.push(GritRoutes.activeWorkout),
        child: Container(
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin),
          decoration: BoxDecoration(
            color: grit.surface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: grit.borderHighlight, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Left: Status + Name
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE SESSION',
                      style: GritTextStyles.labelMicro().copyWith(
                        color: grit.accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Hero(
                      tag: HeroTags.activeWorkoutName,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          session.name.toUpperCase(),
                          style: GritTextStyles.tileTitle().copyWith(
                            color: grit.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Center: Timer
              Hero(
                tag: HeroTags.activeWorkoutTimer,
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: grit.background,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: grit.borderHighlight, width: 1),
                    ),
                    child: Text(
                      timeStr,
                      style: GritTextStyles.mono(16, weight: FontWeight.w800, color: grit.accent),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Right: Progress
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$completedVariations / $totalVariations',
                    style: GritTextStyles.mono(14, weight: FontWeight.w800, color: grit.textPrimary),
                  ),
                  Text(
                    'VARIATIONS',
                    style: GritTextStyles.labelMicro().copyWith(
                      color: grit.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutCubic).fadeIn();
  }
}
