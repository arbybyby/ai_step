import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/account_deleted_listener.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Show loading screen while checking authentication status
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Redirect to login if not authenticated
        if (!authService.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await authService.logout();
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/',
              (route) => false,
            );
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show protected content if authenticated
        return AccountDeletedListener(
          child: child,
        );
      },
    );
  }
}

class GuestGuard extends StatelessWidget {
  final Widget child;

  const GuestGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Don't show loading screen for guest pages - let the page handle its own loading state
        // This allows SnackBars and other UI elements to be displayed properly
        
        // Redirect to home if already authenticated
        if (authService.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show guest content (the page itself will handle loading state through Consumer)
        return child;
      },
    );
  }
}