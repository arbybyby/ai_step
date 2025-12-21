import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.isEmpty) ? 'Enter email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Enter password' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading
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
                          if (status == 200 || status == 201) {
                            final sp = await SharedPreferences.getInstance();
                            await sp.setBool('isLoggedIn', true);
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
                child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/signup'),
                child: const Text('Create a new account'),
              )
            ],
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
}
