import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal.dart';
import '../providers/meals_provider.dart';

extension MealTypeExtension on MealType {
  String getMealTypeLabel() {
    switch (this) {
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

class MealsTrackingScreen extends ConsumerStatefulWidget {
  const MealsTrackingScreen({super.key});

  @override
  ConsumerState<MealsTrackingScreen> createState() =>
      _MealsTrackingScreenState();
}

class _MealsTrackingScreenState extends ConsumerState<MealsTrackingScreen> {
  final Map<MealType, List<Meal>> _selectedMeals = {
    MealType.breakfast: [],
    MealType.lunch: [],
    MealType.dinner: [],
    MealType.snacks: [],
  };

  @override
  void initState() {
    super.initState();
    print('\n=== MealsTrackingScreen.initState START ===');
    Future.microtask(() {
      print('MealsTrackingScreen.initState: Calling fetchAllMeals()');
      ref.read(allMealsProvider.notifier).fetchAllMeals();
    });
    print('=== MealsTrackingScreen.initState END ===\n');
  }

  double _getTotalCalories() {
    double total = 0;
    _selectedMeals.values.forEach((meals) {
      total += meals.fold(0, (sum, meal) => sum + meal.calories);
    });
    return total;
  }

  double _getTotalMacro(String macro) {
    double total = 0;
    _selectedMeals.values.forEach((meals) {
      total += meals.fold(0, (sum, meal) {
        if (macro == 'protein') {
          return sum + meal.protein;
        } else if (macro == 'carbs') {
          return sum + meal.carbs;
        } else if (macro == 'fat') {
          return sum + meal.fat;
        }
        return sum;
      });
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meals Tracking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Track your nutrition',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B7A5A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1B7A5A),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildCaloriesCard(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildMacronutrientsCard(),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildMealSection(MealType.breakfast),
                    _buildMealSection(MealType.lunch),
                    _buildMealSection(MealType.dinner),
                    _buildMealSection(MealType.snacks),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFoodDialog(context),
        backgroundColor: const Color(0xFF1B7A5A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCaloriesCard() {
    const dailyGoal = 2000.0;
    final totalCalories = _getTotalCalories();
    final percentage = (totalCalories / dailyGoal * 100).clamp(0, 100);
    final caloriesLeft = (dailyGoal - totalCalories).clamp(0, dailyGoal);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calories Today',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${totalCalories.toInt()}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B7A5A),
                    ),
                  ),
                  Text(
                    '/ ${dailyGoal.toInt()}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1B7A5A).withOpacity(0.1),
                ),
                child: Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 40,
                    color: const Color(0xFF1B7A5A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1B7A5A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toInt()}% of daily goal',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${caloriesLeft.toInt()} kcal left',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1B7A5A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacronutrientsCard() {
    const macroGoals = {
      'protein': 150.0,
      'carbs': 250.0,
      'fat': 65.0,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Macronutrients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B7A5A),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMacroItem(
                'Protein',
                _getTotalMacro('protein'),
                macroGoals['protein']!,
                Icons.egg,
              ),
              _buildMacroItem(
                'Carbs',
                _getTotalMacro('carbs'),
                macroGoals['carbs']!,
                Icons.grain,
              ),
              _buildMacroItem(
                'Fats',
                _getTotalMacro('fat'),
                macroGoals['fat']!,
                Icons.water_drop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(
    String label,
    double current,
    double goal,
    IconData icon,
  ) {
    final percentage = (current / goal * 100).clamp(0, 100);

    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1B7A5A), size: 32),
        const SizedBox(height: 8),
        Text(
          '${current.toInt()}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B7A5A),
          ),
        ),
        Text(
          '/ ${goal.toInt()}g',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 4,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1B7A5A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection(MealType mealType) {
    final meals = _selectedMeals[mealType] ?? [];
    final totalCalories =
        meals.fold(0.0, (sum, meal) => sum + meal.calories);
    final mealTypeLabel = mealType.getMealTypeLabel();
    final mealIcon = _getMealIcon(mealType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B7A5A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        mealIcon,
                        color: const Color(0xFF1B7A5A),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealTypeLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B7A5A),
                        ),
                      ),
                      Text(
                        '${_getMealTime(mealType)} ${meals.isEmpty ? '• Not logged' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: meals.isEmpty ? Colors.grey : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${totalCalories.toInt()}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B7A5A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'kcal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
            if (meals.isNotEmpty)
              Container(
                color: const Color(0xFF1B7A5A).withOpacity(0.05),
                child: Column(
                  children: meals.map((meal) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1B7A5A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.mealName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1B7A5A),
                                  ),
                                ),
                                Text(
                                  'P${meal.protein.toInt()}g C${meal.carbs.toInt()}g F${meal.fat.toInt()}g',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${meal.calories.toInt()} kcal',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B7A5A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMeals[mealType]?.remove(meal);
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () {
                  _showAddFoodDialog(context, mealType);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      color: const Color(0xFF1B7A5A).withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Food',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF1B7A5A).withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMealIcon(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.wb_sunny_outlined;
      case MealType.dinner:
        return Icons.nights_stay;
      case MealType.snacks:
        return Icons.cookie;
    }
  }

  String _getMealTime(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return '08:30 AM';
      case MealType.lunch:
        return '01:00 PM';
      case MealType.dinner:
        return '07:00 PM';
      case MealType.snacks:
        return '04:00 PM';
    }
  }

  void _showAddFoodDialog(BuildContext context, [MealType? mealType]) {
    print('MealsTrackingScreen._showAddFoodDialog: Opening dialog for mealType: $mealType');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AddFoodDialog(
          mealType: mealType,
          onFoodSelected: (meal, selectedMealType) {
            setState(() {
              if (!_selectedMeals.containsKey(selectedMealType)) {
                _selectedMeals[selectedMealType] = [];
              }
              _selectedMeals[selectedMealType]!.add(meal);
            });
          },
        );
      },
    );
  }
}

class _AddFoodDialog extends ConsumerStatefulWidget {
  final MealType? mealType;
  final Function(Meal, MealType) onFoodSelected;

  const _AddFoodDialog({
    required this.mealType,
    required this.onFoodSelected,
  });

  @override
  ConsumerState<_AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends ConsumerState<_AddFoodDialog> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  MealType? _selectedMealType;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedMealType = widget.mealType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('_AddFoodDialogState.build: Building dialog');
    final allMeals = ref.watch(allMealsProvider);
    print('_AddFoodDialogState.build: allMeals state - $allMeals');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    _selectedMealType != null
                        ? 'Add to ${_selectedMealType!.getMealTypeLabel()}'
                        : 'Add Food',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B7A5A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedMealType == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Meal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B7A5A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2,
                      children: [
                        _mealTypeButton(MealType.breakfast),
                        _mealTypeButton(MealType.lunch),
                        _mealTypeButton(MealType.dinner),
                        _mealTypeButton(MealType.snacks),
                      ],
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Adding to:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B7A5A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMealType = null;
                            });
                          },
                          child: const Text(
                            'Change',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1B7A5A),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B7A5A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedMealType!.getMealTypeLabel(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B7A5A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search foods...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: allMeals.when(
                data: (meals) {
                  // Filter meals based on search query
                  final filteredMeals = _searchQuery.isEmpty
                      ? meals
                      : meals
                          .where((meal) => meal.mealName
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                          .toList();

                  return SingleChildScrollView(
                    child: Column(
                      children: filteredMeals.map((meal) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B7A5A)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.restaurant,
                                          color: Color(0xFF1B7A5A),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meal.mealName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B7A5A),
                                            ),
                                          ),
                                          Text(
                                            '${meal.calories.toInt()} kcal • ${_getServingSize(meal)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            'P: ${meal.protein.toInt()}g C: ${meal.carbs.toInt()}g F: ${meal.fat.toInt()}g',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            'Category: ${meal.getMealTypeLabel()}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        if (_selectedMealType != null) {
                                          widget.onFoodSelected(
                                            meal,
                                            _selectedMealType!,
                                          );
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B7A5A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF1B7A5A),
                    ),
                  ),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $err'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _mealTypeButton(MealType mealType) {
    final isSelected = _selectedMealType == mealType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMealType = mealType;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B7A5A)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF1B7A5A),
                  width: 2,
                )
              : null,
        ),
        child: Center(
          child: Text(
            mealType.getMealTypeLabel(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  String _getServingSize(Meal meal) {
    // Simple serving size based on meal name
    if (meal.mealName.contains('Yogurt')) return '100g';
    if (meal.mealName.contains('Almonds')) return '28g';
    if (meal.mealName.contains('Toast')) return '2 slices';
    if (meal.mealName.contains('Eggs')) return '2 large';
    if (meal.mealName.contains('Broccoli')) return '1 cup';
    if (meal.mealName.contains('Rice')) return '1 cup';
    return '100g';
  }
}
