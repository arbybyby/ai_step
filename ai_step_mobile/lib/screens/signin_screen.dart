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
                            onPressed: () {},
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
}
