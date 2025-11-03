// Google OAuth Configuration for AI Step
// This file contains Google Sign-In configuration

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
}