import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../providers/steps_provider.dart';
import '../models/step_data.dart';
import '../services/step_counter_service.dart';
import '../services/step_storage_service.dart';
import '../services/background_sync_service.dart';
import '../services/notification_service.dart';
import '../services/calories_service.dart';
import 'dart:async';
import 'weekly_progress_screen.dart';
import 'package:intl/intl.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _bg = Color(0xFF0A0D0B);
const _card = Color(0xFF141714);
const _green = Color(0xFF28C76F);
const _greenDim = Color(0xFF1A3D2B);
const _white = Colors.white;
const _grey = Color(0xFF8A8A8A);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late StepCounterService _stepCounterService;
  int _currentSteps = 0;
  int _lastSyncedSteps = 0;
  bool _goalAchieved = false;
  Timer? _syncTimer;
  Timer? _caloriesTimer;
  bool _isSyncing = false;
  bool _isLoggingOut = false;
  DateTime _lastManualSyncAttempt = DateTime.fromMillisecondsSinceEpoch(0);
  String _displayName = '';
  double? _caloriesBurned;
  double? _distanceKm;
  Timer? _distanceTimer;
  final CaloriesService _caloriesService = CaloriesService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await NotificationService().init();
    await BackgroundSyncService.init();
    await BackgroundSyncService.startPeriodicSync();

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      try {
        await BackgroundSyncService.syncNow();
        await ref.read(currentDayStepsProvider.notifier).fetchCurrentDaySteps();
        await ref.read(weeklyStepsProvider.notifier).fetchWeeklySteps();

        final providerState = ref.read(currentDayStepsProvider);
        providerState.whenData((data) async {
          if (data != null && mounted) {
            setState(() {
              _currentSteps = data.stepsCount;
              _lastSyncedSteps = data.stepsCount;
            });
            _stepCounterService = StepCounterService();
            await _stepCounterService.init(
              _onStepCountChanged,
              initialSteps: _currentSteps,
            );
          } else {
            _stepCounterService = StepCounterService();
            await _stepCounterService.init(_onStepCountChanged);
          }
        });
      } catch (e) {
        print('HomeScreen._initializeServices: $e');
      }
    }

    // Start long-polling for calories burned today (every 10 seconds)
    _fetchCaloriesBurned();
    _caloriesTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchCaloriesBurned();
    });

    // Start long-polling for distance today (every 10 seconds)
    _fetchDistanceToday();
    _distanceTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchDistanceToday();
    });

    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted || _isSyncing) return;
      _isSyncing = true;
      try {
        await BackgroundSyncService.syncNow();
        await ref.read(currentDayStepsProvider.notifier).fetchCurrentDaySteps();
        final providerState = ref.read(currentDayStepsProvider);
        providerState.whenData((data) {
          if (data != null && mounted) {
            setState(() {
              _currentSteps = data.stepsCount;
              _lastSyncedSteps = data.stepsCount;
            });
            ref
                .read(weeklyStepsProvider.notifier)
                .updateTodaySteps(data.stepsCount);
          }
        });
      } finally {
        _isSyncing = false;
      }
    });

    try {
      final me = await AuthService.getMe();
      if (mounted && me.isNotEmpty) {
        String name = '';
        final firstPascal = me['FirstName']?.toString() ?? '';
        final lastPascal = me['LastName']?.toString() ?? '';
        if (firstPascal.isNotEmpty || lastPascal.isNotEmpty) {
          name = (firstPascal + (lastPascal.isNotEmpty ? ' $lastPascal' : ''))
              .trim();
        } else if (me['firstName'] != null &&
            me['firstName'].toString().isNotEmpty) {
          name = me['firstName'].toString();
        } else if (me['name'] != null && me['name'].toString().isNotEmpty) {
          name = me['name'].toString();
        } else if (me['email'] != null && me['email'].toString().isNotEmpty) {
          name = me['email'].toString().split('@').first;
        }
        if (name.isNotEmpty) setState(() => _displayName = name);
      }
    } catch (e) {
      print('HomeScreen: could not fetch profile: $e');
    }
  }

  void _onStepCountChanged(int steps) {
    setState(() => _currentSteps = steps);
    const goal = 10000;
    if (!_goalAchieved && steps >= goal) {
      _goalAchieved = true;
      NotificationService().showGoalAchievedNotification(goal);
    }
    ref.read(currentDayStepsProvider.notifier).updateSteps(steps);
    ref.read(weeklyStepsProvider.notifier).updateTodaySteps(steps);

    final now = DateTime.now();
    final diff = steps - _lastSyncedSteps;
    if (diff >= 10 &&
        now.difference(_lastManualSyncAttempt) > const Duration(seconds: 30)) {
      _lastManualSyncAttempt = now;
      _syncSteps();
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final greet = hour >= 5 && hour < 12
        ? 'Good Morning'
        : hour < 18
        ? 'Good Afternoon'
        : 'Good Evening';
    final name = _displayName.isNotEmpty ? ', $_displayName' : '';
    return '$greet$name!';
  }

  Future<void> _syncSteps() async {
    try {
      await ref.read(currentDayStepsProvider.notifier).syncSteps(_currentSteps);
      setState(() => _lastSyncedSteps = _currentSteps);
    } catch (_) {
      NotificationService().showSyncErrorNotification();
    }
  }

  Future<void> _fetchCaloriesBurned() async {
    final value = await _caloriesService.getCaloriesBurnedToday();
    if (value != null && mounted) {
      setState(() {
        _caloriesBurned = value;
      });
    }
  }

  Future<void> _fetchDistanceToday() async {
    final value = await _caloriesService.getDistanceToday();
    if (value != null && mounted) {
      setState(() {
        _distanceKm = value;
      });
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _caloriesTimer?.cancel();
    _distanceTimer?.cancel();
    _stepCounterService.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(goalProvider);

    ref.listen<AsyncValue<StepData?>>(currentDayStepsProvider, (_, next) {
      next.whenData((data) {
        if (data != null && mounted) {
          setState(() {
            _currentSteps = data.stepsCount;
            _lastSyncedSteps = data.stepsCount;
          });
        }
      });
    });

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  goalAsync.when(
                    data: (goal) => _buildStepsCard(goal),
                    loading: () => const SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(color: _green),
                      ),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 14),
                  _buildWeeklyProgress(),
                  const SizedBox(height: 14),
                  _buildMealsWaterRow(),
                  const SizedBox(height: 14),
                  _buildTipKeepGoingRow(),
                  const SizedBox(height: 100),
                ],
              ),
            ),

            // ── Floating bottom nav ───────────────────────────────────
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: _buildBottomNav(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  color: _white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Keep Moving!',
                style: TextStyle(
                  color: _green,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Notification bell
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.notifications_none,
                color: _white,
                size: 22,
              ),
            ),
            Positioned(
              top: 8,
              right: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                  border: Border.all(color: _bg, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Steps Card ────────────────────────────────────────────────────────────
  Widget _buildStepsCard(int goal) {
    final progress = goal == 0 ? 0.0 : (_currentSteps / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          // Top: ring + steps text
          Row(
            children: [
              // Circular indicator
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFFE8F5EF),
                        valueColor: const AlwaysStoppedAnimation<Color>(_green),
                      ),
                    ),
                    const Icon(Icons.directions_walk, color: _green, size: 28),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Steps text + progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$_currentSteps ',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: 'of $goal steps',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFE8F5EF),
                        valueColor: const AlwaysStoppedAnimation<Color>(_green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),

          // Bottom metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricItem(
                _caloriesBurned != null
                    ? _caloriesBurned!.toStringAsFixed(0)
                    : '—',
                'kcal',
              ),
              _vDivider(),
              _metricItem(
                _distanceKm != null
                    ? _distanceKm!.toStringAsFixed(1)
                    : '—',
                'km',
              ),
              _vDivider(),
              _metricItem('0', 'min'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      ],
    );
  }

  Widget _vDivider() {
    return Container(width: 1, height: 30, color: const Color(0xFFEEEEEE));
  }

  // ─── Weekly Progress ───────────────────────────────────────────────────────
  Widget _buildWeeklyProgress() {
    final weeklyAsync = ref.watch(weeklyStepsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Progress',
                style: TextStyle(
                  color: _white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WeeklyProgressScreen(),
                  ),
                ),
                child: const Icon(Icons.chevron_right, color: _grey, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),
          weeklyAsync.when(
            data: (data) =>
                data != null ? _buildBarChart(data) : _buildEmptyBarChart(),
            loading: () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(color: _green)),
            ),
            error: (_, __) => _buildEmptyBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBarChart() {
    final days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Column(
      children: [
        // Y-axis labels + bars
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Y-axis
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: ['180', '120', '60', '0']
                  .map(
                    (l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l,
                        style: const TextStyle(color: _grey, fontSize: 10),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    7,
                    (_) => Container(
                      width: 20,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2D2A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: days
                      .map(
                        (d) => Text(
                          d,
                          style: const TextStyle(color: _grey, fontSize: 11),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart(WeekStepsInfo weekData) {
    final now = DateTime.now();
    // Sunday-first week
    final sundayOffset = now.weekday % 7; // days since last sunday
    final weekStart = now.subtract(Duration(days: sundayOffset));

    final weekDays = List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final day = weekData.dayStepsInfo.firstWhere(
        (d) => d.date == dateStr,
        orElse: () => DayStepsInfo(
          id: 0,
          userId: 0,
          date: dateStr,
          stepsCount: 0,
          distanceKm: 0,
        ),
      );
      return day;
    });

    final labels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    final maxSteps = weekDays
        .map((d) => d.stepsCount)
        .fold<int>(1, (a, b) => a > b ? a : b);
    const chartH = 90.0;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Y-axis labels
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  [
                        maxSteps,
                        (maxSteps * 0.67).round(),
                        (maxSteps * 0.33).round(),
                        0,
                      ]
                      .map(
                        (v) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            '$v',
                            style: const TextStyle(color: _grey, fontSize: 9),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: chartH,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final day = weekDays[i];
                    final isToday =
                        DateTime.parse(day.date).day == now.day &&
                        DateTime.parse(day.date).month == now.month &&
                        DateTime.parse(day.date).year == now.year;
                    final barH = maxSteps > 0
                        ? ((day.stepsCount / maxSteps) * (chartH - 10)).clamp(
                            4.0,
                            chartH - 10,
                          )
                        : 4.0;
                    return Container(
                      width: 20,
                      height: barH,
                      decoration: BoxDecoration(
                        color: isToday ? _green : const Color(0xFF2A2D2A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 32),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (i) {
                  final day = weekDays[i];
                  final isToday =
                      DateTime.parse(day.date).day == now.day &&
                      DateTime.parse(day.date).month == now.month &&
                      DateTime.parse(day.date).year == now.year;
                  return Text(
                    labels[i],
                    style: TextStyle(
                      color: isToday ? _green : _grey,
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Meals & Water row ─────────────────────────────────────────────────────
  Widget _buildMealsWaterRow() {
    return Row(
      children: [
        // Meals — dark card
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/meals'),
            child: Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Meals',
                        style: TextStyle(
                          color: _white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: _grey, size: 18),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.0,
                      minHeight: 5,
                      backgroundColor: const Color(0xFF2A2D2A),
                      valueColor: const AlwaysStoppedAnimation<Color>(_green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Water — green card
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/water'),
            child: Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Water',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.black54,
                        size: 18,
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.3,
                      minHeight: 5,
                      backgroundColor: Colors.black26,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Daily Tip & Keep Going row ────────────────────────────────────────────
  Widget _buildTipKeepGoingRow() {
    return Row(
      children: [
        // Daily Tip — dark
        Expanded(
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Tip',
                  style: TextStyle(
                    color: _white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Learn how your daily tip about the best fitness habits.',
                  style: const TextStyle(
                    color: _grey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Keep Going — green
        Expanded(
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keep Going!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Keep going! We're coming back stronger every day.",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Bottom Nav ────────────────────────────────────────────────────────────
  static const _navItems = [
    _NavItem(Icons.home_rounded, 'Home', null),
    _NavItem(Icons.water_drop_rounded, 'Water', '/water'),
    _NavItem(Icons.restaurant_rounded, 'Meals', '/meals'),
    _NavItem(Icons.bar_chart_rounded, 'Stats', null),
    _NavItem(Icons.person_rounded, 'Profile', '/profile'),
  ];

  Widget _buildBottomNav() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_navItems.length, (i) {
          final item = _navItems[i];
          final active = i == _selectedIndex;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = i);
              if (item.route != null) {
                Navigator.of(context).pushNamed(item.route!);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: active ? 14 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: active ? _green : Colors.transparent,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: active ? Colors.white : Colors.grey[400],
                  ),
                  // Animated label: slides in + fades when active
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    child: active
                        ? Row(
                            children: [
                              const SizedBox(width: 6),
                              AnimatedOpacity(
                                opacity: active ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 220),
                                child: Text(
                                  item.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Logout ────────────────────────────────────────────────────────────────
  Future<void> _onLogoutPressed() async {
    if (_isLoggingOut || !mounted) return;
    setState(() => _isLoggingOut = true);
    try {
      _syncTimer?.cancel();
      try {
        _stepCounterService.dispose();
      } catch (_) {}
      try {
        await StepStorageService().clear();
      } catch (_) {}
      await AuthService.logout();
      final sp = await SharedPreferences.getInstance();
      try {
        await sp.clear();
      } catch (_) {}
      if (mounted) Navigator.of(context).pushReplacementNamed('/signin');
    } catch (e) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Logout failed'),
            content: Text('$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String? route;
  const _NavItem(this.icon, this.label, this.route);
}
