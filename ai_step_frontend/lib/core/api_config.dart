import 'dart:io';
import 'google_oauth_config.dart';

// Автоматическое определение правильного базового URL
String get backendBaseUrl {
  // Проверяем environment variable сначала
  const envUrl = String.fromEnvironment('BACKEND_URL');
  if (envUrl.isNotEmpty) {
    return envUrl;
  }

  // Автоматическое определение в зависимости от платформы
  if (Platform.isAndroid) {
    // Для Android эмулятора используем 10.0.2.2
    return 'http://192.168.1.82:8080';
  } else if (Platform.isIOS) {
    // Для iOS симулятора используем localhost
    return 'http://localhost:8080';
  } else {
    // Для других платформ (Windows, macOS, Linux, Web)
    return 'http://localhost:8080';
  }
}

// Google Client ID с поддержкой переменных окружения
const String googleClientId = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
  defaultValue: GoogleOAuthConfig.webClientId,
);

// Проверка конфигурации OAuth
bool get isGoogleSignInConfigured {
  final config = GoogleOAuthConfig();
  return config.isConfigurationValid();
}

Uri apiUri(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$backendBaseUrl$normalizedPath');
}
