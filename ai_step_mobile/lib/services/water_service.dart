import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/water_info.dart';

class WaterService {
  String get baseUrl {
    const fallback = 'https://192.168.1.213:8081';
    try {
      if (dotenv.isInitialized) {
        final v = dotenv.env['API_BASE_URL'];
        if (v != null && v.isNotEmpty) return v;
      }
    } catch (e) {
      print('WaterService.baseUrl: dotenv access failed: $e');
    }
    return fallback;
  }

  final http.Client httpClient;

  WaterService({http.Client? httpClient}) : httpClient = httpClient ?? _createInsecureClient();

  static http.Client _createInsecureClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? prefs.getString('accessToken') ?? prefs.getString('access_token') ?? prefs.getString('token') ?? prefs.getString('access') ?? '';
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final candidates = [prefs.getString('user_id'), prefs.getString('userId'), prefs.getString('id')];
    for (final c in candidates) {
      if (c != null && c.isNotEmpty) return c;
    }
    return null;
  }

  Future<List<WaterInfo>> getEntries() async {
    final token = await _getToken();
    if (token.isEmpty) throw Exception('No token');
    final uri = Uri.parse('$baseUrl/api/Water');
    http.Response response;
    try {
      response = await httpClient.get(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
    } catch (e) {
      final insecure = _createInsecureClient();
      response = await insecure.get(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
    }

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      if (parsed is List) {
        return parsed.map((e) => WaterInfo.fromJson(e as Map<String, dynamic>)).toList();
      } else if (parsed is Map) {
        // single object -> wrap
        return [WaterInfo.fromJson(parsed.cast<String, dynamic>())];
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load water entries: ${response.statusCode}');
    }
  }

  Future<void> add(int amount) async {
    final token = await _getToken();
    if (token.isEmpty) throw Exception('No token');
    final uri = Uri.parse('$baseUrl/api/Water/add?amount=$amount');
    http.Response response;
    try {
      response = await httpClient.post(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
    } catch (e) {
      final insecure = _createInsecureClient();
      response = await insecure.post(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
    }

    if (response.statusCode == 200) return;
    if (response.statusCode == 401) throw Exception('Unauthorized');
    throw Exception('Failed to add water: ${response.statusCode}');
  }

  Future<void> remove(int amount) async {
    final token = await _getToken();
    if (token.isEmpty) throw Exception('No token');
    final uri = Uri.parse('$baseUrl/api/Water/remove?amount=$amount');
    http.Response response;
    try {
      response = await httpClient.delete(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
    } catch (e) {
      final insecure = _createInsecureClient();
      response = await insecure.delete(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 10));
    }

    if (response.statusCode == 200) return;
    if (response.statusCode == 401) throw Exception('Unauthorized');
    throw Exception('Failed to remove water: ${response.statusCode}');
  }
}
