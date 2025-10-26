import 'dart:io';

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
    return 'http://192.168.42.63:8080';
  } else if (Platform.isIOS) {
    // Для iOS симулятора используем localhost
    return 'http://localhost:8080';
  } else {
    // Для других платформ (Windows, macOS, Linux, Web)
    return 'http://localhost:8080';
  }
}

const String googleClientId = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
  defaultValue:
      '37802022899-a4o3o6qfoglpa0vju8amoubvpkg3ncjk.apps.googleusercontent.com',
);

bool get isGoogleSignInConfigured =>
    !googleClientId.contains('YOUR_GOOGLE_CLIENT_ID');

Uri apiUri(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$backendBaseUrl$normalizedPath');
}
