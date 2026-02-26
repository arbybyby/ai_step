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
    print('\n=== CurrentDayStepsNotifier.fetchCurrentDaySteps START ===');
    state = const AsyncValue.loading();
    try {
      print('fetchCurrentDaySteps: Calling _apiService.getCurrentDaySteps()...');
      final apiData = await _apiService.getCurrentDaySteps();
      print('fetchCurrentDaySteps: API returned: userId=${apiData.userId}, date=${apiData.date}, stepsCount=${apiData.stepsCount}');
      
      print('fetchCurrentDaySteps: Getting local data...');
      final localData = await _storageService.getCurrentDaySteps();
      print('fetchCurrentDaySteps: Local data: ${localData?.stepsCount ?? "null"}');

      if (localData != null && localData.stepsCount > apiData.stepsCount) {
        print('fetchCurrentDaySteps: Local has more steps (${localData.stepsCount} > ${apiData.stepsCount}), pushing to backend');
        // local has more steps -> try to push to backend, but don't overwrite local
        try {
          await _apiService.saveSteps(localData.stepsCount);
          await _storageService.setLastSyncTime(DateTime.now());
          await _storageService.clearSyncQueue();
          print('fetchCurrentDaySteps: Pushed local steps to backend successfully');
        } catch (e) {
          print('fetchCurrentDaySteps: Failed to push local steps: $e');
          // queue for later if push fails
          await _storageService.addToSyncQueue(localData.stepsCount);
        }
        state = AsyncValue.data(localData);
      } else {
        print('fetchCurrentDaySteps: Backend has equal or more steps, updating local');
        // backend has equal or more steps -> update local storage and state
        await _storageService.saveCurrentDaySteps(apiData);
        state = AsyncValue.data(apiData);
        print('fetchCurrentDaySteps: State updated with backend data: ${apiData.stepsCount} steps');
      }
    } catch (e, st) {
      print('fetchCurrentDaySteps: ERROR: $e');
      print('fetchCurrentDaySteps: StackTrace: $st');
      // Try to get from cache on error
      final cached = await _storageService.getCurrentDaySteps();
      if (cached != null) {
        print('fetchCurrentDaySteps: Using cached data: ${cached.stepsCount} steps');
        state = AsyncValue.data(cached);
      } else {
        print('fetchCurrentDaySteps: No cached data, setting error state');
        state = AsyncValue.error(e, st);
      }
    }
    print('=== CurrentDayStepsNotifier.fetchCurrentDaySteps END ===\n');
  }

  Future<void> updateSteps(int steps) async {
    print('CurrentDayStepsNotifier.updateSteps: Updating to $steps steps');
    final currentState = state;
    if (currentState is AsyncData && currentState.value != null) {
      final updated = currentState.value!.copyWith(stepsCount: steps);
      await _storageService.saveCurrentDaySteps(updated);
      state = AsyncValue.data(updated);
      print('CurrentDayStepsNotifier.updateSteps: State updated and saved locally');
    } else {
      print('CurrentDayStepsNotifier.updateSteps: Current state is not AsyncData or value is null');
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

final weeklyStepsProvider =
    StateNotifierProvider<WeeklyStepsNotifier, AsyncValue<WeekStepsInfo?>>((ref) {
  final apiService = ref.watch(stepsApiProvider);
  return WeeklyStepsNotifier(apiService);
});

class WeeklyStepsNotifier extends StateNotifier<AsyncValue<WeekStepsInfo?>> {
  final StepsApiService _apiService;

  WeeklyStepsNotifier(this._apiService) : super(const AsyncValue.loading());

  Future<void> fetchWeeklySteps() async {
    print('\n=== WeeklyStepsNotifier.fetchWeeklySteps START ===');
    state = const AsyncValue.loading();
    try {
      print('fetchWeeklySteps: Calling _apiService.getCurrentWeekSteps()...');
      final weekData = await _apiService.getCurrentWeekSteps();
      print('fetchWeeklySteps: API returned: userId=${weekData.userId}, totalSteps=${weekData.totalSteps}, days=${weekData.dayStepsInfo.length}');
      state = AsyncValue.data(weekData);
      print('fetchWeeklySteps: State updated with weekly data');
    } catch (e, st) {
      print('fetchWeeklySteps: ERROR: $e');
      print('fetchWeeklySteps: StackTrace: $st');
      state = AsyncValue.error(e, st);
    }
    print('=== WeeklyStepsNotifier.fetchWeeklySteps END ===\n');
  }

  /// Silently refreshes weekly data from the API without triggering a loading
  /// state, so the UI doesn't flash a spinner on each poll.
  Future<void> silentRefreshWeeklySteps() async {
    print('WeeklyStepsNotifier.silentRefreshWeeklySteps: polling...');
    try {
      final weekData = await _apiService.getCurrentWeekSteps();
      state = AsyncValue.data(weekData);
      print('WeeklyStepsNotifier.silentRefreshWeeklySteps: updated, totalSteps=${weekData.totalSteps}');
    } catch (e) {
      print('WeeklyStepsNotifier.silentRefreshWeeklySteps: ERROR (keeping old state): $e');
    }
  }

  /// Updates today's step count in the local weekly state without hitting the API.
  void updateTodaySteps(int steps) {
    final current = state;
    if (current is! AsyncData || current.value == null) return;
    final weekData = current.value!;

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final updatedDays = weekData.dayStepsInfo.map((day) {
      final dayStr = day.date.length >= 10 ? day.date.substring(0, 10) : day.date;
      if (dayStr == todayStr) {
        return day.copyWith(stepsCount: steps);
      }
      return day;
    }).toList();

    // If today wasn't in the list yet, don't add it — wait for the next full fetch.
    if (!updatedDays.any((d) {
      final dayStr = d.date.length >= 10 ? d.date.substring(0, 10) : d.date;
      return dayStr == todayStr;
    })) return;

    final newTotal = updatedDays.fold<int>(0, (sum, d) => sum + d.stepsCount);

    // Recalculate best day
    DayStepsInfo? newBestDay = weekData.bestDay;
    if (updatedDays.isNotEmpty) {
      newBestDay = updatedDays.reduce(
        (a, b) => a.stepsCount >= b.stepsCount ? a : b,
      );
    }

    state = AsyncValue.data(weekData.copyWith(
      dayStepsInfo: updatedDays,
      totalSteps: newTotal,
      bestDay: newBestDay,
    ));
  }
}
