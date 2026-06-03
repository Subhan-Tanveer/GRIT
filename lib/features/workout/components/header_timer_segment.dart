import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../providers/workout_timer_provider.dart';
import '../../../core/constants/hero_tags.dart';

class HeaderTimerSegment extends ConsumerWidget {
  const HeaderTimerSegment({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(workoutTimerProvider);
    int elapsed = timerState.elapsedSeconds;
    if (elapsed == 0 && timerState.startedAt != null) {
      elapsed = DateTime.now().difference(timerState.startedAt!).inSeconds;
    }

    final h = elapsed ~/ 3600;
    final m = (elapsed % 3600) ~/ 60;
    final s = elapsed % 60;
    final timeStr = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Hero(
          tag: HeroTags.activeWorkoutTimer,
          child: Material(
            type: MaterialType.transparency,
            child: Text(timeStr,
                style: GritTextStyles.mono(22,
                  weight: FontWeight.w700,
                  color: Theme.of(context).grit.accent,
                )),
          ),
        ),
      ),
    );
  }
}
