import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../models/step_data.dart';

class StepsApiService {
  String get baseUrl {
    const fallback = 'https://192.168.43.31:8081';
    try {
      if (dotenv.isInitialized) {
        final v = dotenv.env['API_BASE_URL'];
        if (v != null && v.isNotEmpty) return v;
      }
    } catch (e) {
      print('StepsApiService.baseUrl: dotenv access failed: $e');
    }
    return fallback;
  }
  final http.Client httpClient;

  StepsApiService({http.Client? httpClient})
      : httpClient = httpClient ?? _createInsecureClient();

  static http.Client _createInsecureClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // Try common keys
    final candidates = [
      prefs.getString('user_id'),
      prefs.getString('userId'),
      prefs.getString('id'),
    ];
    for (final c in candidates) {
      if (c != null && c.isNotEmpty) return c;
    }

    // If not present, try to fetch profile and persist user id
    try {
      final me = await AuthService.getMe();
      final uid = me['userId']?.toString() ?? me['id']?.toString();
      if (uid != null) {
        await prefs.setString('user_id', uid);
        return uid;
      }
    } catch (e) {
      // ignore - will return null below
      print('StepsApiService._getUserId: could not fetch profile: $e');
    }

    return null;
  }

  Future<StepData> getCurrentDaySteps() async {
    print('\n=== StepsApiService.getCurrentDaySteps START ===');
    final userId = await _getUserId();
    if (userId == null) {
      print('StepsApiService.getCurrentDaySteps: ERROR - User ID not found!');
      throw Exception('User ID not found');
    }

    final token = await _getToken();
    print('StepsApiService.getCurrentDaySteps: userId=$userId, tokenLength=${token.length}, tokenPresent=${token.isNotEmpty}');
    
    if (token.isEmpty) {
      print('StepsApiService.getCurrentDaySteps: ERROR - Token is empty!');
      throw Exception('No authentication token found');
    }

    print('StepsApiService.getCurrentDaySteps: Making GET request to $baseUrl/api/steps/current-day');
    
    http.Response response;
    try {
      response = await httpClient.get(
        Uri.parse('$baseUrl/api/steps/current-day'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      // If TLS handshake fails, retry once with an explicitly insecure client
      print('StepsApiService.getCurrentDaySteps: request failed: $e');
      try {
        final insecure = _createInsecureClient();
        response = await insecure.get(
          Uri.parse('$baseUrl/api/steps/current-day'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));
      } catch (e2) {
        print('StepsApiService.getCurrentDaySteps: retry failed: $e2');
        rethrow;
      }
    }

    if (response.statusCode == 200) {
      print('StepsApiService.getCurrentDaySteps: SUCCESS - status=200, body=${response.body}');
      final data = StepData.fromJson(jsonDecode(response.body));
      print('=== StepsApiService.getCurrentDaySteps END ===\n');
      return data;
    } else if (response.statusCode == 401) {
      print('StepsApiService.getCurrentDaySteps: ERROR 401 Unauthorized - body: ${response.body}');
      print('=== StepsApiService.getCurrentDaySteps END ===\n');
      throw Exception('Unauthorized');
    } else {
      print('StepsApiService.getCurrentDaySteps: ERROR status=${response.statusCode} body=${response.body}');
      print('=== StepsApiService.getCurrentDaySteps END ===\n');
      throw Exception('Failed to fetch steps: ${response.statusCode}');
    }
  }

  Future<void> saveSteps(int steps) async {
    print('=== StepsApiService.saveSteps CALLED with steps=$steps ===');
    
    final token = await _getToken();
    print('StepsApiService.saveSteps: Retrieved token, length=${token.length}, isEmpty=${token.isEmpty}');
    
    final uid = await _getUserId();
    print('StepsApiService.saveSteps: Retrieved userId=$uid');
    
    if (token.isEmpty) {
      print('StepsApiService.saveSteps: ERROR - Token is empty! Cannot make authenticated request.');
      throw Exception('No authentication token found');
    }
    
    if (uid == null) {
      print('StepsApiService.saveSteps: ERROR - User ID is null! Cannot make request.');
      throw Exception('User ID not found');
    }
    
    final maskedToken = token.length > 10 ? '${token.substring(0, 6)}....${token.substring(token.length - 4)}' : token;
    print('StepsApiService.saveSteps: Making POST request to $baseUrl/api/steps?steps=$steps');
    print('StepsApiService.saveSteps: Token=$maskedToken, UserId=$uid');

    http.Response response;
    try {
      print('StepsApiService.saveSteps: Attempting HTTP POST...');
      response = await httpClient.post(
        Uri.parse('$baseUrl/api/steps?steps=$steps'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      print('StepsApiService.saveSteps: HTTP POST completed with status=${response.statusCode}');
    } catch (e) {
      print('StepsApiService.saveSteps: initial request failed: $e');
      try {
        final insecure = _createInsecureClient();
        response = await insecure.post(
          Uri.parse('$baseUrl/api/steps?steps=$steps'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));
      } catch (e2) {
        print('StepsApiService.saveSteps: retry failed: $e2');
        rethrow;
      }
    }

    if (response.statusCode == 200) {
      print('StepsApiService.saveSteps: success body=${response.body}');
      return;
    } else if (response.statusCode == 401) {
      print('StepsApiService.saveSteps: 401 response body: ${response.body}');
      // Try to fetch profile to help diagnose token validity
      try {
        final me = await AuthService.getMe();
        print('StepsApiService.saveSteps: getMe after 401 returned: $me');
      } catch (e) {
        print('StepsApiService.saveSteps: getMe after 401 failed: $e');
      }
      throw Exception('Unauthorized');
    } else {
      print('StepsApiService.saveSteps: failed status=${response.statusCode} body=${response.body}');
      throw Exception('Failed to save steps: ${response.statusCode}');
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // support different token key names (try many common variants)
    final token = prefs.getString('auth_token') ?? prefs.getString('accessToken') ?? prefs.getString('access_token') ?? prefs.getString('token') ?? prefs.getString('access') ?? '';
    print('StepsApiService._getToken: Retrieved token (length=${token.length}, isEmpty=${token.isEmpty})');
    if (token.isEmpty) {
      print('StepsApiService._getToken: WARNING - No token found in SharedPreferences!');
      print('StepsApiService._getToken: Checked keys: auth_token, accessToken, access_token, token, access');
    }
    return token;
  }
}
