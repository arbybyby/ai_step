import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../core/api_config.dart';
import '../models/auth_models.dart';

class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  
  String? _token;
  User? _user;
  bool _isLoading = false;

  // Getters
  String? get token => _token;
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;

  // Initialize service - check for existing session
  Future<void> initialize() async {
    print('===== AuthService initialize() called =====');
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);
      
      print('Token from storage: ${_token != null ? "exists" : "null"}');
      print('User from storage: ${userJson != null ? "exists" : "null"}');
      
      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
        print('User parsed: ${_user!.email}');
      }

      // Validate token if exists
      if (_token != null) {
        final isValid = _isTokenValid(_token!);
        print('Token validation result: $isValid');
        if (!isValid) {
          print('Token invalid, logging out');
          await logout();
        }
      }
    } catch (e) {
      print('Error initializing auth service: $e');
      await logout();
    } finally {
      _isLoading = false;
      print('AuthService initialization complete. isAuthenticated: $isAuthenticated');
      notifyListeners();
    }
  }

  // Sign up with email and password
  Future<AuthResult> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        apiUri('/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
        }),
      );

      final responseBody = jsonDecode(response.body);
      print('Sign up response status: ${response.statusCode}');
      print('Sign up response body: $responseBody');

      if (response.statusCode == 200) {
        print('Registration response body keys: ${responseBody.keys}');
        
        // Check if response contains token (AuthResponse) or just message (MessageResponse)
        if (responseBody.containsKey('token')) {
          // Auto-login successful - got AuthResponse
          print('Received AuthResponse with token');
          final authResponse = AuthResponse.fromJson(responseBody);
          print('AuthResponse parsed: ${authResponse.token.isNotEmpty ? "token received" : "no token"}');
          await _saveSession(authResponse);
          print('Session saved, isAuthenticated: $isAuthenticated, user: ${_user?.email}');
          return AuthResult.success('Account created successfully! Welcome aboard!');
        } else {
          // Registration successful but auto-login failed - got MessageResponse
          print('Received MessageResponse without token');
          final message = responseBody['message'] ?? 'Account created successfully! Please sign in.';
          return AuthResult.success(message);
        }
      } else {
        final message = responseBody['message'] ?? 'Registration failed';
        return AuthResult.error(message);
      }
    } catch (e) {
      print('Sign up error: $e');
      return AuthResult.error('Network error. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        apiUri('/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(responseBody);
        await _saveSession(authResponse);
        return AuthResult.success('Welcome back!');
      } else {
        final message = responseBody['message'] ?? 'Invalid credentials';
        return AuthResult.error(message);
      }
    } catch (e) {
      print('Sign in error: $e');
      return AuthResult.error('Network error. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Google Sign In
  Future<AuthResult> signInWithGoogle(String idToken) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        apiUri('/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(responseBody);
        await _saveSession(authResponse);
        return AuthResult.success('Welcome!');
      } else {
        final message = responseBody['message'] ?? 'Google sign-in failed';
        return AuthResult.error(message);
      }
    } catch (e) {
      print('Google sign in error: $e');
      return AuthResult.error('Network error. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      
      _token = null;
      _user = null;
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Get authenticated HTTP headers
  Map<String, String> get authHeaders {
    print('Getting auth headers - token exists: ${_token != null}');
    if (_token != null) {
      print('Token preview: ${_token!.substring(0, math.min(20, _token!.length))}...');
    }
    
    if (_token == null) {
      return {'Content-Type': 'application/json'};
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }

  // Make authenticated HTTP request
  Future<http.Response> authenticatedRequest({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = {...authHeaders, ...?additionalHeaders};
    final uri = apiUri(path);

    print('Making $method request to: $uri');
    print('Headers: $headers');
    if (body != null) {
      print('Body: ${jsonEncode(body)}');
    }

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  // Private methods
  Future<void> _saveSession(AuthResponse authResponse) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      print('Saving session with token: ${authResponse.token.isNotEmpty ? "received" : "empty"}');
      print('User data: ${authResponse.email}, ${authResponse.firstName} ${authResponse.lastName}');
      
      _token = authResponse.token;
      _user = User(
        id: authResponse.id,
        email: authResponse.email,
        firstName: authResponse.firstName,
        lastName: authResponse.lastName,
        isEmailVerified: authResponse.isEmailVerified,
      );

      await prefs.setString(_tokenKey, _token!);
      await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
      
      print('Session saved to preferences');
      notifyListeners();
      print('Listeners notified, isAuthenticated: $isAuthenticated');
    } catch (e) {
      print('Error saving session: $e');
      throw Exception('Failed to save session');
    }
  }

  bool _isTokenValid(String token) {
    try {
      // Check if token is expired using JWT decoder
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  // Public method to check token validity
  bool get isTokenValid {
    if (_token == null) return false;
    return _isTokenValid(_token!);
  }
}