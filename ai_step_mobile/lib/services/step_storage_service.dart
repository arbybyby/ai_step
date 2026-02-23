import 'package:hive_flutter/hive_flutter.dart';
import '../models/step_data.dart';

class StepStorageService {
  static const String _boxName = 'steps_box';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(_boxName);
  }

  Box<dynamic> _getBox() {
    return Hive.box<dynamic>(_boxName);
  }

  Future<StepData?> getCurrentDaySteps() async {
    final box = _getBox();
    final data = box.get('current_day');
    if (data == null) return null;
    return StepData.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> saveCurrentDaySteps(StepData stepData) async {
    final box = _getBox();
    await box.put('current_day', stepData.toJson());
  }

  Future<void> addToSyncQueue(int steps) async {
    final box = _getBox();
    final queue = (box.get('sync_queue') as List<dynamic>?)?.cast<int>() ?? [];
    queue.add(steps);
    await box.put('sync_queue', queue as List<dynamic>);
  }

  Future<List<int>> getSyncQueue() async {
    final box = _getBox();
    final queue = (box.get('sync_queue') as List<dynamic>?)?.cast<int>() ?? [];
    return queue;
  }

  Future<void> clearSyncQueue() async {
    final box = _getBox();
    await box.delete('sync_queue');
  }

  Future<int> getGoal() async {
    final box = _getBox();
    final goal = box.get('goal');
    if (goal == null) return 400;
    if (goal is int) return goal;
    if (goal is String) {
      return int.tryParse(goal) ?? 400;
    }
    return 400;
  }

  Future<void> setGoal(int goal) async {
    final box = _getBox();
    await box.put('goal', goal);
  }

  Future<DateTime?> getLastSyncTime() async {
    final box = _getBox();
    final timestamp = box.get('last_sync_time');
    if (timestamp == null) return null;
    try {
      return DateTime.parse(timestamp.toString());
    } catch (e) {
      return null;
    }
  }

  Future<void> setLastSyncTime(DateTime time) async {
    final box = _getBox();
    await box.put('last_sync_time', time.toIso8601String());
  }

  Future<void> clear() async {
    final box = _getBox();
    await box.clear();
  }
}
