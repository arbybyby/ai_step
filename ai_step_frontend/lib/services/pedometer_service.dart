import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

/// Provides step metrics for the home screen and falls back to a lightweight
/// simulator when real pedometer data is unavailable (e.g. on web/desktop).
class PedometerService extends ChangeNotifier {
  PedometerService({
    double strideLengthInMeters = 0.78, // average adult walking stride
    double caloriesPerStep = 0.04, // rough kcal estimate per step
  }) : _strideLengthInMeters = strideLengthInMeters,
       _caloriesPerStep = caloriesPerStep;

  final double _strideLengthInMeters;
  final double _caloriesPerStep;

  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;
  Timer? _simulationTimer;

  int? _baselineSteps;

  int _steps = 0;
  double _distanceKm = 0;
  double _calories = 0;
  int _activeMinutes = 0;

  bool _isInitializing = false;
  bool _permissionGranted = false;
  bool _isSimulating = false;
  String? _error;

  int get steps => _steps;
  double get distance => _distanceKm;
  double get calories => _calories;
  int get activeMinutes => _activeMinutes;
  bool get hasPermission => _permissionGranted;
  bool get isSimulating => _isSimulating;
  String? get error => _error;

  /// Entry point called from the widget tree. Safe to call multiple times.
  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      if (kIsWeb) {
        _startSimulation();
        return;
      }

      final granted = await _ensurePermission();
      _permissionGranted = granted;
      notifyListeners();

      if (!granted) {
        _error = 'Activity recognition permission denied';
        _startSimulation();
        return;
      }

      await _startMonitoring();
    } catch (e, stackTrace) {
      debugPrint('PedometerService initialization failed: $e');
      debugPrint('$stackTrace');
      _error = e.toString();
      _startSimulation();
    } finally {
      _isInitializing = false;
    }
  }

  Future<bool> _ensurePermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      // iOS grants permission implicitly for motion coprocessor.
      return true;
    }

    final activityStatus = await Permission.activityRecognition.status;
    final sensorsStatus = await Permission.sensors.status;

    if (activityStatus.isGranted && sensorsStatus.isGranted) {
      return true;
    }
    if (activityStatus.isPermanentlyDenied || sensorsStatus.isPermanentlyDenied) {
      return false;
    }

    final results = await [
      Permission.activityRecognition,
      Permission.sensors,
    ].request();

    final grantedActivity =
        results[Permission.activityRecognition]?.isGranted ?? false;
    final grantedSensors = results[Permission.sensors]?.isGranted ?? false;

    return grantedActivity && grantedSensors;
  }

  Future<void> _startMonitoring() async {
    await _stepSubscription?.cancel();
    await _statusSubscription?.cancel();
    _simulationTimer?.cancel();
    _isSimulating = false;

    _baselineSteps = null;
    _resetMetrics();

    final stepStream = Pedometer.stepCountStream;
    final statusStream = Pedometer.pedestrianStatusStream;

    _stepSubscription = stepStream.listen(
      _handleStepCount,
      onError: (error, stackTrace) {
        debugPrint('Pedometer step stream error: $error');
        _error = error.toString();
        _startSimulation();
      },
      cancelOnError: false,
    );

    _statusSubscription = statusStream.listen(
      (_) {},
      onError: (error, stackTrace) {
        debugPrint('Pedometer status stream error: $error');
      },
    );
  }

  void _handleStepCount(StepCount event) {
    _error = null; // clear any previous error once data arrives

    _baselineSteps ??= event.steps;
    final baseline = _baselineSteps!;
    final computed = event.steps - baseline;

    if (computed >= 0) {
      _steps = computed;
    } else {
      // Device counter reset, start over.
      _baselineSteps = event.steps;
      _steps = 0;
    }

    _updateDerivedMetrics();
    notifyListeners();
  }

  void _updateDerivedMetrics() {
    _distanceKm = (_steps * _strideLengthInMeters) / 1000.0;
    _calories = _steps * _caloriesPerStep;
    _activeMinutes = (_steps / 100).round();
  }

  void _startSimulation() {
    if (_isSimulating) {
      notifyListeners();
      return;
    }

    _stepSubscription?.cancel();
    _statusSubscription?.cancel();

    _isSimulating = true;
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Increase by a small periodic batch to mimic real readings.
      _steps += 12;
      _updateDerivedMetrics();
      notifyListeners();
    });
    notifyListeners();
  }

  void _resetMetrics() {
    _steps = 0;
    _distanceKm = 0;
    _calories = 0;
    _activeMinutes = 0;
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }
}
