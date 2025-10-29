import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'steps_service.dart';

/// Provides step metrics for the home screen and falls back to a lightweight
/// simulator when real pedometer data is unavailable (e.g. on web/desktop).
class PedometerService extends ChangeNotifier {
  PedometerService({
    double strideLengthInMeters = 0.78, // average adult walking stride
    double caloriesPerStep = 0.04, // rough kcal estimate per step
    StepsService? stepsService,
  }) : _strideLengthInMeters = strideLengthInMeters,
       _caloriesPerStep = caloriesPerStep,
       _stepsService = stepsService;

  final double _strideLengthInMeters;
  final double _caloriesPerStep;
  final StepsService? _stepsService;

  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _simulationTimer;
  Timer? _syncTimer;

  int? _baselineSteps;
  int _lastSyncedSteps = 0;
  
  // Упрощенная фильтрация движения
  final List<double> _accelerationHistory = [];
  static const int _historySize = 20; // Уменьшенный размер истории
  DateTime? _lastStepTime;
  bool _isWalking = false;
  
  // Упрощенные пороги
  static const double _movementThreshold = 1.5; // Порог для определения движения
  static const int _minStepInterval = 200; // Минимальный интервал между обновлениями (мс)
  static const double _staticThreshold = 0.5; // Порог для статичного состояния

  int _steps = 0;
  double _distanceKm = 0;
  double _calories = 0;
  int _activeMinutes = 0;

  bool _isInitializing = false;
  bool _permissionGranted = false;
  bool _isSimulating = false;
  bool _isDisposed = false;
  String? _error;

  int get steps => _steps;
  double get distance => _distanceKm;
  double get calories => _calories;
  int get activeMinutes => _activeMinutes;
  bool get hasPermission => _permissionGranted;
  bool get isSimulating => _isSimulating;
  bool get isWalking => _isWalking;
  String? get error => _error;

  /// Entry point called from the widget tree. Safe to call multiple times.
  Future<void> initialize() async {
    if (_isInitializing || _isDisposed) return;
    _isInitializing = true;

    try {
      debugPrint('PedometerService: Starting initialization...');
      
      if (kIsWeb) {
        debugPrint('PedometerService: Running on web, starting simulation');
        _startSimulation();
        _startSyncTimer();
        return;
      }

      debugPrint('PedometerService: Checking permissions...');
      final granted = await _ensurePermission();
      _permissionGranted = granted;
      if (!_isDisposed) notifyListeners();

      if (!granted) {
        debugPrint('PedometerService: Permission denied, falling back to simulation');
        _error = 'Activity recognition permission denied';
        _startSimulation();
        _startSyncTimer();
        return;
      }

      debugPrint('PedometerService: Permissions granted, starting monitoring...');
      await _startMonitoring();
      _startSyncTimer();
      debugPrint('PedometerService: Initialization completed successfully');
    } catch (e, stackTrace) {
      debugPrint('PedometerService initialization failed: $e');
      debugPrint('$stackTrace');
      _error = e.toString();
      _startSimulation();
      _startSyncTimer();
    } finally {
      _isInitializing = false;
    }
  }

