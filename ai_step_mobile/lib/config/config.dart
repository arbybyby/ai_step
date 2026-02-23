import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration
class AppConfig {
  /// Default fallback API base URL
  static const String _defaultBaseUrl = 'https://192.168.43.16:8081';

  /// Get the API base URL from environment variable or use fallback
  static String get baseUrl {
    try {
      if (dotenv.isInitialized) {
        final v = dotenv.env['API_BASE_URL'];
        if (v != null && v.isNotEmpty) return v;
      }
    } catch (e) {
      print('AppConfig.baseUrl: dotenv access failed: $e');
    }
    return _defaultBaseUrl;
  }
}
