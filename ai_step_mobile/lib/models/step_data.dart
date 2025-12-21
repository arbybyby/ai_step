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