  Future<bool> _ensurePermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      // iOS grants permission implicitly for motion coprocessor.
      return true;
    }

    try {
      // Для Android API < 29 разрешение ACTIVITY_RECOGNITION не требуется
      // Pedometer API может работать с базовыми разрешениями
      debugPrint('Checking device API level and permissions...');
      
      // Попробуем запросить разрешение только если оно доступно
      try {
        final activityStatus = await Permission.activityRecognition.status;
        debugPrint('Activity recognition permission status: $activityStatus');

        if (activityStatus.isGranted) {
          return true;
        }
        
        if (activityStatus.isPermanentlyDenied) {
          debugPrint('Activity recognition permission permanently denied, but continuing...');
          return true; // Продолжаем работу без этого разрешения
        }

        // Запрашиваем разрешение на распознавание активности
        debugPrint('Requesting activity recognition permission...');
        final activityResult = await Permission.activityRecognition.request();
        debugPrint('Activity recognition permission result: $activityResult');

        return true; // Продолжаем независимо от результата
      } catch (permissionError) {
        debugPrint('Activity recognition permission not available on this device: $permissionError');
        return true; // На старых версиях Android это разрешение не существует
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      // Если произошла ошибка с разрешениями, попробуем работать без них
      return true;
    }
  }

  Future<void> _startMonitoring() async {
    debugPrint('PedometerService: Starting sensor monitoring...');
    
    await _stepSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _accelerometerSubscription?.cancel();
    _simulationTimer?.cancel();
    _isSimulating = false;

    _baselineSteps = null;
    _resetMetrics();
    _accelerationHistory.clear();

    try {
      // Запускаем мониторинг акселерометра для фильтрации движений
      debugPrint('PedometerService: Starting accelerometer monitoring...');
      _accelerometerSubscription = accelerometerEvents.listen(
        _handleAccelerometerEvent,
        onError: (error) {
          debugPrint('Accelerometer stream error: $error');
        },
      );

      debugPrint('PedometerService: Starting pedometer streams...');
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
      
      debugPrint('PedometerService: All sensor streams started successfully');
    } catch (e) {
      debugPrint('PedometerService: Error starting monitoring: $e');
      throw e;
    }
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    // Вычисляем магнитуду ускорения
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    
    // Добавляем в историю
    _accelerationHistory.add(magnitude);
    if (_accelerationHistory.length > _historySize) {
      _accelerationHistory.removeAt(0);
    }
    
    // Простая проверка на движение
    _updateWalkingState();
  }

  // Упрощенная проверка состояния ходьбы
  void _updateWalkingState() {
    if (_accelerationHistory.length < 10) return;
    
    // Вычисляем стандартное отклонение последних 10 измерений
    final recentData = _accelerationHistory.sublist(_accelerationHistory.length - 10);
    final mean = recentData.reduce((a, b) => a + b) / recentData.length;
    final variance = recentData
        .map((x) => math.pow(x - mean, 2))
        .reduce((a, b) => a + b) / recentData.length;
    final standardDeviation = math.sqrt(variance);
    
    // Простая логика: если есть вариация в ускорении, значит человек движется
    // Исключаем статичное состояние (телефон лежит) и слишком сильные встряски
    final isMoving = standardDeviation > _movementThreshold && standardDeviation < 5.0;
    
    // Проверяем, что среднее значение в разумных пределах (не падение/подбрасывание)
    final reasonableMean = mean > 8.0 && mean < 12.0;
    
    _isWalking = isMoving && reasonableMean;
  }

  void _handleStepCount(StepCount event) {
    _error = null; // clear any previous error once data arrives

    _baselineSteps ??= event.steps;
    final baseline = _baselineSteps!;
    final computed = event.steps - baseline;

    if (computed < 0) {
      // Device counter reset, start over.
      _baselineSteps = event.steps;
      _steps = 0;
      _updateDerivedMetrics();
      if (!_isDisposed) notifyListeners();
      return;
    }

    // Упрощенная логика: считаем шаги если человек движется
    if (_shouldCountSteps(computed)) {
      _steps = computed;
      _updateDerivedMetrics();
      if (!_isDisposed) notifyListeners();
    }
  }

  bool _shouldCountSteps(int newStepCount) {
    final now = DateTime.now();
    
    // Ограничиваем частоту обновлений
    if (_lastStepTime != null) {
      final timeSinceLastUpdate = now.difference(_lastStepTime!).inMilliseconds;
      if (timeSinceLastUpdate < _minStepInterval) {
        return false;
      }
    }
    
    // Считаем шаги только если обнаружено движение
    // На симуляторе/веб всегда считаем шаги
    if (_isSimulating || _isWalking) {
      _lastStepTime = now;
      return true;
    }
    
    return false;
  }

  void _updateDerivedMetrics() {
    _distanceKm = (_steps * _strideLengthInMeters) / 1000.0;
    _calories = _steps * _caloriesPerStep;
    _activeMinutes = (_steps / 100).round();
  }

  void _startSimulation() {
    if (_isSimulating) {
      if (!_isDisposed) notifyListeners();
      return;
    }

    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    _accelerometerSubscription?.cancel();

    _isSimulating = true;
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      // Increase by a small periodic batch to mimic real readings.
      _steps += 12;
      _updateDerivedMetrics();
      notifyListeners();
    });
    if (!_isDisposed) notifyListeners();
  }

  void _resetMetrics() {
    _steps = 0;
    _distanceKm = 0;
    _calories = 0;
    _activeMinutes = 0;
    _isWalking = false;
    _accelerationHistory.clear();
    _lastStepTime = null;
  }

  void _startSyncTimer() {
    if (_stepsService == null || _isDisposed) return;
    
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _syncStepsToServer();
    });
  }

  Future<void> _syncStepsToServer() async {
    if (_stepsService == null || _steps <= _lastSyncedSteps) return;
    
    try {
      final newSteps = _steps - _lastSyncedSteps;
      final success = await _stepsService.submitSteps(
        stepCount: newSteps,
        recordedAt: DateTime.now(),
        distanceM: newSteps * _strideLengthInMeters,
        caloriesBurned: newSteps * _caloriesPerStep,
      );
      
      if (success) {
        _lastSyncedSteps = _steps;
        debugPrint('Synced $newSteps steps to server');
      }
    } catch (e) {
      debugPrint('Failed to sync steps to server: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _simulationTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
