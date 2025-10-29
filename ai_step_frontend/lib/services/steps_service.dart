import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class StepsService extends ChangeNotifier {
  final AuthService _authService;
  
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
        return false;
      }

      final response = await _authService.authenticatedRequest(
        method: 'POST',
        path: '/api/steps',
        body: {
          'step_count': stepCount,
          'recorded_at': recordedAt.toUtc().toIso8601String(),
          if (distanceM != null) 'distance_m': distanceM,
          if (caloriesBurned != null) 'calories_burned': caloriesBurned,
          if (deviceId != null) 'device_id': deviceId,
        },
      );

      if (response.statusCode == 201) {
        print('Steps submitted successfully');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Failed to submit steps: ${errorData['error'] ?? 'Unknown error'}');
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
  Future<Map<String, dynamic>?> getDailySteps({DateTime? date}) async {
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
}