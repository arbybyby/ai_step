import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../core/api_config.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    final result = await authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      _showSnackBar(result.message, isSuccess: true);
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else {
      _showSnackBar(result.message);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!isGoogleSignInConfigured) {
      _showSnackBar(
        'Google Sign-In is not configured. Please set GOOGLE_CLIENT_ID.',
      );
      return;
    }

    setState(() => _isGoogleLoading = true);
    final googleSignIn = _buildGoogleSignIn();

    try {
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (!mounted) return;

      if (account == null) {
        _showSnackBar('Sign-in was cancelled.');
        return;
      }

      final auth = await account.authentication;
      if (!mounted) return;

      final idToken = auth.idToken;
      if (idToken == null) {
        _showSnackBar('Could not retrieve Google ID token.');
        return;
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.signInWithGoogle(idToken);

      if (!mounted) return;

      if (result.success) {
        final message = 'Welcome ${account.displayName ?? account.email}!';
        _showSnackBar(message, isSuccess: true);
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        _showSnackBar(result.message);
      }
    } catch (error, stackTrace) {
      print('Google sign-in error: $error');
      print('Stack trace: $stackTrace');
      if (mounted) {
        _showSnackBar(_googleSignInErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  GoogleSignIn _buildGoogleSignIn() {
    if (kIsWeb) {
      return GoogleSignIn(clientId: googleClientId);
    }

    final platform = defaultTargetPlatform;
    final needsExplicitClient =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: googleClientId,
      clientId: needsExplicitClient ? googleClientId : null,
    );
  }

  String _googleSignInErrorMessage(Object error) {
    if (error is PlatformException) {
      switch (error.code) {
        case GoogleSignIn.kSignInCanceledError:
          return 'Google sign-in was cancelled.';
        case GoogleSignIn.kSignInFailedError:
          return 'Google rejected the sign-in request. Check OAuth configuration.';
        case 'network_error':
          return 'Google sign-in failed due to network error.';
        default:
          return 'Google sign-in failed: ${error.message ?? error.code}';
      }
    }
    return 'Google sign-in failed. ${error.toString()}';
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    
                    // Logo and Title
                    Column(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 80,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your account',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Email Field
                    AuthTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      isEmail: true,
                      validator: Validators.email,
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Password Field
                    AuthTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      isPassword: true,
                      validator: Validators.password,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: _handleLogin,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sign In Button
                    AuthButton(
                      text: 'Sign In',
                      onPressed: _handleLogin,
                      isLoading: authService.isLoading,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Divider
                    const AuthDivider(),
                    
                    const SizedBox(height: 24),
                    
                    // Google Sign In Button
                    GoogleSignInButton(
                      onPressed: _handleGoogleSignIn,
                      isLoading: _isGoogleLoading,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacementNamed('/signup');
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}