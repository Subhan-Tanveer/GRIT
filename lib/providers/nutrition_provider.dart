import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dao_providers.dart';
import 'profile_provider.dart';
import '../data/models/nutrition_entry.dart';
import '../utils/nutrition.dart';

String _todayIso() => DateTime.now().toIso8601String().split('T')[0];

class NutritionDaySummary {
  final List<NutritionEntry> entries;
  final Map<String, double> totals;
  final int waterMl;
  final MacroTargets targets;

  const NutritionDaySummary({
    required this.entries,
    required this.totals,
    required this.waterMl,
    required this.targets,
  });

  List<NutritionEntry> forMeal(MealType type) =>
      entries.where((e) => e.mealType == type).toList();
}

final nutritionDayProvider = FutureProvider.autoDispose<NutritionDaySummary>((ref) async {
  final dao = ref.watch(nutritionDaoProvider);
  final profile = ref.watch(profileProvider);
  final today = _todayIso();

  final entries = await dao.getForDate(today);
  final totals = await dao.getTotalsForDate(today);
  final water = await dao.getTotalWaterForDate(today);
  final targets = MacroTargets.forBodyweight(profile.weightKg);

  return NutritionDaySummary(entries: entries, totals: totals, waterMl: water, targets: targets);
});

final weeklyCaloriesProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final dao = ref.watch(nutritionDaoProvider);
  return dao.getDailyCaloriesForPeriod(7);
});

class NutritionActions {
  final Ref ref;
  NutritionActions(this.ref);

  Future<void> addEntry(NutritionEntry entry) async {
    final dao = ref.read(nutritionDaoProvider);
    await dao.insertEntry(entry);
    ref.invalidate(nutritionDayProvider);
    ref.invalidate(weeklyCaloriesProvider);
  }

  Future<void> deleteEntry(int id) async {
    final dao = ref.read(nutritionDaoProvider);
    await dao.deleteEntry(id);
    ref.invalidate(nutritionDayProvider);
    ref.invalidate(weeklyCaloriesProvider);
  }

  Future<void> addWater() async {
    final dao = ref.read(nutritionDaoProvider);
    await dao.addWater(_todayIso(), waterIncrementMl);
    ref.invalidate(nutritionDayProvider);
  }

  Future<void> removeWater() async {
    final dao = ref.read(nutritionDaoProvider);
    await dao.removeLastWaterEntry(_todayIso());
    ref.invalidate(nutritionDayProvider);
  }
}

final nutritionActionsProvider = Provider((ref) => NutritionActions(ref));
