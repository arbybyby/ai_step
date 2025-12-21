import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Update this to your real API base URL
  static const String baseUrl = 'https://192.168.1.81:5051';

  // Create HTTP client that accepts self-signed certificates
  static http.Client _getHttpClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  static Future<http.Response> register({required String email, required String password, required String firstName, required String lastName}) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final body = jsonEncode({
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });
    print('Sending request to: $uri');
    print('Request body: $body');
    try {
      final client = _getHttpClient();
      final response = await client.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
      print('Response received - Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Request failed: $e');
      rethrow;
    }
  }

  static Future<http.Response> verify({required String email, required String code}) async {
    final uri = Uri.parse('$baseUrl/api/auth/verify');
    final body = jsonEncode({'email': email, 'code': code});
    print('Sending request to: $uri');
    print('Request body: $body');
    try {
      final client = _getHttpClient();
      final response = await client.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
      print('Response received - Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Request failed: $e');
      rethrow;
    }
  }

  static Future<http.Response> resendCode({required String email}) async {
    final uri = Uri.parse('$baseUrl/api/auth/resend-code');
    final body = jsonEncode({'email': email});
    print('Sending request to: $uri');
    print('Request body: $body');
    try {
      final client = _getHttpClient();
      final response = await client.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
      print('Response received - Status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Request failed: $e');
      rethrow;
    }
  }

  static Future<http.Response> login({required String email, required String password}) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final body = jsonEncode({'email': email, 'password': password});
    print('Sending request to: $uri');
    print('Request body: $body');
    try {
      final client = _getHttpClient();
      final response = await client.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
      print('Response received - Status: ${response.statusCode}');
      // If login succeeded, try to extract and persist tokens from response body
      if ((response.statusCode == 200 || response.statusCode == 201) && response.body.isNotEmpty) {
        try {
          final decoded = response.body.startsWith('{') ? jsonDecode(response.body) : null;
          if (decoded != null) {
            await _saveTokensFromBody(decoded);
          }
        } catch (e) {
          print('Failed to parse/save tokens: $e');
        }
      }
      return response;
    } catch (e) {
      print('Request failed: $e');
      rethrow;
    }
  }

  /// Fetch current user profile from `/api/auth/me`.
  /// Returns decoded JSON as a Map (e.g. {"userId": "..", "email": ".."}).
  static Future<Map<String, dynamic>> getMe() async {
    final uri = Uri.parse('$baseUrl/api/auth/me');
    print('Sending request to: $uri');
    try {
      final client = _getHttpClient();
      final token = await _getAccessToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      final response = await client.get(uri, headers: headers);
      print('getMe Response - Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty && response.body.startsWith('{')) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) return decoded;
          return Map<String, dynamic>.from(decoded);
        }
        return {};
      }
      // For non-success, try to decode error body but throw to let callers handle it
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    } catch (e) {
      print('Request failed: $e');
      rethrow;
    }
  }

  // Helper: read stored access token
  static Future<String?> _getAccessToken() async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getString('accessToken');
    } catch (e) {
      print('Could not read access token: $e');
      return null;
    }
  }

  // Helper: attempt to extract known token fields from various response shapes
  static Future<void> _saveTokensFromBody(dynamic decoded) async {
    if (decoded == null) return;
    try {
      Map<String, dynamic>? map;
      if (decoded is Map<String, dynamic>) map = decoded;
      if (map == null) return;

      // Possible locations/keys
      dynamic maybeTokens;
      if (map.containsKey('tokens')) maybeTokens = map['tokens'];
      if (maybeTokens == null) maybeTokens = map;

      String? access;
      String? refresh;
      String? accessExp;
      String? refreshExp;

      // Try different key name variants
      access = maybeTokens['accessToken']?.toString() ?? maybeTokens['AccessToken']?.toString() ?? map['accessToken']?.toString() ?? map['AccessToken']?.toString();
      refresh = maybeTokens['refreshToken']?.toString() ?? maybeTokens['RefreshToken']?.toString() ?? map['refreshToken']?.toString() ?? map['RefreshToken']?.toString();
      accessExp = maybeTokens['accessTokenExpiration']?.toString() ?? maybeTokens['AccessTokenExpiration']?.toString() ?? map['accessTokenExpiration']?.toString() ?? map['AccessTokenExpiration']?.toString();
      refreshExp = maybeTokens['refreshTokenExpiration']?.toString() ?? maybeTokens['RefreshTokenExpiration']?.toString() ?? map['refreshTokenExpiration']?.toString() ?? map['RefreshTokenExpiration']?.toString();

      final sp = await SharedPreferences.getInstance();
      var saved = false;
      if (access != null) {
        print('AuthService._saveTokensFromBody: Saving accessToken (length=${access.length})');
        await sp.setString('accessToken', access);
        saved = true;
        print('AuthService._saveTokensFromBody: accessToken saved successfully');
      } else {
        print('AuthService._saveTokensFromBody: WARNING - No access token found in response');
      }
      if (refresh != null) {
        print('AuthService._saveTokensFromBody: Saving refreshToken (length=${refresh.length})');
        await sp.setString('refreshToken', refresh);
        saved = true;
        print('AuthService._saveTokensFromBody: refreshToken saved successfully');
      }
      if (accessExp != null) {
        await sp.setString('accessTokenExpiration', accessExp);
        saved = true;
      }
      if (refreshExp != null) {
        await sp.setString('refreshTokenExpiration', refreshExp);
        saved = true;
      }
      if (saved) {
        print('AuthService._saveTokensFromBody: Tokens saved to SharedPreferences');
      } else {
        print('AuthService._saveTokensFromBody: WARNING - No tokens were saved!');
      }
    } catch (e) {
      print('Error saving tokens: $e');
    }
  }

  /// Call logout endpoint with stored refresh token and clear local tokens/login flag.
  /// Returns true if server responded with success (200/201), false otherwise.
  static Future<bool> logout() async {
    final sp = await SharedPreferences.getInstance();
    final refresh = sp.getString('refreshToken') ?? '';
    final uri = Uri.parse('$baseUrl/api/auth/logout');
    final body = jsonEncode({'RefreshToken': refresh});
    try {
      final client = _getHttpClient();
      final response = await client.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
      print('logout Response - Status: ${response.statusCode}, Body: ${response.body}');
      // Clear local tokens and login flag regardless of server result to avoid stale state
      await sp.remove('accessToken');
      await sp.remove('refreshToken');
      await sp.remove('accessTokenExpiration');
      await sp.remove('refreshTokenExpiration');
      await sp.setBool('isLoggedIn', false);
      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print('Logout request failed: $e');
      try {
        await sp.remove('accessToken');
        await sp.remove('refreshToken');
        await sp.remove('accessTokenExpiration');
        await sp.remove('refreshTokenExpiration');
        await sp.setBool('isLoggedIn', false);
      } catch (_) {}
      return false;
    }
  }
}

