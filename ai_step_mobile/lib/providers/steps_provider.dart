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
      final apiData = await _apiService.getCurrentDaySteps();
      final localData = await _storageService.getCurrentDaySteps();

      if (localData != null && localData.stepsCount > apiData.stepsCount) {
        // local has more steps -> try to push to backend, but don't overwrite local
        try {
          await _apiService.saveSteps(localData.stepsCount);
          await _storageService.setLastSyncTime(DateTime.now());
          await _storageService.clearSyncQueue();
        } catch (e) {
          // queue for later if push fails
          await _storageService.addToSyncQueue(localData.stepsCount);
        }
        state = AsyncValue.data(localData);
      } else {
        // backend has equal or more steps -> update local storage and state
        await _storageService.saveCurrentDaySteps(apiData);
        state = AsyncValue.data(apiData);
      }
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
    print('CurrentDayStepsNotifier.syncSteps: Attempting to sync $steps steps to backend');
    try {
      await _apiService.saveSteps(steps);
      await _storageService.setLastSyncTime(DateTime.now());
      print('CurrentDayStepsNotifier.syncSteps: Successfully synced $steps steps');
    } catch (e) {
      print('CurrentDayStepsNotifier.syncSteps: Failed to sync steps: $e');
      await _storageService.addToSyncQueue(steps);
      print('CurrentDayStepsNotifier.syncSteps: Added $steps steps to sync queue');
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
