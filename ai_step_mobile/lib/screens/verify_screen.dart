import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class VerifyScreen extends StatefulWidget {
  final String? email;
  final String? password;
  const VerifyScreen({super.key, this.email, this.password});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _code = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _email = widget.email ?? '';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();
    setState(() => _isLoading = true);
    try {
      final res = await AuthService.verify(email: _email, code: _code);
      final status = res.statusCode;
      print('Verify Response - Status: $status, Body: ${res.body}');
      final body = res.body.isNotEmpty ? (res.body.startsWith('{') ? jsonDecode(res.body) : {}) : {};
      if (status == 200 || status == 201) {
        // Verified successfully — proceed without blocking dialog
        // If we have the password (passed from signup), try to auto-login
        if ((widget.password ?? '').isNotEmpty) {
          try {
            final loginRes = await AuthService.login(email: _email, password: widget.password!);
            final lStatus = loginRes.statusCode;
            print('Auto-login after verify - Status: $lStatus, Body: ${loginRes.body}');
            final lBody = loginRes.body.isNotEmpty ? (loginRes.body.startsWith('{') ? jsonDecode(loginRes.body) : {}) : {};
            if (lStatus == 200 || lStatus == 201) {
              final sp = await SharedPreferences.getInstance();
              await sp.setBool('isLoggedIn', true);
              Navigator.of(context).pushReplacementNamed('/home');
              return;
            } else {
              final lm = lBody['message'] ?? lBody['error'] ?? loginRes.body;
              await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Login error'), content: Text('$lm'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
              Navigator.of(context).pushReplacementNamed('/signin');
              return;
            }
          } catch (e) {
            await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Network error'), content: Text('Auto-login failed: $e'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
            Navigator.of(context).pushReplacementNamed('/signin');
            return;
          }
        }
        Navigator.of(context).pushReplacementNamed('/signin');
      } else if (status == 400) {
        final message = body['message'] ?? 'Invalid code';
        await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Error'), content: Text(message), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
      } else {
        final errorMsg = body['message'] ?? body['error'] ?? res.body;
        await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Error'), content: Text('$errorMsg'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
      }
    } catch (e) {
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Network error'), content: Text('Could not reach server: $e'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    if (_email.isEmpty) {
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Email required'), content: const Text('Please enter your email to resend code'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await AuthService.resendCode(email: _email);
      print('Resend Response - Status: ${res.statusCode}, Body: ${res.body}');
      final body = res.body.isNotEmpty ? (res.body.startsWith('{') ? jsonDecode(res.body) : {}) : {};
      if (res.statusCode == 200 || res.statusCode == 201) {
        // Code resend succeeded — no blocking dialog shown
      } else {
        final errorMsg = body['message'] ?? body['error'] ?? res.body;
        await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Error'), content: Text('$errorMsg'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
      }
    } catch (e) {
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Network error'), content: Text('Could not reach server: $e'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.verified_user, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Verify Account', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('Enter the verification code sent to your email', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 22),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          initialValue: _email,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            filled: true,
                            fillColor: const Color(0xFFF5F6F8),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (v) => _email = v?.trim() ?? '',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter email' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Verification code',
                            filled: true,
                            fillColor: const Color(0xFFF5F6F8),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onSaved: (v) => _code = v?.trim() ?? '',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter code' : null,
                        ),
                        const SizedBox(height: 18),

                        GestureDetector(
                          onTap: _isLoading ? null : _submit,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF0DA96B), Color(0xFF06C17A)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2))
                                  : const Text('Verify', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isLoading ? null : _resend,
                          child: const Text('Resend code', style: TextStyle(color: Color(0xFF8E3A44))),
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
}
