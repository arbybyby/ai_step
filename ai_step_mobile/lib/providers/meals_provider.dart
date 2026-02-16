import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal.dart';
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
