// Rule-based GRIT AI Coach. Reads the user's real recent data (sessions,
// wellness, nutrition) and generates a contextual response. No network
// calls — every answer is derived from on-device data.

class CoachContext {
  final int sessionsLast7Days;
  final List<double> dailyVolumesLast7Days; // chronological
  final Map<String, List<double>> recentMaxWeightsByExercise;
  final int? latestReadinessScore;
  final int currentStreak;
  final double todayCalories;
  final double targetCalories;
  final double todayProtein;
  final double targetProtein;

  const CoachContext({
    required this.sessionsLast7Days,
    required this.dailyVolumesLast7Days,
    required this.recentMaxWeightsByExercise,
    required this.latestReadinessScore,
    required this.currentStreak,
    required this.todayCalories,
    required this.targetCalories,
    required this.todayProtein,
    required this.targetProtein,
  });

  bool get isOvertraining {
    if (sessionsLast7Days < 6) return false;
    if (dailyVolumesLast7Days.length < 4) return false;
    final recent = dailyVolumesLast7Days.sublist(dailyVolumesLast7Days.length - 2);
    final earlier = dailyVolumesLast7Days.sublist(0, dailyVolumesLast7Days.length - 2);
    final recentAvg = recent.isEmpty ? 0 : recent.reduce((a, b) => a + b) / recent.length;
    final earlierAvg = earlier.isEmpty ? 0 : earlier.reduce((a, b) => a + b) / earlier.length;
    return recentAvg < earlierAvg * 0.7;
  }

  List<String> get plateauedExercises {
    final result = <String>[];
    recentMaxWeightsByExercise.forEach((name, weights) {
      if (weights.length >= 3) {
        final lastThree = weights.sublist(0, 3);
        if (lastThree.toSet().length == 1 && lastThree.first > 0) {
          result.add(name);
        }
      }
    });
    return result;
  }
}

enum QuickQuestion {
  eatToday,
  improveBench,
  overtraining,
  recovery,
  motivation,
}

extension QuickQuestionX on QuickQuestion {
  String get label => switch (this) {
        QuickQuestion.eatToday => 'What should I eat today?',
        QuickQuestion.improveBench => 'How do I improve my lifts?',
        QuickQuestion.overtraining => 'Am I overtraining?',
        QuickQuestion.recovery => 'How is my recovery?',
        QuickQuestion.motivation => 'Keep me motivated',
      };
}

class AiCoachEngine {
  AiCoachEngine._();

  static String respond(String userMessage, CoachContext ctx) {
    final lower = userMessage.toLowerCase();

    if (lower.contains('overtrain') || lower.contains('too much') || lower.contains('too hard')) {
      return _overtrainingResponse(ctx);
    }
    if (lower.contains('eat') || lower.contains('food') || lower.contains('nutrition') || lower.contains('diet')) {
      return _nutritionResponse(ctx);
    }
    if (lower.contains('recover') || lower.contains('rest') || lower.contains('sleep') || lower.contains('readiness')) {
      return _recoveryResponse(ctx);
    }
    if (lower.contains('improve') || lower.contains('plateau') || lower.contains('stuck') || lower.contains('lift')) {
      return _plateauResponse(ctx);
    }
    if (lower.contains('motivat') || lower.contains('streak') || lower.contains('keep going')) {
      return _motivationResponse(ctx);
    }

    return _generalResponse(ctx);
  }

  static String _overtrainingResponse(CoachContext ctx) {
    if (ctx.isOvertraining) {
      return "Your training volume has dropped sharply over the last couple of sessions after a stretch of ${ctx.sessionsLast7Days} workouts in 7 days. That pattern — high frequency followed by a volume crash — usually means accumulated fatigue, not laziness. Consider a deload day or two before pushing intensity again.";
    }
    if (ctx.sessionsLast7Days >= 6) {
      return "You've trained ${ctx.sessionsLast7Days} times in the last 7 days. Your volume is holding steady, which is a good sign, but keep an eye on sleep and soreness — that frequency only works long-term if recovery keeps pace.";
    }
    return "You're at ${ctx.sessionsLast7Days} sessions this week. Nothing in your data suggests overtraining — volume and frequency both look sustainable.";
  }

