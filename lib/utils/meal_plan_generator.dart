import '../data/models/nutrition_entry.dart';
import 'nutrition.dart';
import 'recipes.dart';

/// Generates a 7-day meal plan by picking one recipe per meal slot, rotating
/// through the catalog so the same recipe doesn't repeat within a few days,
/// and roughly balancing toward the day's calorie target.
class MealPlanGenerator {
  MealPlanGenerator._();

  static Map<int, Map<MealType, Recipe>> generateWeek(MacroTargets targets, {int seed = 0}) {
    final plan = <int, Map<MealType, Recipe>>{};
    final recentlyUsed = <String>{};

    for (int day = 0; day < 7; day++) {
      final dayPlan = <MealType, Recipe>{};
      for (final mealType in MealType.values) {
        final options = recipesFor(mealType);
        final available = options.where((r) => !recentlyUsed.contains(r.id)).toList();
        final pool = available.isNotEmpty ? available : options;

        // Pick whichever option's calories are closest to an even split of
        // the daily target across 4 meal slots. The seed rotates the
        // starting offset so "regenerate" produces real variety instead of
        // always picking the single closest match.
        final targetPerMeal = targets.calories / 4;
        final sorted = [...pool]
          ..sort((a, b) => (a.calories - targetPerMeal).abs().compareTo((b.calories - targetPerMeal).abs()));
        final offset = (seed + day) % sorted.length;
        final chosen = sorted[offset];

        dayPlan[mealType] = chosen;
        recentlyUsed.add(chosen.id);
        if (recentlyUsed.length > 12) {
          recentlyUsed.remove(recentlyUsed.first);
        }
      }
      plan[day] = dayPlan;
    }
    return plan;
  }

  /// Aggregates every ingredient line across the whole week into a flat,
  /// deduplicated grocery list (sorted alphabetically).
  static List<String> groceryListFor(Map<int, Map<MealType, Recipe>> week) {
    final items = <String>{};
    for (final dayPlan in week.values) {
      for (final recipe in dayPlan.values) {
        items.addAll(recipe.ingredients);
      }
    }
    final sorted = items.toList()..sort();
    return sorted;
  }
}
