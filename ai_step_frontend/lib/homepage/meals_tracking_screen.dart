import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  // Mock user data - replace with actual profile data
  final int _dailyGoal = 2000; // Get from profile TDEE calculation
  final int _proteinGoal = 150; // Get from profile
  final int _carbsGoal = 250;
  final int _fatsGoal = 65;

  List<Map<String, dynamic>> _meals = [
    {
      'category': 'Breakfast',
      'icon': Icons.wb_sunny_rounded,
      'time': '08:30 AM',
      'foods': [
        {
          'name': 'Scrambled Eggs',
          'calories': 150,
          'protein': 12,
          'carbs': 2,
          'fats': 10,
          'amount': '2 eggs',
        },
        {
          'name': 'Whole Wheat Toast',
          'calories': 140,
          'protein': 6,
          'carbs': 24,
          'fats': 2,
          'amount': '2 slices',
        },
      ],
    },
    {
      'category': 'Lunch',
      'icon': Icons.wb_sunny_outlined,
      'time': '01:00 PM',
      'foods': [
        {
          'name': 'Grilled Chicken Breast',
          'calories': 280,
          'protein': 53,
          'carbs': 0,
          'fats': 6,
          'amount': '200g',
        },
        {
          'name': 'Brown Rice',
          'calories': 216,
          'protein': 5,
          'carbs': 45,
          'fats': 2,
          'amount': '1 cup',
        },
        {
          'name': 'Steamed Broccoli',
          'calories': 55,
          'protein': 4,
          'carbs': 11,
          'fats': 1,
          'amount': '1 cup',
        },
      ],
    },
    {
      'category': 'Dinner',
      'icon': Icons.nightlight_rounded,
      'time': 'Not logged',
      'foods': [],
    },
    {
      'category': 'Snacks',
      'icon': Icons.cookie_rounded,
      'time': '04:00 PM',
      'foods': [
        {
          'name': 'Greek Yogurt',
          'calories': 100,
          'protein': 17,
          'carbs': 6,
          'fats': 0,
          'amount': '170g',
        },
        {
          'name': 'Almonds',
          'calories': 160,
          'protein': 6,
          'carbs': 6,
          'fats': 14,
          'amount': '28g',
        },
      ],
    },
  ];

  // Comprehensive food database
  final List<Map<String, dynamic>> _foodDatabase = [
    // Proteins
    {
      'name': 'Chicken Breast',
      'calories': 165,
      'protein': 31,
      'carbs': 0,
      'fats': 3.6,
      'serving': '100g',
      'category': 'Protein',
    },
    {
      'name': 'Salmon',
      'calories': 208,
      'protein': 20,
      'carbs': 0,
      'fats': 13,
      'serving': '100g',
      'category': 'Protein',
    },
    {
      'name': 'Eggs',
      'calories': 155,
      'protein': 13,
      'carbs': 1.1,
      'fats': 11,
      'serving': '2 large',
      'category': 'Protein',
    },
    {
      'name': 'Greek Yogurt',
      'calories': 59,
      'protein': 10,
      'carbs': 3.6,
      'fats': 0.4,
      'serving': '100g',
      'category': 'Protein',
    },
    {
      'name': 'Tuna',
      'calories': 116,
      'protein': 26,
      'carbs': 0,
      'fats': 0.8,
      'serving': '100g',
      'category': 'Protein',
    },
    {
      'name': 'Beef Steak',
      'calories': 271,
      'protein': 25,
      'carbs': 0,
      'fats': 19,
      'serving': '100g',
      'category': 'Protein',
    },
    {
      'name': 'Tofu',
      'calories': 76,
      'protein': 8,
      'carbs': 1.9,
      'fats': 4.8,
      'serving': '100g',
      'category': 'Protein',
    },

    // Carbs
    {
      'name': 'Brown Rice',
      'calories': 112,
      'protein': 2.6,
      'carbs': 24,
      'fats': 0.9,
      'serving': '100g cooked',
      'category': 'Carbs',
    },
    {
      'name': 'White Rice',
      'calories': 130,
      'protein': 2.7,
      'carbs': 28,
      'fats': 0.3,
      'serving': '100g cooked',
      'category': 'Carbs',
    },
    {
      'name': 'Oatmeal',
      'calories': 71,
      'protein': 2.5,
      'carbs': 12,
      'fats': 1.5,
      'serving': '100g cooked',
      'category': 'Carbs',
    },
    {
      'name': 'Whole Wheat Bread',
      'calories': 70,
      'protein': 3,
      'carbs': 12,
      'fats': 1,
      'serving': '1 slice',
      'category': 'Carbs',
    },
    {
      'name': 'Sweet Potato',
      'calories': 86,
      'protein': 1.6,
      'carbs': 20,
      'fats': 0.1,
      'serving': '100g',
      'category': 'Carbs',
    },
    {
      'name': 'Pasta',
      'calories': 131,
      'protein': 5,
      'carbs': 25,
      'fats': 1.1,
      'serving': '100g cooked',
      'category': 'Carbs',
    },
    {
      'name': 'Quinoa',
      'calories': 120,
      'protein': 4.4,
      'carbs': 21,
      'fats': 1.9,
      'serving': '100g cooked',
      'category': 'Carbs',
    },

    // Vegetables
    {
      'name': 'Broccoli',
      'calories': 55,
      'protein': 3.7,
      'carbs': 11,
      'fats': 0.6,
      'serving': '1 cup',
      'category': 'Vegetables',
    },
    {
      'name': 'Spinach',
      'calories': 23,
      'protein': 2.9,
      'carbs': 3.6,
      'fats': 0.4,
      'serving': '100g',
      'category': 'Vegetables',
    },
    {
      'name': 'Tomato',
      'calories': 18,
      'protein': 0.9,
      'carbs': 3.9,
      'fats': 0.2,
      'serving': '100g',
      'category': 'Vegetables',
    },
    {
      'name': 'Cucumber',
      'calories': 16,
      'protein': 0.7,
      'carbs': 3.6,
      'fats': 0.1,
      'serving': '100g',
      'category': 'Vegetables',
    },
    {
      'name': 'Bell Pepper',
      'calories': 31,
      'protein': 1,
      'carbs': 6,
      'fats': 0.3,
      'serving': '100g',
      'category': 'Vegetables',
    },

    // Fruits
    {
      'name': 'Banana',
      'calories': 89,
      'protein': 1.1,
      'carbs': 23,
      'fats': 0.3,
      'serving': '1 medium',
      'category': 'Fruits',
    },
    {
      'name': 'Apple',
      'calories': 52,
      'protein': 0.3,
      'carbs': 14,
      'fats': 0.2,
      'serving': '1 medium',
      'category': 'Fruits',
    },
    {
      'name': 'Orange',
      'calories': 47,
      'protein': 0.9,
      'carbs': 12,
      'fats': 0.1,
      'serving': '1 medium',
      'category': 'Fruits',
    },
    {
      'name': 'Strawberries',
      'calories': 32,
      'protein': 0.7,
      'carbs': 7.7,
      'fats': 0.3,
      'serving': '100g',
      'category': 'Fruits',
    },
    {
      'name': 'Blueberries',
      'calories': 57,
      'protein': 0.7,
      'carbs': 14,
      'fats': 0.3,
      'serving': '100g',
      'category': 'Fruits',
    },

    // Nuts & Seeds
    {
      'name': 'Almonds',
      'calories': 579,
      'protein': 21,
      'carbs': 22,
      'fats': 50,
      'serving': '100g',
      'category': 'Nuts',
    },
    {
      'name': 'Peanut Butter',
      'calories': 94,
      'protein': 4,
      'carbs': 3,
      'fats': 8,
      'serving': '1 tbsp',
      'category': 'Nuts',
    },
    {
      'name': 'Walnuts',
      'calories': 654,
      'protein': 15,
      'carbs': 14,
      'fats': 65,
      'serving': '100g',
      'category': 'Nuts',
    },
    {
      'name': 'Chia Seeds',
      'calories': 486,
      'protein': 17,
      'carbs': 42,
      'fats': 31,
      'serving': '100g',
      'category': 'Seeds',
    },

    // Dairy
    {
      'name': 'Milk',
      'calories': 42,
      'protein': 3.4,
      'carbs': 5,
      'fats': 1,
      'serving': '100ml',
      'category': 'Dairy',
    },
    {
      'name': 'Cheese',
      'calories': 402,
      'protein': 25,
      'carbs': 1.3,
      'fats': 33,
      'serving': '100g',
      'category': 'Dairy',
    },
    {
      'name': 'Cottage Cheese',
      'calories': 98,
      'protein': 11,
      'carbs': 3.4,
      'fats': 4.3,
      'serving': '100g',
      'category': 'Dairy',
    },
  ];

  int get _totalCalories {
    int total = 0;
    for (var meal in _meals) {
      for (var food in meal['foods'] as List) {
        total += food['calories'] as int;
      }
    }
    return total;
  }

  int get _totalProtein {
    int total = 0;
    for (var meal in _meals) {
      for (var food in meal['foods'] as List) {
        total += (food['protein'] as num).round();
      }
    }
    return total;
  }

  int get _totalCarbs {
    int total = 0;
    for (var meal in _meals) {
      for (var food in meal['foods'] as List) {
        total += (food['carbs'] as num).round();
      }
    }
    return total;
  }

  int get _totalFats {
    int total = 0;
    for (var meal in _meals) {
      for (var food in meal['foods'] as List) {
        total += (food['fats'] as num).round();
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_totalCalories / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildCaloriesSummary(progress),
                      const SizedBox(height: 16),
                      _buildMacros(),
                      const SizedBox(height: 24),
                      ..._meals.asMap().entries.map(
                        (entry) => _buildMealCard(entry.value, entry.key),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFoodOptions,
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Food',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meals Tracking',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Track your nutrition',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showWeeklyView();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesSummary(double progress) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calories Today',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: _totalCalories),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, value, child) {
                          return Text(
                            value.toString(),
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF059669),
                              height: 1,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '/ $_dailyGoal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.restaurant_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: const Color(0xFFD1FAE5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF059669),
                  ),
                  minHeight: 10,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% of daily goal',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_dailyGoal - _totalCalories} kcal left',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacros() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Macronutrients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMacroItem(
                  'Protein',
                  _totalProtein,
                  _proteinGoal,
                  const Color(0xFF10B981),
                  Icons.egg_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroItem(
                  'Carbs',
                  _totalCarbs,
                  _carbsGoal,
                  const Color(0xFF34D399),
                  Icons.grain_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroItem(
                  'Fats',
                  _totalFats,
                  _fatsGoal,
                  const Color(0xFF6EE7B7),
                  Icons.water_drop_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(
    String label,
    int current,
    int goal,
    Color color,
    IconData icon,
  ) {
    final progress = (current / goal).clamp(0.0, 1.0);

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          '$current',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
          ),
        ),
        Text(
          '/ ${goal}g',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, int mealIndex) {
    final foods = meal['foods'] as List;
    final hasData = foods.isNotEmpty;

    int mealCalories = 0;
    for (var food in foods) {
      mealCalories += food['calories'] as int;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _showMealDetails(meal, mealIndex);
              },
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: hasData
                            ? const LinearGradient(
                                colors: [Color(0xFF059669), Color(0xFF10B981)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: hasData ? null : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        meal['icon'] as IconData,
                        color: hasData ? Colors.white : Colors.grey.shade400,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal['category'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meal['time'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          hasData ? mealCalories.toString() : '—',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: hasData
                                ? const Color(0xFF059669)
                                : Colors.grey.shade400,
                          ),
                        ),
                        Text(
                          'kcal',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasData)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: foods.map((food) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF059669),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food['name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              Text(
                                food['amount'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${food['calories']} cal',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF059669),
                              ),
                            ),
                            Text(
                              'P${food['protein']}g C${food['carbs']}g F${food['fats']}g',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              foods.remove(food);
                              if (foods.isEmpty) {
                                meal['time'] = 'Not logged';
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showAddFoodToMeal(mealIndex);
                },
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: const Color(0xFF059669),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Add Food',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFoodOptions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Meal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 24),
            ..._meals.asMap().entries.map((entry) {
              final meal = entry.value;
              final index = entry.key;
              return _buildMealOption(meal, index);
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMealOption(Map<String, dynamic> meal, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
            _showAddFoodToMeal(index);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF059669).withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    meal['icon'] as IconData,
                    color: const Color(0xFF059669),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    meal['category'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFF059669),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddFoodToMeal(int mealIndex) {
    final searchController = TextEditingController();
    List<Map<String, dynamic>> filteredFoods = List.from(_foodDatabase);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void searchFood(String query) {
            setModalState(() {
              if (query.isEmpty) {
                filteredFoods = List.from(_foodDatabase);
              } else {
                filteredFoods = _foodDatabase
                    .where(
                      (food) => food['name'].toString().toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                    )
                    .toList();
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add to ${_meals[mealIndex]['category']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  onChanged: searchFood,
                  decoration: InputDecoration(
                    hintText: 'Search foods...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF059669),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF059669).withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF059669),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredFoods.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No foods found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredFoods.length,
                          itemBuilder: (context, index) {
                            final food = filteredFoods[index];
                            return _buildFoodItem(food, mealIndex);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food, int mealIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showFoodDetails(food, mealIndex);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${food['calories']} cal • ${food['serving']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'P: ${food['protein']}g  C: ${food['carbs']}g  F: ${food['fats']}g',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_rounded,
                  color: const Color(0xFF059669),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFoodDetails(Map<String, dynamic> food, int mealIndex) {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              food['name'],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF059669),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                food['category'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${food['calories']} Calories',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildNutrientBox(
                    'Protein',
                    '${food['protein']}g',
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNutrientBox(
                    'Carbs',
                    '${food['carbs']}g',
                    const Color(0xFF34D399),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNutrientBox(
                    'Fats',
                    '${food['fats']}g',
                    const Color(0xFF6EE7B7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.straighten_rounded,
                    color: const Color(0xFF059669),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Serving Size: ${food['serving']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    final meal = _meals[mealIndex];
                    final foods = meal['foods'] as List;
                    foods.add({
                      'name': food['name'],
                      'calories': food['calories'],
                      'protein': food['protein'],
                      'carbs': food['carbs'],
                      'fats': food['fats'],
                      'amount': food['serving'],
                    });

                    if (meal['time'] == 'Not logged') {
                      final now = DateTime.now();
                      meal['time'] =
                          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${food['name']} added to ${_meals[mealIndex]['category']}!',
                      ),
                      backgroundColor: const Color(0xFF059669),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Add to Meal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showMealDetails(Map<String, dynamic> meal, int mealIndex) {
    HapticFeedback.lightImpact();
    _showAddFoodToMeal(mealIndex);
  }

  void _showWeeklyView() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Weekly Overview',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF059669),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Weekly calorie tracking coming soon!'),
            SizedBox(height: 16),
            Text(
              'You\'ll be able to see your nutrition trends and patterns.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Text(
              'Got it',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
