import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class StepsService extends ChangeNotifier {
  final AuthService _authService;
  
  // Данные о шагах с сервера
  int _serverSteps = 0;
  double _serverDistanceM = 0.0;
  double _serverCalories = 0.0;
  DateTime? _lastServerUpdate;
  
  int get serverSteps => _serverSteps;
  double get serverDistanceM => _serverDistanceM;
  double get serverCalories => _serverCalories;
  DateTime? get lastServerUpdate => _lastServerUpdate;
  
  StepsService(this._authService);

  /// Отправить данные о шагах на сервер
  Future<bool> submitSteps({
    required int stepCount,
    required DateTime recordedAt,
    double? distanceM,
    double? caloriesBurned,
    String? deviceId,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        print('User not authenticated, cannot submit steps');
        print('Token: ${_authService.token != null ? "exists" : "null"}');
        print('User: ${_authService.user != null ? "exists" : "null"}');
        return false;
      }

      // Проверяем валидность токена
      if (!_authService.isTokenValid) {
        print('Token is expired or invalid, cannot submit steps');
        return false;
      }

      print('Submitting steps - authenticated user: ${_authService.user?.email}');
      print('Token available: ${_authService.token != null}');
      print('Token valid: ${_authService.isTokenValid}');

      final requestBody = {
        'step_count': stepCount,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
        if (distanceM != null) 'distance_m': distanceM,
        if (caloriesBurned != null) 'calories_burned': caloriesBurned,
        if (deviceId != null) 'device_id': deviceId,
      };
      
      print('Request body: $requestBody');

      final response = await _authService.authenticatedRequest(
        method: 'POST',
        path: '/api/steps',
        body: requestBody,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        print('Steps submitted successfully');
        return true;
      } else if (response.statusCode == 401) {
        print('Unauthorized - token may be expired');
        // Попробуем обновить токен или заставить пользователя войти снова
        return false;
      } else {
        try {
          final errorData = jsonDecode(response.body);
          print('Failed to submit steps: ${errorData['error'] ?? errorData['message'] ?? 'Unknown error'}');
        } catch (e) {
          print('Failed to submit steps: HTTP ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      print('Error submitting steps: $e');
      return false;
    }
  }

  /// Проверить соединение с сервером
  Future<bool> checkHealth() async {
    try {
      if (!_authService.isAuthenticated) {
        print('User not authenticated, cannot check health');
        return false;
      }

      final response = await _authService.authenticatedRequest(
        method: 'GET',
        path: '/api/steps/health',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Health check successful: ${data['status']}');
        return data['status'] == 'ok';
      } else {
        print('Health check failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error checking health: $e');
      return false;
    }
  }

  /// Получить данные о шагах за определенный день
  Future<Map<String, dynamic>?> getDailySteps({DateTime? date, bool forceUpdate = false}) async {
    try {
      if (!_authService.isAuthenticated) {
        print('User not authenticated, cannot get daily steps');
        return null;
      }

      final dateStr = date != null 
          ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
          : null;

      String path = '/api/steps/daily';
      if (dateStr != null) {
        path += '?date=$dateStr';
      }

      final response = await _authService.authenticatedRequest(
        method: 'GET',
        path: path,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('===== Daily steps response =====');
        print('Full response: $data');
        print('Has data field: ${data.containsKey('data')}');
        print('Data value: ${data['data']}');
        print('Data type: ${data['data'].runtimeType}');
        
        // Обновляем локальное состояние данными с сервера
        if (data['data'] != null) {
          final serverData = data['data'];
          print('Server data keys: ${serverData.keys}');
          print('Raw server data: $serverData');
          
          // Безопасный парсинг - обрабатываем разные типы данных
          final rawSteps = serverData['total_steps'];
          final rawDistance = serverData['total_distance_m'];
          final rawCalories = serverData['total_calories'];
          
          print('Raw values:');
          print('  total_steps: $rawSteps (type: ${rawSteps.runtimeType})');
          print('  total_distance_m: $rawDistance (type: ${rawDistance.runtimeType})');
          print('  total_calories: $rawCalories (type: ${rawCalories.runtimeType})');
          
          int newServerSteps = 0;
          if (rawSteps != null) {
            if (rawSteps is int) {
              newServerSteps = rawSteps;
            } else if (rawSteps is double) {
              newServerSteps = rawSteps.toInt();
            } else {
              newServerSteps = int.tryParse(rawSteps.toString()) ?? 0;
            }
          }
          
          double newServerDistanceM = 0.0;
          if (rawDistance != null) {
            if (rawDistance is double) {
              newServerDistanceM = rawDistance;
            } else if (rawDistance is int) {
              newServerDistanceM = rawDistance.toDouble();
            } else {
              newServerDistanceM = double.tryParse(rawDistance.toString()) ?? 0.0;
            }
          }
          
          double newServerCalories = 0.0;
          if (rawCalories != null) {
            if (rawCalories is double) {
              newServerCalories = rawCalories;
            } else if (rawCalories is int) {
              newServerCalories = rawCalories.toDouble();
            } else {
              newServerCalories = double.tryParse(rawCalories.toString()) ?? 0.0;
            }
          }
          
          print('Parsed server data:');
          print('  Steps: $newServerSteps (type: ${newServerSteps.runtimeType})');
          print('  Distance: $newServerDistanceM m (type: ${newServerDistanceM.runtimeType})');
          print('  Calories: $newServerCalories (type: ${newServerCalories.runtimeType})');
          print('  Current server steps: $_serverSteps');
          print('  Force update: $forceUpdate');
          
          // При первой загрузке (forceUpdate) всегда обновляем
          // При обычной загрузке - только если данные больше или равны
          if (forceUpdate || newServerSteps >= _serverSteps) {
            _serverSteps = newServerSteps;
            _serverDistanceM = newServerDistanceM;
            _serverCalories = newServerCalories;
            _lastServerUpdate = DateTime.now();
            
            print('✓ Updated server steps: $_serverSteps, distance: $_serverDistanceM, calories: $_serverCalories');
            notifyListeners();
          } else {
            print('⚠ Server has fewer steps ($_serverSteps -> $newServerSteps), keeping current value');
          }
        } else {
          print('⚠ No data from server yet (data field is null)');
          // При первой загрузке обновляем в любом случае, показывая 0
          if (forceUpdate) {
            _serverSteps = 0;
            _serverDistanceM = 0.0;
            _serverCalories = 0.0;
            _lastServerUpdate = DateTime.now();
            print('✓ Force update: set server steps to 0');
            notifyListeners();
          }
        }
        print('================================');
        
        return data;
      } else if (response.statusCode == 401) {
        print('Authentication failed, logging out user');
        await _authService.logout();
        return null;
      } else {
        print('Failed to get daily steps: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting daily steps: $e');
      return null;
    }
  }

  /// Получить историю шагов за диапазон дат
  Future<Map<String, dynamic>?> getStepsHistory({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        print('User not authenticated, cannot get steps history');
        return null;
      }

      String path = '/api/steps/history';
      List<String> params = [];
      
      if (from != null) {
        final fromStr = '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
        params.add('from=$fromStr');
      }
      
      if (to != null) {
        final toStr = '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';
        params.add('to=$toStr');
      }
      
      if (params.isNotEmpty) {
        path += '?${params.join('&')}';
      }

      final response = await _authService.authenticatedRequest(
        method: 'GET',
        path: path,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        print('Authentication failed, logging out user');
        await _authService.logout();
        return null;
      } else {
        print('Failed to get steps history: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting steps history: $e');
      return null;
    }
  }

  /// Получить weekly progress (статистику за неделю)
  Future<Map<String, dynamic>?> getWeeklyProgress() async {
    try {
      if (!_authService.isAuthenticated) {
        print('User not authenticated, cannot get weekly progress');
        return null;
      }

      final response = await _authService.authenticatedRequest(
        method: 'GET',
        path: '/api/weekly-progress/current',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('===== Weekly progress response =====');
        print('Full response: $data');
        print('================================');
        return data;
      } else if (response.statusCode == 401) {
        print('Authentication failed, logging out user');
        await _authService.logout();
        return null;
      } else {
        print('Failed to get weekly progress: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting weekly progress: $e');
      return null;
    }
  }

  /// Получить статистику за последние N недель
  Future<List<Map<String, dynamic>>?> getLastNWeeks(int weeks) async {
    try {
      if (!_authService.isAuthenticated) {
        print('User not authenticated, cannot get last N weeks');
        return null;
      }

      final response = await _authService.authenticatedRequest(
        method: 'GET',
        path: '/api/weekly-progress/last?weeks=$weeks',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('===== Last $weeks weeks response =====');
        print('Data: $data');
        print('================================');
        
        if (data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return null;
      } else if (response.statusCode == 401) {
        print('Authentication failed, logging out user');
        await _authService.logout();
        return null;
      } else {
        print('Failed to get last N weeks: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting last N weeks: $e');
      return null;
    }
  }
}