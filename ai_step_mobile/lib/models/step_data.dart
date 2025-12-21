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
    return StepData(
      userId: json['userId'] as int,
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
