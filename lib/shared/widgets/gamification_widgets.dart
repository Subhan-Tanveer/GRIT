import 'package:flutter/material.dart';
import '../../core/theme/grit_theme.dart';
import '../../utils/gamification.dart';

Color levelColor(GritLevel level, GritThemeData grit) {
  switch (level) {
    case GritLevel.rookie:
      return grit.textSecondary;
    case GritLevel.iron:
      return const Color(0xFF9FA8B2);
    case GritLevel.steel:
      return const Color(0xFFD0D5DA);
    case GritLevel.titan:
      return const Color(0xFFFFD60A);
    case GritLevel.legend:
      return grit.accent;
  }
}

class LevelBadge extends StatelessWidget {
  final GritLevelInfo levelInfo;
  final double size;

  const LevelBadge({super.key, required this.levelInfo, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final color = levelColor(levelInfo.level, grit);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        levelInfo.name.substring(0, 1),
        style: GritTextStyles.headlineMedium().copyWith(color: color),
      ),
    );
  }
}

class XpProgressBar extends StatelessWidget {
  final double progress;
  final String label;

  const XpProgressBar({super.key, required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GritTextStyles.dataLabel().copyWith(
            color: grit.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Stack(
            children: [
              Container(height: 8, color: grit.surface2),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(height: 8, color: grit.accent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GritScoreRing extends StatelessWidget {
  final int score; // 0-1000
  final double size;

  const GritScoreRing({super.key, required this.score, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final progress = (score / 1000).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              color: grit.surface2,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              color: grit.accent,
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.butt,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: GritTextStyles.displayMedium().copyWith(color: grit.textPrimary),
              ),
              Text(
                'GRIT SCORE',
                style: GritTextStyles.labelMicro().copyWith(
                  color: grit.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StreakFlame extends StatelessWidget {
  final int streakDays;

  const StreakFlame({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final active = streakDays > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department,
          color: active ? grit.warning : grit.textSecondary.withValues(alpha: 0.3),
          size: 22,
        ),
        const SizedBox(width: 4),
        Text(
          '$streakDays',
          style: GritTextStyles.dataValueSmall().copyWith(
            color: active ? grit.textPrimary : grit.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'DAY STREAK',
          style: GritTextStyles.labelMicro().copyWith(
            color: grit.textSecondary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class AchievementTile extends StatelessWidget {
  final GritAchievement achievement;
  final bool unlocked;
  final double progress;

  const AchievementTile({
    super.key,
    required this.achievement,
    required this.unlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final color = unlocked ? grit.accent : grit.textSecondary.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? grit.accent.withValues(alpha: 0.06) : grit.surface,
        border: Border.all(color: unlocked ? grit.accent : grit.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                unlocked ? Icons.military_tech : Icons.lock_outline,
                color: color,
                size: 20,
              ),
              Text(
                '+${achievement.xpReward} XP',
                style: GritTextStyles.labelMicro().copyWith(color: color, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: GritTextStyles.tileTitle().copyWith(
              color: unlocked ? grit.textPrimary : grit.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: GritTextStyles.label(11, color: grit.textSecondary),
          ),
          if (!unlocked) ...[
            const SizedBox(height: 8),
            ClipRRect(
              child: Stack(
                children: [
                  Container(height: 4, color: grit.surface2),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(height: 4, color: grit.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
