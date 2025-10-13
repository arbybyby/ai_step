import 'dart:math' as math;

import 'package:flutter/material.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Map<String, dynamic>> _weeklyData = const [
    {'day': 'Mon', 'steps': 6500, 'calories': 280, 'distance': 4.8},
    {'day': 'Tue', 'steps': 8200, 'calories': 350, 'distance': 6.1},
    {'day': 'Wed', 'steps': 7100, 'calories': 305, 'distance': 5.3},
    {'day': 'Thu', 'steps': 9300, 'calories': 398, 'distance': 6.9},
    {'day': 'Fri', 'steps': 8900, 'calories': 381, 'distance': 6.6},
    {'day': 'Sat', 'steps': 7845, 'calories': 336, 'distance': 5.8},
    {'day': 'Sun', 'steps': 0, 'calories': 0, 'distance': 0.0},
  ];

  final List<int> _monthlyDailySteps = const [
    8200, 7500, 9100, 8800, 9500, 7800, 8400, 9200, 8600, 9800,
    8100, 7900, 9400, 8700, 6600, 10300, 9700, 8800, 7600, 9400,
    8900, 8200, 7200, 6600, 8800, 9100, 9400, 8300, 8800, 9100,
  ];

  final List<Map<String, dynamic>> _yearlySteps = const [
    {'month': 'Jan', 'steps': 220000},
    {'month': 'Feb', 'steps': 198000},
    {'month': 'Mar', 'steps': 245000},
    {'month': 'Apr', 'steps': 234000},
    {'month': 'May', 'steps': 267000},
    {'month': 'Jun', 'steps': 289000},
    {'month': 'Jul', 'steps': 301000},
    {'month': 'Aug', 'steps': 287000},
    {'month': 'Sep', 'steps': 256000},
    {'month': 'Oct', 'steps': 234000},
    {'month': 'Nov', 'steps': 215000},
    {'month': 'Dec', 'steps': 0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            colors: [Color(0xFFFFD464), Color(0xFFFF5E5E), Color(0xFFE23C64)],
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
                child: TabBarView(
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
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
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
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: const Color(0xFFE23C64),
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        tabs: const [
          Tab(text: 'Week'),
          Tab(text: 'Month'),
          Tab(text: 'Year'),
        ],
      ),
    );
  }

  Widget _buildWeeklyView() {
    final totalSteps = _weeklyData.fold<int>(0, (sum, day) => sum + (day['steps'] as int));
    final avgSteps = (totalSteps / _weeklyData.length).round();
    final bestDay = _weeklyData.reduce((a, b) {
      return (a['steps'] as int) >= (b['steps'] as int) ? a : b;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSummaryCard(
            title: 'Weekly Summary',
            items: [
              {'label': 'Total Steps', 'value': '$totalSteps', 'icon': Icons.directions_walk_rounded},
              {'label': 'Avg/Day', 'value': '$avgSteps', 'icon': Icons.show_chart_rounded},
              {'label': 'Best Day', 'value': '${bestDay['day']} (${bestDay['steps']})', 'icon': Icons.emoji_events_rounded},
            ],
          ),
          const SizedBox(height: 24),
          ..._weeklyData.map(_buildDayCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMonthlyView() {
    final totalSteps = _monthlyDailySteps.fold<int>(0, (sum, steps) => sum + steps);
    final avgSteps = (totalSteps / _monthlyDailySteps.length).round();
    final maxSteps = _monthlyDailySteps.reduce(math.max);
    final goalDays = _monthlyDailySteps.where((steps) => steps >= 10000).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSummaryCard(
            title: 'Monthly Summary',
            items: [
              {'label': 'Total Steps', 'value': _formatNumber(totalSteps), 'icon': Icons.directions_walk_rounded},
              {'label': 'Avg/Day', 'value': _formatNumber(avgSteps), 'icon': Icons.show_chart_rounded},
              {'label': 'Goal Days', 'value': '$goalDays/${_monthlyDailySteps.length}', 'icon': Icons.flag_rounded},
              {'label': 'Best Day', 'value': _formatNumber(maxSteps), 'icon': Icons.star_rate_rounded},
            ],
          ),
          const SizedBox(height: 24),
          _buildMonthlyChart(),
        ],
      ),
    );
  }

  Widget _buildYearlyView() {
    final totalSteps = _yearlySteps.fold<int>(0, (sum, month) => sum + (month['steps'] as int));
    final activeMonths = _yearlySteps.where((month) => (month['steps'] as int) > 0).length;
    final avgSteps = activeMonths == 0 ? 0 : (totalSteps / activeMonths).round();
    final bestMonth = _yearlySteps.reduce((a, b) {
      return (a['steps'] as int) >= (b['steps'] as int) ? a : b;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSummaryCard(
            title: 'Yearly Summary',
            items: [
              {'label': 'Total Steps', 'value': _formatNumber(totalSteps), 'icon': Icons.directions_walk_rounded},
              {'label': 'Avg/Month', 'value': _formatNumber(avgSteps), 'icon': Icons.show_chart_rounded},
              {'label': 'Best Month', 'value': '${bestMonth['month']}', 'icon': Icons.star_rounded},
            ],
          ),
          const SizedBox(height: 24),
          _buildYearlyChart(),
        ],
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day) {
    final steps = day['steps'] as int;
    final hasData = steps > 0;
    final reachedGoal = steps >= 10000;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: hasData && reachedGoal ? Border.all(color: const Color(0xFFE23C64), width: 2) : null,
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
                  ? const LinearGradient(
                      colors: [Color(0xFFE23C64), Color(0xFFFF5E5E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: hasData ? null : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                day['day'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: hasData ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasData ? '${_formatNumber(steps)} steps' : 'No data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: hasData ? const Color(0xFFE23C64) : Colors.grey.shade400,
                  ),
                ),
                if (hasData) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${day['calories']} kcal · ${(day['distance'] as double).toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasData)
            Icon(
              reachedGoal ? Icons.check_circle : Icons.chevron_right_rounded,
              color: reachedGoal ? Colors.green : Colors.grey.shade400,
              size: 24,
            ),
        ],
      ),
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
              color: Color(0xFFE23C64),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_monthlyDailySteps.length, (index) {
                final height = (_monthlyDailySteps[index] / maxSteps).clamp(0.05, 1.0) * 180;
                final highlight = index == _monthlyDailySteps.length - 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: highlight
                              ? const [Color(0xFF39C3AA), Color(0xFF1AA67A)]
                              : const [Color(0xFFE23C64), Color(0xFFFF5E5E)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
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
              Text('1', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              Text('8', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              Text('16', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              Text('24', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              Text('31', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyChart() {
    final nonZeroSteps = _yearlySteps.where((m) => (m['steps'] as int) > 0).map((m) => m['steps'] as int).toList();
    final maxSteps = nonZeroSteps.isNotEmpty ? nonZeroSteps.reduce(math.max) : 1;

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
              color: Color(0xFFE23C64),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _yearlySteps.map((month) {
                final steps = month['steps'] as int;
                final height = steps == 0 ? 8.0 : ((steps / maxSteps).clamp(0.05, 1.0) * 160);
                final isBest = steps == maxSteps && steps > 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
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
                                        ? const [Color(0xFFFFC371), Color(0xFFFF5E5E)]
                                        : const [Color(0xFFE23C64), Color(0xFFFF5E5E)],
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
                            color: steps > 0 ? const Color(0xFFE23C64) : Colors.grey.shade400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
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
              color: Color(0xFFE23C64),
            ),
          ),
          const SizedBox(height: 20),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE23C64).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: const Color(0xFFE23C64),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    item['value'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE23C64),
                    ),
                  ),
                ],
              ),
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