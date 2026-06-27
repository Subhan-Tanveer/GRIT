import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_preferences_provider.dart';
import 'profile_provider.dart';
import '../data/models/nutrition_entry.dart';
import '../utils/meal_plan_generator.dart';
import '../utils/nutrition.dart';
import '../utils/recipes.dart';

const _seedPrefKey = 'grit_meal_plan_seed';

class MealPlanSeedNotifier extends Notifier<int> {
  @override
  int build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getInt(_seedPrefKey) ?? 0;
  }

  Future<void> regenerate() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final next = state + 1;
    await prefs.setInt(_seedPrefKey, next);
    state = next;
  }
}

final mealPlanSeedProvider = NotifierProvider<MealPlanSeedNotifier, int>(MealPlanSeedNotifier.new);

final mealPlanProvider = Provider<Map<int, Map<MealType, Recipe>>>((ref) {
  final profile = ref.watch(profileProvider);
  final seed = ref.watch(mealPlanSeedProvider);
  final targets = MacroTargets.forBodyweight(profile.weightKg);
  return MealPlanGenerator.generateWeek(targets, seed: seed);
});

final groceryListProvider = Provider<List<String>>((ref) {
  final plan = ref.watch(mealPlanProvider);
  return MealPlanGenerator.groceryListFor(plan);
});
