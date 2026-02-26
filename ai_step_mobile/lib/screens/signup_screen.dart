import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/step_storage_service.dart';
import 'verify_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const _darkBg = Color(0xFF0E0E0E);
  static const _green = Color(0xFF1DB954);
  static const _fieldBg = Color(0xFF1A1A1A);
  static const _fieldBorder = Color(0xFF2A2A2A);

  final _formKey = GlobalKey<FormState>();
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
              const SizedBox(height: 8),

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

              const SizedBox(height: 24),

              // ── Title ─────────────────────────────────────────────────
              const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join us and start your fitness journey',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 36),

              // ── Form ──────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            hint: 'First Name',
                            onSaved: (v) => _firstName = v?.trim() ?? '',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            hint: 'Last Name',
                            onSaved: (v) => _lastName = v?.trim() ?? '',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      hint: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (v) => _email = v?.trim() ?? '',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter email';
                        if (!RegExp(
                          r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                        ).hasMatch(v.trim()))
                          return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      hint: 'Password',
                      obscureText: _obscurePassword,
                      suffix: _eyeButton(
                        visible: _obscurePassword,
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      onSaved: (v) => _password = v ?? '',
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      hint: 'Confirm Password',
                      obscureText: _obscureConfirm,
                      suffix: _eyeButton(
                        visible: _obscureConfirm,
                        onTap: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      onSaved: (v) => _confirmPassword = v ?? '',
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Min 6 chars' : null,
                    ),

                    const SizedBox(height: 28),

                    // ── Submit button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
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
                        onPressed: _isLoading ? null : _submit,
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
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Sign in link ────────────────────────────────────
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pushReplacementNamed('/signin'),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 14,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Log In',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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

  Widget _buildField({
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      style: const TextStyle(color: Colors.white, fontSize: 15),
      keyboardType: keyboardType,
      obscureText: obscureText,
      onSaved: onSaved,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 15,
        ),
        filled: true,
        fillColor: _fieldBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
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
        suffixIcon: suffix,
      ),
    );
  }

  Widget _eyeButton({required bool visible, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.white30,
        size: 20,
      ),
      onPressed: onTap,
    );
  }

  Future<void> _submit() async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    if (_password != _confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await AuthService.register(
        email: _email,
        password: _password,
        firstName: _firstName,
        lastName: _lastName,
      );
      final status = res.statusCode;
      final body = res.body.isNotEmpty && res.body.startsWith('{')
          ? Map<String, dynamic>.from(jsonDecode(res.body))
          : <String, dynamic>{};

      if (status == 201) {
        try {
          await StepStorageService().clear();
          final sp = await SharedPreferences.getInstance();
          await sp.clear();
        } catch (_) {}
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VerifyScreen(email: _email, password: _password),
            ),
          );
        }
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
}
