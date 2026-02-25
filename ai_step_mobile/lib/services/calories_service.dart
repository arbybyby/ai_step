import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';

class CaloriesService {
  String get baseUrl => AppConfig.baseUrl;

  final http.Client httpClient;

  CaloriesService({http.Client? httpClient})
      : httpClient = httpClient ?? _createInsecureClient();

  static http.Client _createInsecureClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  /// Fetches calories burned today from GET /api/calories/burned/today.
  /// Returns the [caloriesBurned] value, or null on error.
  Future<double?> getCaloriesBurnedToday() async {
    final token = await _getToken();
    if (token.isEmpty) {
      print('CaloriesService: token is empty, skipping request');
      return null;
    }

    try {
      final response = await httpClient
          .get(
            Uri.parse('$baseUrl/api/calories/burned/today'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = json['caloriesBurned'];
        if (raw != null) {
          return (raw as num).toDouble();
        }
      } else {
        print(
            'CaloriesService: unexpected status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('CaloriesService.getCaloriesBurnedToday: error: $e');
    }
    return null;
  }

  /// Fetches distance walked today from GET /api/steps/distance/today.
  /// Returns the [distanceKM] value, or null on error.
  Future<double?> getDistanceToday() async {
    final token = await _getToken();
    if (token.isEmpty) {
      print('CaloriesService: token is empty, skipping distance request');
      return null;
    }

    try {
      final response = await httpClient
          .get(
            Uri.parse('$baseUrl/api/steps/distance/today'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = json['distanceKM'];
        if (raw != null) {
          return (raw as num).toDouble();
        }
      } else {
        print(
            'CaloriesService.getDistanceToday: unexpected status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('CaloriesService.getDistanceToday: error: $e');
    }
    return null;
  }
}
