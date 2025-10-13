import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/pedometer_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final int _goalSteps = 10000;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUser = prefs.getString('auth_user');
      if (cachedUser == null || cachedUser.isEmpty) return;

      final decoded = jsonDecode(cachedUser);
      if (decoded is Map<String, dynamic>) {
        final name = (decoded['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _userName = name.split(' ').first;
          });
        }
      }
    } catch (_) {
      // ignore cache/parsing issues, keep default name
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pedometer = context.watch<PedometerService>();
    final currentSteps = pedometer.steps;
    final caloriesBurned = pedometer.calories;
    final distance = pedometer.distance;
    final activeMinutes = pedometer.activeMinutes;

    final progress = _goalSteps > 0 ? (currentSteps / _goalSteps).clamp(0.0, 1.0) : 0.0;

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
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStepCounter(currentSteps, progress),
                      const SizedBox(height: 24),
                      _buildQuickStats(caloriesBurned, distance, activeMinutes),
                      const SizedBox(height: 24),
                      _buildWeeklyProgress(currentSteps),
                      const SizedBox(height: 24),
                      _buildActionCards(),
                      const SizedBox(height: 24),
                      _buildMotivationCard(currentSteps, activeMinutes),
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
        onPressed: () => Navigator.pushNamed(context, '/profile'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE23C64),
        elevation: 8,
        icon: const Icon(Icons.person_rounded),
        label: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
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
                'Hello, $_userName!',
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
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCounter(int currentSteps, double progress) {
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
                        backgroundColor: const Color(0xFFFCEDD8),
                        progressColor: const Color(0xFFE23C64),
                      ),
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_walk_rounded, size: 40, color: Color(0xFFE23C64)),
                  const SizedBox(height: 8),
                  Text(
                    currentSteps.toString(),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE23C64),
                      height: 1,
                    ),
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
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFFCEDD8),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE23C64)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% of daily goal',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(double caloriesBurned, double distance, int activeMinutes) {
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
                color: const Color(0xFFFF5E5E),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.straighten_rounded,
                value: distance.toStringAsFixed(1),
                unit: 'km',
                label: 'Distance',
                color: const Color(0xFFFFD464),
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
          color: const Color(0xFFE23C64),
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
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: color,
                              height: 1,
                            ),
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
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: color,
                        height: 1,
                      ),
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
    final weekData = [6500, 8200, 7100, 9300, 8900, currentSteps, 0];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Находим максимум, исключая нулевые значения
    final nonZeroData = weekData.where((v) => v > 0).toList();
    final maxSteps = nonZeroData.isNotEmpty ? nonZeroData.reduce(math.max) : 10000;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/statistics'),
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
                    color: Color(0xFFE23C64),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE23C64).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: const Color(0xFFE23C64).withOpacity(0.7),
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final isToday = index == 5;
                  final stepCount = weekData[index];
                  final height = stepCount == 0 ? 10.0 : ((stepCount / maxSteps) * 140).clamp(10.0, 140.0);
                  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (stepCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${(stepCount / 1000).toStringAsFixed(1)}k',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isToday ? const Color(0xFFE23C64) : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        width: 32,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isToday
                                ? [const Color(0xFFE23C64), const Color(0xFFFF5E5E)]
                                : [
                                    const Color(0xFFFCEDD8),
                                    const Color(0xFFFCEDD8).withOpacity(0.6)
                                  ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        days[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                          color: isToday ? const Color(0xFFE23C64) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  );
                }),
              ),
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
            color: const Color(0xFFFF5E5E),
            onTap: () => Navigator.pushNamed(context, '/meals'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            icon: Icons.water_drop_rounded,
            title: 'Water',
            subtitle: 'Stay hydrated',
            color: const Color(0xFF64B5F6),
            onTap: () => Navigator.pushNamed(context, '/water'),
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

  Widget _buildMotivationCard(int currentSteps, int activeMinutes) {
    final remainingSteps = math.max(0, _goalSteps - currentSteps);
    final motivationText = remainingSteps > 0
        ? "You're only $remainingSteps steps away from your goal!"
        : "Amazing! You surpassed your goal today!";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE23C64), Color(0xFFFF5E5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE23C64).withOpacity(0.4),
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
                  remainingSteps > 0 ? '🔥 Keep Going!' : '🎉 Goal Reached!',
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              remainingSteps > 0 ? Icons.emoji_events_rounded : Icons.celebration_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
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
