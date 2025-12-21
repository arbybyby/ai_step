import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';

class StepCounterService {
  StreamSubscription<StepCount>? _stepCountSubscription;
  int _lastStepCount = 0;
  bool _isInitialized = false;

  // Sensor baseline holds the sensor cumulative value that corresponds to 0 steps for today
  int? _sensorBaseline;

  Future<void> init(Function(int) onStepCountChanged, {int initialSteps = 0}) async {
    // Use last known steps (from storage/backend) so sensor baseline
    // is computed relative to that value instead of resetting to 0.
    _lastStepCount = initialSteps;
    // Request permissions for activity recognition on Android
    if (Platform.isAndroid) {
      final activityStatus = await Permission.activityRecognition.request();
      print('Activity recognition permission: $activityStatus');
      if (!activityStatus.isGranted) {
        print('Activity recognition permission not granted');
      }
    }

    // Try to subscribe to the device pedometer sensor first
    try {
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        (StepCount event) async {
          await _handleSensorStep(event, onStepCountChanged);
        },
        onError: (error) {
          print('Pedometer stream error: $error');
        },
        cancelOnError: false,
      );

      _isInitialized = true;
      print('StepCounterService: using device pedometer sensor');
    } catch (e) {
      print('Failed to initialize pedometer: $e');
      _isInitialized = false;
    }

    // No Health/Health Connect integration needed — app counts steps itself via sensor
  }

  Future<void> _handleSensorStep(StepCount event, Function(int) onStepCountChanged) async {
    final sensorSteps = event.steps;

    if (_sensorBaseline == null) {
      // Compute baseline using last known step count — no Health integration
      _sensorBaseline = sensorSteps - _lastStepCount;
      print('Computed sensor baseline (no health): $_sensorBaseline');
    }

    final calculated = (_sensorBaseline != null) ? sensorSteps - _sensorBaseline! : sensorSteps;

    if (calculated != _lastStepCount) {
      _lastStepCount = calculated;
      onStepCountChanged(calculated);
      print('Sensor step update: $calculated');
    }
  }


  void dispose() {
    _stepCountSubscription?.cancel();
  }

  int getLastStepCount() {
    return _lastStepCount;
  }
}
