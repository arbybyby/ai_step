import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data
  String _name = '';
  String _email = '';
  int? _age;
  double? _height;
  double? _weight;
  String? _gender;
  String? _activityLevel;
  String? _birthDate;
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');
      
      if (_authToken == null) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
        return;
      }

      final response = await http.get(
        apiUri('/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'] as Map<String, dynamic>;
        
        setState(() {
          _name = user['name'] ?? 'User';
          _email = user['email'] ?? '';
          _height = user['height_cm']?.toDouble();
          _weight = user['weight_kg']?.toDouble();
          _gender = user['gender'];
          _activityLevel = user['activity_level'];
          _birthDate = user['birth_date'];
          
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
          _isRefreshing = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await prefs.remove('auth_token');
        await prefs.remove('auth_user');
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        _showSnackBar('Failed to load profile data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        _showSnackBar('Error loading profile: ${e.toString()}');
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadUserData();
    _showSnackBar('Profile refreshed!', isSuccess: true);
  }

  Future<void> _updateProfile({
    double? height,
    double? weight,
    String? gender,
    String? activityLevel,
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
          if (birthDate != null) 'birth_date': birthDate,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
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

  double get _bmi {
    if (_weight == null || _height == null || _height == 0) return 0;
    return _weight! / ((_height! / 100) * (_height! / 100));
  }

  int get _dailyCalories {
    if (_weight == null || _height == null || _age == null) return 2000;
    
    double bmr;
    if (_gender == 'male') {
      bmr = 10 * _weight! + 6.25 * _height! - 5 * _age! + 5;
    } else if (_gender == 'female') {
      bmr = 10 * _weight! + 6.25 * _height! - 5 * _age! - 161;
    } else {
      bmr = 10 * _weight! + 6.25 * _height! - 5 * _age! - 78;
    }
    
    final activityMultipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };
    
    return (bmr * (activityMultipliers[_activityLevel] ?? 1.55)).round();
  }

  String _getGenderDisplay(String? gender) {
    if (gender == null) return 'Not set';
    switch (gender.toLowerCase()) {
      case 'male': return 'Male';
      case 'female': return 'Female';
      case 'other': return 'Other';
      default: return 'Unspecified';
    }
  }

  String _getActivityDisplay(String? activity) {
    if (activity == null) return 'Not set';
    switch (activity.toLowerCase()) {
      case 'sedentary': return 'Sedentary';
      case 'light': return 'Light';
      case 'moderate': return 'Moderate';
      case 'active': return 'Active';
      case 'very_active': return 'Very Active';
      default: return 'Not set';
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? const Color(0xFFE23C64) : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showActivityHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE23C64).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.history_rounded, color: Color(0xFFE23C64)),
            ),
            const SizedBox(width: 12),
            const Text('Activity History', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Activity:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildHistoryItem('Today', '7,845 steps', '5.8 km', Icons.directions_walk_rounded),
            _buildHistoryItem('Yesterday', '8,900 steps', '6.5 km', Icons.check_circle_outline),
            _buildHistoryItem('2 days ago', '9,300 steps', '7.0 km', Icons.check_circle_outline),
            const SizedBox(height: 8),
            const Text(
              'Full history coming soon!',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE23C64))),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String day, String steps, String distance, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE23C64), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('$steps • $distance', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE23C64).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.settings_rounded, color: Color(0xFFE23C64)),
            ),
            const SizedBox(width: 12),
            const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingOption('Notifications', Icons.notifications_outlined, true),
            _buildSettingOption('Dark Mode', Icons.dark_mode_outlined, false),
            _buildSettingOption('Auto-sync', Icons.sync_rounded, true),
            const SizedBox(height: 8),
            const Text(
              'More settings coming soon!',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE23C64))),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingOption(String title, IconData icon, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE23C64), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
          Switch(
            value: value,
            onChanged: (v) {},
            activeColor: const Color(0xFFE23C64),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE23C64).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.help_outline_rounded, color: Color(0xFFE23C64)),
            ),
            const SizedBox(width: 12),
            const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('FAQ', Icons.quiz_outlined, 'Find answers to common questions'),
            _buildHelpItem('Contact Us', Icons.email_outlined, 'Get in touch with our team'),
            _buildHelpItem('Tutorial', Icons.play_circle_outline, 'Learn how to use AI-Step'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFE23C64), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE23C64))),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, IconData icon, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE23C64), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
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
              colors: [Color(0xFFFFD464), Color(0xFFFF5E5E), Color(0xFFE23C64)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ),
        ),
      );
    }

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
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildHealthMetrics(),
                      const SizedBox(height: 16),
                      _buildPersonalInfo(),
                      const SizedBox(height: 16),
                      _buildSettings(),
                      const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(16),
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
          const Spacer(),
          const Text(
            'Profile',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            onPressed: _showEditDialog,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
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
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.person_rounded, size: 60, color: Color(0xFFE23C64)),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD464),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _name.isNotEmpty ? _name : 'User',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          _email,
          style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildHealthMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              icon: Icons.monitor_weight_outlined,
              label: 'BMI',
              value: _bmi > 0 ? _bmi.toStringAsFixed(1) : '--',
              color: const Color(0xFFFF5E5E),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.local_fire_department_rounded,
              label: 'Daily Goal',
              value: '$_dailyCalories',
              suffix: 'kcal',
              color: const Color(0xFFFFD464),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    String? suffix,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, height: 1)),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(suffix, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color.withOpacity(0.7))),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
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
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFE23C64))),
            ),
            _buildInfoRow(Icons.cake_outlined, 'Age', _age != null ? '$_age years' : 'Not set'),
            _buildInfoRow(Icons.height_rounded, 'Height', _height != null ? '${_height!.toStringAsFixed(0)} cm' : 'Not set'),
            _buildInfoRow(Icons.monitor_weight_outlined, 'Weight', _weight != null ? '${_weight!.toStringAsFixed(1)} kg' : 'Not set'),
            _buildInfoRow(Icons.wc_rounded, 'Gender', _getGenderDisplay(_gender)),
            _buildInfoRow(Icons.fitness_center_rounded, 'Activity', _getActivityDisplay(_activityLevel), isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE23C64).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFE23C64), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFE23C64))),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            _buildSettingItem(Icons.refresh_rounded, 'Refresh Data', _isRefreshing ? null : _refreshData, isLoading: _isRefreshing),
            _buildSettingItem(Icons.history_rounded, 'Activity History', _showActivityHistory),
            _buildSettingItem(Icons.settings_rounded, 'Settings', _showSettings),
            _buildSettingItem(Icons.help_outline_rounded, 'Help & Support', _showHelpSupport),
            _buildSettingItem(Icons.logout_rounded, 'Logout', _showLogoutDialog, isLast: true, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    VoidCallback? onTap, {
    bool isLast = false,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.vertical(
        top: title == 'Refresh Data' ? const Radius.circular(24) : Radius.zero,
        bottom: isLast ? const Radius.circular(24) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.withOpacity(0.1) : const Color(0xFFE23C64).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE23C64)),
                    )
                  : Icon(icon, color: isDestructive ? Colors.red : const Color(0xFFE23C64), size: 24),
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
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    final heightController = TextEditingController(text: _height?.toStringAsFixed(0) ?? '');
    final weightController = TextEditingController(text: _weight?.toStringAsFixed(1) ?? '');
    String selectedGender = _gender ?? 'unspecified';
    String selectedActivity = _activityLevel ?? 'moderate';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                    DropdownMenuItem(value: 'unspecified', child: Text('Prefer not to say')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedGender = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedActivity,
                  decoration: const InputDecoration(labelText: 'Activity Level', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
                    DropdownMenuItem(value: 'light', child: Text('Light')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'very_active', child: Text('Very Active')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedActivity = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                final height = double.tryParse(heightController.text);
                final weight = double.tryParse(weightController.text);
                
                await _updateProfile(
                  height: height,
                  weight: weight,
                  gender: selectedGender,
                  activityLevel: selectedActivity,
                );
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE23C64))),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('auth_token');
              await prefs.remove('auth_user');
              
              if (mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
          ),
        ],
      ),
    );
  }
}






