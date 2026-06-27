import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/nutrition_entry.dart';
import '../../providers/meal_plan_provider.dart';
import '../../utils/recipes.dart';

class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  int _selectedDay = 0;

  static const _dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final plan = ref.watch(mealPlanProvider);
    final dayPlan = plan[_selectedDay]!;
    final dayTotal = dayPlan.values.fold<double>(0, (sum, r) => sum + r.calories);

    return Scaffold(
      backgroundColor: grit.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: grit.border, width: 1))),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: grit.textPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Text('MEAL PLAN', style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.shopping_cart, color: grit.accent),
                  onPressed: () => _showGroceryList(context),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: grit.accent),
                  onPressed: () {
                    GritHaptics.mediumImpact();
                    ref.read(mealPlanSeedProvider.notifier).regenerate();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _dayTabs(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 8),
            child: Text(
              '${dayTotal.round()} KCAL TOTAL',
              style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 1),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 8),
              children: [
                for (final mealType in MealType.values) _mealCard(context, mealType, dayPlan[mealType]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayTabs(BuildContext context) {
    final grit = Theme.of(context).grit;
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 8),
        itemCount: 7,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDay;
          return GestureDetector(
            onTap: () {
              GritHaptics.selectionTick();
              setState(() => _selectedDay = index);
            },
            child: Container(
              width: 56,
              margin: const EdgeInsets.only(right: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? grit.accent : Colors.transparent,
                border: Border.all(color: isSelected ? grit.accent : grit.border),
              ),
              child: Text(
                _dayLabels[index],
                style: GritTextStyles.label(11, weight: FontWeight.w700,
                    color: isSelected ? Colors.white : grit.textSecondary),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mealCard(BuildContext context, MealType type, Recipe recipe) {
    final grit = Theme.of(context).grit;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: grit.surface, border: Border.all(color: grit.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type.label, style: GritTextStyles.labelMicro().copyWith(color: grit.accent, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(recipe.name, style: GritTextStyles.tileTitle().copyWith(color: grit.textPrimary)),
          const SizedBox(height: 6),
          Text(
            '${recipe.calories.round()} KCAL · ${recipe.protein.round()}P / ${recipe.carbs.round()}C / ${recipe.fat.round()}F',
            style: GritTextStyles.label(11, color: grit.textSecondary),
          ),
          const SizedBox(height: 10),
          for (final ingredient in recipe.ingredients)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• $ingredient', style: GritTextStyles.label(11, color: grit.muted)),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  void _showGroceryList(BuildContext context) {
    final grit = Theme.of(context).grit;
    final items = ref.read(groceryListProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: grit.background,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetCtx, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 36, height: 4, decoration: BoxDecoration(color: grit.border)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('GROCERY LIST (THIS WEEK)',
                      style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (itemContext, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.check_box_outline_blank, size: 16, color: grit.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(items[index], style: GritTextStyles.label(13, color: grit.textPrimary))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
