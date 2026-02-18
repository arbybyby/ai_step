class User {
  final int id;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final int? age;
  final double? height;
  final double? weight;
  final Gender? gender;
  final ActivityLevel? activityLevel;
  final FitnessGoal? goal;
  final bool? isVerified;
  final DateTime? createdAt;
  final double calorieGoal;
  final double proteinGoal;
  final double waterGoal;
  final int stepsGoal;
  final String? avatarPath;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.activityLevel,
    this.goal,
    this.isVerified,
    this.createdAt,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.waterGoal,
    required this.stepsGoal,
    this.avatarPath,
  });

  /// Calculate BMI from height and weight
  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    return weight! / ((height! / 100) * (height! / 100));
  }

  /// Calculate TDEE (Total Daily Energy Expenditure)
  /// Using simplified formula: BMR * activity multiplier
  /// This is a basic calculation and should be refined with backend
  double? get estimatedTDEE {
    if (weight == null || height == null || age == null) return null;
    
    // Simple BMR calculation (Mifflin-St Jeor)
    double bmr;
    if (gender == Gender.male) {
      bmr = 10 * weight! + 6.25 * height! - 5 * age! + 5;
    } else {
      bmr = 10 * weight! + 6.25 * height! - 5 * age! - 161;
    }

    // Activity multiplier
    double multiplier = 1.2; // Default sedentary
    if (activityLevel != null) {
      multiplier = _getActivityMultiplier(activityLevel!);
    }

    return bmr * multiplier;
  }

  double _getActivityMultiplier(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }

  /// Create a copy of this user with some fields replaced
  User copyWith({
    int? id,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    int? age,
    double? height,
    double? weight,
    Gender? gender,
    ActivityLevel? activityLevel,
    FitnessGoal? goal,
    bool? isVerified,
    DateTime? createdAt,
    double? calorieGoal,
    double? proteinGoal,
    double? waterGoal,
    int? stepsGoal,
    String? avatarPath,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['ID'] ?? json['userId'];
    final emailValue = json['email'] ?? json['Email'];
    final firstNameValue = json['firstName'] ?? json['FirstName'];
    final lastNameValue = json['lastName'] ?? json['LastName'];
    final displayNameValue = json['displayName'] as String? ??
        _buildDisplayName(firstNameValue?.toString(), lastNameValue?.toString());
    final createdAtRaw = json['createdAt'] ?? json['CreatedAt'];
    return User(
      id: idValue is int ? idValue : int.tryParse(idValue?.toString() ?? '') ?? 0,
      email: emailValue?.toString() ?? '',
      displayName: displayNameValue,
      firstName: firstNameValue?.toString(),
      lastName: lastNameValue?.toString(),
      age: json['age'] as int?,
      height: (json['height'] as num?)?.toDouble() ??
          (json['heightCm'] as num?)?.toDouble() ??
          (json['HeightCm'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble() ??
          (json['weightKg'] as num?)?.toDouble() ??
          (json['WeightKg'] as num?)?.toDouble(),
      gender: _parseGender(json['gender']),
      activityLevel: _parseActivityLevel(json['activityLevel']),
      goal: _parseFitnessGoal(json['fitnessGoal'] ?? json['goal']),
      isVerified: (json['isVerified'] ?? json['IsVerified']) as bool?,
      createdAt: createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw.toString())
          : null,
      calorieGoal: (json['calorieGoal'] as num?)?.toDouble() ?? 2000,
      proteinGoal: (json['proteinGoal'] as num?)?.toDouble() ?? 150,
      waterGoal: (json['waterGoal'] as num?)?.toDouble() ?? 2.0,
      stepsGoal: json['stepsGoal'] as int? ?? 10000,
      avatarPath: json['avatarPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender?.name,
      'activityLevel': activityLevel?.name,
      'goal': goal?.name,
      'isVerified': isVerified,
      'createdAt': createdAt?.toIso8601String(),
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'waterGoal': waterGoal,
      'stepsGoal': stepsGoal,
      'avatarPath': avatarPath,
    };
  }

  static Gender? _parseGender(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      return value < Gender.values.length ? Gender.values[value] : Gender.none;
    }
    return Gender.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => Gender.none,
    );
  }

  static ActivityLevel? _parseActivityLevel(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      return value < ActivityLevel.values.length
          ? ActivityLevel.values[value]
          : ActivityLevel.sedentary;
    }
    return ActivityLevel.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => ActivityLevel.sedentary,
    );
  }

  static FitnessGoal? _parseFitnessGoal(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      return value < FitnessGoal.values.length
          ? FitnessGoal.values[value]
          : FitnessGoal.maintainWeight;
    }
    return FitnessGoal.values.firstWhere(
      (e) => e.name == value.toString(),
      orElse: () => FitnessGoal.maintainWeight,
    );
  }

  static String? _buildDisplayName(String? first, String? last) {
    final safeFirst = (first ?? '').trim();
    final safeLast = (last ?? '').trim();
    if (safeFirst.isEmpty && safeLast.isEmpty) return null;
    if (safeLast.isEmpty) return safeFirst;
    if (safeFirst.isEmpty) return safeLast;
    return '$safeFirst $safeLast';
  }
}

enum Gender {
  none,
  male,
  female,
  other,
}

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive,
}

enum FitnessGoal {
  loseWeight,
  maintainWeight,
  gainMuscle,
}
