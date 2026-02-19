import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/user_service.dart';

// Provider for sharing preferences
final sharedPreferencesProvider = Provider((ref) async {
  return await SharedPreferences.getInstance();
});

// Provider for user profile data
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<User?>>((ref) {
  return UserProfileNotifier();
});

class UserProfileNotifier extends StateNotifier<AsyncValue<User?>> {
  static const String _userStorageKey = 'user_profile';
  final UserService _userService = UserService();

  UserProfileNotifier() : super(const AsyncValue.loading()) {
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userStorageKey);

      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = User.fromJson(userMap);
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (_) {
      state = const AsyncValue.data(null);
    }
    await _refreshFromRemote();
  }

  Future<void> _refreshFromRemote() async {
    try {
      final results = await Future.wait([
        AuthService.getMe(),
        AuthService.getAvatarUrl(),
      ]);
      final remoteMap = results[0] as Map<String, dynamic>;
      final avatarUrl = results[1] as String?;
      if (remoteMap.isEmpty) return;
      final remoteUser = User.fromJson(remoteMap);
      final currentUser = state.whenData((user) => user).value;
      if (currentUser == null) {
        await _saveLocalProfile(remoteUser.copyWith(
          avatarPath: avatarUrl ?? remoteUser.avatarPath,
        ));
        return;
      }
      // Use remote data; prefer fresh avatar URL from /api/auth/avatar
      final mergedUser = remoteUser.copyWith(
        avatarPath: avatarUrl ?? currentUser.avatarPath ?? remoteUser.avatarPath,
      );
      await _saveLocalProfile(mergedUser);
    } catch (_) {
      // Keep local cache when remote fetch fails.
    }
  }

  Future<void> updateUserProfile(User user) async {
    try {
      await _userService.submitUser(user);
    } catch (_) {
      // Ignore remote errors — always save locally
    }
    await _saveLocalProfile(user);
  }

  Future<void> saveAvatarLocally(String avatarPath) async {
    final currentUser = state.whenData((user) => user).value;
    if (currentUser != null) {
      await _saveLocalProfile(currentUser.copyWith(avatarPath: avatarPath));
    }
  }

  /// Fetches the avatar URL from `/api/auth/avatar` and updates the profile.
  Future<void> refreshAvatarUrl() async {
    try {
      final url = await AuthService.getAvatarUrl();
      if (url != null && url.isNotEmpty) {
        await saveAvatarLocally(url);
      }
    } catch (_) {}
  }

  Future<void> _saveLocalProfile(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userStorageKey, jsonEncode(user.toJson()));
    state = AsyncValue.data(user);
  }

  Future<void> clearUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userStorageKey);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Update specific user fields
  Future<void> updateUserField({
    String? firstName,
    String? lastName,
    int? age,
    double? height,
    double? weight,
    Gender? gender,
    ActivityLevel? activityLevel,
    FitnessGoal? goal,
    double? calorieGoal,
    double? proteinGoal,
    double? waterGoal,
    int? stepsGoal,
    String? avatarPath,
  }) async {
    final currentUser = state.whenData((user) => user).value;
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        firstName: firstName,
        lastName: lastName,
        age: age,
        height: height,
        weight: weight,
        gender: gender,
        activityLevel: activityLevel,
        goal: goal,
        calorieGoal: calorieGoal,
        proteinGoal: proteinGoal,
        waterGoal: waterGoal,
        stepsGoal: stepsGoal,
        avatarPath: avatarPath,
      );
      await updateUserProfile(updatedUser);
    }
  }
}
