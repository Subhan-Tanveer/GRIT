// Readiness scoring + journal prompt rotation for the Wellness Hub.

class WellnessCalc {
  WellnessCalc._();

  /// Composite readiness score (0-100) from sleep, mood, stress, and recent
  /// training load. Heavier recent training load lowers readiness even with
  /// good sleep/mood, modeling accumulated fatigue.
  static int readinessScore({
    required double sleepHours,
    required int sleepQuality, // 1-5
    required int mood, // 1-5
    required int stressLevel, // 1-10
    required int recentSessionsLast2Days,
  }) {
    final sleepScore = ((sleepHours / 8.0) * 100).clamp(0, 100);
    final qualityScore = (sleepQuality / 5.0) * 100;
    final moodScore = (mood / 5.0) * 100;
    final stressScore = ((10 - stressLevel) / 10.0) * 100;

    double composite = (sleepScore * 0.35) +
        (qualityScore * 0.15) +
        (moodScore * 0.25) +
        (stressScore * 0.25);

    final loadPenalty = recentSessionsLast2Days >= 2 ? 12 : (recentSessionsLast2Days == 1 ? 4 : 0);
    composite -= loadPenalty;

    return composite.clamp(0, 100).round();
  }

  static String readinessLabel(int score) {
    if (score >= 80) return 'PRIMED';
    if (score >= 60) return 'READY';
    if (score >= 40) return 'MODERATE';
    if (score >= 20) return 'LOW';
    return 'DEPLETED';
  }
}

const List<String> moodEmojis = ['😣', '😕', '😐', '🙂', '😄'];
const List<String> moodLabels = ['AWFUL', 'ROUGH', 'OKAY', 'GOOD', 'GREAT'];

const List<String> journalPrompts = [
  "What's one thing that went right today, training or otherwise?",
  "What's draining your energy right now, and is it temporary?",
  "If today's workout was a letter grade, what would it be and why?",
  "What would make tomorrow 1% better than today?",
  "Name one thing you're grateful your body could do today.",
  "What's a recurring excuse you keep telling yourself?",
  "Where did you show the most discipline today?",
  "What does 'recovered' actually feel like for you right now?",
  "What's one habit outside the gym that's helping or hurting your training?",
  "If you could only keep one workout this week, which would it be?",
];

String journalPromptForDate(DateTime date) {
  final dayIndex = date.difference(DateTime(date.year, 1, 1)).inDays;
  return journalPrompts[dayIndex % journalPrompts.length];
}
