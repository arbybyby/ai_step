import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/pedometer_service.dart';
import '../services/steps_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = false;

  // This will hold real data from pedometer service
  List<Map<String, dynamic>> _weeklyData = [];
  List<int> _monthlyDailySteps = [];
  List<Map<String, dynamic>> _yearlySteps = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final stepsService = Provider.of<StepsService>(context, listen: false);
      final pedometer = Provider.of<PedometerService>(context, listen: false);
      
      // Try to get real data for the last 7 days
      final today = DateTime.now();
      final weekAgo = today.subtract(const Duration(days: 6));
      
      final historyData = await stepsService.getStepsHistory(
        from: weekAgo,
        to: today,
      );
      
      if (historyData != null && historyData['dailyStats'] != null) {
        _weeklyData = _processServerDataForWeekly(historyData['dailyStats']);
      } else {
        // Fallback to generated data
        _weeklyData = _generateWeeklyData(pedometer.steps);
      }
      
      _monthlyDailySteps = _generateMonthlyData();
      _yearlySteps = _generateYearlyData();
    } catch (e) {
      print('Error loading statistics: $e');
      // Fallback to generated data
      final pedometer = Provider.of<PedometerService>(context, listen: false);
      _weeklyData = _generateWeeklyData(pedometer.steps);
      _monthlyDailySteps = _generateMonthlyData();
      _yearlySteps = _generateYearlyData();
    }

    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> _processServerDataForWeekly(List<dynamic> dailyStats) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    
    // Create a map for quick lookup by date
    final statsMap = <String, Map<String, dynamic>>{};
    for (final stat in dailyStats) {
      if (stat is Map<String, dynamic> && stat['day'] != null) {
        statsMap[stat['day']] = stat;
      }
    }
    
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final serverData = statsMap[dateStr];
      if (serverData != null) {
        return {
          'day': days[index],
          'steps': serverData['totalSteps'] ?? 0,
          'calories': (serverData['totalCalories'] ?? 0).round(),
          'distance': (serverData['totalDistanceM'] ?? 0.0) / 1000.0, // Convert to km
        };
      } else {
        // Fallback data if no server data available
        return {
          'day': days[index],
          'steps': 0,
          'calories': 0,
          'distance': 0.0,
        };
      }
    });
  }

  List<Map<String, dynamic>> _generateWeeklyData(int todaySteps) {
    // Generate last 7 days data with some randomness
    final random = math.Random();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (index) {
      final isToday = index == 5; // Saturday is today
      final steps = isToday ? todaySteps : 6000 + random.nextInt(4000);
      final calories = (steps * 0.04).round();
      final distance = steps * 0.00075; // ~0.75m per step

      return {
        'day': days[index],
        'steps': steps,
        'calories': calories,
        'distance': distance,
      };
    });
  }

  List<int> _generateMonthlyData() {
    final random = math.Random();
    return List.generate(30, (index) => 6000 + random.nextInt(5000));
  }

  List<Map<String, dynamic>> _generateYearlyData() {
    final random = math.Random();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // Current month is October (index 9), so Nov and Dec should be 0
    final now = DateTime.now();
    final currentMonth = now.month - 1; // 0-indexed

    return List.generate(12, (index) {
      // Only show data for months up to current month
      final isFutureMonth = index > currentMonth;
      final steps = isFutureMonth ? 0 : 200000 + random.nextInt(100000);

      return {'month': months[index], 'steps': steps};
    });
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadStatistics();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 8),
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildTabBar(),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildWeeklyView(),
                          _buildMonthlyView(),
                          _buildYearlyView(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).maybePop();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
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
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _handleRefresh,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF047857),
        unselectedLabelColor: Colors.white.withOpacity(0.9),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        onTap: (index) => HapticFeedback.selectionClick(),
        tabs: const [
          Tab(text: 'Week'),
          Tab(text: 'Month'),
          Tab(text: 'Year'),
        ],
      ),
    );
  }

  Widget _buildWeeklyView() {
    if (_weeklyData.isEmpty) return const SizedBox();

    final totalSteps = _weeklyData.fold<int>(
      0,
      (sum, day) => sum + (day['steps'] as int),
    );
    final avgSteps = (totalSteps / _weeklyData.length).round();
    final bestDay = _weeklyData.reduce((a, b) {
      return (a['steps'] as int) >= (b['steps'] as int) ? a : b;
    });
    final goalDays = _weeklyData
        .where((day) => (day['steps'] as int) >= 10000)
        .length;
    final currentStreak = _calculateCurrentStreak(_weeklyData);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFF047857),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildPersonalRecords(
              totalSteps: totalSteps,
              avgSteps: avgSteps,
              currentStreak: currentStreak,
              bestDay: bestDay['steps'] as int,
            ),
            const SizedBox(height: 24),
            _buildSummaryCard(
              title: 'Weekly Summary',
              items: [
                {
                  'label': 'Total Steps',
                  'value': _formatNumber(totalSteps),
                  'icon': Icons.directions_walk_rounded,
                  'trend': '+15%',
                  'trendUp': true,
                },
                {
                  'label': 'Avg/Day',
                  'value': _formatNumber(avgSteps),
                  'icon': Icons.show_chart_rounded,
                },
                {
                  'label': 'Goal Days',
                  'value': '$goalDays/7',
                  'icon': Icons.flag_rounded,
                },
                {
                  'label': 'Best Day',
                  'value':
                      '${bestDay['day']} (${_formatNumber(bestDay['steps'] as int)})',
                  'icon': Icons.emoji_events_rounded,
                },
              ],
            ),
            const SizedBox(height: 24),
            ..._weeklyData.asMap().entries.map(
              (entry) => _buildDayCard(entry.value, entry.key),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyView() {
    if (_monthlyDailySteps.isEmpty) return const SizedBox();

    final totalSteps = _monthlyDailySteps.fold<int>(
      0,
      (sum, steps) => sum + steps,
    );
    final avgSteps = (totalSteps / _monthlyDailySteps.length).round();
    final maxSteps = _monthlyDailySteps.reduce(math.max);
    final goalDays = _monthlyDailySteps.where((steps) => steps >= 10000).length;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFF047857),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSummaryCard(
              title: 'Monthly Summary',
              items: [
                {
                  'label': 'Total Steps',
                  'value': _formatNumber(totalSteps),
                  'icon': Icons.directions_walk_rounded,
                  'trend': '+8%',
                  'trendUp': true,
                },
                {
                  'label': 'Avg/Day',
                  'value': _formatNumber(avgSteps),
                  'icon': Icons.show_chart_rounded,
                },
                {
                  'label': 'Goal Days',
                  'value': '$goalDays/${_monthlyDailySteps.length}',
                  'icon': Icons.flag_rounded,
                },
                {
                  'label': 'Best Day',
                  'value': _formatNumber(maxSteps),
                  'icon': Icons.star_rate_rounded,
                },
              ],
            ),
            const SizedBox(height: 24),
            _buildMonthlyChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyView() {
    if (_yearlySteps.isEmpty) return const SizedBox();

    final totalSteps = _yearlySteps.fold<int>(
      0,
      (sum, month) => sum + (month['steps'] as int),
    );
    final activeMonths = _yearlySteps
        .where((month) => (month['steps'] as int) > 0)
        .length;
    final avgSteps = activeMonths == 0
        ? 0
        : (totalSteps / activeMonths).round();
    final bestMonth = _yearlySteps.reduce((a, b) {
      return (a['steps'] as int) >= (b['steps'] as int) ? a : b;
    });

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFF047857),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSummaryCard(
              title: 'Yearly Summary',
              items: [
                {
                  'label': 'Total Steps',
                  'value': _formatNumber(totalSteps),
                  'icon': Icons.directions_walk_rounded,
                  'trend': '+22%',
                  'trendUp': true,
                },
                {
                  'label': 'Avg/Month',
                  'value': _formatNumber(avgSteps),
                  'icon': Icons.show_chart_rounded,
                },
                {
                  'label': 'Active Months',
                  'value': '$activeMonths/12',
                  'icon': Icons.calendar_today_rounded,
                },
                {
                  'label': 'Best Month',
                  'value': '${bestMonth['month']}',
                  'icon': Icons.star_rounded,
                },
              ],
            ),
            const SizedBox(height: 24),
            _buildYearlyChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRecords({
    required int totalSteps,
    required int avgSteps,
    required int currentStreak,
    required int bestDay,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Personal Records',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRecordItem(
            icon: Icons.local_fire_department_rounded,
            label: 'Current Streak',
            value: '$currentStreak days',
          ),
          const SizedBox(height: 12),
          _buildRecordItem(
            icon: Icons.trending_up_rounded,
            label: 'Best Day Ever',
            value: _formatNumber(bestDay),
          ),
          const SizedBox(height: 12),
          _buildRecordItem(
            icon: Icons.insights_rounded,
            label: 'Weekly Average',
            value: _formatNumber(avgSteps),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  int _calculateCurrentStreak(List<Map<String, dynamic>> weekData) {
    int streak = 0;
    for (int i = weekData.length - 1; i >= 0; i--) {
      if ((weekData[i]['steps'] as int) >= 10000) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Widget _buildDayCard(Map<String, dynamic> day, int index) {
    final steps = day['steps'] as int;
    final hasData = steps > 0;
    final reachedGoal = steps >= 10000;
    final isToday = index == 5;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showDayDetails(day);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: isToday
                      ? Border.all(color: const Color(0xFF10B981), width: 3)
                      : (hasData && reachedGoal
                            ? Border.all(
                                color: const Color(0xFF059669),
                                width: 2,
                              )
                            : null),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: hasData
                            ? LinearGradient(
                                colors: isToday
                                    ? [
                                        const Color(0xFF10B981),
                                        const Color(0xFF34D399),
                                      ]
                                    : [
                                        const Color(0xFF059669),
                                        const Color(0xFF10B981),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: hasData ? null : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              day['day'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: hasData
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                            if (isToday)
                              Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                hasData ? _formatNumber(steps) : 'No data',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: hasData
                                      ? const Color(0xFF059669)
                                      : Colors.grey.shade400,
                                ),
                              ),
                              if (hasData)
                                Text(
                                  ' steps',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                          if (hasData) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${day['calories']} kcal',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.straighten_rounded,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(day['distance'] as double).toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (hasData)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: reachedGoal
                              ? const Color(0xFF059669).withOpacity(0.1)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          reachedGoal
                              ? Icons.check_circle
                              : Icons.more_horiz_rounded,
                          color: reachedGoal
                              ? const Color(0xFF059669)
                              : Colors.grey.shade400,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDayDetails(Map<String, dynamic> day) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${day['day']} Details',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              Icons.directions_walk_rounded,
              'Steps',
              '${day['steps']}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.local_fire_department_rounded,
              'Calories',
              '${day['calories']} kcal',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.straighten_rounded,
              'Distance',
              '${(day['distance'] as double).toStringAsFixed(2)} km',
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
              'Close',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF059669), size: 20),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF059669),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    final maxSteps = _monthlyDailySteps.reduce(math.max);

    return Container(
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
          const Text(
            'Daily Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_monthlyDailySteps.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 800 + (index * 20)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        final height =
                            (_monthlyDailySteps[index] / maxSteps).clamp(
                              0.05,
                              1.0,
                            ) *
                            180 *
                            value;
                        final highlight =
                            index >= _monthlyDailySteps.length - 7;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Day ${index + 1}: ${_formatNumber(_monthlyDailySteps[index])} steps',
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: highlight
                                    ? const [
                                        Color(0xFF10B981),
                                        Color(0xFF34D399),
                                      ]
                                    : const [
                                        Color(0xFF059669),
                                        Color(0xFF10B981),
                                      ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '8',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '16',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '24',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '31',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyChart() {
    final nonZeroSteps = _yearlySteps
        .where((m) => (m['steps'] as int) > 0)
        .map((m) => m['steps'] as int)
        .toList();
    final maxSteps = nonZeroSteps.isNotEmpty
        ? nonZeroSteps.reduce(math.max)
        : 1;

    return Container(
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
          const Text(
            'Monthly Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _yearlySteps.asMap().entries.map((entry) {
              final index = entry.key;
              final month = entry.value;
              final steps = month['steps'] as int;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 600 + (index * 80)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      final height = steps == 0
                          ? 8.0
                          : ((steps / maxSteps).clamp(0.05, 1.0) * 160 * value);
                      final isBest = steps == maxSteps && steps > 0;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (steps > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${month['month']}: ${_formatNumber(steps)} steps',
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: height,
                              decoration: BoxDecoration(
                                gradient: steps == 0
                                    ? null
                                    : LinearGradient(
                                        colors: isBest
                                            ? const [
                                                Color(0xFFFFD700),
                                                Color(0xFF10B981),
                                              ]
                                            : const [
                                                Color(0xFF059669),
                                                Color(0xFF10B981),
                                              ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                color: steps == 0 ? Colors.grey.shade300 : null,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              month['month'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: steps > 0
                                    ? const Color(0xFF059669)
                                    : Colors.grey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 20),
          ...items.asMap().entries.map(
            (entry) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (entry.key * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(20 * (1 - value), 0),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              entry.value['icon'] as IconData,
                              color: const Color(0xFF059669),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              entry.value['label'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                entry.value['value'] as String,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              if (entry.value.containsKey('trend'))
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      (entry.value['trendUp'] as bool? ?? true)
                                          ? Icons.trending_up_rounded
                                          : Icons.trending_down_rounded,
                                      size: 14,
                                      color:
                                          (entry.value['trendUp'] as bool? ??
                                              true)
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      entry.value['trend'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            (entry.value['trendUp'] as bool? ??
                                                true)
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }
}
