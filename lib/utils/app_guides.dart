// Knowledge base for the GRIT AI guide system: step-by-step navigation
// flows for common "how do I..." questions, plus direct factual answers
// (e.g. "where is my data stored") that don't require navigation.

import '../app/routes.dart';

class GuideStep {
  final String instruction;
  /// Route the user needs to reach for this step to be considered done and
  /// the next step to fire. Null means this is the final step — no further
  /// navigation is expected, the guide completes as soon as this step is shown.
  final String? targetRoute;

  const GuideStep({required this.instruction, this.targetRoute});
}

class GuideFlow {
  final String id;
  final List<String> triggerKeywords;
  final List<GuideStep> steps;

  const GuideFlow({required this.id, required this.triggerKeywords, required this.steps});

  bool matches(String message) {
    final lower = message.toLowerCase();
    return triggerKeywords.any((k) => lower.contains(k));
  }
}

final List<GuideFlow> appGuides = [
  GuideFlow(
    id: 'journal',
    triggerKeywords: ['journal', 'write a journal', 'how do i journal'],
    steps: [
      GuideStep(instruction: "Sure — first, tap the Profile tab at the bottom of the screen.", targetRoute: GritRoutes.profile),
      GuideStep(instruction: "Now tap \"WELLNESS HUB\" — it's in the list below your stats.", targetRoute: GritRoutes.wellness),
      GuideStep(instruction: "You're there. Scroll down to \"TODAY'S JOURNAL PROMPT\" — there's a prompt and a text box right under it. Write whatever's on your mind, it saves automatically with your check-in."),
    ],
  ),
  GuideFlow(
    id: 'log_food',
    triggerKeywords: [
      'log food', 'log a meal', 'track food', 'add food', 'log nutrition',
      'diet', 'meal plan', 'macro', 'calorie', 'manage my nutrition', 'manage my diet',
    ],
    steps: [
      GuideStep(instruction: "Tap the Profile tab at the bottom.", targetRoute: GritRoutes.profile),
      GuideStep(instruction: "Tap \"NUTRITION\" in the list.", targetRoute: GritRoutes.nutrition),
      GuideStep(instruction: "Pick the meal section — Breakfast, Lunch, Dinner, or Snacks — and tap the + icon next to it. A sheet pops up where you can enter the food name and its calories/macros."),
    ],
  ),
  GuideFlow(
    id: 'water',
    triggerKeywords: ['water', 'hydration', 'drink'],
    steps: [
      GuideStep(instruction: "Tap the Profile tab at the bottom.", targetRoute: GritRoutes.profile),
      GuideStep(instruction: "Tap \"NUTRITION\".", targetRoute: GritRoutes.nutrition),
      GuideStep(instruction: "You'll see a water tracker card with a + and − button. Tap + each time you drink a glass — it adds 250ml. Tap − if you tapped it by mistake."),
    ],
  ),
  GuideFlow(
    id: 'achievements',
    triggerKeywords: ['achievement', 'badge', 'grit score', 'xp', 'level up', 'rank'],
    steps: [
      GuideStep(instruction: "Tap the Profile tab at the bottom.", targetRoute: GritRoutes.profile),
      GuideStep(instruction: "Tap the card near the top showing your level and streak — it's right under your name.", targetRoute: GritRoutes.gamification),
      GuideStep(instruction: "This is your GRIT Rank screen — your XP progress, GRIT Score, streak, and all 20 achievements are here. Locked ones show a progress bar so you know how close you are."),
    ],
  ),
  GuideFlow(
    id: 'measurements',
    triggerKeywords: ['measurement', 'body fat', 'waist', 'chest size', 'biceps'],
    steps: [
      GuideStep(instruction: "Tap the Profile tab at the bottom.", targetRoute: GritRoutes.profile),
      GuideStep(instruction: "Tap \"BODY MEASUREMENTS\".", targetRoute: GritRoutes.measurements),
      GuideStep(instruction: "From here you can view your trends, or log a new measurement entry for chest, waist, arms, and more."),
    ],
  ),
  GuideFlow(
    id: 'start_workout',
    triggerKeywords: ['start a workout', 'start workout', 'log a workout', 'begin a session'],
    steps: [
      GuideStep(instruction: "Tap the Workout tab at the bottom.", targetRoute: GritRoutes.workout),
      GuideStep(instruction: "Pick a routine from the list and tap \"START\" on it — or tap the quick-start option if you don't have a routine yet. That'll take you straight into the active workout screen where you log sets and reps."),
    ],
  ),
  GuideFlow(
    id: 'breathing',
    triggerKeywords: ['breathing', 'breathe', 'calm down', 'relax'],
    steps: [
      GuideStep(instruction: "Tap the Profile tab at the bottom.", targetRoute: GritRoutes.profile),
      GuideStep(instruction: "Tap \"WELLNESS HUB\".", targetRoute: GritRoutes.wellness),
      GuideStep(instruction: "Scroll down to the \"BREATHE\" section — tap the glowing circle to start a 4-7-8 breathing cycle. Tap it again any time to stop."),
    ],
  ),
];

/// Direct factual answers that don't need step-by-step navigation.
String? knowledgeAnswer(String message) {
  final lower = message.toLowerCase();

  if (lower.contains('where') && (lower.contains('store') || lower.contains('save') || lower.contains('data'))) {
    return "Everything you log — workouts, body weight, wellness check-ins, nutrition, even this chat — is stored locally on your phone in a SQLite database. Nothing is sent to a server; there's no account and no internet connection involved.";
  }
  if (lower.contains('readiness') && lower.contains('calculat')) {
    return "Your readiness score blends sleep hours/quality, mood, and stress level from your wellness check-in, then subtracts a penalty if you've trained hard in the last 2 days. It's recalculated fresh every time you save a check-in.";
  }
  if (lower.contains('grit score') && (lower.contains('calculat') || lower.contains('how'))) {
    return "GRIT Score (0-1000) combines your current streak, total lifetime volume lifted, and total PRs — consistency counts for the most, since that's the hardest thing to fake.";
  }
  if (lower.contains('streak') && lower.contains('how')) {
    return "Your streak counts consecutive calendar days where you completed at least one workout. Miss a day and it resets to 0 — there's no streak shield yet, so consistency really matters here.";
  }

  return null;
}

const List<String> _navigationIntentWords = [
  'where', 'find', 'manage', 'locate', 'navigate', 'go to', 'access', 'open', 'show me',
];

/// When the user clearly wants to be pointed somewhere in the app, but no
/// guide flow matched their exact phrasing, list what's actually available
/// instead of repeating an unrelated canned response.
String? navigationFallback(String message) {
  final lower = message.toLowerCase();
  final hasNavIntent = _navigationIntentWords.any((w) => lower.contains(w));
  if (!hasNavIntent) return null;

  return "I'm not totally sure what you're after — I can guide you to: your journal, logging food/nutrition, water tracking, achievements & GRIT rank, body measurements, starting a workout, or the breathing exercise. Try naming one of those directly, like \"where do I log food\".";
}
