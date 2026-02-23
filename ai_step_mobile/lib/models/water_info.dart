class WaterInfo {
  final int id;
  final int userId;
  final int waterDrank; // ml

  WaterInfo({required this.id, required this.userId, required this.waterDrank});

  factory WaterInfo.fromJson(Map<String, dynamic> json) {
    return WaterInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['userID'] is int ? json['userID'] : int.tryParse(json['userID']?.toString() ?? '0') ?? 0,
      waterDrank: json['waterDrank'] is int ? json['waterDrank'] : int.tryParse(json['waterDrank']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userID': userId,
        'waterDrank': waterDrank,
      };
}
