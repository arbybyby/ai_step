import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal.dart';
import '../models/user_meal.dart';
import '../services/meals_service.dart';

final mealsServiceProvider = Provider((ref) {
  return MealsService();
});

final allMealsProvider =
    StateNotifierProvider<AllMealsNotifier, AsyncValue<List<Meal>>>((ref) {
  final mealsService = ref.watch(mealsServiceProvider);
  return AllMealsNotifier(mealsService);
});

class AllMealsNotifier extends StateNotifier<AsyncValue<List<Meal>>> {
  final MealsService _mealsService;

  AllMealsNotifier(this._mealsService) : super(const AsyncValue.loading());

  Future<void> fetchAllMeals() async {
    print('\n=== AllMealsNotifier.fetchAllMeals START ===');
    state = const AsyncValue.loading();
    try {
      print('AllMealsNotifier.fetchAllMeals: Calling _mealsService.getAllMeals()...');
      final meals = await _mealsService.getAllMeals();
      print('AllMealsNotifier.fetchAllMeals: Got ${meals.length} meals, updating state');
      state = AsyncValue.data(meals);
      print('=== AllMealsNotifier.fetchAllMeals END ===\n');
    } on MealsServiceException catch (e) {
      print('AllMealsNotifier.fetchAllMeals: MealsServiceException - ${e.userFriendlyMessage}');
      state = AsyncValue.error(e, StackTrace.current);
      print('=== AllMealsNotifier.fetchAllMeals END ===\n');
    } catch (e) {
      print('AllMealsNotifier.fetchAllMeals: Error - $e');
      state = AsyncValue.error(e, StackTrace.current);
      print('=== AllMealsNotifier.fetchAllMeals END ===\n');
    }
  }
}

final mealsByTypeProvider =
    FutureProvider.family<List<Meal>, MealType>((ref, mealType) async {
  final mealsService = ref.watch(mealsServiceProvider);
  return mealsService.getMealsByType(mealType);
});

final filteredMealsProvider =
    StateNotifierProvider<FilteredMealsNotifier, List<Meal>>((ref) {
  final mealsService = ref.watch(mealsServiceProvider);
  return FilteredMealsNotifier(mealsService);
});

class FilteredMealsNotifier extends StateNotifier<List<Meal>> {
  final MealsService _mealsService;

  FilteredMealsNotifier(this._mealsService) : super([]);

  Future<void> searchMeals(String query) async {
    state = await _mealsService.searchMeals(query);
  }

  void clearSearch() {
    state = [];
  }
}

/// Provider for user-specific meals (meals tracked by the current user)
final userMealsProvider =
    StateNotifierProvider<UserMealsNotifier, AsyncValue<List<UserMeal>>>((ref) {
  final mealsService = ref.watch(mealsServiceProvider);
  return UserMealsNotifier(mealsService);
});

class UserMealsNotifier extends StateNotifier<AsyncValue<List<UserMeal>>> {
  final MealsService _mealsService;

  UserMealsNotifier(this._mealsService) : super(const AsyncValue.loading());

  Future<void> fetchUserMeals() async {
    print('\n=== UserMealsNotifier.fetchUserMeals START ===');
    state = const AsyncValue.loading();
    try {
      print('UserMealsNotifier.fetchUserMeals: Calling _mealsService.getUserMeals()...');
      final userMeals = await _mealsService.getUserMeals();
      print('UserMealsNotifier.fetchUserMeals: Got ${userMeals.length} user meals, updating state');
      state = AsyncValue.data(userMeals);
      print('=== UserMealsNotifier.fetchUserMeals END ===\n');
    } on MealsServiceException catch (e) {
      print('UserMealsNotifier.fetchUserMeals: MealsServiceException - ${e.userFriendlyMessage}');
      state = AsyncValue.error(e, StackTrace.current);
      print('=== UserMealsNotifier.fetchUserMeals END ===\n');
    } catch (e) {
      print('UserMealsNotifier.fetchUserMeals: Error - $e');
      state = AsyncValue.error(e, StackTrace.current);
      print('=== UserMealsNotifier.fetchUserMeals END ===\n');
    }
  }

