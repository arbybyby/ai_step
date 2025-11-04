import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../core/api_config.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // User data
  String _name = '';
  String _email = '';
  int? _age;
  double? _height;
  double? _weight;
  String? _gender;
  String? _activityLevel;
  String? _goal; // lose, maintain, gain
  String? _birthDate;

  bool _isLoading = true;
  String? _authToken;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      print('===== ProfileScreen _loadUserData =====');
      print('AuthService authenticated: ${authService.isAuthenticated}');
      print('AuthService token exists: ${authService.token != null}');
      print('AuthService user exists: ${authService.user != null}');

      _authToken = authService.token;
      print('Token obtained: ${_authToken?.substring(0, 20)}...');

      final response = await authService.authenticatedRequest(
        method: 'GET',
        path: '/api/profile',
      );

      print('Profile response status: ${response.statusCode}');
      print('Profile response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        setState(() {
          _name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}' .trim();
          if (_name.isEmpty) _name = 'User';
          _email = data['email'] ?? '';
          // Эти поля пока не возвращаются бэкендом, но оставляем для будущего использования
          _height = data['height_cm']?.toDouble();
          _weight = data['weight_kg']?.toDouble();
          _gender = data['gender'];
          _activityLevel = data['activity_level'];
          _goal = data['goal'] ?? 'maintain';
          _birthDate = data['birth_date'];

          if (_birthDate != null && _birthDate!.isNotEmpty) {
            final birthDate = DateTime.parse(_birthDate!);
            final now = DateTime.now();
            _age = now.year - birthDate.year;
            if (now.month < birthDate.month ||
                (now.month == birthDate.month && now.day < birthDate.day)) {
              _age = _age! - 1;
            }
          }

          _isLoading = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.logout();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Failed to load profile data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error loading profile: ${e.toString()}');
      }
    }
  }

  Future<void> _refreshData() async {
    HapticFeedback.mediumImpact();
    await _loadUserData();
    HapticFeedback.lightImpact();
    _showSnackBar('Profile refreshed!', isSuccess: true);
  }

  Future<void> _updateProfile({
    double? height,
    double? weight,
    String? gender,
    String? activityLevel,
    String? goal,
    String? birthDate,
  }) async {
    try {
      final response = await http.post(
        apiUri('/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (height != null) 'height_cm': height,
          if (weight != null) 'weight_kg': weight,
          if (gender != null) 'gender': gender,
          if (activityLevel != null) 'activity_level': activityLevel,
          if (goal != null) 'goal': goal,
          if (birthDate != null) 'birth_date': birthDate,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        HapticFeedback.mediumImpact();
        _showSnackBar('Profile updated successfully!', isSuccess: true);
        await _loadUserData();
      } else {
        _showSnackBar('Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating profile: ${e.toString()}');
      }
    }
  }

  // SMART CALCULATIONS

  double get _bmi {
    if (_weight == null || _height == null || _height == 0) return 0;
    return _weight! / ((_height! / 100) * (_height! / 100));
  }

  String get _bmiCategory {
    if (_bmi == 0) return 'Unknown';
    if (_bmi < 18.5) return 'Underweight';
    if (_bmi < 25) return 'Normal';
    if (_bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color get _bmiColor {
    if (_bmi == 0) return Colors.grey;
    if (_bmi < 18.5) return Colors.blue;
    if (_bmi < 25) return Colors.green;
    if (_bmi < 30) return Colors.orange;
    return Colors.red;
  }

  // BMR (Basal Metabolic Rate) - Mifflin-St Jeor Equation
  double get _bmr {
    if (_weight == null || _height == null || _age == null) return 0;

    double bmr;
    if (_gender == 'male') {
      bmr = 10 * _weight! + 6.25 * _height! - 5 * _age! + 5;
    } else if (_gender == 'female') {
      bmr = 10 * _weight! + 6.25 * _height! - 5 * _age! - 161;
    } else {
      // Average for non-specified
      bmr = 10 * _weight! + 6.25 * _height! - 5 * _age! - 78;
    }

    return bmr;
  }

  // TDEE (Total Daily Energy Expenditure) - Real calorie burn
  int get _tdee {
    if (_bmr == 0) return 2000;

    final activityMultipliers = {
      'sedentary': 1.2, // Little/no exercise
      'light': 1.375, // Exercise 1-3 days/week
      'moderate': 1.55, // Exercise 3-5 days/week
      'active': 1.725, // Exercise 6-7 days/week
      'very_active': 1.9, // Very hard exercise daily
    };

    return (_bmr * (activityMultipliers[_activityLevel] ?? 1.55)).round();
  }

  // Calorie goal based on user's goal
  int get _calorieGoal {
    if (_goal == 'lose') {
      return _tdee - 500; // Lose ~0.5kg per week
    } else if (_goal == 'gain') {
      return _tdee + 300; // Gain ~0.3kg per week
    }
    return _tdee; // Maintain
  }

  // Water goal based on weight and activity
  int get _waterGoalMl {
    if (_weight == null) return 2000;

    // Base: 35ml per kg of body weight
    double baseWater = _weight! * 35;

    // Activity bonus
    final activityBonus = {
      'sedentary': 0,
      'light': 200,
      'moderate': 400,
      'active': 600,
      'very_active': 800,
    };

    baseWater += activityBonus[_activityLevel] ?? 400;

    return baseWater.round();
  }

  // Protein goal (1.6-2.2g per kg for active people)
  int get _proteinGoalG {
    if (_weight == null) return 150;
    return (_weight! * 1.8).round();
  }

  // Step goal based on activity level
  int get _stepGoal {
    final stepGoals = {
      'sedentary': 5000,
      'light': 7500,
      'moderate': 10000,
      'active': 12500,
      'very_active': 15000,
    };
    return stepGoals[_activityLevel] ?? 10000;
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? const Color(0xFF059669) : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

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
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFF059669),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildSmartMetrics(),
                      const SizedBox(height: 16),
                      _buildDailyGoals(),
                      const SizedBox(height: 16),
                      _buildPersonalInfo(),
                      const SizedBox(height: 16),
                      _buildSettingsSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
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
      title: const Text(
        'Profile',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showEditDialog();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 60,
                        color: Color(0xFF059669),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF34D399)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _name.isNotEmpty ? _name : 'User',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmartMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.monitor_weight_outlined,
                  label: 'BMI',
                  value: _bmi > 0 ? _bmi.toStringAsFixed(1) : '--',
                  subtitle: _bmiCategory,
                  color: _bmiColor,
                  index: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'TDEE',
                  value: _tdee > 0 ? _tdee.toString() : '--',
                  subtitle: 'Daily burn',
                  suffix: 'cal',
                  color: const Color(0xFFFF9800),
                  index: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            icon: Icons.flag_rounded,
            label: 'Calorie Goal',
            value: _calorieGoal > 0 ? _calorieGoal.toString() : '--',
            subtitle: _goal == 'lose'
                ? 'Weight Loss'
                : (_goal == 'gain' ? 'Muscle Gain' : 'Maintain'),
            suffix: 'kcal',
            color: const Color(0xFF059669),
            isWide: true,
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    String? suffix,
    required Color color,
    bool isWide = false,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animValue)),
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
              child: isWide
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
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
                                    tween: IntTween(
                                      begin: 0,
                                      end: int.tryParse(value) ?? 0,
                                    ),
                                    duration: const Duration(
                                      milliseconds: 1200,
                                    ),
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
                                  if (suffix != null) ...[
                                    const SizedBox(width: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        suffix,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: color.withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ],
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
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              value,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: color,
                                height: 1,
                              ),
                            ),
                            if (suffix != null) ...[
                              const SizedBox(width: 3),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  suffix,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyGoals() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
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
                    Icons.track_changes_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Daily Goals',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildGoalRow(
              Icons.directions_walk_rounded,
              'Steps',
              '$_stepGoal steps',
            ),
            const SizedBox(height: 12),
            _buildGoalRow(
              Icons.water_drop_rounded,
              'Water',
              '${(_waterGoalMl / 1000).toStringAsFixed(1)}L',
            ),
            const SizedBox(height: 12),
            _buildGoalRow(
              Icons.restaurant_rounded,
              'Protein',
              '${_proteinGoalG}g',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
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

  Widget _buildPersonalInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
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
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
                ),
              ),
            ),
            _buildInfoRow(
              Icons.cake_outlined,
              'Age',
              _age != null ? '$_age years' : 'Not set',
            ),
            _buildInfoRow(
              Icons.height_rounded,
              'Height',
              _height != null ? '${_height!.toStringAsFixed(0)} cm' : 'Not set',
            ),
            _buildInfoRow(
              Icons.monitor_weight_outlined,
              'Weight',
              _weight != null ? '${_weight!.toStringAsFixed(1)} kg' : 'Not set',
            ),
            _buildInfoRow(
              Icons.wc_rounded,
              'Gender',
              _getGenderDisplay(_gender),
            ),
            _buildInfoRow(
              Icons.fitness_center_rounded,
              'Activity',
              _getActivityDisplay(_activityLevel),
            ),
            _buildInfoRow(
              Icons.flag_outlined,
              'Goal',
              _getGoalDisplay(_goal),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF059669), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
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
            _buildSettingItem(Icons.info_outline_rounded, 'About', () {
              HapticFeedback.lightImpact();
              _showAboutDialog();
            }),
            _buildSettingItem(Icons.help_outline_rounded, 'Help & Support', () {
              HapticFeedback.lightImpact();
              _showHelpDialog();
            }),
            _buildSettingItem(
              Icons.logout_rounded,
              'Logout',
              () {
                HapticFeedback.lightImpact();
                _showLogoutDialog();
              },
              isLast: true,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLast = false,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: title == 'About' ? const Radius.circular(24) : Radius.zero,
        bottom: isLast ? const Radius.circular(24) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF059669),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDestructive ? Colors.red : Colors.grey.shade800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  String _getGenderDisplay(String? gender) {
    if (gender == null) return 'Not set';
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return 'Prefer not to say';
    }
  }

  String _getActivityDisplay(String? activity) {
    if (activity == null) return 'Not set';
    switch (activity.toLowerCase()) {
      case 'sedentary':
        return 'Sedentary (Desk job)';
      case 'light':
        return 'Light (1-3 days/week)';
      case 'moderate':
        return 'Moderate (3-5 days/week)';
      case 'active':
        return 'Active (6-7 days/week)';
      case 'very_active':
        return 'Very Active (Athlete)';
      default:
        return 'Not set';
    }
  }

  String _getGoalDisplay(String? goal) {
    if (goal == null) return 'Not set';
    switch (goal.toLowerCase()) {
      case 'lose':
        return 'Lose Weight (-0.5kg/week)';
      case 'gain':
        return 'Gain Muscle (+0.3kg/week)';
      case 'maintain':
        return 'Maintain Weight';
      default:
        return 'Not set';
    }
  }

  void _showEditDialog() {
    final heightController = TextEditingController(
      text: _height?.toStringAsFixed(0) ?? '',
    );
    final weightController = TextEditingController(
      text: _weight?.toStringAsFixed(1) ?? '',
    );
    String selectedGender = _gender ?? 'unspecified';
    String selectedActivity = _activityLevel ?? 'moderate';
    String selectedGoal = _goal ?? 'maintain';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF059669),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Height (cm)',
                    prefixIcon: const Icon(
                      Icons.height_rounded,
                      color: Color(0xFF059669),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF059669),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: const Icon(
                      Icons.monitor_weight_outlined,
                      color: Color(0xFF059669),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF059669),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: const Icon(
                      Icons.wc_rounded,
                      color: Color(0xFF059669),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF059669),
                        width: 2,
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                    DropdownMenuItem(
                      value: 'unspecified',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedGender = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedActivity,
                  decoration: InputDecoration(
                    labelText: 'Activity Level',
                    prefixIcon: const Icon(
                      Icons.fitness_center_rounded,
                      color: Color(0xFF059669),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF059669),
                        width: 2,
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'sedentary',
                      child: Text('Sedentary (Desk job)'),
                    ),
                    DropdownMenuItem(
                      value: 'light',
                      child: Text('Light (1-3 days/week)'),
                    ),
                    DropdownMenuItem(
                      value: 'moderate',
                      child: Text('Moderate (3-5 days/week)'),
                    ),
                    DropdownMenuItem(
                      value: 'active',
                      child: Text('Active (6-7 days/week)'),
                    ),
                    DropdownMenuItem(
                      value: 'very_active',
                      child: Text('Very Active (Athlete)'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedActivity = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGoal,
                  decoration: InputDecoration(
                    labelText: 'Fitness Goal',
                    prefixIcon: const Icon(
                      Icons.flag_outlined,
                      color: Color(0xFF059669),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF059669),
                        width: 2,
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'lose', child: Text('Lose Weight')),
                    DropdownMenuItem(
                      value: 'maintain',
                      child: Text('Maintain Weight'),
                    ),
                    DropdownMenuItem(value: 'gain', child: Text('Gain Muscle')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedGoal = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);

                final height = double.tryParse(heightController.text);
                final weight = double.tryParse(weightController.text);

                await _updateProfile(
                  height: height,
                  weight: weight,
                  gender: selectedGender,
                  activityLevel: selectedActivity,
                  goal: selectedGoal,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF059669),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'About AI-Step',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI-Step uses scientifically proven formulas to calculate your personalized fitness goals:',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            _buildInfoBullet('BMR: Mifflin-St Jeor Equation'),
            _buildInfoBullet('TDEE: Activity-based multipliers'),
            _buildInfoBullet('Water: 35ml per kg + activity bonus'),
            _buildInfoBullet('Protein: 1.8g per kg body weight'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF059669),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildInfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF059669),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Help & Support',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHelpItem(
              'FAQ',
              'Find answers to common questions',
              Icons.quiz_outlined,
            ),
            _buildHelpItem(
              'Tutorial',
              'Learn how to use AI-Step',
              Icons.play_circle_outline,
            ),
            _buildHelpItem(
              'Contact Us',
              'Get in touch with support',
              Icons.email_outlined,
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

  Widget _buildHelpItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF059669), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.logout();

              if (mounted) {
                Navigator.pop(context);
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
