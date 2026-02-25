class StepData {
  final int userId;
  final String date;
  final int stepsCount;

  StepData({
    required this.userId,
    required this.date,
    required this.stepsCount,
  });

  factory StepData.fromJson(Map<String, dynamic> json) {
    // Handle both userId and userID (backend sends userID with capital ID)
    final uid = json['userId'] ?? json['userID'] ?? json['id'];
    return StepData(
      userId: uid is int ? uid : int.parse(uid.toString()),
      date: json['date'] as String,
      stepsCount: json['stepsCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'date': date,
      'stepsCount': stepsCount,
    };
  }

  StepData copyWith({
    int? userId,
    String? date,
    int? stepsCount,
  }) {
    return StepData(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      stepsCount: stepsCount ?? this.stepsCount,
    );
  }
}

class DayStepsInfo {
  final int id;
  final int userId;
  final String date;
  final int stepsCount;
  final double distanceKm;

  DayStepsInfo({
    required this.id,
    required this.userId,
    required this.date,
    required this.stepsCount,
    required this.distanceKm,
  });

  factory DayStepsInfo.fromJson(Map<String, dynamic> json) {
    // Handle both userId and userID (backend sends userID with capital ID)
    final uid = json['userId'] ?? json['userID'];
    return DayStepsInfo(
      id: json['id'] as int? ?? 0,
      userId: uid is int ? uid : int.parse(uid.toString()),
      date: json['date'] as String,
      stepsCount: json['stepsCount'] as int,
      distanceKm: (json['distanceKM'] ?? json['distanceKm'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userID': userId,
      'date': date,
      'stepsCount': stepsCount,
      'distanceKM': distanceKm,
    };
  }

  DayStepsInfo copyWith({
    int? id,
    int? userId,
    String? date,
    int? stepsCount,
    double? distanceKm,
  }) {
    return DayStepsInfo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      stepsCount: stepsCount ?? this.stepsCount,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

class WeekStepsInfo {
  final int userId;
  final DayStepsInfo? bestDay;
  final List<DayStepsInfo> dayStepsInfo;
  final int totalSteps;

  WeekStepsInfo({
    required this.userId,
    this.bestDay,
    required this.dayStepsInfo,
    required this.totalSteps,
  });

  factory WeekStepsInfo.fromJson(Map<String, dynamic> json) {
    // Parse nested objects first
    final bestDay = json['bestDay'] != null 
        ? DayStepsInfo.fromJson(json['bestDay']) 
        : null;
    final dayStepsInfo = (json['dayStepsInfo'] as List<dynamic>?)
            ?.map((e) => DayStepsInfo.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];
    
    // Handle both userId and userID (backend may not send userID at top level)
    // Try to get from top level first, then from bestDay or first day in list
    int userId = 0;
    final uid = json['userId'] ?? json['userID'];
    if (uid != null && uid != 0) {
      userId = uid is int ? uid : int.parse(uid.toString());
    } else if (bestDay != null) {
      userId = bestDay.userId;
    } else if (dayStepsInfo.isNotEmpty) {
      userId = dayStepsInfo.first.userId;
    }
    
    return WeekStepsInfo(
      userId: userId,
      bestDay: bestDay,
      dayStepsInfo: dayStepsInfo,
      totalSteps: json['totalSteps'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userId,
      'bestDay': bestDay?.toJson(),
      'dayStepsInfo': dayStepsInfo.map((e) => e.toJson()).toList(),
      'totalSteps': totalSteps,
    };
  }

  WeekStepsInfo copyWith({
    int? userId,
    DayStepsInfo? bestDay,
    List<DayStepsInfo>? dayStepsInfo,
    int? totalSteps,
  }) {
    return WeekStepsInfo(
      userId: userId ?? this.userId,
      bestDay: bestDay ?? this.bestDay,
      dayStepsInfo: dayStepsInfo ?? this.dayStepsInfo,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }
}
