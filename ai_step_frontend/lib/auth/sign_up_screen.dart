import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        apiUri('/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        await _persistSession(payload);

        if (!mounted) return;

        _showSnackBar(
          (payload['message'] as String?) ?? 'Account created successfully!',
          isSuccess: true,
        );
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        final message =
            _parseErrorMessage(response.body) ??
            'Registration failed. Please try again.';
        _showSnackBar(message);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Could not reach server. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

      final response = await http.post(
        apiUri('/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        await _persistSession(payload);

        if (!mounted) return;

        final message =
            (payload['message'] as String?) ??
            'Welcome ${account.displayName ?? account.email}!';
        _showSnackBar(message, isSuccess: true);
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        final message =
            _parseErrorMessage(response.body) ??
            'Google sign-in failed. Try again.';
        _showSnackBar(message);
      }
    } catch (error, stackTrace) {
      debugPrint('Google sign-up error: $error');
      debugPrintStack(stackTrace: stackTrace);
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
          return 'Google rejected the sign-in request. Проверьте OAuth конфигурацию.';
        case 'network_error':
          return 'Google sign-in failed due to network error.';
        default:
          return 'Google sign-in failed: ${error.message ?? error.code}';
      }
    }
    return 'Google sign-in failed. ${error.toString()}';
  }

  Future<void> _persistSession(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final token = payload['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await prefs.setString('auth_token', token);
    }
    final user = payload['user'];
    if (user is Map<String, dynamic>) {
      await prefs.setString('auth_user', jsonEncode(user));
    }
  }

  String? _parseErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final message = decoded['message'] ?? decoded['error'];
      return message is String && message.isNotEmpty ? message : null;
    } catch (_) {
      return null;
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? const Color(0xFFE23C64) : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD464), Color(0xFFFF5E5E), Color(0xFFE23C64)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Start your fitness journey today',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 48),
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFFE23C64),
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFE23C64),
                                elevation: 8,
                                shadowColor: Colors.black26,
                                disabledBackgroundColor: Colors.white
                                    .withOpacity(0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(29),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Color(0xFFE23C64),
                                      ),
                                    )
                                  : const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.4),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.4),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isGoogleLoading || !isGoogleSignInConfigured
                                  ? null
                                  : _handleGoogleSignIn,
                              icon: _isGoogleLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.g_mobiledata_rounded,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _isGoogleLoading
                                    ? 'Connecting...'
                                    : isGoogleSignInConfigured
                                    ? 'Continue with Google'
                                    : 'Google Sign-In unavailable',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(29),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 15,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(
                                  context,
                                ).pushReplacementNamed('/login'),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                    decorationThickness: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFE23C64)),
        suffixIcon: suffixIcon,
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE23C64), width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      validator: validator,
    );
  }
}
