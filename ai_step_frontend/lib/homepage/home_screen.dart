import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/pedometer_service.dart';
import '../services/auth_service.dart';
import '../services/steps_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final int _goalSteps = 10000;
  String _userName = 'User';
  bool _isRefreshing = false;
  
  // Weekly progress data
  List<int> _weeklySteps = [0, 0, 0, 0, 0, 0, 0]; // Mon-Sun
  bool _weeklyDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
    _loadUserName();
    
    // Загружаем данные после построения виджета, когда провайдеры готовы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadUserName() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user != null) {
      setState(() {
        _userName = authService.user!.firstName;
      });
    }
  }

  Future<void> _loadInitialData() async {
    try {
      print('═══════════════════════════════════════');
      print('🚀 Loading initial data on app entry');
      print('═══════════════════════════════════════');
      
      final pedometer = Provider.of<PedometerService>(context, listen: false);
      final stepsService = Provider.of<StepsService>(context, listen: false);
      
      print('📍 Step 1: Current pedometer state BEFORE server load');
      print('   Local steps: ${pedometer.steps}');
      print('   Is simulating: ${pedometer.isSimulating}');
      
      // Загружаем данные с сервера при входе в приложение
      print('📍 Step 2: Loading from server...');
      await stepsService.getDailySteps(forceUpdate: true);
      
      print('📍 Step 3: Server data loaded');
      print('   Server steps: ${stepsService.serverSteps}');
      print('   Server distance: ${stepsService.serverDistanceM} m');
      print('   Server calories: ${stepsService.serverCalories}');
      
      // Синхронизируем локальный счетчик педометра с сервером
      print('📍 Step 4: Syncing pedometer with server...');
      await pedometer.loadFromServer();
      
      print('📍 Step 5: Final state after sync');
      print('   Local steps: ${pedometer.steps}');
      print('   Distance: ${pedometer.distance.toStringAsFixed(2)} km');
      print('   Calories: ${pedometer.calories.toStringAsFixed(1)} kcal');
      
      // Загружаем weekly progress
      print('📍 Step 6: Loading weekly progress...');
      await _loadWeeklyProgress();
      
      // Принудительно обновляем UI
      if (mounted) {
        setState(() {});
        print('📍 Step 7: UI force updated');
      }
      
      print('═══════════════════════════════════════');
      print('✅ Initial data loading completed');
      print('═══════════════════════════════════════');
    } catch (e, stackTrace) {
      print('❌ Error loading initial data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadWeeklyProgress() async {
    try {
      final stepsService = Provider.of<StepsService>(context, listen: false);
      final weeklyData = await stepsService.getWeeklyProgress();
      
      print('📊 =================================');
      print('📊 Loading Weekly Progress Data');
      print('📊 =================================');
      print('Raw response: $weeklyData');
      
      if (weeklyData != null && weeklyData['data'] != null) {
        final data = weeklyData['data'];
        print('Data object: $data');
        print('Data type: ${data.runtimeType}');
        print('Data keys: ${data is Map ? data.keys.toList() : "Not a map"}');
        
        // Извлекаем daily breakdown (массив данных по дням недели)
        if (data['daily_breakdown'] != null && data['daily_breakdown'] is List) {
          final dailyBreakdown = data['daily_breakdown'] as List;
          print('✅ Found daily_breakdown with ${dailyBreakdown.length} days');
          
          // Создаем новый список для хранения шагов по дням
          List<int> newWeeklySteps = [0, 0, 0, 0, 0, 0, 0];
          
          for (var day in dailyBreakdown) {
            if (day is Map) {
              final dayOfWeek = day['day_of_week']; // 1=Monday, 7=Sunday
              final steps = day['steps'] ?? 0;
              final dayName = day['day_name'] ?? 'Unknown';
              
              print('  Day: $dayName (day_of_week: $dayOfWeek), steps: $steps');
              
              if (dayOfWeek != null && dayOfWeek >= 1 && dayOfWeek <= 7) {
                // Преобразуем day_of_week (1-7) в индекс массива (0-6)
                newWeeklySteps[dayOfWeek - 1] = steps is int ? steps : (steps as num).toInt();
              }
            }
          }
          
          setState(() {
            _weeklySteps = newWeeklySteps;
            _weeklyDataLoaded = true;
          });
          
          print('✅ Weekly steps loaded successfully!');
          print('   Monday: ${newWeeklySteps[0]}');
          print('   Tuesday: ${newWeeklySteps[1]}');
          print('   Wednesday: ${newWeeklySteps[2]}');
          print('   Thursday: ${newWeeklySteps[3]}');
          print('   Friday: ${newWeeklySteps[4]}');
          print('   Saturday: ${newWeeklySteps[5]}');
          print('   Sunday: ${newWeeklySteps[6]}');
        } else {
          print('⚠️ No daily_breakdown in weekly progress data');
          print('   Available keys: ${data is Map ? data.keys.toList() : "Not a map"}');
        }
      } else {
        print('⚠️ No weekly progress data available');
        print('   weeklyData is null: ${weeklyData == null}');
        if (weeklyData != null) {
          print('   data field is null: ${weeklyData["data"] == null}');
        }
      }
      print('📊 =================================');
    } catch (e, stackTrace) {
      print('❌ Error loading weekly progress: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    try {
      final pedometer = Provider.of<PedometerService>(context, listen: false);
      final stepsService = Provider.of<StepsService>(context, listen: false);
      
      print('🔄 Manual refresh started');
      print('   Current local steps: ${pedometer.steps}');
      
      // При ручном обновлении загружаем данные с сервера
      await stepsService.getDailySteps(forceUpdate: true);
      
      print('   Server steps after refresh: ${stepsService.serverSteps}');
      
      // И синхронизируем локальный счетчик
      await pedometer.loadFromServer();
      
      // Обновляем weekly progress
      await _loadWeeklyProgress();
      
      print('   Final local steps: ${pedometer.steps}');
      print('✅ Refresh completed');
    } catch (e) {
      print('Error during refresh: $e');
    }

    setState(() => _isRefreshing = false);
    HapticFeedback.lightImpact();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pedometer = context.watch<PedometerService>();
    
    // Используем только локальные данные педометра
    // Синхронизация с сервером происходит только при входе в приложение или pull-to-refresh
    final currentSteps = pedometer.steps;
    final caloriesBurned = pedometer.calories;
    final distance = pedometer.distance;
    final activeMinutes = pedometer.activeMinutes;
    
    // DEBUG: Выводим текущее состояние при каждом обновлении UI
    print('🖼️ UI build() called:');
    print('   Current steps: $currentSteps');
    print('   Calories: $caloriesBurned');
    print('   Distance: $distance km');

    final progress = _goalSteps > 0
        ? (currentSteps / _goalSteps).clamp(0.0, 1.0)
        : 0.0;

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
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  color: const Color(0xFF059669),
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isRefreshing)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        _buildStepCounter(currentSteps, progress),
                        const SizedBox(height: 16),
                        _buildAchievementsBadges(currentSteps),
                        const SizedBox(height: 24),
                        _buildQuickStats(
                          caloriesBurned,
                          distance,
                          activeMinutes,
                        ),
                        const SizedBox(height: 24),
                        _buildWeeklyProgress(currentSteps),
                        const SizedBox(height: 24),
                        _buildActionCards(),
                        const SizedBox(height: 24),
                        _buildDailyTip(),
                        const SizedBox(height: 24),
                        _buildMotivationCard(currentSteps, activeMinutes),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          // If user is authenticated, go to profile. Otherwise redirect to login.
          final authService = Provider.of<AuthService>(context, listen: false);
          if (authService.isAuthenticated) {
            Navigator.pushNamed(context, '/profile');
          } else {
            Navigator.pushNamed(context, '/login');
          }
        },
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF047857),
        elevation: 8,
        icon: const Icon(Icons.person_rounded),
        label: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, $_userName!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Keep Moving!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notifications coming soon!'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  await authService.logout();
                  if (mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCounter(int currentSteps, double progress) {
    final stepsService = context.watch<StepsService>();
    final hasServerData = stepsService.lastServerUpdate != null;
    
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
          // Индикатор синхронизации
          if (hasServerData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_done_rounded,
                    size: 16,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Synced with server',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: CircularProgressPainter(
                        progress: progress * _animationController.value,
                        strokeWidth: 16,
                        backgroundColor: const Color(0xFFD1FAE5),
                        progressColor: const Color(0xFF059669),
                      ),
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_walk_rounded,
                    size: 40,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: currentSteps),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
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
                  const SizedBox(height: 4),
                  Text(
                    'of $_goalSteps steps',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: const Color(0xFFD1FAE5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF059669),
                  ),
                  minHeight: 8,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% of daily goal',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (currentSteps > 0 && currentSteps < 10000)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '↑ Keep going!',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF059669),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMovementStatus(),
        ],
      ),
    );
  }

  Widget _buildAchievementsBadges(int currentSteps) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
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
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadge(
                icon: Icons.track_changes_rounded,
                label: '5K Steps',
                isUnlocked: currentSteps >= 5000,
                color: const Color(0xFF10B981),
              ),
              _buildBadge(
                icon: Icons.local_fire_department_rounded,
                label: 'On Fire',
                isUnlocked: currentSteps >= 7500,
                color: const Color(0xFFFF6B35),
              ),
              _buildBadge(
                icon: Icons.workspace_premium_rounded,
                label: 'Champion',
                isUnlocked: currentSteps >= 10000,
                color: const Color(0xFFFFD700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required bool isUnlocked,
    required Color color,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isUnlocked
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUnlocked ? null : Colors.grey.shade200,
            shape: BoxShape.circle,
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 32,
            color: isUnlocked ? Colors.white : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isUnlocked ? color : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(
    double caloriesBurned,
    double distance,
    int activeMinutes,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department_rounded,
                value: caloriesBurned.toStringAsFixed(0),
                unit: 'kcal',
                label: 'Calories',
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.straighten_rounded,
                value: distance.toStringAsFixed(1),
                unit: 'km',
                label: 'Distance',
                color: const Color(0xFF34D399),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          icon: Icons.timer_outlined,
          value: activeMinutes.toString(),
          unit: 'min',
          label: 'Active Minutes',
          color: const Color(0xFF059669),
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
    bool isWide = false,
  }) {
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
      child: isWide
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: int.parse(value)),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            builder: (context, val, child) {
                              return Text(
                                val.toString(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                  height: 1,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              unit,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: color.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: double.parse(value)),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, child) {
                        return Text(
                          val.toStringAsFixed(value.contains('.') ? 1 : 0),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: color,
                            height: 1,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        unit,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWeeklyProgress(int currentSteps) {
    // Используем только реальные данные из _weeklySteps
    final weekData = _weeklyDataLoaded 
        ? List<int>.from(_weeklySteps)
        : List<int>.filled(7, 0); // показываем пустой график, пока данные не загружены
    
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Определяем текущий день недели (1=Monday, 7=Sunday)
    final today = DateTime.now();
    final todayIndex = today.weekday - 1; // 0=Monday, 6=Sunday

    final nonZeroData = weekData.where((v) => v > 0).toList();
    final maxSteps = nonZeroData.isNotEmpty
        ? nonZeroData.reduce(math.max)
        : 10000;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/statistics');
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF059669),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: const Color(0xFF059669).withOpacity(0.7),
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (!_weeklyDataLoaded && nonZeroData.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_download_rounded,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading weekly data...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                final isToday = index == todayIndex; // используем реальный день недели
                final stepCount = weekData[index];
                final hasSteps = stepCount > 0;
                final height = stepCount == 0
                    ? 20.0
                    : ((stepCount / maxSteps) * 120).clamp(20.0, 120.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Label above bar
                        SizedBox(
                          height: 20,
                          child: hasSteps
                              ? Text(
                                  '${(stepCount / 1000).toStringAsFixed(1)}k',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isToday
                                        ? const Color(0xFF059669)
                                        : Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        // Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          width: double.infinity,
                          height: height,
                          decoration: BoxDecoration(
                            gradient: hasSteps
                                ? LinearGradient(
                                    colors: isToday
                                        ? [
                                            const Color(0xFF059669),
                                            const Color(0xFF10B981),
                                          ]
                                        : [
                                            const Color(0xFF059669).withOpacity(0.6),
                                            const Color(0xFF10B981).withOpacity(0.6),
                                          ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            color: hasSteps ? null : const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Day label
                        Text(
                          days[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isToday
                                ? const Color(0xFF059669)
                                : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.restaurant_rounded,
            title: 'Meals',
            subtitle: 'Track food',
            color: const Color(0xFF10B981),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/meals');
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            icon: Icons.water_drop_rounded,
            title: 'Water',
            subtitle: 'Stay hydrated',
            color: const Color(0xFF34D399),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/water');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTip() {
    final tips = [
      {
        'icon': Icons.stairs_rounded,
        'text': 'Take the stairs instead of the elevator',
      },
      {
        'icon': Icons.directions_walk_rounded,
        'text': 'A 10-minute walk burns around 40 calories',
      },
      {
        'icon': Icons.local_parking_rounded,
        'text': 'Park farther away to add extra steps',
      },
      {
        'icon': Icons.notifications_active_rounded,
        'text': 'Set hourly reminders to stand and stretch',
      },
      {
        'icon': Icons.music_note_rounded,
        'text': 'Listen to music to make walking more fun',
      },
    ];

    final randomTip = tips[math.Random().nextInt(tips.length)];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF059669), const Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              randomTip['icon'] as IconData,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.white.withOpacity(0.9),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Daily Tip',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  randomTip['text'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(int currentSteps, int activeMinutes) {
    final remainingSteps = math.max(0, _goalSteps - currentSteps);
    final motivationText = remainingSteps > 0
        ? "You're only $remainingSteps steps away from your goal!"
        : "Amazing! You surpassed your goal today!";
    final goalReached = remainingSteps == 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: goalReached
              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
              : [const Color(0xFF059669), const Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                (goalReached
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF059669))
                    .withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goalReached ? '🎉 Goal Reached!' : '🔥 Keep Going!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  motivationText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              goalReached
                  ? Icons.celebration_rounded
                  : Icons.emoji_events_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementStatus() {
    final pedometer = context.watch<PedometerService>();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: pedometer.isWalking 
            ? const Color(0xFF059669).withOpacity(0.1) 
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: pedometer.isWalking 
              ? const Color(0xFF059669).withOpacity(0.3) 
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: pedometer.isWalking 
                  ? const Color(0xFF059669) 
                  : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            pedometer.isWalking ? 'Walking detected' : 'Stationary',
            style: TextStyle(
              fontSize: 12,
              color: pedometer.isWalking 
                  ? const Color(0xFF059669) 
                  : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (pedometer.isSimulating) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.computer,
              size: 14,
              color: Colors.grey.shade600,
            ),
          ],
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [progressColor, progressColor.withOpacity(0.7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
