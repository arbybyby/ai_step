import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        print('===== AuthGuard check =====');
        print('AuthService isLoading: ${authService.isLoading}');
        print('AuthService isAuthenticated: ${authService.isAuthenticated}');
        
        // Show loading screen while checking authentication status
        if (authService.isLoading) {
          print('AuthGuard: showing loading screen');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Redirect to login if not authenticated
        if (!authService.isAuthenticated) {
          print('AuthGuard: user not authenticated, redirecting to login');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        print('AuthGuard: user authenticated, showing protected content');
        // Show protected content if authenticated
        return child;
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
        // Show loading screen while checking authentication status
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

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

        // Show guest content if not authenticated
        return child;
      },
    );
  }
}