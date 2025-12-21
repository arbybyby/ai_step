import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/step_data.dart';

class StepsApiService {
  final String baseUrl = 'http://192.168.1.124:5051';
  final http.Client httpClient;

  StepsApiService({http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<StepData> getCurrentDaySteps() async {
    final userId = await _getUserId();
    if (userId == null) {
      throw Exception('User ID not found');
    }

    final response = await httpClient.get(
      Uri.parse('$baseUrl/api/steps/current-day'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return StepData.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to fetch steps: ${response.statusCode}');
    }
  }

  Future<void> saveSteps(int steps) async {
    final userId = await _getUserId();
    if (userId == null) {
      throw Exception('User ID not found');
    }

    final response = await httpClient.post(
      Uri.parse('$baseUrl/api/steps?steps=$steps'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await _getToken()}',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to save steps: ${response.statusCode}');
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }
}