  /// Add a newly tracked meal to the user meals list immediately
  void addTrackedMeal(UserMeal userMeal) {
    print('\n=== UserMealsNotifier.addTrackedMeal START ===');
    print('UserMealsNotifier.addTrackedMeal: Adding meal: ${userMeal.mealName}');
    
    state.whenData((meals) {
      final updatedMeals = [...meals, userMeal];
      state = AsyncValue.data(updatedMeals);
      print('UserMealsNotifier.addTrackedMeal: Meal added, total: ${updatedMeals.length}');
      print('=== UserMealsNotifier.addTrackedMeal END ===\n');
    });
  }

  /// Refresh user meals from the server to sync any changes
  Future<void> refreshUserMeals() async {
    print('\n=== UserMealsNotifier.refreshUserMeals START ===');
    try {
      print('UserMealsNotifier.refreshUserMeals: Calling _mealsService.getUserMeals()...');
      final userMeals = await _mealsService.getUserMeals();
      print('UserMealsNotifier.refreshUserMeals: Got ${userMeals.length} user meals, updating state');
      state = AsyncValue.data(userMeals);
      print('=== UserMealsNotifier.refreshUserMeals END ===\n');
    } on MealsServiceException catch (e) {
      print('UserMealsNotifier.refreshUserMeals: MealsServiceException - ${e.userFriendlyMessage}');
      state = AsyncValue.error(e, StackTrace.current);
      print('=== UserMealsNotifier.refreshUserMeals END ===\n');
    } catch (e) {
      print('UserMealsNotifier.refreshUserMeals: Error - $e');
      state = AsyncValue.error(e, StackTrace.current);
      print('=== UserMealsNotifier.refreshUserMeals END ===\n');
    }
  }

  /// Delete a meal entry and remove it from the state
  Future<void> deleteMeal(int mealId, int userId) async {
    print('\n=== UserMealsNotifier.deleteMeal START ===');
    print('UserMealsNotifier.deleteMeal: Deleting meal with id: $mealId');
    
    try {
      // Delete from server first
      await _mealsService.deleteMeal(id: mealId, userId: userId);
      print('UserMealsNotifier.deleteMeal: Meal deleted from server');
      
      // Remove from local state
      state.whenData((meals) {
        final updatedMeals = meals.where((m) => m.id != mealId).toList();
        state = AsyncValue.data(updatedMeals);
        print('UserMealsNotifier.deleteMeal: Meal removed from state, total: ${updatedMeals.length}');
        print('=== UserMealsNotifier.deleteMeal END ===\n');
      });
    } on MealsServiceException catch (e) {
      print('UserMealsNotifier.deleteMeal: MealsServiceException - ${e.userFriendlyMessage}');
      state = AsyncValue.error(e, StackTrace.current);
      print('=== UserMealsNotifier.deleteMeal END ===\n');
      rethrow;
    } catch (e) {
      print('UserMealsNotifier.deleteMeal: Error - $e');
      state = AsyncValue.error(e, StackTrace.current);
      print('=== UserMealsNotifier.deleteMeal END ===\n');
      rethrow;
    }
  }

  /// Group user meals by meal type
  Map<MealType, List<UserMeal>> groupByMealType(List<UserMeal> meals) {
    final Map<MealType, List<UserMeal>> grouped = {
      MealType.breakfast: [],
      MealType.lunch: [],
      MealType.dinner: [],
      MealType.snacks: [],
    };

    for (var meal in meals) {
      grouped[meal.mealType]?.add(meal);
    }

    return grouped;
  }

  /// Calculate total calories from a list of user meals
  double calculateTotalCalories(List<UserMeal> meals) {
    return meals.fold(0.0, (sum, meal) => sum + meal.calories);
  }

  /// Calculate total protein from a list of user meals
  double calculateTotalProtein(List<UserMeal> meals) {
    return meals.fold(0.0, (sum, meal) => sum + meal.protein);
  }

  /// Calculate total carbs from a list of user meals
  double calculateTotalCarbs(List<UserMeal> meals) {
    return meals.fold(0.0, (sum, meal) => sum + meal.carbs);
  }

  /// Calculate total fat from a list of user meals
  double calculateTotalFat(List<UserMeal> meals) {
    return meals.fold(0.0, (sum, meal) => sum + meal.fat);
  }
}
