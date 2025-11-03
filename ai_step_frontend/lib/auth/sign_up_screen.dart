import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../core/api_config.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import '../utils/validators.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    
    print('Starting sign up process...');

    final result = await authService.signUp(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    print('Sign up result: ${result.success}, message: ${result.message}');
    print('User authenticated after signup: ${authService.isAuthenticated}');
    print('User data after signup: ${authService.user?.toJson()}');

    if (result.success) {
      _showSnackBar(result.message, isSuccess: true);
      
      // Check if user is now authenticated (auto-login successful)
      if (authService.isAuthenticated) {
        // Auto-login successful, go to home
        print('Auto-login successful, navigating to home');
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else {
        // Registration successful but auto-login failed, go to login page
        print('Registration successful but auto-login failed, navigating to login');
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    } else {
      _showSnackBar(result.message);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    // Validate OAuth configuration first
    final authService = Provider.of<AuthService>(context, listen: false);
    final configResult = await authService.validateGoogleOAuthConfig();
    
    if (!configResult.success) {
      if (mounted) {
        _showSnackBar(configResult.message);
        setState(() => _isGoogleLoading = false);
      }
      return;
    }

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
          return 'OAuth configuration error. Please check:\n'
                 '• SHA-1 certificate fingerprint\n'
                 '• Package name in Google Console\n'
                 '• Client ID configuration';
        case 'network_error':
          return 'Network error during Google sign-in. Check your internet connection.';
        case 'sign_in_required':
          return 'Google sign-in required. Please try again.';
        case 'invalid_account':
          return 'Invalid Google account. Please select a different account.';
        default:
          return 'Google sign-in error (${error.code}): ${error.message ?? "Unknown error"}';
      }
    }
    
    // Handle common error messages
    String errorStr = error.toString().toLowerCase();
    if (errorStr.contains('oauth') || errorStr.contains('configuration')) {
      return 'OAuth configuration error. Please contact support if this persists.';
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (errorStr.contains('cancelled') || errorStr.contains('canceled')) {
      return 'Google sign-in was cancelled by user.';
    }
    
    return 'Google sign-in failed: ${error.toString()}';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Consumer<AuthService>(
            builder: (context, authService, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo and Title
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.directions_walk_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join us and start your fitness journey',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Form Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                    
                    // First Name Field
                    AuthTextField(
                      controller: _firstNameController,
                      labelText: 'First Name',
                      hintText: 'Enter your first name',
                      validator: Validators.firstName,
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Last Name Field
                    AuthTextField(
                      controller: _lastNameController,
                      labelText: 'Last Name',
                      hintText: 'Enter your last name',
                      validator: Validators.lastName,
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: 16),
                    
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
                      hintText: 'Create a password',
                      isPassword: true,
                      validator: Validators.password,
                      textInputAction: TextInputAction.next,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Confirm Password Field
                    AuthTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your password',
                      isPassword: true,
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: _handleSignUp,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sign Up Button
                    AuthButton(
                      text: 'Create Account',
                      onPressed: _handleSignUp,
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
                    
                            // Sign In Link
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushReplacementNamed('/login');
                                  },
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}