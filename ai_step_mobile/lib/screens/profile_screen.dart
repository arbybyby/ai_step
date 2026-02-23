import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    final user = userAsync.valueOrNull ?? _emptyUser;

    if (userAsync.isLoading && userAsync.valueOrNull == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    {

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: CustomScrollView(
            slivers: [
              // Green Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: false,
                backgroundColor: const Color(0xFF1B8A6B),
                elevation: 0,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _showEditProfileDialog(context, ref, user),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: const Color(0xFF1B8A6B),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _showAvatarOptions(context, ref, user),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
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
                                          color: Color(0xFF1B8A6B),
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Color(0xFF1B8A6B),
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getFullName(user).isNotEmpty
                              ? _getFullName(user)
                              : 'User',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Stats cards (BMI, TDEE)
                      Row(
                        children: [
                          Expanded(
                            child: _BuildStatsCard(
                              icon: Icons.scale,
                              label: 'BMI',
                              value: user.bmi != null
                                  ? user.bmi!.toStringAsFixed(1)
                                  : 'Unknown',
                              color: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BuildStatsCard(
                              icon: Icons.local_fire_department,
                              label: 'TDEE',
                              value: user.estimatedTDEE != null
                                  ? user.estimatedTDEE!.toStringAsFixed(0)
                                  : 'Unknown',
                              subtitle: 'Daily burn',
                              color: const Color(0xFFFFF3E0),
                              valueColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Calorie Goal Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.flag,
                                color: Color(0xFF1B8A6B),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${user.calorieGoal.toStringAsFixed(0)} kcal',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B8A6B),
                                    ),
                                  ),
                                  const Text(
                                    'Calorie Goal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _getFitnessGoalLabel(user.goal),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Daily Goals Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A9F7F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.track_changes,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Daily Goals',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _DailyGoalRow(
                              icon: Icons.directions_walk,
                              label: 'Steps',
                              value: '${user.stepsGoal} steps',
                            ),
                            const SizedBox(height: 12),
                            _DailyGoalRow(
                              icon: Icons.water_drop,
                              label: 'Water',
                              value: '${user.waterGoal.toStringAsFixed(1)}L',
                            ),
                            const SizedBox(height: 12),
                            _DailyGoalRow(
                              icon: Icons.set_meal,
                              label: 'Protein',
                              value: '${user.proteinGoal.toStringAsFixed(0)}g',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Personal Information Section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding:
                                  EdgeInsets.fromLTRB(16, 16, 16, 12),
                              child: Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            _PersonalInfoRow(
                              icon: Icons.cake,
                              label: 'Age',
                              value: user.age != null
                                  ? '${user.age} years'
                                  : 'Not set',
                            ),
                            _PersonalInfoRow(
                              icon: Icons.height,
                              label: 'Height',
                              value: user.height != null
                                  ? '${user.height} cm'
                                  : 'Not set',
                            ),
                            _PersonalInfoRow(
                              icon: Icons.scale,
                              label: 'Weight',
                              value: user.weight != null
                                  ? '${user.weight} kg'
                                  : 'Not set',
                            ),
                            _PersonalInfoRow(
                              icon: Icons.people,
                              label: 'Gender',
                              value: _getGenderLabel(user.gender),
                            ),
                            _PersonalInfoRow(
                              icon: Icons.fitness_center,
                              label: 'Activity',
                              value: _getActivityLabel(user.activityLevel),
                            ),
                            _PersonalInfoRow(
                              icon: Icons.flag,
                              label: 'Goal',
                              value: _getFitnessGoalLabel(user.goal),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Menu
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _SettingsRow(
                              icon: Icons.info,
                              label: 'About',
                              onTap: () {},
                            ),
                            _SettingsRow(
                              icon: Icons.help,
                              label: 'Help & Support',
                              onTap: () {},
                            ),
                            _SettingsRow(
                              icon: Icons.logout,
                              label: 'Logout',
                              isLast: true,
                              isDestructive: true,
                              onTap: () {
                                _showLogoutDialog(context);
                              },
                            ),
                          ],
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
  }

  static final _emptyUser = User(
    id: 0,
    email: '',
    calorieGoal: 2000,
    proteinGoal: 150,
    waterGoal: 2.0,
    stepsGoal: 10000,
  );

  void _showAvatarOptions(BuildContext context, WidgetRef ref, User user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Avatar Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1B8A6B)),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUploadImage(context, ref, user, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1B8A6B)),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUploadImage(context, ref, user, ImageSource.gallery);
              },
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading avatar...')),
      );

      final userService = UserService();
      final avatarPath = await userService.uploadAvatar(user.id, File(pickedFile.path));

      if (!context.mounted) return;

      // Immediately update the avatar in the profile with cache busting
      final userNotifier = ref.read(userProfileProvider.notifier);
      await userNotifier.updateAvatarPath(avatarPath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar uploaded successfully!'),
          backgroundColor: Color(0xFF1B8A6B),
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

  String _getFullName(User user) {
    final parts = <String>[];
    if (user.firstName != null && user.firstName!.trim().isNotEmpty) {
      parts.add(user.firstName!.trim());
    }
    if (user.lastName != null && user.lastName!.trim().isNotEmpty) {
      parts.add(user.lastName!.trim());
    }
    return parts.isEmpty ? '' : parts.join(' ');
  }

  String _getInitials(User user) {
    final first = user.firstName?.trim() ?? '';
    final last = user.lastName?.trim() ?? '';
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) {
      return first[0].toUpperCase();
    }
    if (last.isNotEmpty) {
      return last[0].toUpperCase();
    }
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
        return 'Light (1-3 days/week)';
      case ActivityLevel.moderate:
        return 'Moderate (3-5 days/week)';
      case ActivityLevel.active:
        return 'Active (6-7 days/week)';
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
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/signin', (_) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BuildStatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color? color;
  final Color? valueColor;

  const _BuildStatsCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.color,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyGoalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DailyGoalRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PersonalInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _PersonalInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF1B8A6B), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1B8A6B),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 0,
            indent: 56,
            endIndent: 16,
            color: Colors.grey[200],
          ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLast;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? Colors.red
                        : const Color(0xFF1B8A6B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 0,
            indent: 56,
            endIndent: 16,
            color: Colors.grey[200],
          ),
      ],
    );
  }
}

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
    _firstNameController =
      TextEditingController(text: widget.user?.firstName ?? '');
    _lastNameController =
      TextEditingController(text: widget.user?.lastName ?? '');
    _ageController =
        TextEditingController(text: widget.user?.age?.toString() ?? '');
    _heightController =
        TextEditingController(text: widget.user?.height?.toString() ?? '');
    _weightController =
        TextEditingController(text: widget.user?.weight?.toString() ?? '');
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
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B8A6B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // First Name
                  _TextInputField(
                    label: 'First Name',
                    controller: _firstNameController,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  // Last Name
                  _TextInputField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  // Age
                  _TextInputField(
                    label: 'Age',
                    controller: _ageController,
                    icon: Icons.cake,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  // Height
                  _TextInputField(
                    label: 'Height (cm)',
                    controller: _heightController,
                    icon: Icons.height,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  // Weight
                  _TextInputField(
                    label: 'Weight (kg)',
                    controller: _weightController,
                    icon: Icons.scale,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  // Gender
                  _DropdownField<Gender>(
                    label: 'Gender',
                    icon: Icons.people,
                    value: _selectedGender,
                    items: Gender.values,
                    itemBuilder: (gender) {
                      switch (gender) {
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
                    onChanged: (value) => setState(() => _selectedGender = value),
                  ),
                  const SizedBox(height: 16),
                  // Activity Level
                  _DropdownField<ActivityLevel>(
                    label: 'Activity Level',
                    icon: Icons.fitness_center,
                    value: _selectedActivity,
                    items: ActivityLevel.values,
                    itemBuilder: (activity) {
                      switch (activity) {
                        case ActivityLevel.sedentary:
                          return 'Sedentary (Desk job)';
                        case ActivityLevel.light:
                          return 'Light (1-3 days/week)';
                        case ActivityLevel.moderate:
                          return 'Moderate (3-5 days/week)';
                        case ActivityLevel.active:
                          return 'Active (6-7 days/week)';
                        case ActivityLevel.veryActive:
                          return 'Very Active (Athlete)';
                      }
                    },
                    onChanged: (value) => setState(() => _selectedActivity = value),
                  ),
                  const SizedBox(height: 16),
                  // Fitness Goal
                  _DropdownField<FitnessGoal>(
                    label: 'Fitness Goal',
                    icon: Icons.flag,
                    value: _selectedGoal,
                    items: FitnessGoal.values,
                    itemBuilder: (goal) {
                      switch (goal) {
                        case FitnessGoal.loseWeight:
                          return 'Lose Weight';
                        case FitnessGoal.maintainWeight:
                          return 'Maintain Weight';
                        case FitnessGoal.gainMuscle:
                          return 'Gain Muscle';
                      }
                    },
                    onChanged: (value) => setState(() => _selectedGoal = value),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B8A6B),
                          ),
                          onPressed: _saveProfile,
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
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
        age: _ageController.text.isNotEmpty ? int.parse(_ageController.text) : null,
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

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _TextInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;

  const _TextInputField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1B8A6B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1B8A6B),
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) itemBuilder;
  final Function(T?) onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1B8A6B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1B8A6B),
            width: 2,
          ),
        ),
      ),
      items: [
        DropdownMenuItem<T?>(
          value: null,
          child: const Text('Not set'),
        ),
        ...items.map((item) {
          return DropdownMenuItem<T?>(
            value: item,
            child: Text(itemBuilder(item)),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}
