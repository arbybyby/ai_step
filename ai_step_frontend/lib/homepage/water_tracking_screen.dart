import 'package:flutter/material.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> with SingleTickerProviderStateMixin {
  int _glassesConsumed = 5;
  final int _dailyGoal = 8;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addGlass() {
    if (_glassesConsumed < _dailyGoal) {
      setState(() => _glassesConsumed++);
      _animationController.forward(from: 0);
    }
  }

  void _removeGlass() {
    if (_glassesConsumed > 0) {
      setState(() => _glassesConsumed--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_glassesConsumed / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFF42A5F5), Color(0xFF2196F3)],
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
                      _buildWaterBottle(progress),
                      const SizedBox(height: 40),
                      _buildProgressInfo(),
                      const SizedBox(height: 32),
                      _buildControls(),
                      const SizedBox(height: 32),
                      _buildGlassGrid(),
                      const SizedBox(height: 32),
                      _buildTips(),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Water Tracker',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Stay hydrated today',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterBottle(double progress) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
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
              Container(
                width: 160,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(80),
                  border: Border.all(color: const Color(0xFF2196F3), width: 4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(76),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                          width: double.infinity,
                          height: 280 * progress,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2196F3).withOpacity(0.8),
                                const Color(0xFF64B5F6).withOpacity(0.6),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                      // Wave effect
                      if (progress > 0)
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Positioned(
                              top: 280 * (1 - progress) - 10,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.water_drop_rounded,
                    size: 60,
                    color: Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_glassesConsumed / $_dailyGoal',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const Text(
                    'glasses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressInfo() {
    final remaining = _dailyGoal - _glassesConsumed;
    final liters = (_glassesConsumed * 0.25).toStringAsFixed(2);

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                icon: Icons.water_drop_outlined,
                value: '$liters L',
                label: 'Consumed',
                color: const Color(0xFF2196F3),
              ),
              Container(width: 1, height: 50, color: Colors.grey.shade300),
              _buildInfoItem(
                icon: Icons.flag_outlined,
                value: remaining > 0 ? '$remaining left' : 'Completed!',
                label: 'Goal Status',
                color: remaining > 0 ? const Color(0xFFFF5E5E) : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
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
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _removeGlass,
            icon: const Icon(Icons.remove_rounded, size: 24),
            label: const Text(
              'Remove',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFF5E5E),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _addGlass,
            icon: const Icon(Icons.add_rounded, size: 24),
            label: const Text(
              'Add Glass',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassGrid() {
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
            'Today\'s Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: _dailyGoal,
            itemBuilder: (context, index) {
              final isFilled = index < _glassesConsumed;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: isFilled
                      ? const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isFilled ? null : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  color: isFilled ? Colors.white : Colors.grey.shade400,
                  size: 32,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTips() {
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
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2196F3), size: 24),
              SizedBox(width: 8),
              Text(
                'Hydration Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('💧', 'Drink water first thing in the morning'),
          _buildTipItem('⏰', 'Set reminders throughout the day'),
          _buildTipItem('🏃', 'Drink more during and after exercise'),
          _buildTipItem('🍉', 'Eat water-rich fruits and vegetables'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}