  static String _nutritionResponse(CoachContext ctx) {
    final calRatio = ctx.targetCalories > 0 ? ctx.todayCalories / ctx.targetCalories : 0;
    final proteinRatio = ctx.targetProtein > 0 ? ctx.todayProtein / ctx.targetProtein : 0;

    if (ctx.todayCalories == 0) {
      return "You haven't logged anything today. Aim for roughly ${ctx.targetCalories.round()} kcal and ${ctx.targetProtein.round()}g protein based on your bodyweight — log your meals in Nutrition and I can track how close you're getting.";
    }
    if (proteinRatio < 0.5) {
      return "You're at ${ctx.todayProtein.round()}g protein today, well under your ${ctx.targetProtein.round()}g target. Prioritize a protein-dense meal next — chicken, eggs, whey, or Greek yogurt are quick wins.";
    }
    if (calRatio < 0.6) {
      return "You're under-fueled today at ${ctx.todayCalories.round()} of ${ctx.targetCalories.round()} kcal. If you've got a session coming up, eat something substantial first — training in a big deficit tanks performance.";
    }
    if (calRatio > 1.2) {
      return "You're already past your calorie target today (${ctx.todayCalories.round()} of ${ctx.targetCalories.round()} kcal). That's fine occasionally, but keep an eye on it if your goal is a controlled surplus or deficit.";
    }
    return "You're tracking well today — ${ctx.todayCalories.round()} kcal and ${ctx.todayProtein.round()}g protein, right in range. Keep the protein consistent across meals rather than backloading it at dinner.";
  }

  static String _recoveryResponse(CoachContext ctx) {
    final score = ctx.latestReadinessScore;
    if (score == null) {
      return "You haven't logged a wellness check-in yet. Head to the Wellness Hub and log your sleep, mood, and stress — I'll use that to give you a real recovery read instead of guessing.";
    }
    if (score < 40) {
      return "Your last readiness score was $score — that's low. Combined with your recent training load, today might be a good day for mobility work or a lighter session rather than chasing a PR.";
    }
    if (score < 70) {
      return "Readiness is sitting at $score — moderate. You can train, but maybe don't max out. Pay attention to how the first couple of warm-up sets feel before deciding how hard to push.";
    }
    return "Readiness is $score — you're primed. Sleep, mood, and recent training load are all lining up. Good day to chase a PR if one's on the program.";
  }

  static String _plateauResponse(CoachContext ctx) {
    final plateaued = ctx.plateauedExercises;
    if (plateaued.isEmpty) {
      return "Nothing in your recent lifts looks stuck — your weights are still trending up or you don't have 3+ sessions yet on a given exercise. Keep logging consistently and I'll flag it the moment something plateaus.";
    }
    final list = plateaued.take(3).join(', ');
    return "$list ${plateaued.length == 1 ? 'has' : 'have'} been stuck at the same weight for your last 3 sessions. Try one of: add a rep instead of weight, swap in a 5lb micro-load if your gym has them, or deload 10% for a week then build back up.";
  }

  static String _motivationResponse(CoachContext ctx) {
    if (ctx.currentStreak == 0) {
      return "No active streak right now — that's fine, everyone resets. The only workout that matters is the next one. Pick something simple and just start the clock again.";
    }
    if (ctx.currentStreak < 7) {
      return "You're ${ctx.currentStreak} day${ctx.currentStreak == 1 ? '' : 's'} into a streak. The first week is the hardest part — momentum builds fast from here if you keep showing up.";
    }
    if (ctx.currentStreak < 30) {
      return "${ctx.currentStreak} days strong. You've already beaten the point where most people quit. Don't let one bad day erase this — use a streak shield if you need it.";
    }
    return "${ctx.currentStreak} days. That's not a streak anymore, that's a lifestyle. Whatever you're doing — keep doing exactly that.";
  }

  static String _generalResponse(CoachContext ctx) {
    return "I can help with training load, recovery, plateaus, or nutrition — try asking something like \"am I overtraining?\" or \"what should I eat today?\". I only look at your real logged data, no guesswork.";
  }
}
