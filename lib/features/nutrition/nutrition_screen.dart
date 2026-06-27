import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/nutrition_entry.dart';
import '../../providers/nutrition_provider.dart';
import '../../shared/widgets/nutrition_widgets.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../shared/widgets/grit_button.dart';
import '../../utils/nutrition.dart';
import '../../app/routes.dart';
import 'package:go_router/go_router.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final summaryAsync = ref.watch(nutritionDayProvider);

    return Scaffold(
      backgroundColor: grit.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: grit.border, width: 1)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: grit.textPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Text('NUTRITION', style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.restaurant_menu, color: grit.accent),
                  onPressed: () => context.push(GritRoutes.mealPlan),
                ),
              ],
            ),
          ),
        ),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: GritSkeleton(height: 220, width: 220)),
        error: (e, st) => Center(
          child: Text('Failed to load nutrition data', style: GritTextStyles.label(13, color: grit.textSecondary)),
        ),
        data: (summary) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: MacroRings(
                  calories: summary.totals['calories'] ?? 0,
                  protein: summary.totals['protein'] ?? 0,
                  carbs: summary.totals['carbs'] ?? 0,
                  fat: summary.totals['fat'] ?? 0,
                  targets: summary.targets,
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: 20),
              MacroLegendRow(
                label: 'PROTEIN', value: summary.totals['protein'] ?? 0, target: summary.targets.proteinG,
                unit: 'g', color: grit.success,
              ),
              MacroLegendRow(
                label: 'CARBS', value: summary.totals['carbs'] ?? 0, target: summary.targets.carbsG,
                unit: 'g', color: grit.warning,
              ),
              MacroLegendRow(
                label: 'FAT', value: summary.totals['fat'] ?? 0, target: summary.targets.fatG,
                unit: 'g', color: grit.timerAmber,
              ),
              const SizedBox(height: 24),
              WaterTracker(
                currentMl: summary.waterMl,
                targetMl: waterTargetMl,
                onAdd: () {
                  GritHaptics.selectionTick();
                  ref.read(nutritionActionsProvider).addWater();
                },
                onRemove: () {
                  GritHaptics.selectionTick();
                  ref.read(nutritionActionsProvider).removeWater();
                },
              ),
              const SizedBox(height: 32),
              for (final meal in MealType.values) ...[
                _mealSection(context, ref, meal, summary.forMeal(meal)),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _mealSection(BuildContext context, WidgetRef ref, MealType meal, List<NutritionEntry> entries) {
    final grit = Theme.of(context).grit;
    final mealCalories = entries.fold<double>(0, (sum, e) => sum + e.calories);

    return Container(
      decoration: BoxDecoration(color: grit.surface, border: Border.all(color: grit.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(meal.label, style: GritTextStyles.tileTitle().copyWith(color: grit.textPrimary, letterSpacing: 1.5)),
                Row(
                  children: [
                    Text('${mealCalories.round()} KCAL', style: GritTextStyles.label(11, color: grit.textSecondary)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        GritHaptics.selectionTick();
                        _showAddFoodSheet(context, ref, meal);
                      },
                      child: Icon(Icons.add_circle, color: grit.accent, size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 14),
              child: Text('No items logged.', style: GritTextStyles.label(12, color: grit.muted)),
            )
          else
            for (final entry in entries)
              Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => ref.read(nutritionActionsProvider).deleteEntry(entry.id!),
                background: Container(color: grit.failureSet),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: grit.border, width: 0.5))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(entry.foodName, style: GritTextStyles.label(13, color: grit.textPrimary)),
                      ),
                      Text('${entry.calories.round()} KCAL', style: GritTextStyles.mono(11, color: grit.textSecondary)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _showAddFoodSheet(BuildContext context, WidgetRef ref, MealType meal) {
    final grit = Theme.of(context).grit;
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: grit.surface,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: 20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ADD TO ${meal.label}', style: GritTextStyles.titleMedium().copyWith(color: grit.textPrimary)),
              const SizedBox(height: 16),
              _textField(grit, nameController, 'FOOD NAME', isNumber: false),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _textField(grit, caloriesController, 'KCAL')),
                  const SizedBox(width: 8),
                  Expanded(child: _textField(grit, proteinController, 'PROTEIN G')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _textField(grit, carbsController, 'CARBS G')),
                  const SizedBox(width: 8),
                  Expanded(child: _textField(grit, fatController, 'FAT G')),
                ],
              ),
              const SizedBox(height: 20),
              GritPrimaryButton(
                label: 'ADD FOOD',
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  final entry = NutritionEntry(
                    date: DateTime.now().toIso8601String().split('T')[0],
                    mealType: meal,
                    foodName: nameController.text.trim(),
                    calories: double.tryParse(caloriesController.text) ?? 0,
                    protein: double.tryParse(proteinController.text) ?? 0,
                    carbs: double.tryParse(carbsController.text) ?? 0,
                    fat: double.tryParse(fatController.text) ?? 0,
                  );
                  ref.read(nutritionActionsProvider).addEntry(entry);
                  GritHaptics.mediumImpact();
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _textField(GritThemeData grit, TextEditingController controller, String label, {bool isNumber = true}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GritTextStyles.label(13, color: grit.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary),
      ),
    );
  }
}
