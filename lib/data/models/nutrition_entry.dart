enum MealType { breakfast, lunch, dinner, snacks }

extension MealTypeX on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'BREAKFAST',
        MealType.lunch => 'LUNCH',
        MealType.dinner => 'DINNER',
        MealType.snacks => 'SNACKS',
      };

  String get dbValue => name;

  static MealType fromDb(String value) =>
      MealType.values.firstWhere((m) => m.name == value, orElse: () => MealType.snacks);
}

class NutritionEntry {
  final int? id;
  final String date;
  final MealType mealType;
  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double quantity;
  final String unit;

  const NutritionEntry({
    this.id,
    required this.date,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.quantity = 1,
    this.unit = 'serving',
  });

  factory NutritionEntry.fromMap(Map<String, dynamic> m) => NutritionEntry(
        id: m['id'] as int?,
        date: m['date'] as String,
        mealType: MealTypeX.fromDb(m['meal_type'] as String),
        foodName: m['food_name'] as String,
        calories: (m['calories'] as num).toDouble(),
        protein: (m['protein'] as num).toDouble(),
        carbs: (m['carbs'] as num).toDouble(),
        fat: (m['fat'] as num).toDouble(),
        quantity: (m['quantity'] as num).toDouble(),
        unit: m['unit'] as String? ?? 'serving',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'meal_type': mealType.dbValue,
        'food_name': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'quantity': quantity,
        'unit': unit,
      };
}

class WaterEntry {
  final int? id;
  final String date;
  final int amountMl;

  const WaterEntry({this.id, required this.date, required this.amountMl});

  factory WaterEntry.fromMap(Map<String, dynamic> m) => WaterEntry(
        id: m['id'] as int?,
        date: m['date'] as String,
        amountMl: m['amount_ml'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'amount_ml': amountMl,
      };
}
