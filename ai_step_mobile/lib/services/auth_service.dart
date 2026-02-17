import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';
import 'step_storage_service.dart';

class AuthService {
  // Get base URL from centralized config
  static String get baseUrl => AppConfig.baseUrl;

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
    print('\n=== AuthService.login START ===');
    print('AuthService.login: Sending request to: $uri');
    try {
      final client = _getHttpClient();
      final response = await client.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
      print('AuthService.login: Response received - Status: ${response.statusCode}');
      print('AuthService.login: Response body: ${response.body}');
      // If login succeeded, try to extract and persist tokens from response body
      if ((response.statusCode == 200 || response.statusCode == 201) && response.body.isNotEmpty) {
        try {
          final decoded = response.body.startsWith('{') ? jsonDecode(response.body) : null;
          if (decoded != null) {
            print('AuthService.login: Decoded response keys: ${decoded.keys.toList()}');
            await _saveTokensFromBody(decoded);
          }
        } catch (e) {
          print('AuthService.login: Failed to parse/save tokens: $e');
        }
      }
      print('=== AuthService.login END ===\n');
      return response;
    } catch (e) {
      print('AuthService.login: Request failed: $e');
      print('=== AuthService.login END ===\n');
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
      maybeTokens ??= map;

      String? access;
      String? refresh;
      String? accessExp;
      String? refreshExp;

      // Try different key name variants, and include common short keys like 'token' or 'access_token'
      access = maybeTokens['accessToken']?.toString() ?? maybeTokens['AccessToken']?.toString() ?? maybeTokens['token']?.toString() ?? maybeTokens['access_token']?.toString() ?? map['accessToken']?.toString() ?? map['AccessToken']?.toString() ?? map['token']?.toString() ?? map['access_token']?.toString();
      refresh = maybeTokens['refreshToken']?.toString() ?? maybeTokens['RefreshToken']?.toString() ?? map['refreshToken']?.toString() ?? map['RefreshToken']?.toString();
      accessExp = maybeTokens['accessTokenExpiration']?.toString() ?? maybeTokens['AccessTokenExpiration']?.toString() ?? map['accessTokenExpiration']?.toString() ?? map['AccessTokenExpiration']?.toString();
      refreshExp = maybeTokens['refreshTokenExpiration']?.toString() ?? maybeTokens['RefreshTokenExpiration']?.toString() ?? map['refreshTokenExpiration']?.toString() ?? map['RefreshTokenExpiration']?.toString();

      final sp = await SharedPreferences.getInstance();
      var saved = false;
      if (access != null) {
        print('AuthService._saveTokensFromBody: Saving accessToken (length=${access.length})');
        await sp.setString('accessToken', access);
        // also save under common alternate key for compatibility
        await sp.setString('auth_token', access);
        saved = true;
        print('AuthService._saveTokensFromBody: accessToken saved successfully (also saved as auth_token)');
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
      // If response included user id, persist it for StepsApiService._getUserId
      try {
        if (map.containsKey('userId')) {
          final uid = map['userId']?.toString();
          if (uid != null && uid.isNotEmpty) {
            await sp.setString('user_id', uid);
            print('AuthService._saveTokensFromBody: saved user_id=$uid');
          }
        }
        if (map.containsKey('id')) {
          final uid = map['id']?.toString();
          if (uid != null && uid.isNotEmpty) {
            await sp.setString('user_id', uid);
            print('AuthService._saveTokensFromBody: saved user_id (from id)=$uid');
          }
        }
      } catch (e) {
        print('AuthService._saveTokensFromBody: failed to save user id: $e');
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
      // Clear all SharedPreferences to remove any user-specific state
      try {
        await sp.clear();
        print('AuthService.logout: SharedPreferences cleared');
      } catch (e) {
        print('AuthService.logout: Failed to clear SharedPreferences: $e');
      }

      // Clear local pedometer/step storage
      try {
        await StepStorageService().clear();
        print('AuthService.logout: StepStorageService cleared');
      } catch (e) {
        print('AuthService.logout: Failed to clear StepStorageService: $e');
      }
      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print('Logout request failed: $e');
      try {
        await sp.clear();
        print('AuthService.logout (catch): SharedPreferences cleared');
      } catch (_) {}
      try {
        await StepStorageService().clear();
        print('AuthService.logout (catch): StepStorageService cleared');
      } catch (_) {}
      return false;
    }
  }

  /// Check if accessToken is expired by comparing with current time.
  /// Subtracts 5 minutes buffer to refresh before actual expiration.
  static Future<bool> isTokenExpired() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final expirationStr = sp.getString('accessTokenExpiration');
      
      if (expirationStr == null || expirationStr.isEmpty) {
        print('AuthService.isTokenExpired: No expiration date stored, token considered expired');
        return true;
      }

      // Try to parse as ISO 8601 datetime
      try {
        final expirationTime = DateTime.parse(expirationStr);
        final now = DateTime.now();
        // Add 5-minute buffer: refresh if expires within 5 minutes
        final bufferTime = now.add(const Duration(minutes: 5));
        
        final isExpired = bufferTime.isAfter(expirationTime);
        print('AuthService.isTokenExpired: now=$now, expiration=$expirationTime, isExpired=$isExpired');
        return isExpired;
      } catch (e) {
        print('AuthService.isTokenExpired: Failed to parse expiration datetime: $e');
        // If we can't parse it, assume expired to be safe
        return true;
      }
    } catch (e) {
      print('AuthService.isTokenExpired: Error checking token expiration: $e');
      return true;
    }
  }

  /// Refresh access token using refresh token.
  /// Calls POST /api/auth/refresh with stored refreshToken.
  /// Returns true if refresh was successful, false otherwise.
  static Future<bool> refreshToken() async {
    print('\n=== AuthService.refreshToken START ===');
    try {
      final sp = await SharedPreferences.getInstance();
      final refreshToken = sp.getString('refreshToken');
      
      if (refreshToken == null || refreshToken.isEmpty) {
        print('AuthService.refreshToken: No refresh token stored, cannot refresh');
        print('=== AuthService.refreshToken END ===\n');
        return false;
      }

      final uri = Uri.parse('$baseUrl/api/auth/refresh');
      final body = jsonEncode({'RefreshToken': refreshToken});
      
      print('AuthService.refreshToken: Sending refresh request to: $uri');
      
      try {
        final client = _getHttpClient();
        final response = await client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 10));

        print('AuthService.refreshToken: Response status=${response.statusCode}');
        
        if ((response.statusCode == 200 || response.statusCode == 201) && response.body.isNotEmpty) {
          try {
            final decoded = jsonDecode(response.body);
            print('AuthService.refreshToken: Successfully decoded response');
            await _saveTokensFromBody(decoded);
            print('AuthService.refreshToken: New tokens saved successfully');
            print('=== AuthService.refreshToken END ===\n');
            return true;
          } catch (e) {
            print('AuthService.refreshToken: Failed to parse/save tokens: $e');
            print('=== AuthService.refreshToken END ===\n');
            return false;
          }
        } else {
          print('AuthService.refreshToken: Unexpected response status ${response.statusCode}: ${response.body}');
          print('=== AuthService.refreshToken END ===\n');
          return false;
        }
      } catch (e) {
        print('AuthService.refreshToken: Request failed: $e');
        print('=== AuthService.refreshToken END ===\n');
        return false;
      }
    } catch (e) {
      print('AuthService.refreshToken: Error: $e');
      print('=== AuthService.refreshToken END ===\n');
      return false;
    }
  }

  /// Get access token, automatically refreshing if expired or expiring soon.
  /// If refresh fails, returns the existing token anyway.
  static Future<String> getAccessTokenWithRefresh() async {
    print('AuthService.getAccessTokenWithRefresh: Checking if token needs refresh...');
    
    final isExpired = await isTokenExpired();
    if (isExpired) {
      print('AuthService.getAccessTokenWithRefresh: Token expired or expiring soon, attempting refresh...');
      final refreshed = await refreshToken();
      if (!refreshed) {
        print('AuthService.getAccessTokenWithRefresh: Token refresh failed, using existing token');
      }
    } else {
      print('AuthService.getAccessTokenWithRefresh: Token is still valid');
    }
    
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('auth_token') ?? sp.getString('accessToken') ?? sp.getString('access_token') ?? '';
    return token;
  }
}

