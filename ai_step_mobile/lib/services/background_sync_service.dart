import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'step_storage_service.dart';
import 'steps_api_service.dart';
import '../models/step_data.dart';

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
  StepStorageService? storageService;
  var storageReady = false;
  try {
    storageService = StepStorageService();
    await storageService.init();
    storageReady = true;
  } catch (e) {
    print('BackgroundSyncService: Hive init failed in background isolate: $e');
  }

  final apiService = StepsApiService();

  try {
    // Get current step data (local and remote)
    StepData? localData;
    if (storageReady && storageService != null) {
      localData = await storageService.getCurrentDaySteps();
    } else {
      final sp = await SharedPreferences.getInstance();
      final json = sp.getString('current_day');
      if (json != null) {
        try {
          localData = StepData.fromJson(jsonDecode(json));
        } catch (e) {
          localData = null;
        }
      }
    }

    StepData? remoteData;
    try {
      remoteData = await apiService.getCurrentDaySteps();
    } catch (e) {
      remoteData = null;
    }

    // Merge logic
    if (localData != null && remoteData != null) {
      if (localData.stepsCount > remoteData.stepsCount) {
        await apiService.saveSteps(localData.stepsCount);
        if (storageReady && storageService != null) {
          await storageService.setLastSyncTime(DateTime.now());
          await storageService.clearSyncQueue();
        } else {
          final sp = await SharedPreferences.getInstance();
          await sp.setString('last_sync_time', DateTime.now().toIso8601String());
          await sp.remove('sync_queue');
        }
      } else if (remoteData.stepsCount > localData.stepsCount) {
        if (storageReady && storageService != null) {
          await storageService.saveCurrentDaySteps(remoteData);
          await storageService.setLastSyncTime(DateTime.now());
        } else {
          final sp = await SharedPreferences.getInstance();
          await sp.setString('current_day', jsonEncode(remoteData.toJson()));
          await sp.setString('last_sync_time', DateTime.now().toIso8601String());
        }
      } else {
        if (storageReady && storageService != null) {
          await storageService.setLastSyncTime(DateTime.now());
        } else {
          final sp = await SharedPreferences.getInstance();
          await sp.setString('last_sync_time', DateTime.now().toIso8601String());
        }
      }
    } else if (localData != null && remoteData == null) {
      if (storageReady && storageService != null) {
        await storageService.addToSyncQueue(localData.stepsCount);
      } else {
        final sp = await SharedPreferences.getInstance();
        final queue = sp.getStringList('sync_queue') ?? [];
        queue.add(localData.stepsCount.toString());
        await sp.setStringList('sync_queue', queue);
      }
    } else if (localData == null && remoteData != null) {
      if (storageReady && storageService != null) {
        await storageService.saveCurrentDaySteps(remoteData);
        await storageService.setLastSyncTime(DateTime.now());
      } else {
        final sp = await SharedPreferences.getInstance();
        await sp.setString('current_day', jsonEncode(remoteData.toJson()));
        await sp.setString('last_sync_time', DateTime.now().toIso8601String());
      }
    }

    // Flush queued entries (Hive)
    if (storageReady && storageService != null) {
      final queue = await storageService.getSyncQueue();
      if (queue.isNotEmpty) {
        for (final qSteps in queue) {
          try {
            await apiService.saveSteps(qSteps);
          } catch (e) {
            print('Failed to flush queued steps: $e');
            break;
          }
        }
        await storageService.clearSyncQueue();
      }
    } else {
      // Flush SharedPreferences queue
      try {
        final sp = await SharedPreferences.getInstance();
        final queue = sp.getStringList('sync_queue') ?? [];
        if (queue.isNotEmpty) {
          for (final s in List<String>.from(queue)) {
            try {
              final val = int.tryParse(s);
              if (val != null) await apiService.saveSteps(val);
            } catch (e) {
              print('Failed to flush SharedPreferences queued steps: $e');
              break;
            }
          }
          await sp.remove('sync_queue');
        }
      } catch (e) {
        print('Error flushing SharedPreferences queue: $e');
      }
    }
  } catch (e) {
    print('Failed to sync steps: $e');
    // Keep data in sync queue for retry
    if (storageReady && storageService != null) {
      final currentData = await storageService.getCurrentDaySteps();
      if (currentData != null) {
        await storageService.addToSyncQueue(currentData.stepsCount);
      }
    } else {
      try {
        final sp = await SharedPreferences.getInstance();
        final json = sp.getString('current_day');
        if (json != null) {
          final cd = StepData.fromJson(jsonDecode(json));
          final queue = sp.getStringList('sync_queue') ?? [];
          queue.add(cd.stepsCount.toString());
          await sp.setStringList('sync_queue', queue);
        }
      } catch (e2) {
        print('Failed to add to SharedPreferences sync queue: $e2');
      }
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
    // Schedule periodic sync (minimum allowed by OS is typically 15 minutes).
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: const Duration(minutes: 15),
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
