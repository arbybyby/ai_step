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
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool keyboardOpen = bottomInset > 0;
    final double topIconSize = keyboardOpen ? 56 : 88;
    final double titleFontSize = keyboardOpen ? 24 : 36;
    final double subtitleFontSize = keyboardOpen ? 13 : 16;
    final double topSpacing = keyboardOpen ? 8 : 18;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B8B57), Color(0xFF0EA859)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: topSpacing),
              Container(
                width: topIconSize,
                height: topIconSize,
                decoration: BoxDecoration(color: Colors.white24.withOpacity(0.08), borderRadius: BorderRadius.circular(18)),
                child: Center(child: Icon(Icons.directions_walk, size: topIconSize * 0.45, color: Colors.white)),
              ),
              SizedBox(height: topSpacing),
              Text('Create Account', style: TextStyle(color: Colors.white, fontSize: titleFontSize, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Join us and start your fitness journey', style: TextStyle(color: Colors.white70, fontSize: subtitleFontSize)),
              const SizedBox(height: 22),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(left: 18, right: 18, bottom: 18),
                  padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))]),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildField(hint: 'First Name', onSaved: (v) => _firstName = v?.trim() ?? '', validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter first name' : null),
                          const SizedBox(height: 10),
                          _buildField(hint: 'Last Name', onSaved: (v) => _lastName = v?.trim() ?? '', validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter last name' : null),
                          const SizedBox(height: 10),
                          _buildField(hint: 'Email', keyboardType: TextInputType.emailAddress, onSaved: (v) => _email = v?.trim() ?? '', validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter email';
                            final email = v.trim();
                            if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email)) return 'Enter valid email';
                            return null;
                          }),
                          const SizedBox(height: 10),
                          _buildField(hint: 'Password', obscureText: _obscurePassword, suffix: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)), onSaved: (v) => _password = v ?? '', validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 chars' : null),
                          const SizedBox(height: 10),
                          _buildField(hint: 'Confirm Password', obscureText: _obscureConfirm, suffix: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)), onSaved: (v) => _confirmPassword = v ?? '', validator: (v) {
                            if (v == null || v.length < 6) return 'Minimum 6 chars';
                            return null;
                          }),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF0B8B57), Color(0xFF0EA859)]),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(25),
                                onTap: _isLoading
                                    ? null
                                    : () async {
                                        print('SignUp: Create account tapped');
                                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitting...')));
                                        if (_formKey.currentState?.validate() ?? false) {
                                          _formKey.currentState?.save();
                                          if (_password != _confirmPassword) {
                                            await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Error'), content: const Text('Passwords do not match'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
                                            return;
                                          }
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          try {
                                            final res = await AuthService.register(email: _email, password: _password, firstName: _firstName, lastName: _lastName);
                                            final int status = res.statusCode;
                                            print('SignUp Response - Status: $status, Body: ${res.body}');
                                            final Map<String, dynamic> body = res.body.isNotEmpty ? (res.body.startsWith('{') ? Map<String, dynamic>.from(jsonDecode(res.body)) : {}) : {};
                                            if (status == 201) {
                                              // Clear all local device data before registering a new account
                                              try {
                                                await StepStorageService().clear();
                                                print('SignUp: StepStorageService cleared');
                                              } catch (e) {
                                                print('SignUp: Failed to clear StepStorageService: $e');
                                              }
                                              try {
                                                final sp = await SharedPreferences.getInstance();
                                                await sp.clear();
                                                print('SignUp: SharedPreferences cleared');
                                              } catch (e) {
                                                print('SignUp: Failed to clear SharedPreferences: $e');
                                              }
                                              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => VerifyScreen(email: _email, password: _password)));
                                            } else if (status == 400) {
                                              final message = body['message'] ?? 'Invalid request';
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
                                      },
                                child: Center(child: _isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 2)) : const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushReplacementNamed('/signin'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [Text('Already have an account? ', style: TextStyle(color: Colors.black54, fontSize: 13)), Text('Sign In', style: TextStyle(color: Color(0xFFAD2B2B), fontWeight: FontWeight.w700, fontSize: 13))],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
    }

  Widget _buildField({required String hint, TextInputType? keyboardType, bool obscureText = false, Widget? suffix, FormFieldSetter<String>? onSaved, FormFieldValidator<String>? validator}) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w600, fontSize: 16),
        filled: true,
        fillColor: const Color(0xFFF6F6F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        suffixIcon: suffix,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      onSaved: onSaved,
      validator: validator,
    );
  }
}
