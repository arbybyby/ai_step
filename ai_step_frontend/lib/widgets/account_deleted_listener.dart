import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

/// Виджет для обработки и отображения уведомлений об удалении аккаунта
/// Должен быть размещен где-то в дереве виджетов приложения (например, в Scaffold)
class AccountDeletedListener extends StatefulWidget {
  final Widget child;

  const AccountDeletedListener({
    required this.child,
    super.key,
  });

  @override
  State<AccountDeletedListener> createState() => _AccountDeletedListenerState();
}

class _AccountDeletedListenerState extends State<AccountDeletedListener> {
  bool _isNavigating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Слушаем изменения AuthService
    final authService = context.watch<AuthService>();
    
    // Если аккаунт был удален, показываем сообщение и выполняем навигацию
    if (authService.accountDeleted && !_isNavigating) {
      _isNavigating = true;
      _handleAccountDeleted();
    }
  }

  Future<void> _handleAccountDeleted() async {
    // Показываем SnackBar с сообщением
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ваш аккаунт был удалён администратором'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      // Ждем некоторое время для отображения сообщения
      await Future.delayed(const Duration(milliseconds: 500));

      // Очищаем локальные данные пользователя
      final authService = context.read<AuthService>();
      await authService.logout();

      // Выполняем навигацию на экран входа
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }

    // Сбрасываем флаг для возможности повторного использования
    if (mounted) {
      final authService = context.read<AuthService>();
      authService.resetAccountDeletedFlag();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
