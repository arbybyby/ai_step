import 'dart:async';
import 'dart:io';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class StepCounterService {
  late StreamSubscription? _stepCountSubscription;
  int _lastStepCount = 0;
  Timer? _pollingTimer;
  final Health _health = Health();
  bool _isInitialized = false;

  Future<void> init(Function(int) onStepCountChanged) async {
    // First, request Android activity recognition permission
    if (Platform.isAndroid) {
      final activityStatus = await Permission.activityRecognition.request();
      print('Activity recognition permission: $activityStatus');
      
      if (!activityStatus.isGranted) {
        print('Activity recognition permission not granted');
        // Continue anyway, Health Connect might still work
      }
    }
    
    // Configure the health plugin
    await _health.configure();
    
    // Define step types to request
    final types = [HealthDataType.STEPS];
    
    // Request permissions - on Android this requires Health Connect
    try {
      // Check if Health Connect is available (Android 14+) or installed
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        print('Health Connect SDK status: $status');
        
        if (status == HealthConnectSdkStatus.sdkUnavailable) {
          print('Health Connect SDK is not available on this device');
          // You need to install Health Connect from Play Store
        }
        
        // Install Health Connect if needed
        if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
          print('Health Connect needs to be updated');
          await _health.installHealthConnect();
          return;
        }
      }
      
      // Request authorization with read permissions
      final hasPermissions = await _health.hasPermissions(types);
      print('Has health permissions: $hasPermissions');
      
      if (hasPermissions != true) {
        final authorized = await _health.requestAuthorization(
          types,
          permissions: [HealthDataAccess.READ],
        );
        print('Health authorization result: $authorized');
        
        if (!authorized) {
          print('Health permissions not granted');
          return;
        }
      }
      
      _isInitialized = true;
      print('StepCounterService initialized successfully');
    } catch (e, stackTrace) {
      print('Permission request error: $e');
      print('Stack trace: $stackTrace');
    }

    // Poll for step data every 10 seconds
    _pollingTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      await _updateStepCount(onStepCountChanged);
    });

    // Initial fetch
    await _updateStepCount(onStepCountChanged);
  }

  Future<void> _updateStepCount(Function(int) onStepCountChanged) async {
    if (!_isInitialized) {
      print('StepCounterService not initialized, skipping update');
      return;
    }
    
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      print('Fetching steps from $startOfDay to $now');
      
      // Use getTotalStepsInInterval for a simpler approach
      final totalSteps = await _health.getTotalStepsInInterval(startOfDay, now);
      
      print('Total steps fetched: $totalSteps');

      if (totalSteps != null && totalSteps != _lastStepCount) {
        _lastStepCount = totalSteps;
        onStepCountChanged(totalSteps);
        print('Step count updated: $totalSteps');
      } else if (totalSteps == null) {
        print('No step data available. Make sure Health Connect is connected and has step data.');
        
        // Try alternative method: fetch health data points directly
        try {
          final healthData = await _health.getHealthDataFromTypes(
            types: [HealthDataType.STEPS],
            startTime: startOfDay,
            endTime: now,
          );
          
          print('Health data points found: ${healthData.length}');
          
          if (healthData.isNotEmpty) {
            // Sum all step data
            int steps = 0;
            for (var point in healthData) {
              if (point.value is NumericHealthValue) {
                steps += (point.value as NumericHealthValue).numericValue.toInt();
              }
            }
            print('Calculated steps from health data: $steps');
            if (steps > 0 && steps != _lastStepCount) {
              _lastStepCount = steps;
              onStepCountChanged(steps);
            }
          }
        } catch (e) {
          print('Alternative step fetch error: $e');
        }
      }
    } catch (e, stackTrace) {
      print('Step count error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _stepCountSubscription?.cancel();
  }

  int getLastStepCount() {
    return _lastStepCount;
  }
}
