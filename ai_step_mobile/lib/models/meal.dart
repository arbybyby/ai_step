enum MealType { breakfast, lunch, dinner, snacks }

class Meal {
  final int id;
  final String mealName;
  final MealType mealType;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  Meal({
    required this.id,
    required this.mealName,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as int,
      mealName: json['mealName'] as String,
      mealType: _parseMealType(json['mealType']),
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealName': mealName,
      'mealType': mealType.toString().split('.').last,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  static MealType _parseMealType(dynamic value) {
    // Handle integer values (0 = breakfast, 1 = lunch, 2 = dinner)
    if (value is int) {
      switch (value) {
        case 0:
          return MealType.breakfast;
        case 1:
          return MealType.lunch;
        case 2:
          return MealType.dinner;
        default:
          return MealType.breakfast;
      }
    }

    // Handle string values
    if (value is String) {
      return MealType.values.firstWhere(
        (e) => e.toString().split('.').last == value.toLowerCase(),
        orElse: () => MealType.breakfast,
      );
    }

    return MealType.breakfast;
  }

  String getMealTypeLabel() {
    switch (mealType) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snacks:
        return 'Snacks';
    }
  }
}
