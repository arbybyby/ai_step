import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Класс для обработки случаев удаления аккаунта
class AccountDeletedHandler {
  /// Проверяет, содержит ли ответ сервера признаки удаления аккаунта
  static bool isAccountDeletedError(http.Response response, {String? responseBody}) {
    final statusCode = response.statusCode;
    
    // Проверяем HTTP статус коды
    if (statusCode == 401 || statusCode == 403) {
      // Проверяем тело ответа на наличие признаков удаления аккаунта
      try {
        final body = responseBody ?? response.body;
        if (body.isEmpty) {
          // Пустое тело может быть признаком удаления
          return statusCode == 403; // 403 чаще всего означает доступ запрещён
        }

        final jsonBody = jsonDecode(body) as Map<String, dynamic>;
        
        // Проверяем различные варианты сообщений об удалении
        final message = (jsonBody['message'] ?? '').toString().toLowerCase();
        final error = (jsonBody['error'] ?? '').toString().toLowerCase();
        final reason = (jsonBody['reason'] ?? '').toString().toLowerCase();
        
        return message.contains('user deleted') ||
               message.contains('user not found') ||
               message.contains('пользователь удален') ||
               message.contains('пользователь не найден') ||
               message.contains('account deleted') ||
               message.contains('account not found') ||
               error.contains('user deleted') ||
               error.contains('user not found') ||
               error.contains('пользователь удален') ||
               error.contains('пользователь не найден') ||
               reason.contains('deleted') ||
               reason.contains('not found') ||
               reason.contains('удален') ||
               reason.contains('не найден');
      } catch (e) {
        // Если не можем распарсить JSON, считаем 403 как признак удаления
        debugPrint('Error parsing response body in AccountDeletedHandler: $e');
        return statusCode == 403;
      }
    }
    
    return false;
  }

  /// Извлекает сообщение об ошибке из ответа сервера
  static String getErrorMessage(http.Response response) {
    try {
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonBody['message'] ?? jsonBody['error'] ?? 'Unknown error';
    } catch (e) {
      return 'Unknown error';
    }
  }
}
