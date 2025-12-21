import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/step_data.dart';
import '../services/step_storage_service.dart';
import '../services/steps_api_service.dart';
import '../services/notification_service.dart';

final stepStorageProvider = Provider((ref) {
  return StepStorageService();
});

final stepsApiProvider = Provider((ref) {
  return StepsApiService();
});

final notificationProvider = Provider((ref) {
  return NotificationService();
});

final currentDayStepsProvider =
    StateNotifierProvider<CurrentDayStepsNotifier, AsyncValue<StepData?>>((ref) {
  final storageService = ref.watch(stepStorageProvider);
  final apiService = ref.watch(stepsApiProvider);
  return CurrentDayStepsNotifier(storageService, apiService);
});

class CurrentDayStepsNotifier extends StateNotifier<AsyncValue<StepData?>> {
  final StepStorageService _storageService;
  final StepsApiService _apiService;

  CurrentDayStepsNotifier(
      this._storageService, this._apiService)
      : super(const AsyncValue.loading());

  Future<void> fetchCurrentDaySteps() async {
    state = const AsyncValue.loading();
    try {
      final data = await _apiService.getCurrentDaySteps();
      await _storageService.saveCurrentDaySteps(data);
      state = AsyncValue.data(data);
    } catch (e, st) {
      // Try to get from cache on error
      final cached = await _storageService.getCurrentDaySteps();
      if (cached != null) {
        state = AsyncValue.data(cached);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> updateSteps(int steps) async {
    final currentState = state;
    if (currentState is AsyncData && currentState.value != null) {
      final updated = currentState.value!.copyWith(stepsCount: steps);
      await _storageService.saveCurrentDaySteps(updated);
      state = AsyncValue.data(updated);
    }
  }

  Future<void> syncSteps(int steps) async {
    try {
      await _apiService.saveSteps(steps);
      await _storageService.setLastSyncTime(DateTime.now());
    } catch (e) {
      print('Failed to sync steps: $e');
      await _storageService.addToSyncQueue(steps);
      rethrow;
    }
  }
}

final goalProvider = FutureProvider<int>((ref) async {
  final storageService = ref.watch(stepStorageProvider);
  return await storageService.getGoal();
});

final lastSyncTimeProvider = FutureProvider<DateTime?>((ref) async {
  final storageService = ref.watch(stepStorageProvider);
  return await storageService.getLastSyncTime();
});
