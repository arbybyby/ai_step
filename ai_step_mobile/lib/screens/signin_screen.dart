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
  static const _darkBg = Color(0xFF0E0E0E);
  static const _green = Color(0xFF1DB954);
  static const _fieldBg = Color(0xFF1A1A1A);
  static const _fieldBorder = Color(0xFF2A2A2A);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // ── Icon ──────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_walk,
                  size: 38,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 28),

              // ── Title ─────────────────────────────────────────────────
              const Text(
                'Welcome Back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue your fitness journey',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 40),

              // ── Form ──────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter email' : null,
                      decoration: _fieldDeco('Email'),
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter password' : null,
                      decoration: _fieldDeco('Password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white30,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showPasswordResetDialog(context),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Sign In button ──────────────────────────────────
                    SizedBox(
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _darkBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _signIn,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Sign up link ────────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(
                          context,
                        ).pushReplacementNamed('/signup'),
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 14,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
      filled: true,
      fillColor: _fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _green, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    );
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() => _isLoading = true);

    try {
      final res = await AuthService.login(email: email, password: password);
      final status = res.statusCode;
      final body = res.body.isNotEmpty && res.body.startsWith('{')
          ? jsonDecode(res.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (status == 200 || status == 201) {
        final sp = await SharedPreferences.getInstance();
        await sp.setBool('isLoggedIn', true);
        try {
          await BackgroundSyncService.syncNow();
        } catch (_) {}
        try {
          await ref
              .read(currentDayStepsProvider.notifier)
              .fetchCurrentDaySteps();
        } catch (_) {}
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else {
        _showError(body['message'] ?? body['error'] ?? res.body);
      }
    } catch (e) {
      _showError('Could not reach server: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: _green)),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const PasswordResetDialog(),
    );
  }
}

// ─── Password Reset Dialog ────────────────────────────────────────────────────

class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({super.key});

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  static const _green = Color(0xFF1DB954);
  static const _fieldBg = Color(0xFF1A1A1A);

  int _step = 1;
  String _resetEmail = '';
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _deco(String hint, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
    filled: true,
    fillColor: _fieldBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _green, width: 1.5),
    ),
    suffixIcon: suffix,
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _step == 1 ? 'Reset Password' : 'Enter Reset Code',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _step == 1
                    ? 'Enter your email to receive a reset code'
                    : 'Enter the code and your new password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              if (_step == 1) ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _deco('Email address'),
                ),
                const SizedBox(height: 20),
                _actionButton(
                  'Send Reset Code',
                  _isLoading,
                  _handleForgotPassword,
                ),
              ] else ...[
                TextField(
                  controller: _codeController,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _deco('Reset code'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _deco(
                    'New password',
                    suffix: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white30,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _deco(
                    'Confirm password',
                    suffix: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white30,
                        size: 18,
                      ),
                      onPressed: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _actionButton(
                  'Reset Password',
                  _isLoading,
                  _handleResetPassword,
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() => _step = 1),
                  child: const Text(
                    '← Back',
                    style: TextStyle(color: _green, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String label, bool loading, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0E0E0E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErr('Please enter your email address');
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
        _showSnack('Reset code sent to your email');
      } else {
        final body = response.body.isNotEmpty && response.body.startsWith('{')
            ? jsonDecode(response.body) as Map<String, dynamic>
            : <String, dynamic>{};
        _showErr(
          body['message'] ?? body['error'] ?? 'Failed to send reset code',
        );
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      _showErr('Could not reach server: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (code.isEmpty) {
      _showErr('Enter the reset code');
      return;
    }
    if (password.isEmpty) {
      _showErr('Enter a new password');
      return;
    }
    if (password != confirm) {
      _showErr('Passwords do not match');
      return;
    }
    if (password.length < 6) {
      _showErr('Password must be at least 6 characters');
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
          _showSnack('Password reset successfully! Please log in.');
        }
      } else {
        final body = response.body.isNotEmpty && response.body.startsWith('{')
            ? jsonDecode(response.body) as Map<String, dynamic>
            : <String, dynamic>{};
        _showErr(
          body['message'] ?? body['error'] ?? 'Failed to reset password',
        );
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      _showErr('Could not reach server: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErr(String msg) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Error', style: TextStyle(color: Colors.white)),
      content: Text(msg, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK', style: TextStyle(color: _green)),
        ),
      ],
    ),
  );

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: _green,
      duration: const Duration(seconds: 3),
    ),
  );
}
