import 'meal.dart';

/// Represents a meal entry for a specific user
/// This corresponds to the data returned from /api/meals endpoint
class UserMeal {
  final int id;
  final int userId;
  final int mealId;
  final String mealName;
  final MealType mealType;
  final double grammes;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  UserMeal({
    required this.id,
    required this.userId,
    required this.mealId,
    required this.mealName,
    required this.mealType,
    required this.grammes,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory UserMeal.fromJson(Map<String, dynamic> json) {
    return UserMeal(
      id: json['id'] as int,
      userId: json['userID'] as int,
      mealId: json['mealID'] as int,
      mealName: json['mealName'] as String,
      mealType: _parseMealType(json['mealType']),
      grammes: (json['grammes'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );
  }

  /// Create a UserMeal from a Meal for immediate display
  /// Used when a meal is just added and need to show it immediately
  factory UserMeal.fromMeal({
    required Meal meal,
    required int userId,
  }) {
    return UserMeal(
      id: 0, // Will be assigned by server on next sync
      userId: userId,
      mealId: meal.id,
      mealName: meal.mealName,
      mealType: meal.mealType,
      grammes: meal.grammes,
      calories: meal.calories,
      protein: meal.protein,
      carbs: meal.carbs,
      fat: meal.fat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userID': userId,
      'mealID': mealId,
      'mealName': mealName,
      'mealType': _mealTypeToString(mealType),
      'grammes': grammes,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  static MealType _parseMealType(dynamic value) {
    // Handle integer values (0 = breakfast, 1 = lunch, 2 = dinner, 3 = snacks)
    if (value is int) {
      switch (value) {
        case 0:
          return MealType.breakfast;
        case 1:
          return MealType.lunch;
        case 2:
          return MealType.dinner;
        case 3:
          return MealType.snacks;
        default:
          return MealType.breakfast;
      }
    }

    // Handle string values (case-insensitive)
    if (value is String) {
      final lowercaseValue = value.toLowerCase();
      return MealType.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == lowercaseValue,
        orElse: () => MealType.breakfast,
      );
    }

    return MealType.breakfast;
  }

  static String _mealTypeToString(MealType mealType) {
    return mealType.toString().split('.').last;
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

  /// Convert UserMeal to a base Meal object (without user tracking info)
  Meal toMeal() {
    return Meal(
      id: mealId,
      mealName: mealName,
      mealType: mealType,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      grammes: grammes,
    );
  }
}
