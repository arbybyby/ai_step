import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/steps_provider.dart';
import '../models/step_data.dart';
import 'package:intl/intl.dart';

class WeeklyProgressScreen extends ConsumerStatefulWidget {
  const WeeklyProgressScreen({super.key});

  @override
  ConsumerState<WeeklyProgressScreen> createState() => _WeeklyProgressScreenState();
}

class _WeeklyProgressScreenState extends ConsumerState<WeeklyProgressScreen> {
  String _selectedPeriod = 'Week';

  @override
  void initState() {
    super.initState();
    // Fetch weekly data on init
    Future.microtask(() {
      ref.read(weeklyStepsProvider.notifier).fetchWeeklySteps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final weeklyStepsAsync = ref.watch(weeklyStepsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2D8B5F),
              Color(0xFF1E6B47),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              _buildCustomAppBar(),
              
              // Content
              Expanded(
                child: weeklyStepsAsync.when(
                  data: (weekData) {
                    if (weekData == null) {
                      return const Center(
                        child: Text(
                          'No weekly data available',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return _buildWeeklyProgressContent(weekData);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.white),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load weekly data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(weeklyStepsProvider.notifier).fetchWeeklySteps();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2D8B5F),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Refresh button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                ref.read(weeklyStepsProvider.notifier).fetchWeeklySteps();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressContent(WeekStepsInfo weekData) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(weeklyStepsProvider.notifier).fetchWeeklySteps();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            
            // Period Selector (Week/Month/Year)
            _buildPeriodSelector(),
            const SizedBox(height: 20),

            // Personal Records Section
            _buildPersonalRecordsCard(weekData),
            const SizedBox(height: 16),

            // Weekly Summary Section
            _buildWeeklySummaryCard(weekData),
            const SizedBox(height: 16),

            // Daily Progress List
            _buildDailyProgressCards(weekData.dayStepsInfo),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildPeriodTab('Week'),
          _buildPeriodTab('Month'),
          _buildPeriodTab('Year'),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            period,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2D8B5F) : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalRecordsCard(WeekStepsInfo weekData) {
    // Calculate stats
    final avgSteps = weekData.dayStepsInfo.isEmpty 
        ? 0 
        : (weekData.totalSteps / weekData.dayStepsInfo.length).round();
    final bestDaySteps = weekData.bestDay?.stepsCount ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3FA976),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Personal Records',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildRecordRow(Icons.local_fire_department, 'Current Streak', '0 days'),
          const SizedBox(height: 16),
          _buildRecordRow(Icons.trending_up, 'Best Day Ever', bestDaySteps.toString()),
          const SizedBox(height: 16),
          _buildRecordRow(Icons.show_chart, 'Weekly Average', avgSteps.toString()),
        ],
      ),
    );
  }

  Widget _buildRecordRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummaryCard(WeekStepsInfo weekData) {
    final avgSteps = weekData.dayStepsInfo.isEmpty 
        ? 0 
        : (weekData.totalSteps / weekData.dayStepsInfo.length).round();
    final goalDays = 0; // TODO: Calculate based on goal
    final totalDays = 7;
    
    // Get best day name
    String bestDayName = 'Mon';
    int bestDaySteps = 0;
    if (weekData.bestDay != null) {
      final date = DateTime.parse(weekData.bestDay!.date);
      bestDayName = DateFormat('E').format(date);
      bestDaySteps = weekData.bestDay!.stepsCount;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Summary',
            style: TextStyle(
              color: Color(0xFF2D8B5F),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildSummaryRow(
            Icons.directions_walk,
            'Total Steps',
            weekData.totalSteps.toString(),
            '+15%',
            const Color(0xFFE8F5F0),
            const Color(0xFF2D8B5F),
          ),
          const SizedBox(height: 16),
          
          _buildSummaryRow(
            Icons.trending_up,
            'Avg/Day',
            avgSteps.toString(),
            null,
            const Color(0xFFE8F5F0),
            const Color(0xFF2D8B5F),
          ),
          const SizedBox(height: 16),
          
          _buildSummaryRow(
            Icons.flag,
            'Goal Days',
            '$goalDays/$totalDays',
            null,
            const Color(0xFFE8F5F0),
            const Color(0xFF2D8B5F),
          ),
          const SizedBox(height: 16),
          
          _buildSummaryRow(
            Icons.emoji_events,
            'Best Day',
            '$bestDayName ($bestDaySteps)',
            null,
            const Color(0xFFE8F5F0),
            const Color(0xFF2D8B5F),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value,
    String? percentage,
    Color bgColor,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2D8B5F),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (percentage != null)
              Text(
                percentage,
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyProgressCards(List<DayStepsInfo> dayStepsInfo) {
    // Create a map of all week days
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final weekDays = List.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayData = dayStepsInfo.firstWhere(
        (d) => d.date == dateStr,
        orElse: () => DayStepsInfo(
          id: 0,
          userId: 0,
          date: dateStr,
          stepsCount: 0,
          distanceKm: 0,
        ),
      );
      return dayData;
    });

    return Column(
      children: weekDays.map((dayData) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDayCard(dayData),
        );
      }).toList(),
    );
  }

  Widget _buildDayCard(DayStepsInfo dayData) {
    final date = DateTime.parse(dayData.date);
    final dayName = DateFormat('E').format(date);
    final isToday = date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;
    final hasData = dayData.stepsCount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday 
            ? Border.all(color: const Color(0xFF2D8B5F), width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isToday)
                    const Text(
                      'Today',
                      style: TextStyle(
                        color: Color(0xFF2D8B5F),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              hasData ? '${dayData.stepsCount} steps' : 'No data',
              style: TextStyle(
                color: hasData ? Colors.black87 : Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          if (hasData)
            Text(
              '${dayData.distanceKm.toStringAsFixed(2)} km',
              style: const TextStyle(
                color: Color(0xFF2D8B5F),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
