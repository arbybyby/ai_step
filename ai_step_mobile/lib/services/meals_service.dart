import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/meal.dart';
import '../models/user_meal.dart';
import '../config/config.dart';
import 'auth_service.dart';

class MealsServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? details;

  MealsServiceException(this.message, {this.statusCode, this.details});

  @override
  String toString() {
    if (statusCode != null) {
      return 'MealsServiceException: $message (Status: $statusCode)${details != null ? '\nDetails: $details' : ''}';
    }
    return 'MealsServiceException: $message${details != null ? '\nDetails: $details' : ''}';
  }

  String get userFriendlyMessage {
    if (statusCode == 401) {
      return 'Authentication failed. Please log in again.';
    } else if (statusCode == 403) {
      return 'Access denied. You don\'t have permission to perform this action.';
    } else if (statusCode == 404) {
      return 'Resource not found. Please check your connection.';
    } else if (statusCode == 400) {
      return 'Invalid data. Please check your input.\n${details ?? ''}';
    } else if (statusCode != null && statusCode! >= 500) {
      return 'Server error. Please try again later.';
    } else if (message.contains('SocketException') ||
        message.contains('Connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (message.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    return message;
  }
}

class MealsService {
  String get baseUrl => AppConfig.baseUrl;

  final http.Client httpClient;

  MealsService({http.Client? httpClient})
    : httpClient = httpClient ?? _createInsecureClient();

  static http.Client _createInsecureClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  Future<String?> _getAccessToken() async {
    try {
      // Use AuthService to get token with automatic refresh if needed
      final token = await AuthService.getAccessTokenWithRefresh();
      print(
        'MealsService._getAccessToken: Token retrieved - ${token.isNotEmpty ? 'Present' : 'Missing'}${token.isNotEmpty ? ' (length: ${token.length})' : ''}',
      );
      return token.isNotEmpty ? token : null;
    } catch (e) {
      print('MealsService._getAccessToken: Could not read access token: $e');
      return null;
    }
  }

  Future<int?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try multiple possible keys
      final candidates = [
        prefs.getString('user_id'),
        prefs.getString('userId'),
        prefs.getString('id'),
      ];

      final userIdStr = candidates.firstWhere(
        (id) => id != null && id.isNotEmpty,
        orElse: () => null,
      );

      if (userIdStr != null) {
        return int.tryParse(userIdStr);
      }

      print('MealsService._getUserId: No userId found in SharedPreferences');
      return null;
    } catch (e) {
      print('MealsService._getUserId: Error retrieving userId: $e');
      return null;
    }
  }

  Map<String, String> _getHeaders() {
    return {'Content-Type': 'application/json'};
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = _getHeaders();
    final token = await _getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('MealsService._getAuthHeaders: Authorization header added');
    } else {
      print(
        'MealsService._getAuthHeaders: No token available - request will fail',
      );
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

      print(
        'MealsService.getAllMeals: Response received - Status: ${response.statusCode}',
      );
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
        throw MealsServiceException(
          'Failed to fetch meals',
          statusCode: response.statusCode,
          details: response.body,
        );
      }
    } on MealsServiceException {
      rethrow;
    } catch (e) {
      print('MealsService.getAllMeals: Exception - $e');
      print('=== MealsService.getAllMeals END ===\n');
      throw MealsServiceException(
        'Network error while fetching meals',
        details: e.toString(),
      );
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
        .where(
          (meal) => meal.mealName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  /// Get all meals tracked by the current user
  ///
  /// GET /api/meals
  ///
  /// Returns a list of user-specific meal entries with tracking information
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   final mealsService = MealsService();
  ///   final userMeals = await mealsService.getUserMeals();
  ///   print('User has ${userMeals.length} meal entries');
  /// } on MealsServiceException catch (e) {
  ///   print('Error: ${e.userFriendlyMessage}');
  /// }
  /// ```
  Future<List<UserMeal>> getUserMeals() async {
    try {
      final url = Uri.parse('$baseUrl/api/meals');
      print('\n=== MealsService.getUserMeals START ===');
      print('MealsService.getUserMeals: BaseURL: $baseUrl');
      print('MealsService.getUserMeals: Full URL: $url');

      final headers = await _getAuthHeaders();
      print('MealsService.getUserMeals: Headers: $headers');

      print('MealsService.getUserMeals: Making GET request...');
      final response = await httpClient.get(url, headers: headers);

      print(
        'MealsService.getUserMeals: Response received - Status: ${response.statusCode}',
      );
      print('MealsService.getUserMeals: Response headers: ${response.headers}');
      print('MealsService.getUserMeals: Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('MealsService.getUserMeals: Success (200)');
        final List<dynamic> jsonList = jsonDecode(response.body);
        final userMeals = jsonList
            .map((json) => UserMeal.fromJson(json))
            .toList();
        print(
          'MealsService.getUserMeals: Parsed ${userMeals.length} user meals',
        );
        print('=== MealsService.getUserMeals END ===\n');
        return userMeals;
      } else if (response.statusCode == 401) {
        print('MealsService.getUserMeals: Unauthorized (401)');
        print('=== MealsService.getUserMeals END ===\n');
        throw MealsServiceException(
          'Authentication required',
          statusCode: response.statusCode,
          details: 'Please log in to view your meals',
        );
      } else {
        print('MealsService.getUserMeals: Error ${response.statusCode}');
        print('=== MealsService.getUserMeals END ===\n');
        throw MealsServiceException(
          'Failed to fetch user meals',
          statusCode: response.statusCode,
          details: response.body,
        );
      }
    } on MealsServiceException {
      rethrow;
    } catch (e) {
      print('MealsService.getUserMeals: Exception - $e');
      print('=== MealsService.getUserMeals END ===\n');
      throw MealsServiceException(
        'Network error while fetching user meals',
        details: e.toString(),
      );
    }
  }

  /// Add a new meal to the database
  ///
  /// POST /api/meals/add
  ///
  /// Automatically retrieves userID from SharedPreferences.
  /// MealType is sent as capitalized string (e.g., "Breakfast", "Lunch", "Dinner", "Snacks")
  ///
  /// Request format:
  /// ```json
  /// {
  ///   "userID": 1,
  ///   "mealName": "Куриная грудка с рисом",
  ///   "mealType": "Lunch",
  ///   "grammes": 350.0,
  ///   "calories": 450.0,
  ///   "protein": 45.0,
  ///   "carbs": 48.0,
  ///   "fat": 8.5
  /// }
  /// ```
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   final mealsService = MealsService();
  ///   final newMeal = await mealsService.addMeal(
  ///     mealName: 'Куриная грудка с рисом',
  ///     mealType: MealType.lunch,
  ///     grammes: 350.0,
  ///     calories: 450.0,
  ///     protein: 45.0,
  ///     carbs: 48.0,
  ///     fat: 8.5,
  ///   );
  ///   print('Created meal: ${newMeal.mealName}');
  /// } on MealsServiceException catch (e) {
  ///   // Show user-friendly error message
  ///   showDialog(
  ///     context: context,
  ///     builder: (context) => AlertDialog(
  ///       title: Text('Error'),
  ///       content: Text(e.userFriendlyMessage),
  ///       actions: [
  ///         TextButton(
  ///           onPressed: () => Navigator.pop(context),
  ///           child: Text('OK'),
  ///         ),
  ///       ],
  ///     ),
  ///   );
  /// } catch (e) {
  ///   print('Unexpected error: $e');
  /// }
  /// ```
  Future<Meal> addMeal({
    required String mealName,
    required MealType mealType,
    required double grammes,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    try {
      // Get userId from SharedPreferences
      final userId = await _getUserId();
      if (userId == null) {
        throw MealsServiceException(
          'User ID not found',
          details: 'Please log in again to continue',
        );
      }

      final url = Uri.parse('http://10.197.22.175:8082/meals/add');
      print('\n=== MealsService.addMeal START ===');
      print('MealsService.addMeal: BaseURL: $baseUrl');
      print('MealsService.addMeal: Full URL: $url');
      print('MealsService.addMeal: UserID: $userId');

      final headers = _getHeaders();
      print('MealsService.addMeal: Headers: $headers');

      // Convert MealType enum to capitalized string format (e.g., "Breakfast", "Lunch")
      final mealTypeString = mealType.toString().split('.').last;
      final mealTypeCapitalized =
          mealTypeString[0].toUpperCase() +
          mealTypeString.substring(1).toLowerCase();

      final body = jsonEncode({
        'userID': userId,
        'mealName': mealName,
        'mealType': mealTypeCapitalized,
        'grammes': grammes,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      });

      print('MealsService.addMeal: Request body: $body');
      print('MealsService.addMeal: Making POST request...');

      final response = await httpClient.post(url, headers: headers, body: body);

      print(
        'MealsService.addMeal: Response received - Status: ${response.statusCode}',
      );
      print('MealsService.addMeal: Response headers: ${response.headers}');
      print('MealsService.addMeal: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('MealsService.addMeal: Success (${response.statusCode})');
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final meal = Meal.fromJson(jsonResponse);
        print('MealsService.addMeal: Created meal with id: ${meal.id}');
        print('=== MealsService.addMeal END ===\n');
        return meal;
      } else {
        print('MealsService.addMeal: Error ${response.statusCode}');
        print('=== MealsService.addMeal END ===\n');
        String errorDetails = response.body;
        try {
          final errorJson = jsonDecode(response.body);
          errorDetails =
              errorJson['message'] ?? errorJson['error'] ?? response.body;
        } catch (_) {
          // If response is not JSON, use the raw body
        }
        throw MealsServiceException(
          'Failed to add meal',
          statusCode: response.statusCode,
          details: errorDetails,
        );
      }
    } on MealsServiceException {
      rethrow;
    } catch (e) {
      print('MealsService.addMeal: Exception - $e');
      print('=== MealsService.addMeal END ===\n');
      throw MealsServiceException(
        'Network error while adding meal',
        details: e.toString(),
      );
    }
  }

  /// Track a meal that the user has consumed
  ///
  /// POST /api/meals/track (or appropriate endpoint for meal tracking)
  ///
  /// This method records that the user ate a specific meal
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   final mealsService = MealsService();
  ///   await mealsService.trackMeal(
  ///     mealId: meal.id,
  ///     mealType: MealType.lunch,
  ///     grammes: 250.0,
  ///   );
  /// } on MealsServiceException catch (e) {
  ///   ErrorHandler.showError(context, e);
  /// }
  /// ```
  Future<void> trackMeal({
    required int mealId,
    required MealType mealType,
    required double grammes,
  }) async {
    try {
      // Get userId from SharedPreferences
      final userId = await _getUserId();
      if (userId == null) {
        throw MealsServiceException(
          'User ID not found',
          details: 'Please log in again to continue',
        );
      }

      final url = Uri.parse('http://10.197.22.175:8082/meals/add');
      print('\n=== MealsService.trackMeal START ===');
      print('MealsService.trackMeal: BaseURL: $baseUrl');
      print('MealsService.trackMeal: Full URL: $url');
      print('MealsService.trackMeal: UserID: $userId, MealID: $mealId');

      final headers = _getHeaders();
      print('MealsService.trackMeal: Headers: $headers');

      final mealTypeString = mealType.toString().split('.').last;
      final mealTypeCapitalized =
          mealTypeString[0].toUpperCase() +
          mealTypeString.substring(1).toLowerCase();

      final body = jsonEncode({
        'userID': userId,
        'mealID': mealId,
        'mealType': mealTypeCapitalized,
        'grammes': grammes,
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('MealsService.trackMeal: Request body: $body');
      print('MealsService.trackMeal: Making POST request...');

      final response = await httpClient.post(url, headers: headers, body: body);

      print(
        'MealsService.trackMeal: Response received - Status: ${response.statusCode}',
      );
      print('MealsService.trackMeal: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('MealsService.trackMeal: Success (${response.statusCode})');
        print('=== MealsService.trackMeal END ===\n');
      } else {
        print('MealsService.trackMeal: Error ${response.statusCode}');
        print('=== MealsService.trackMeal END ===\n');
        String errorDetails = response.body;
        try {
          final errorJson = jsonDecode(response.body);
          errorDetails =
              errorJson['message'] ?? errorJson['error'] ?? response.body;
        } catch (_) {
          // If response is not JSON, use the raw body
        }
        throw MealsServiceException(
          'Failed to track meal',
          statusCode: response.statusCode,
          details: errorDetails,
        );
      }
    } on MealsServiceException {
      rethrow;
    } catch (e) {
      print('MealsService.trackMeal: Exception - $e');
      print('=== MealsService.trackMeal END ===\n');
      throw MealsServiceException(
        'Network error while tracking meal',
        details: e.toString(),
      );
    }
  }

  /// Delete a meal entry from the database
  ///
  /// DELETE /api/meals/delete
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   final mealsService = MealsService();
  ///   await mealsService.deleteMeal(
  ///     id: mealEntry.id,
  ///     userId: userId,
  ///   );
  ///   print('Meal deleted successfully');
  /// } on MealsServiceException catch (e) {
  ///   ErrorHandler.showError(context, e);
  /// }
  /// ```
  Future<void> deleteMeal({required int id, required int userId}) async {
    try {
      final url = Uri.parse('http://10.197.22.175:8082/meals/delete');
      print('\n=== MealsService.deleteMeal START ===');
      print('MealsService.deleteMeal: BaseURL: $baseUrl');
      print('MealsService.deleteMeal: Full URL: $url');
      print('MealsService.deleteMeal: ID: $id, UserID: $userId');

      final headers = _getHeaders();
      print('MealsService.deleteMeal: Headers: $headers');

      final body = jsonEncode({'id': id, 'userID': userId});

      print('MealsService.deleteMeal: Request body: $body');
      print('MealsService.deleteMeal: Making DELETE request...');

      final response = await httpClient.delete(
        url,
        headers: headers,
        body: body,
      );

      print(
        'MealsService.deleteMeal: Response received - Status: ${response.statusCode}',
      );
      print('MealsService.deleteMeal: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('MealsService.deleteMeal: Success (${response.statusCode})');
        print('=== MealsService.deleteMeal END ===\n');
      } else {
        print('MealsService.deleteMeal: Error ${response.statusCode}');
        print('=== MealsService.deleteMeal END ===\n');
        String errorDetails = response.body;
        try {
          final errorJson = jsonDecode(response.body);
          errorDetails =
              errorJson['message'] ?? errorJson['error'] ?? response.body;
        } catch (_) {
          // If response is not JSON, use the raw body
        }
        throw MealsServiceException(
          'Failed to delete meal',
          statusCode: response.statusCode,
          details: errorDetails,
        );
      }
    } on MealsServiceException {
      rethrow;
    } catch (e) {
      print('MealsService.deleteMeal: Exception - $e');
      print('=== MealsService.deleteMeal END ===\n');
      throw MealsServiceException(
        'Network error while deleting meal',
        details: e.toString(),
      );
    }
  }
}
