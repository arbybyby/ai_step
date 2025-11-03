// Google OAuth Configuration for AI Step
// This file contains Google Sign-In configuration

import 'package:flutter/foundation.dart';

class GoogleOAuthConfig {
  // ВАЖНО: Замените эти значения на ваши реальные Client IDs из Google Cloud Console
  
  // Web Client ID (используется для верификации токенов на backend)
  static const String webClientId = 
      '37802022899-a4o3o6qfoglpa0vju8amoubvpkg3ncjk.apps.googleusercontent.com';
  
  // Android Client ID (если отличается от Web)
  static const String androidClientId = webClientId;
  
  // iOS Client ID (если отличается от Web)
  static const String iosClientId = webClientId;

  // Проверка, настроен ли OAuth (не placeholder)
  static bool get isConfigured => 
      !webClientId.contains('37802022899') && 
      webClientId.contains('.apps.googleusercontent.com');
      
  // Получить подходящий Client ID для текущей платформы
  static String getClientIdForPlatform() {
    // Для всех платформ используем Web Client ID
    // так как он нужен для верификации токенов на сервере
    return webClientId;
  }
  
  // Scopes для Google Sign-In
  static const List<String> scopes = ['email', 'profile'];
  
  // Настройки для отладки
  static const bool enableDebugLogs = true;

  // Get Client ID with validation
  String getClientId() {
    return webClientId;
  }

  // Check if configuration is valid
  bool isConfigurationValid() {
    try {
      final clientId = getClientId();
      return _isValidClientId(clientId);
    } catch (e) {
      return false;
    }
  }

  // Validate Client ID format
  bool _isValidClientId(String clientId) {
    // Check if it's not a placeholder or empty
    if (clientId.isEmpty || 
        clientId == 'YOUR_GOOGLE_CLIENT_ID_HERE' ||
        clientId.startsWith('placeholder') ||
        clientId.startsWith('your-')) {
      return false;
    }
    
    // Basic format validation for Google Client IDs
    // They typically end with .googleusercontent.com
    return clientId.contains('.googleusercontent.com');
  }

  // Get configuration status with details
  Map<String, dynamic> getConfigurationStatus() {
    final clientId = getClientId();
    final isValid = _isValidClientId(clientId);
    
    return {
      'isValid': isValid,
      'clientId': isValid ? clientId : 'Invalid or missing',
      'environment': kDebugMode ? 'debug' : 'release',
      'message': isValid 
        ? 'Google OAuth configuration is valid'
        : 'Google OAuth Client ID не настроен или некорректен. '
          'Пожалуйста, обратитесь к администратору приложения.',
    };
  }
}