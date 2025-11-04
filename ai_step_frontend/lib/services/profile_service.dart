import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class ProfileService extends ChangeNotifier {
  final AuthService _authService;
  
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;

  ProfileService(this._authService);

  // Getters
  Map<String, dynamic>? get profileData => _profileData;
  bool get isLoading => _isLoading;

  String get fullName {
    if (_profileData == null) return 'User';
    final firstName = _profileData!['firstName'] ?? '';
    final lastName = _profileData!['lastName'] ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'User' : name;
  }

  String get email => _profileData?['email'] ?? '';
  double? get heightCm => _profileData?['heightCm']?.toDouble();
  double? get weightKg => _profileData?['weightKg']?.toDouble();
  String? get gender => _profileData?['gender'];
  String? get activityLevel => _profileData?['activityLevel'];
  String? get goal => _profileData?['goal'];
  String? get birthDate => _profileData?['birthDate'];
  int? get age => _profileData?['age']?.toInt();

  /// Load user profile from server
  Future<bool> loadProfile() async {
    if (!_authService.isAuthenticated) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.authenticatedRequest(
        method: 'GET',
        path: '/api/profile',
      );

      if (response.statusCode == 200) {
        _profileData = jsonDecode(response.body) as Map<String, dynamic>;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('Failed to load profile: ${response.statusCode}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    double? heightCm,
    double? weightKg,
    String? gender,
    String? activityLevel,
    String? goal,
    String? birthDate,
    int? age,
  }) async {
    if (!_authService.isAuthenticated) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{};
      
      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (heightCm != null) updateData['heightCm'] = heightCm;
      if (weightKg != null) updateData['weightKg'] = weightKg;
      if (gender != null) updateData['gender'] = gender;
      if (activityLevel != null) updateData['activityLevel'] = activityLevel;
      if (goal != null) updateData['goal'] = goal;
      if (birthDate != null) updateData['birthDate'] = birthDate;
      if (age != null) updateData['age'] = age;

      final response = await _authService.authenticatedRequest(
        method: 'PUT',
        path: '/api/profile',
        body: updateData,
      );

      if (response.statusCode == 200) {
        _profileData = jsonDecode(response.body) as Map<String, dynamic>;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('Failed to update profile: ${response.statusCode}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Partial update using PATCH
  Future<bool> patchProfile(Map<String, dynamic> updateData) async {
    if (!_authService.isAuthenticated) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.authenticatedRequest(
        method: 'PATCH',
        path: '/api/profile',
        body: updateData,
      );

      if (response.statusCode == 200) {
        _profileData = jsonDecode(response.body) as Map<String, dynamic>;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('Failed to patch profile: ${response.statusCode}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error patching profile: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear profile data
  void clearProfile() {
    _profileData = null;
    _isLoading = false;
    notifyListeners();
  }
}