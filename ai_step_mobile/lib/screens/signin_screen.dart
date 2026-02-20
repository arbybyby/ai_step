import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/background_sync_service.dart';
import '../providers/steps_provider.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: height),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F8A5F), Color(0xFF1AC07B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.directions_walk, size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Welcome Back', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Sign in to continue your fitness journey', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 22),

                // White card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter email' : null,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            filled: true,
                            fillColor: const Color(0xFFF5F6F8),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            filled: true,
                            fillColor: const Color(0xFFF5F6F8),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[600]),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showPasswordResetDialog(context),
                            child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF8E3A44))),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Gradient Sign In button
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () async {
                                  if (!(_formKey.currentState?.validate() ?? false)) return;
                                  final email = _emailController.text.trim();
                                  final password = _passwordController.text;
                                  setState(() => _isLoading = true);
                                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signing in...')));
                                  try {
                                    final res = await AuthService.login(email: email, password: password);
                                    final status = res.statusCode;
                                    final body = res.body.isNotEmpty ? (res.body.startsWith('{') ? jsonDecode(res.body) : {}) : {};
                                    print('SignInScreen: Login response - status=$status, body=$body');
                                    
                                    if (status == 200 || status == 201) {
                                      final sp = await SharedPreferences.getInstance();
                                      await sp.setBool('isLoggedIn', true);
                                      print('SignInScreen: Login successful, isLoggedIn=true');
                                      
                                      // Attempt an immediate sync+fetch after login to populate data
                                      print('SignInScreen: Starting immediate sync after login...');
                                      try {
                                        await BackgroundSyncService.syncNow();
                                        print('SignInScreen: BackgroundSyncService.syncNow completed');
                                      } catch (e, stackTrace) {
                                        print('SignInScreen: syncNow failed: $e');
                                        print('SignInScreen: sync stackTrace: $stackTrace');
                                      }
                                      
                                      // Fetch from backend to update provider state
                                      print('SignInScreen: Fetching steps via provider...');
                                      try {
                                        await ref.read(currentDayStepsProvider.notifier).fetchCurrentDaySteps();
                                        print('SignInScreen: fetchCurrentDaySteps completed - provider state updated');
                                      } catch (e, stackTrace) {
                                        print('SignInScreen: fetchCurrentDaySteps failed: $e');
                                        print('SignInScreen: fetch stackTrace: $stackTrace');
                                      }
                                      
                                      print('SignInScreen: Navigating to /home');
                                      Navigator.of(context).pushReplacementNamed('/home');
                                    } else {
                                      final errorMsg = body['message'] ?? body['error'] ?? res.body;
                                      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Error'), content: Text('$errorMsg'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
                                    }
                                  } catch (e) {
                                    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Network error'), content: Text('Could not reach server: $e'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
                                  } finally {
                                    if (mounted) setState(() => _isLoading = false);
                                  }
                                },
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF0DA96B), Color(0xFF06C17A)]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2))
                                  : const Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/signup'),
                          child: RichText(
                            text: const TextSpan(children: [
                              TextSpan(text: "Don't have an account? ", style: TextStyle(color: Colors.black54)),
                              TextSpan(text: 'Sign Up', style: TextStyle(color: Color(0xFF8E3A44), fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showPasswordResetDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const PasswordResetDialog(),
    );
  }
}

class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({super.key});

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  int _step = 1; // 1: email, 2: code + password
  String _resetEmail = '';
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _step == 1 ? 'Reset Password' : 'Enter Reset Code',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _step == 1
                    ? 'Enter your email address to receive a reset code'
                    : 'Enter the reset code and your new password',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              if (_step == 1) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _isLoading ? null : _handleForgotPassword,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                          : const LinearGradient(
                              colors: [Color(0xFF0DA96B), Color(0xFF06C17A)],
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Send Reset Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.text,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Reset code',
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'New password',
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _isLoading ? null : _handleResetPassword,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                          : const LinearGradient(
                              colors: [Color(0xFF0DA96B), Color(0xFF06C17A)],
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Reset Password',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (_step == 2)
                TextButton(
                  onPressed: _isLoading ? null : () => setState(() => _step = 1),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: Color(0xFF0DA96B)),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog('Error', 'Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.forgotPassword(email: email);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _resetEmail = email;
        setState(() {
          _step = 2;
          _isLoading = false;
        });
        _showSuccessMessage('Reset code sent to your email');
      } else {
        final body = response.body.isNotEmpty ? (response.body.startsWith('{') ? jsonDecode(response.body) : {}) : {};
        final errorMsg = body['message'] ?? body['error'] ?? 'Failed to send reset code';
        if (mounted) {
          _showErrorDialog('Error', errorMsg);
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Network Error', 'Could not reach server: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (code.isEmpty) {
      _showErrorDialog('Error', 'Please enter the reset code');
      return;
    }

    if (password.isEmpty) {
      _showErrorDialog('Error', 'Please enter a new password');
      return;
    }

    if (password != confirmPassword) {
      _showErrorDialog('Error', 'Passwords do not match');
      return;
    }

    if (password.length < 6) {
      _showErrorDialog('Error', 'Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.resetPassword(
        email: _resetEmail,
        code: code,
        newPassword: password,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessMessage('Password reset successfully! Please login with your new password');
        }
      } else {
        final body = response.body.isNotEmpty ? (response.body.startsWith('{') ? jsonDecode(response.body) : {}) : {};
        final errorMsg = body['message'] ?? body['error'] ?? 'Failed to reset password';
        if (mounted) {
          _showErrorDialog('Error', errorMsg);
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Network Error', 'Could not reach server: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0DA96B),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
