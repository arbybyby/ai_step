import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/meal.dart';

class MealsService {
  String get baseUrl {
    const fallback = 'https://192.168.1.213:8081';
    try {
      if (dotenv.isInitialized) {
        final v = dotenv.env['API_BASE_URL'];
        if (v != null && v.isNotEmpty) return v;
      }
    } catch (e) {
      print('MealsService.baseUrl: dotenv access failed: $e');
    }
    return fallback;
  }

  final http.Client httpClient;

  MealsService({http.Client? httpClient})
      : httpClient = httpClient ?? _createInsecureClient();

  static http.Client _createInsecureClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  Future<String?> _getAccessToken() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('accessToken');
      print('MealsService._getAccessToken: Token retrieved - ${token != null ? 'Present' : 'Missing'}${token != null ? ' (length: ${token.length})' : ''}');
      return token;
    } catch (e) {
      print('MealsService._getAccessToken: Could not read access token: $e');
      return null;
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = _getHeaders();
    final token = await _getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('MealsService._getAuthHeaders: Authorization header added');
    } else {
      print('MealsService._getAuthHeaders: No token available - request will fail');
    }
    return headers;
  }

  Future<List<Meal>> getAllMeals() async {
    try {
      final url = Uri.parse('$baseUrl/all-meals');
      print('\n=== MealsService.getAllMeals START ===');
      print('MealsService.getAllMeals: BaseURL: $baseUrl');
      print('MealsService.getAllMeals: Full URL: $url');

      final headers = await _getAuthHeaders();
      print('MealsService.getAllMeals: Headers: $headers');
      
      print('MealsService.getAllMeals: Making GET request...');
      final response = await httpClient.get(url, headers: headers);

      print('MealsService.getAllMeals: Response received - Status: ${response.statusCode}');
      print('MealsService.getAllMeals: Response headers: ${response.headers}');
      print('MealsService.getAllMeals: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('MealsService.getAllMeals: Success (200)');
        final List<dynamic> jsonList = jsonDecode(response.body);
        final meals = jsonList.map((json) => Meal.fromJson(json)).toList();
        print('MealsService.getAllMeals: Parsed ${meals.length} meals');
        print('=== MealsService.getAllMeals END ===\n');
        return meals;
      } else {
        print('MealsService.getAllMeals: Error ${response.statusCode}');
        print('=== MealsService.getAllMeals END ===\n');
        throw Exception('Failed to fetch meals: ${response.statusCode}');
      }
    } catch (e) {
      print('MealsService.getAllMeals: Exception - $e');
      print('=== MealsService.getAllMeals END ===\n');
      rethrow;
    }
  }

  Future<List<Meal>> getMealsByType(MealType type) async {
    // Get all meals and filter locally
    final allMeals = await getAllMeals();
    return allMeals.where((meal) => meal.mealType == type).toList();
  }

  Future<List<Meal>> searchMeals(String query) async {
    final allMeals = await getAllMeals();

    return allMeals
        .where((meal) =>
            meal.mealName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
