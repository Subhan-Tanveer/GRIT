import '../data/models/nutrition_entry.dart';

class Recipe {
  final String id;
  final String name;
  final MealType mealType;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<String> ingredients;

  const Recipe({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
  });
}

const List<Recipe> recipeCatalog = [
  // Breakfast
  Recipe(
    id: 'b1', name: 'Greek Yogurt & Berry Bowl', mealType: MealType.breakfast,
    calories: 380, protein: 32, carbs: 42, fat: 9,
    ingredients: ['1.5 cups Greek yogurt', '1 cup mixed berries', '2 tbsp honey', '1/4 cup granola'],
  ),
  Recipe(
    id: 'b2', name: 'Veggie Egg Scramble', mealType: MealType.breakfast,
    calories: 420, protein: 30, carbs: 18, fat: 24,
    ingredients: ['4 eggs', '1/2 cup bell peppers', '1/2 cup spinach', '1 oz cheddar', '1 slice toast'],
  ),
  Recipe(
    id: 'b3', name: 'Protein Oats', mealType: MealType.breakfast,
    calories: 440, protein: 28, carbs: 58, fat: 10,
    ingredients: ['1 cup rolled oats', '1 scoop protein powder', '1 banana', '1 tbsp peanut butter'],
  ),
  Recipe(
    id: 'b4', name: 'Cottage Cheese & Pineapple', mealType: MealType.breakfast,
    calories: 320, protein: 28, carbs: 30, fat: 8,
    ingredients: ['1.5 cups cottage cheese', '1 cup pineapple chunks', '1 tbsp flaxseed'],
  ),
  Recipe(
    id: 'b5', name: 'Breakfast Burrito', mealType: MealType.breakfast,
    calories: 480, protein: 26, carbs: 44, fat: 22,
    ingredients: ['2 eggs', '1 large tortilla', '1/4 cup black beans', '2 tbsp salsa', '1 oz cheese'],
  ),
  Recipe(
    id: 'b6', name: 'Smoked Salmon Bagel', mealType: MealType.breakfast,
    calories: 460, protein: 27, carbs: 48, fat: 16,
    ingredients: ['1 whole wheat bagel', '3 oz smoked salmon', '2 tbsp cream cheese', '1/2 red onion'],
  ),

  // Lunch
  Recipe(
    id: 'l1', name: 'Grilled Chicken Rice Bowl', mealType: MealType.lunch,
    calories: 620, protein: 48, carbs: 62, fat: 14,
    ingredients: ['6 oz chicken breast', '1.5 cups cooked rice', '1 cup broccoli', '1 tbsp olive oil'],
  ),
  Recipe(
    id: 'l2', name: 'Turkey & Avocado Wrap', mealType: MealType.lunch,
    calories: 560, protein: 38, carbs: 46, fat: 22,
    ingredients: ['6 oz turkey breast', '1 large tortilla', '1/2 avocado', 'lettuce', 'tomato'],
  ),
  Recipe(
    id: 'l3', name: 'Tuna Pasta Salad', mealType: MealType.lunch,
    calories: 580, protein: 40, carbs: 64, fat: 14,
    ingredients: ['2 cans tuna', '2 cups cooked pasta', '1/4 cup mayo', 'celery', 'red onion'],
  ),
  Recipe(
    id: 'l4', name: 'Beef & Sweet Potato Bowl', mealType: MealType.lunch,
    calories: 640, protein: 42, carbs: 58, fat: 22,
    ingredients: ['6 oz ground beef', '1 large sweet potato', '1 cup green beans', '1 tbsp olive oil'],
  ),
  Recipe(
    id: 'l5', name: 'Chickpea Quinoa Salad', mealType: MealType.lunch,
    calories: 540, protein: 24, carbs: 70, fat: 16,
    ingredients: ['1 cup quinoa', '1 cup chickpeas', 'cucumber', 'feta cheese', 'lemon dressing'],
  ),
  Recipe(
    id: 'l6', name: 'Shrimp Stir Fry', mealType: MealType.lunch,
    calories: 520, protein: 38, carbs: 50, fat: 14,
    ingredients: ['8 oz shrimp', '1.5 cups mixed vegetables', '1 cup rice', 'soy sauce'],
  ),

  // Dinner
  Recipe(
    id: 'd1', name: 'Salmon & Roasted Veggies', mealType: MealType.dinner,
    calories: 600, protein: 44, carbs: 32, fat: 28,
    ingredients: ['7 oz salmon fillet', '2 cups roasted vegetables', '1 tbsp olive oil'],
  ),
  Recipe(
    id: 'd2', name: 'Steak & Mashed Potatoes', mealType: MealType.dinner,
    calories: 700, protein: 46, carbs: 50, fat: 30,
    ingredients: ['8 oz sirloin steak', '2 cups mashed potatoes', '1 cup asparagus'],
  ),
  Recipe(
    id: 'd3', name: 'Chicken Fajita Bowl', mealType: MealType.dinner,
    calories: 620, protein: 46, carbs: 54, fat: 20,
    ingredients: ['7 oz chicken thigh', 'bell peppers', 'onion', '1.5 cups rice', 'fajita seasoning'],
  ),
  Recipe(
    id: 'd4', name: 'Baked Cod & Quinoa', mealType: MealType.dinner,
    calories: 540, protein: 42, carbs: 48, fat: 14,
    ingredients: ['7 oz cod fillet', '1 cup quinoa', '1 cup zucchini', 'lemon'],
  ),
  Recipe(
    id: 'd5', name: 'Turkey Chili', mealType: MealType.dinner,
    calories: 560, protein: 44, carbs: 46, fat: 16,
    ingredients: ['8 oz ground turkey', '1 can kidney beans', '1 can diced tomatoes', 'chili spices'],
  ),
  Recipe(
    id: 'd6', name: 'Pork Tenderloin & Rice', mealType: MealType.dinner,
    calories: 640, protein: 48, carbs: 56, fat: 20,
    ingredients: ['8 oz pork tenderloin', '1.5 cups rice', '1 cup green beans'],
  ),

  // Snacks
  Recipe(
    id: 's1', name: 'Protein Shake', mealType: MealType.snacks,
    calories: 220, protein: 30, carbs: 12, fat: 4,
    ingredients: ['1 scoop protein powder', '1 cup milk', '1/2 banana'],
  ),
  Recipe(
    id: 's2', name: 'Apple & Almond Butter', mealType: MealType.snacks,
    calories: 260, protein: 6, carbs: 32, fat: 14,
    ingredients: ['1 apple', '2 tbsp almond butter'],
  ),
  Recipe(
    id: 's3', name: 'Trail Mix', mealType: MealType.snacks,
    calories: 240, protein: 8, carbs: 22, fat: 16,
    ingredients: ['1/4 cup almonds', '2 tbsp raisins', '1 tbsp dark chocolate chips'],
  ),
  Recipe(
    id: 's4', name: 'Rice Cakes & Cottage Cheese', mealType: MealType.snacks,
    calories: 200, protein: 16, carbs: 24, fat: 4,
    ingredients: ['2 rice cakes', '1/2 cup cottage cheese'],
  ),
  Recipe(
    id: 's5', name: 'Hard-Boiled Eggs', mealType: MealType.snacks,
    calories: 180, protein: 14, carbs: 2, fat: 12,
    ingredients: ['2 hard-boiled eggs', 'pinch of salt'],
  ),
  Recipe(
    id: 's6', name: 'Greek Yogurt Cup', mealType: MealType.snacks,
    calories: 160, protein: 18, carbs: 14, fat: 3,
    ingredients: ['1 cup Greek yogurt', '1 tsp honey'],
  ),
];

List<Recipe> recipesFor(MealType type) => recipeCatalog.where((r) => r.mealType == type).toList();
