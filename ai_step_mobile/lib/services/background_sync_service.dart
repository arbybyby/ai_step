import 'package:workmanager/workmanager.dart';
import 'step_storage_service.dart';
import 'steps_api_service.dart';
import 'notification_service.dart';

const String syncTaskName = 'steps_sync_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == syncTaskName) {
        await _performSync();
      }
      return true;
    } catch (e) {
      print('Background sync error: $e');
      return false;
    }
  });
}

Future<void> _performSync() async {
  final storageService = StepStorageService();
  await storageService.init();

  final apiService = StepsApiService();

  try {
    // Get current step data
    final currentData = await storageService.getCurrentDaySteps();

    if (currentData != null) {
      // Try to sync with backend
      await apiService.saveSteps(currentData.stepsCount);

      // Update last sync time
      await storageService.setLastSyncTime(DateTime.now());

      // Clear sync queue if successful
      await storageService.clearSyncQueue();
    }
  } catch (e) {
    print('Failed to sync steps: $e');
    // Keep data in sync queue for retry
    final currentData = await storageService.getCurrentDaySteps();
    if (currentData != null) {
      await storageService.addToSyncQueue(currentData.stepsCount);
    }
  }
}

class BackgroundSyncService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> startPeriodicSync() async {
    // Sync every 1 minute
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  static Future<void> stopPeriodicSync() async {
    await Workmanager().cancelByUniqueName(syncTaskName);
  }

  static Future<void> syncNow() async {
    await _performSync();
  }
}
