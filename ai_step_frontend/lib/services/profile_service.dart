import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class ProfileService extends ChangeNotifier {
  final AuthService _authService;
  
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;
  String? _lastValidationError;
  FlutterProfileValidationResult? _lastValidationResult;

  ProfileService(this._authService);

  // Getters
  Map<String, dynamic>? get profileData => _profileData;
  bool get isLoading => _isLoading;
  String? get lastValidationError => _lastValidationError;
  FlutterProfileValidationResult? get lastValidationResult => _lastValidationResult;

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
    _lastValidationError = null;
    _lastValidationResult = null;
    notifyListeners();
  }

  // Flutter Profile Validation Methods

  /// Валидация данных профиля в реальном времени
  Future<FlutterProfileValidationResult?> validateFlutterProfile({
    required String? userName,
    required int? heightCm,
    required double? weightKg,
    required int? age,
    required String? activityLevel,
    required String? gender,
    required int? dailyStepGoal,
  }) async {
    _isLoading = true;
    _lastValidationError = null;
    notifyListeners();

    try {
      final profileData = FlutterProfileUpdateRequest(
        userName: userName,
        heightCm: heightCm,
        weightKg: weightKg,
        age: age,
        activityLevel: activityLevel,
        gender: gender,
        dailyStepGoal: dailyStepGoal,
      );

      _lastValidationResult = await _authService.validateProfileData(profileData);
      
      _isLoading = false;
      notifyListeners();
      
      return _lastValidationResult;
    } catch (e) {
      _lastValidationError = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Обновление профиля через Flutter endpoint с валидацией
  Future<bool> updateFlutterProfile({
    required String? userName,
    required int? heightCm,
    required double? weightKg,
    required int? age,
    required String? activityLevel,
    required String? gender,
    required int? dailyStepGoal,
  }) async {
    _isLoading = true;
    _lastValidationError = null;
    notifyListeners();

    try {
      // Сначала валидируем
      final validation = await validateFlutterProfile(
        userName: userName,
        heightCm: heightCm,
        weightKg: weightKg,
        age: age,
        activityLevel: activityLevel,
        gender: gender,
        dailyStepGoal: dailyStepGoal,
      );

      if (validation == null || !validation.valid) {
        _lastValidationError = 'Validation failed: ${validation?.errors?.toString() ?? 'Unknown error'}';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Если валидация прошла - обновляем
      final profileData = FlutterProfileUpdateRequest(
        userName: userName,
        heightCm: heightCm,
        weightKg: weightKg,
        age: age,
        activityLevel: activityLevel,
        gender: gender,
        dailyStepGoal: dailyStepGoal,
      );

      await _authService.updateProfileFromFlutter(profileData);
      
      // Перезагружаем профиль
      await loadProfile();
      
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      if (e is ValidationException) {
        _lastValidationError = 'Validation error: ${e.errors?.toString() ?? e.message}';
      } else {
        _lastValidationError = 'Update failed: $e';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Проверка конкретного поля на валидность
  Future<String?> validateField(String fieldName, dynamic value) async {
    try {
      // Создаем минимальный объект для валидации конкретного поля
      Map<String, dynamic> testData = {};
      testData[fieldName] = value;

      final response = await _authService.authenticatedRequest(
        method: 'POST',
        path: '/api/profile/flutter/validate',
        body: testData,
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        final validation = FlutterProfileValidationResult.fromJson(
          jsonDecode(response.body)
        );

        if (validation.errors != null && validation.errors!.containsKey(fieldName)) {
          return validation.errors![fieldName];
        }

        return null; // Поле валидно
      } else {
        return 'Server error during validation';
      }
    } catch (e) {
      return 'Validation error: $e';
    }
  }

  /// Очистка ошибок валидации
  void clearValidationErrors() {
    _lastValidationError = null;
    _lastValidationResult = null;
    notifyListeners();
  }

  /// BMI калькулятор для UI
  double? calculateBMI(int? heightCm, double? weightKg) {
    if (heightCm == null || weightKg == null || heightCm <= 0 || weightKg <= 0) {
      return null;
    }
    
    double heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Недостаточный вес';
    if (bmi < 25.0) return 'Нормальный вес';
    if (bmi < 30.0) return 'Избыточный вес';
    return 'Ожирение';
  }

  /// Получение рекомендаций по целям шагов
  String getStepGoalRecommendation(String? activityLevel, int? age) {
    if (activityLevel == null || age == null) return 'Рекомендуется 10000 шагов в день';

    switch (activityLevel.toUpperCase()) {
      case 'LOW':
        return age > 65 ? '6000-8000 шагов в день' : '8000-10000 шагов в день';
      case 'MODERATE':
        return age > 65 ? '8000-10000 шагов в день' : '10000-12000 шагов в день';
      case 'HIGH':
        return age > 65 ? '10000-12000 шагов в день' : '12000-15000 шагов в день';
      default:
        return 'Рекомендуется 10000 шагов в день';
    }
  }
}