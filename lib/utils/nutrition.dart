// Macro target estimation. Uses a straightforward bodyweight-based formula
// (no goal/activity-level inputs exist on the profile yet) so every user gets
// a sane default target without extra onboarding steps.

class MacroTargets {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const MacroTargets({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory MacroTargets.forBodyweight(double weightKg) {
    final protein = weightKg * 2.0;
    final fat = weightKg * 1.0;
    final calories = weightKg * 30.0;
    final proteinCalories = protein * 4;
    final fatCalories = fat * 9;
    final carbsCalories = (calories - proteinCalories - fatCalories).clamp(0, double.infinity);
    final carbs = carbsCalories / 4;

    return MacroTargets(
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
    );
  }
}

const int waterTargetMl = 2500;
const int waterIncrementMl = 250;
