import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

// ─── Design tokens (shared with HomeScreen) ───────────────────────────────────
const _bg = Color(0xFF0A0D0B);
const _card = Color(0xFF141714);
const _green = Color(0xFF28C76F);
const _white = Colors.white;
const _grey = Color(0xFF8A8A8A);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static final _emptyUser = User(
    id: 0,
    email: '',
    calorieGoal: 2000,
    proteinGoal: 150,
    waterGoal: 2.0,
    stepsGoal: 10000,
  );

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final user = userAsync.valueOrNull ?? _emptyUser;

    if (userAsync.isLoading && userAsync.valueOrNull == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _green)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context, ref, user),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            _buildAvatarSection(user),
            const SizedBox(height: 22),
            _buildQuickStatsRow(user),
            const SizedBox(height: 22),
            _buildDailyGoalsCard(user),
            const SizedBox(height: 22),
            _buildPersonalInfoCard(user),
            const SizedBox(height: 22),
            _buildMenuSection(context),
            const SizedBox(height: 28),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    User user,
  ) {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Profile',
        style: TextStyle(
          color: _white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => _showEditProfileDialog(context, ref, user),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_outlined, color: _white, size: 18),
          ),
        ),
      ],
    );
  }

  // ─── Avatar ────────────────────────────────────────────────────────────────
  Widget _buildAvatarSection(User user) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showAvatarOptions(context, ref, user),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _green, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: _card,
                  backgroundImage: user.avatarPath != null
                      ? NetworkImage(
                          user.avatarPath!.startsWith('http')
                              ? '${user.avatarPath!}?t=${DateTime.now().millisecondsSinceEpoch}'
                              : 'http://192.168.43.16:9000/avatars/${user.avatarPath}?t=${DateTime.now().millisecondsSinceEpoch}',
                        )
                      : null,
                  child: user.avatarPath == null
                      ? Text(
                          _getInitials(user),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _green,
                          ),
                        )
                      : null,
                ),
              ),
              // Camera badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bg, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _getFullName(user).isNotEmpty ? _getFullName(user) : 'User',
          style: const TextStyle(
            color: _white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email.isNotEmpty ? user.email : 'No email',
          style: const TextStyle(color: _grey, fontSize: 14),
        ),
      ],
    );
  }

  // ─── Quick Stats Row ───────────────────────────────────────────────────────
  Widget _buildQuickStatsRow(User user) {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            label: 'Weight',
            value: user.weight != null
                ? '${user.weight!.toStringAsFixed(0)}'
                : '—',
            unit: 'kg',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            label: 'Height',
            value: user.height != null
                ? '${user.height!.toStringAsFixed(0)}'
                : '—',
            unit: 'cm',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            label: 'Age',
            value: user.age != null ? '${user.age}' : '—',
            unit: 'yrs',
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: _green,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(color: _grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: _grey, fontSize: 12)),
        ],
      ),
    );
  }

  // ─── Daily Goals ───────────────────────────────────────────────────────────
  Widget _buildDailyGoalsCard(User user) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.track_changes_rounded, 'Daily Goals'),
          const SizedBox(height: 14),
          _goalRow(
            Icons.directions_walk_rounded,
            'Steps',
            '${user.stepsGoal} steps',
          ),
          _divider(),
          _goalRow(
            Icons.water_drop_rounded,
            'Water',
            '${user.waterGoal.toStringAsFixed(1)} L',
          ),
          _divider(),
          _goalRow(
            Icons.local_fire_department_rounded,
            'Calories',
            '${user.calorieGoal.toStringAsFixed(0)} kcal',
          ),
          _divider(),
          _goalRow(
            Icons.set_meal_rounded,
            'Protein',
            '${user.proteinGoal.toStringAsFixed(0)} g',
          ),
        ],
      ),
    );
  }

  Widget _goalRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _green, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: _white, fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: _green,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Personal Info ─────────────────────────────────────────────────────────
  Widget _buildPersonalInfoCard(User user) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.person_rounded, 'Personal Info'),
          const SizedBox(height: 14),
          _infoRow('Gender', _getGenderLabel(user.gender)),
          _divider(),
          _infoRow('Activity', _getActivityLabel(user.activityLevel)),
          _divider(),
          _infoRow('Goal', _getFitnessGoalLabel(user.goal)),
          _divider(),
          _infoRow(
            'BMI',
            user.bmi != null ? user.bmi!.toStringAsFixed(1) : '—',
          ),
          _divider(),
          _infoRow(
            'Est. TDEE',
            user.estimatedTDEE != null
                ? '${user.estimatedTDEE!.toStringAsFixed(0)} kcal'
                : '—',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: _grey, fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: _white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Menu Section ──────────────────────────────────────────────────────────
  Widget _buildMenuSection(BuildContext context) {
    final items = [
      _MenuItem(
        Icons.edit_rounded,
        'Edit Profile',
        false,
        () => _showEditProfileDialog(
          context,
          ref,
          ref.read(userProfileProvider).valueOrNull ?? _emptyUser,
        ),
      ),
      _MenuItem(Icons.notifications_rounded, 'Notifications', false, () {}),
      _MenuItem(Icons.flag_rounded, 'Goal Settings', false, () {}),
      _MenuItem(Icons.lock_rounded, 'Privacy', false, () {}),
      _MenuItem(Icons.info_rounded, 'About', false, () {}),
      _MenuItem(Icons.help_rounded, 'Help & Support', false, () {}),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Settings',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
        ),
        ...items.map((item) => _menuTile(item)).toList(),
      ],
    );
  }

  Widget _menuTile(_MenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.isDestructive
                    ? Colors.red.withOpacity(0.12)
                    : _green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: item.isDestructive ? Colors.redAccent : _green,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: item.isDestructive ? Colors.redAccent : _white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _grey, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Logout Button ─────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            SizedBox(width: 10),
            Text(
              'Log Out',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared helpers ────────────────────────────────────────────────────────
  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _green, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Colors.white.withOpacity(0.05));
  }

  // ─── Unchanged helpers from original ──────────────────────────────────────
  String _getFullName(User user) {
    final parts = <String>[];
    if (user.firstName != null && user.firstName!.trim().isNotEmpty)
      parts.add(user.firstName!.trim());
    if (user.lastName != null && user.lastName!.trim().isNotEmpty)
      parts.add(user.lastName!.trim());
    return parts.isEmpty ? '' : parts.join(' ');
  }

  String _getInitials(User user) {
    final first = user.firstName?.trim() ?? '';
    final last = user.lastName?.trim() ?? '';
    if (first.isNotEmpty && last.isNotEmpty)
      return '${first[0]}${last[0]}'.toUpperCase();
    if (first.isNotEmpty) return first[0].toUpperCase();
    if (last.isNotEmpty) return last[0].toUpperCase();
    return user.email.isNotEmpty ? user.email[0].toUpperCase() : 'U';
  }

  String _getGenderLabel(Gender? gender) {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.none:
        return 'Prefer not to say';
      case null:
        return 'Not set';
    }
  }

  String _getActivityLabel(ActivityLevel? activity) {
    switch (activity) {
      case ActivityLevel.sedentary:
        return 'Sedentary (Desk job)';
      case ActivityLevel.light:
        return 'Light (1–3 days/week)';
      case ActivityLevel.moderate:
        return 'Moderate (3–5 days/week)';
      case ActivityLevel.active:
        return 'Active (6–7 days/week)';
      case ActivityLevel.veryActive:
        return 'Very Active (Athlete)';
      case null:
        return 'Not set';
    }
  }

  String _getFitnessGoalLabel(FitnessGoal? goal) {
    switch (goal) {
      case FitnessGoal.loseWeight:
        return 'Lose Weight';
      case FitnessGoal.maintainWeight:
        return 'Maintain Weight';
      case FitnessGoal.gainMuscle:
        return 'Gain Muscle';
      case null:
        return 'Not set';
    }
  }

  void _showAvatarOptions(BuildContext context, WidgetRef ref, User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Change Photo',
              style: TextStyle(
                color: _white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _sheetTile(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUploadImage(context, ref, user, ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            _sheetTile(
              icon: Icons.photo_library_rounded,
              label: 'Gallery',
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUploadImage(context, ref, user, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E221E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: _green, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: _white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    WidgetRef ref,
    User user,
    ImageSource source,
  ) async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(source: source);
      if (pickedFile == null) return;
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uploading avatar...')));
      final userService = UserService();
      final avatarPath = await userService.uploadAvatar(
        user.id,
        File(pickedFile.path),
      );
      if (!context.mounted) return;
      await ref.read(userProfileProvider.notifier).updateAvatarPath(avatarPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar uploaded successfully!'),
          backgroundColor: _green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading avatar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, User? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileModal(user: user),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(color: _white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: _grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/signin', (_) => false);
            },
            child: const Text(
              'Log Out',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Internal data model ───────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.isDestructive, this.onTap);
}

// ─── Edit Profile Modal (unchanged logic, dark-themed) ────────────────────────
class _EditProfileModal extends ConsumerStatefulWidget {
  final User? user;
  const _EditProfileModal({this.user});

  @override
  ConsumerState<_EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends ConsumerState<_EditProfileModal> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  Gender? _selectedGender;
  ActivityLevel? _selectedActivity;
  FitnessGoal? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.user?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.user?.lastName ?? '',
    );
    _ageController = TextEditingController(
      text: widget.user?.age?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.user?.height?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.user?.weight?.toString() ?? '',
    );
    _selectedGender = widget.user?.gender;
    _selectedActivity = widget.user?.activityLevel;
    _selectedGoal = widget.user?.goal;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: _white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                _field(
                  'First Name',
                  _firstNameController,
                  Icons.person_rounded,
                ),
                const SizedBox(height: 14),
                _field('Last Name', _lastNameController, Icons.person_rounded),
                const SizedBox(height: 14),
                _field(
                  'Age',
                  _ageController,
                  Icons.cake_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _field(
                  'Height (cm)',
                  _heightController,
                  Icons.height_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _field(
                  'Weight (kg)',
                  _weightController,
                  Icons.scale_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                _dropdown<Gender>(
                  label: 'Gender',
                  icon: Icons.people_rounded,
                  value: _selectedGender,
                  items: Gender.values,
                  labelOf: (g) {
                    switch (g) {
                      case Gender.male:
                        return 'Male';
                      case Gender.female:
                        return 'Female';
                      case Gender.other:
                        return 'Other';
                      case Gender.none:
                        return 'Prefer not to say';
                    }
                  },
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
                const SizedBox(height: 14),
                _dropdown<ActivityLevel>(
                  label: 'Activity Level',
                  icon: Icons.fitness_center_rounded,
                  value: _selectedActivity,
                  items: ActivityLevel.values,
                  labelOf: (a) {
                    switch (a) {
                      case ActivityLevel.sedentary:
                        return 'Sedentary (Desk job)';
                      case ActivityLevel.light:
                        return 'Light (1–3 days/week)';
                      case ActivityLevel.moderate:
                        return 'Moderate (3–5 days/week)';
                      case ActivityLevel.active:
                        return 'Active (6–7 days/week)';
                      case ActivityLevel.veryActive:
                        return 'Very Active (Athlete)';
                    }
                  },
                  onChanged: (v) => setState(() => _selectedActivity = v),
                ),
                const SizedBox(height: 14),
                _dropdown<FitnessGoal>(
                  label: 'Fitness Goal',
                  icon: Icons.flag_rounded,
                  value: _selectedGoal,
                  items: FitnessGoal.values,
                  labelOf: (g) {
                    switch (g) {
                      case FitnessGoal.loseWeight:
                        return 'Lose Weight';
                      case FitnessGoal.maintainWeight:
                        return 'Maintain Weight';
                      case FitnessGoal.gainMuscle:
                        return 'Gain Muscle';
                    }
                  },
                  onChanged: (v) => setState(() => _selectedGoal = v),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E221E),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: _grey,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _saveProfile,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _grey, fontSize: 14),
        prefixIcon: Icon(icon, color: _green, size: 20),
        filled: true,
        fillColor: const Color(0xFF1E221E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) labelOf,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T?>(
      value: value,
      dropdownColor: const Color(0xFF1E221E),
      style: const TextStyle(color: _white, fontSize: 15),
      iconEnabledColor: _grey,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _grey, fontSize: 14),
        prefixIcon: Icon(icon, color: _green, size: 20),
        filled: true,
        fillColor: const Color(0xFF1E221E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
      ),
      items: [
        DropdownMenuItem<T?>(
          value: null,
          child: const Text('Not set', style: TextStyle(color: _grey)),
        ),
        ...items.map(
          (item) => DropdownMenuItem<T?>(
            value: item,
            child: Text(labelOf(item), style: const TextStyle(color: _white)),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Future<void> _saveProfile() async {
    final userNotifier = ref.read(userProfileProvider.notifier);
    final currentUser = widget.user;
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        firstName: _firstNameController.text.isNotEmpty
            ? _firstNameController.text
            : null,
        lastName: _lastNameController.text.isNotEmpty
            ? _lastNameController.text
            : null,
        age: _ageController.text.isNotEmpty
            ? int.parse(_ageController.text)
            : null,
        height: _heightController.text.isNotEmpty
            ? double.parse(_heightController.text)
            : null,
        weight: _weightController.text.isNotEmpty
            ? double.parse(_weightController.text)
            : null,
        gender: _selectedGender,
        activityLevel: _selectedActivity,
        goal: _selectedGoal,
      );
      await userNotifier.updateUserProfile(updatedUser);
    }
    if (mounted) Navigator.pop(context);
  }
}
