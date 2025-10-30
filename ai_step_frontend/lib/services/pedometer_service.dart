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
  DateTime? _lastRecordedDate; // Для отслеживания смены дня
  
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
        // НЕ загружаем данные с сервера автоматически
        // Загрузка будет только при явном вызове loadFromServer()
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
        // НЕ загружаем данные с сервера автоматически
        return;
      }

      debugPrint('PedometerService: Permissions granted, starting monitoring...');
      await _startMonitoring();
      _startSyncTimer();
      // НЕ загружаем данные с сервера автоматически
      // Загрузка будет только при явном вызове loadFromServer()
      debugPrint('PedometerService: Initialization completed successfully');
    } catch (e, stackTrace) {
      debugPrint('PedometerService initialization failed: $e');
      debugPrint('$stackTrace');
      _error = e.toString();
      _startSimulation();
      _startSyncTimer();
      // НЕ загружаем данные с сервера автоматически
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
    // НЕ сбрасываем _steps и производные метрики, чтобы сохранить прогресс
    // Только очищаем вспомогательные данные для фильтрации
    _isWalking = false;
    _accelerationHistory.clear();
    _lastStepTime = null;

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

    // Проверяем смену дня
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastRecordedDate != null) {
      final lastDay = DateTime(_lastRecordedDate!.year, _lastRecordedDate!.month, _lastRecordedDate!.day);
      if (!today.isAtSameMomentAs(lastDay)) {
        // Новый день - сбрасываем счетчики
        debugPrint('New day detected, resetting step counter');
        _steps = 0;
        _lastSyncedSteps = 0;
        _baselineSteps = event.steps;
        _updateDerivedMetrics();
        if (!_isDisposed) notifyListeners();
      }
    }
    _lastRecordedDate = now;

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
    // Используем максимум между вычисленным значением и текущим, чтобы не терять прогресс
    if (_shouldCountSteps(computed)) {
      // Если computed меньше текущего _steps (например, после загрузки с сервера),
      // сохраняем большее значение
      final newSteps = computed > _steps ? computed : _steps;
      
      // Обновляем только если значение изменилось
      if (newSteps != _steps) {
        _steps = newSteps;
        _updateDerivedMetrics();
        if (!_isDisposed) notifyListeners();
      }
      
      // Если computed больше или равен _steps, обновляем baseline для корректного подсчета
      // Это важно после загрузки данных с сервера
      if (computed >= _steps && _steps > 0) {
        // Корректируем baseline так, чтобы computed соответствовал текущему _steps
        _baselineSteps = event.steps - _steps;
        debugPrint('Adjusted baseline to ${_baselineSteps} for current steps: $_steps');
      }
    }
  }

  bool _shouldCountSteps(int newStepCount) {
    final now = DateTime.now();
    
    // Ограничиваем частоту обновлений (не чаще чем раз в 200ms)
    if (_lastStepTime != null) {
      final timeSinceLastUpdate = now.difference(_lastStepTime!).inMilliseconds;
      if (timeSinceLastUpdate < _minStepInterval) {
        return false;
      }
    }
    
    // Если шаги изменились, считаем их
    // На симуляторе всегда считаем, на реальном устройстве - если есть изменения
    if (_isSimulating || newStepCount > 0) {
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
    // Синхронизация каждую минуту для снижения нагрузки на сервер
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _syncStepsToServer();
    });
  }

  Future<void> _syncStepsToServer() async {
    if (_stepsService == null || _steps <= 0) return;
    
    try {
      // Отправляем текущее общее количество шагов за день
      // Бэкенд будет суммировать все записи, поэтому отправляем только если есть изменения
      if (_steps > _lastSyncedSteps) {
        final newSteps = _steps - _lastSyncedSteps;
        final success = await _stepsService.submitSteps(
          stepCount: newSteps,
          recordedAt: DateTime.now(),
          distanceM: newSteps * _strideLengthInMeters,
          caloriesBurned: newSteps * _caloriesPerStep,
        );
        
        if (success) {
          _lastSyncedSteps = _steps;
          debugPrint('✓ Synced $newSteps steps to server (total: $_steps)');
          
          // Не загружаем данные с сервера сразу после каждой синхронизации
          // Это может вызвать конфликты и сброс счетчика
          // Данные обновятся при следующем pull-to-refresh или при запуске
        } else {
          debugPrint('✗ Failed to sync steps to server');
        }
      }
    } catch (e) {
      debugPrint('Error syncing steps to server: $e');
    }
  }

  /// Загрузить данные с сервера и синхронизировать с локальным счетчиком
  /// Вызывается только при входе в приложение или при явном обновлении пользователем
  Future<void> loadFromServer() async {
    if (_stepsService == null) {
      debugPrint('⚠ StepsService is null, cannot load from server');
      return;
    }
    
    try {
      debugPrint('📡 Loading steps from server...');
      debugPrint('  Current local steps before load: $_steps');
      
      final serverSteps = _stepsService.serverSteps;
      debugPrint('  Server steps (from cache): $serverSteps');
      
      // Используем максимум между текущим значением и значением с сервера
      // Это важно, потому что симуляция или реальный счетчик могли уже добавить шаги
      // после запуска приложения, но до загрузки с сервера
      final previousSteps = _steps;
      
      // ВАЖНО: При загрузке с сервера ВСЕГДА используем значение с сервера
      // если это первая загрузка (previousSteps == 0)
      if (previousSteps == 0 && serverSteps >= 0) {
        _steps = serverSteps;
        _lastSyncedSteps = serverSteps;
        debugPrint('  ✓ First load from server: $_steps');
      } else if (serverSteps > _steps) {
        _steps = serverSteps;
        _lastSyncedSteps = serverSteps;
        debugPrint('  ✓ Updated from server: $previousSteps → $_steps');
      } else if (_steps > 0) {
        debugPrint('  ℹ Keeping local value: $_steps (server has $serverSteps)');
      } else {
        // Оба значения 0 - это нормально для нового дня
        _lastSyncedSteps = 0;
        debugPrint('  ℹ Both local and server are 0 (new day)');
      }
      
      _lastRecordedDate = DateTime.now();
      _updateDerivedMetrics();
      
      debugPrint('📊 Current state after sync:');
      debugPrint('  Steps: $_steps');
      debugPrint('  Distance: ${_distanceKm.toStringAsFixed(2)} km');
      debugPrint('  Calories: ${_calories.toStringAsFixed(1)} kcal');
      debugPrint('  Last synced: $_lastSyncedSteps');
      
      // Важно: НЕ сбрасываем _baselineSteps, чтобы продолжить корректный подсчет
      // Baseline будет установлен при следующем событии от педометра
      
      if (!_isDisposed) {
        notifyListeners();
        debugPrint('✅ UI notified of changes');
      } else {
        debugPrint('⚠ Service disposed, skipping notifyListeners');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading steps from server: $e');
      debugPrint('Stack trace: $stackTrace');
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
